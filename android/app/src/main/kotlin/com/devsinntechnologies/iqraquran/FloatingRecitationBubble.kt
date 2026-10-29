package com.devsinntechnologies.iqraquran

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.hypot

/**
 * Floats the Iqra logo over other apps while a recitation is loaded and the
 * app is in the background. Tapping the logo opens controls; dragging it
 * onto the close target stops the recitation.
 *
 * Dart sends the recitation's state over [CHANNEL] and the bubble sends taps
 * back as commands, so it controls the recitation exactly as the app does.
 * Inside the app, Flutter draws its own floating logo; this one only shows
 * while the app is not visible.
 */
object FloatingRecitationBubble : MethodChannel.MethodCallHandler {
    const val CHANNEL = "iqra/floating_player"
    private const val TAG = "FloatingBubble"

    private const val BUBBLE_WINDOW_DP = 88
    private const val FACE_DP = 60
    private const val PANEL_WIDTH_DP = 300
    private const val CLOSE_WINDOW_DP = 84

    private data class State(
        val active: Boolean = false,
        val title: String = "",
        val subtitle: String = "",
        val playing: Boolean = false,
        val hasNext: Boolean = true,
        val color: Int = 0xFF227C9E.toInt(),
    )

    private var appContext: Context? = null
    private var channel: MethodChannel? = null
    private val windowManager: WindowManager?
        get() = appContext?.getSystemService(Context.WINDOW_SERVICE) as? WindowManager

    private var enabled = true
    private var appVisible = true
    // "Hide" keeps the bubble away until the app is next opened.
    private var hidden = false
    private var recitation = State()

    // Where the bubble rests; kept between shows. -1 means not placed yet.
    private var restX = -1
    private var restY = -1

    private var bubble: BubbleViews? = null
    private var panel: PanelViews? = null
    private var closeTarget: View? = null
    private var overClose = false
    private var lastOutsideCollapse = 0L
    private var logo: Bitmap? = null

    fun attach(context: Context, channel: MethodChannel) {
        appContext = context.applicationContext
        this.channel = channel
        channel.setMethodCallHandler(this)
    }

    /** Called from the activity's onStart and onStop. */
    fun setAppVisible(visible: Boolean) {
        appVisible = visible
        if (visible) hidden = false
        refresh()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "update" -> {
                recitation = State(
                    active = call.argument<Boolean>("active") ?: false,
                    title = call.argument<String>("title") ?: "",
                    subtitle = call.argument<String>("subtitle") ?: "",
                    playing = call.argument<Boolean>("playing") ?: false,
                    hasNext = call.argument<Boolean>("hasNext") ?: true,
                    color = (call.argument<Number>("color") ?: recitation.color).toInt(),
                )
                refresh()
                result.success(null)
            }
            "setEnabled" -> {
                enabled = call.arguments as? Boolean ?: true
                refresh()
                result.success(null)
            }
            "canDrawOverlays" -> result.success(canDrawOverlays())
            "openPermissionSettings" -> {
                openPermissionSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun canDrawOverlays(): Boolean {
        val context = appContext ?: return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)
    }

    private fun openPermissionSettings() {
        val context = appContext ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "Overlay settings unavailable", e)
        }
    }

    private fun send(command: String) {
        try {
            channel?.invokeMethod("command", command)
        } catch (e: Exception) {
            Log.w(TAG, "Could not send $command", e)
        }
    }

    private fun refresh() {
        val show = enabled && !appVisible && !hidden && recitation.active && canDrawOverlays()
        if (!show) {
            removeAll()
            return
        }
        if (bubble == null) addBubble()
        bind()
    }

    // ── Bubble ──────────────────────────────────────────────────────────────

    private class BubbleViews(
        val root: FrameLayout,
        val params: WindowManager.LayoutParams,
        val face: FrameLayout,
        val halo: View,
        val badge: FrameLayout,
        val badgeIcon: ImageView,
        val bob: ObjectAnimator,
        val pulse: ObjectAnimator,
    )

    @SuppressLint("ClickableViewAccessibility")
    private fun addBubble() {
        val context = appContext ?: return
        val wm = windowManager ?: return
        val windowSize = dp(BUBBLE_WINDOW_DP)

        val root = FrameLayout(context).apply {
            clipChildren = false
            contentDescription = "IQRA recitation player. Tap for controls."
        }
        val halo = View(context).apply {
            background = oval(recitation.color)
            alpha = 0f
        }
        root.addView(halo, FrameLayout.LayoutParams(dp(FACE_DP), dp(FACE_DP), Gravity.CENTER))

        // Logo and badge move together in the gentle floating motion.
        val floatGroup = FrameLayout(context).apply { clipChildren = false }
        root.addView(floatGroup, FrameLayout.LayoutParams(dp(FACE_DP + 8), dp(FACE_DP + 8), Gravity.CENTER))

        val face = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.WHITE)
                setStroke(dp(3), recitation.color)
            }
            elevation = dp(6).toFloat()
        }
        floatGroup.addView(face, FrameLayout.LayoutParams(dp(FACE_DP), dp(FACE_DP), Gravity.CENTER))

        val logoView = ImageView(context).apply {
            setImageBitmap(logoBitmap(context))
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
        }
        face.addView(logoView, FrameLayout.LayoutParams(dp(FACE_DP - 14), dp(FACE_DP - 14), Gravity.CENTER))

        val badgeIcon = ImageView(context)
        val badge = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(recitation.color)
                setStroke(dp(2), Color.WHITE)
            }
            elevation = dp(8).toFloat()
            addView(badgeIcon, FrameLayout.LayoutParams(dp(13), dp(13), Gravity.CENTER))
        }
        floatGroup.addView(badge, FrameLayout.LayoutParams(dp(22), dp(22), Gravity.BOTTOM or Gravity.END))

        val (screenW, screenH) = screenSize()
        if (restX < 0) {
            restX = screenW - windowSize
            restY = (screenH * 0.6).toInt()
        }
        val params = overlayParams(windowSize, windowSize).apply {
            x = restX.coerceIn(0, maxOf(0, screenW - windowSize))
            y = restY.coerceIn(0, maxOf(0, screenH - windowSize))
        }

        val bob = ObjectAnimator.ofFloat(floatGroup, View.TRANSLATION_Y, -dp(3).toFloat(), dp(3).toFloat()).apply {
            duration = 1600
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
        }
        val pulse = ObjectAnimator.ofPropertyValuesHolder(
            halo,
            PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.45f),
            PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.45f),
            PropertyValuesHolder.ofFloat(View.ALPHA, 0.55f, 0f),
        ).apply {
            duration = 1400
            repeatCount = ValueAnimator.INFINITE
        }

        val views = BubbleViews(root, params, face, halo, badge, badgeIcon, bob, pulse)
        root.setOnTouchListener(BubbleTouch(views))

        try {
            wm.addView(root, params)
        } catch (e: Exception) {
            Log.w(TAG, "Could not show the floating bubble", e)
            return
        }
        bubble = views
        bob.start()

        // Pops in.
        floatGroup.scaleX = 0.3f
        floatGroup.scaleY = 0.3f
        floatGroup.animate().scaleX(1f).scaleY(1f).setDuration(320)
            .setInterpolator(OvershootInterpolator(2f)).start()
    }

    private fun bind() {
        val views = bubble ?: return
        (views.face.background as? GradientDrawable)?.setStroke(dp(3), recitation.color)
        (views.badge.background as? GradientDrawable)?.setColor(recitation.color)
        (views.halo.background as? GradientDrawable)?.setColor(recitation.color)
        views.badgeIcon.setImageResource(
            if (recitation.playing) R.drawable.ic_bubble_pause else R.drawable.ic_bubble_play,
        )
        if (recitation.playing && !views.pulse.isStarted) {
            views.pulse.start()
        } else if (!recitation.playing && views.pulse.isStarted) {
            views.pulse.cancel()
            views.halo.alpha = 0f
        }
        panel?.let { bindPanel(it) }
    }

    private class BubbleTouch(private val views: BubbleViews) : View.OnTouchListener {
        private var downX = 0f
        private var downY = 0f
        private var startX = 0
        private var startY = 0
        private var dragging = false

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(view: View, event: MotionEvent): Boolean {
            val wm = windowManager ?: return false
            val slop = ViewConfiguration.get(view.context).scaledTouchSlop
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = views.params.x
                    startY = views.params.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && hypot(dx, dy) > slop) {
                        dragging = true
                        collapsePanel()
                        showCloseTarget()
                    }
                    if (dragging) {
                        val (w, h) = screenSize()
                        val size = views.root.width
                        views.params.x = (startX + dx.toInt()).coerceIn(0, maxOf(0, w - size))
                        views.params.y = (startY + dy.toInt()).coerceIn(0, maxOf(0, h - size))
                        safeUpdate(wm, views.root, views.params)
                        updateOverClose(views)
                    }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) {
                        hideCloseTarget()
                        if (overClose) {
                            overClose = false
                            view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                            send("stop")
                            removeAll()
                        } else {
                            snapToEdge(views)
                        }
                    } else if (event.actionMasked == MotionEvent.ACTION_UP) {
                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                        // The tap that closed the panel from outside should
                        // not open it again straight away.
                        if (panel != null) {
                            collapsePanel()
                        } else if (SystemClock.uptimeMillis() - lastOutsideCollapse > 300) {
                            expandPanel()
                        }
                    }
                    dragging = false
                }
            }
            return true
        }
    }

    private fun snapToEdge(views: BubbleViews) {
        val wm = windowManager ?: return
        val (w, _) = screenSize()
        val size = views.root.width
        val target = if (views.params.x + size / 2 < w / 2) 0 else w - size
        ValueAnimator.ofInt(views.params.x, target).apply {
            duration = 380
            interpolator = OvershootInterpolator(1.4f)
            addUpdateListener {
                if (bubble !== views) return@addUpdateListener
                views.params.x = (it.animatedValue as Int).coerceIn(0, maxOf(0, w - size))
                safeUpdate(wm, views.root, views.params)
            }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    restX = views.params.x
                    restY = views.params.y
                }
            })
            start()
        }
    }

    // ── Close target ────────────────────────────────────────────────────────

    private fun showCloseTarget() {
        val context = appContext ?: return
        val wm = windowManager ?: return
        if (closeTarget != null) return
        val size = dp(CLOSE_WINDOW_DP)
        val root = FrameLayout(context)
        val circle = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0x99000000.toInt())
                setStroke(dp(2), Color.WHITE)
            }
            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_bubble_close)
            }, FrameLayout.LayoutParams(dp(30), dp(30), Gravity.CENTER))
        }
        root.addView(circle, FrameLayout.LayoutParams(dp(64), dp(64), Gravity.CENTER))
        val (w, h) = screenSize()
        val params = overlayParams(size, size, touchable = false).apply {
            x = (w - size) / 2
            y = h - size - dp(70)
        }
        try {
            wm.addView(root, params)
            closeTarget = root
            circle.scaleX = 0f
            circle.scaleY = 0f
            circle.animate().scaleX(1f).scaleY(1f).setDuration(220)
                .setInterpolator(OvershootInterpolator()).start()
        } catch (e: Exception) {
            Log.w(TAG, "Could not show the close target", e)
        }
    }

    private fun updateOverClose(views: BubbleViews) {
        val target = closeTarget ?: return
        val (w, h) = screenSize()
        val size = dp(CLOSE_WINDOW_DP)
        val targetX = (w / 2).toFloat()
        val targetY = (h - size / 2 - dp(70)).toFloat()
        val bubbleX = views.params.x + views.root.width / 2f
        val bubbleY = views.params.y + views.root.height / 2f
        val over = hypot(bubbleX - targetX, bubbleY - targetY) < dp(72)
        if (over != overClose) {
            overClose = over
            if (over) target.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
            val circle = (target as ViewGroup).getChildAt(0)
            (circle.background as? GradientDrawable)?.setColor(
                if (over) 0xFFE53935.toInt() else 0x99000000.toInt(),
            )
            circle.animate().scaleX(if (over) 1.25f else 1f)
                .scaleY(if (over) 1.25f else 1f).setDuration(150).start()
            views.root.animate().scaleX(if (over) 0.8f else 1f)
                .scaleY(if (over) 0.8f else 1f).setDuration(150).start()
        }
    }

    private fun hideCloseTarget() {
        val target = closeTarget ?: return
        closeTarget = null
        windowManager?.let { safeRemove(it, target) }
    }

    // ── Controls panel ──────────────────────────────────────────────────────

    private class PanelViews(
        val root: FrameLayout,
        val card: LinearLayout,
        val title: TextView,
        val subtitle: TextView,
        val playIcon: ImageView,
        val next: View,
        val buttons: List<View>,
    )

    @SuppressLint("ClickableViewAccessibility")
    private fun expandPanel() {
        val context = appContext ?: return
        val wm = windowManager ?: return
        val anchor = bubble ?: return
        if (panel != null) return

        val shadowPad = dp(14)
        val root = FrameLayout(context).apply {
            setPadding(shadowPad, shadowPad, shadowPad, shadowPad)
            clipToPadding = false
        }
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(14), dp(10), dp(16))
            elevation = dp(12).toFloat()
        }
        root.addView(card, FrameLayout.LayoutParams(dp(PANEL_WIDTH_DP), ViewGroup.LayoutParams.WRAP_CONTENT))

        // Header: what is being recited, and a button to fold the panel.
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val texts = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        val title = TextView(context).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        val subtitle = TextView(context).apply {
            setTextColor(0xCCFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        texts.addView(title)
        texts.addView(subtitle)
        header.addView(texts, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        val fold = iconButton(context, R.drawable.ic_bubble_close, 36, 20, Color.TRANSPARENT, Color.WHITE, "Close controls") {
            collapsePanel()
        }
        header.addView(fold)
        card.addView(header)

        // Previous, play/pause and next.
        val controls = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val previous = iconButton(context, R.drawable.ic_bubble_previous, 50, 26, Color.WHITE, recitation.color, "Previous ayah") {
            send("previous")
        }
        val play = iconButton(context, R.drawable.ic_bubble_play, 66, 34, Color.WHITE, recitation.color, "Play or pause") {
            send("toggle")
        }
        val next = iconButton(context, R.drawable.ic_bubble_next, 50, 26, Color.WHITE, recitation.color, "Next ayah") {
            send("next")
        }
        controls.addView(previous)
        controls.addView(space(context, 22))
        controls.addView(play)
        controls.addView(space(context, 22))
        controls.addView(next)
        card.addView(controls, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(14)
            bottomMargin = dp(14)
            rightMargin = dp(8)
        })

        // Open the app, or hide the bubble until it is next opened.
        val actions = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        actions.addView(chip(context, R.drawable.ic_bubble_open, "Open IQRA") {
            collapsePanel()
            openApp()
        })
        actions.addView(space(context, 8))
        actions.addView(chip(context, R.drawable.ic_bubble_hide, "Hide") {
            hidden = true
            removeAll()
        })
        card.addView(actions)

        val views = PanelViews(
            root, card, title, subtitle,
            play.getChildAt(0) as ImageView, next, listOf(previous, play, next),
        )
        bindPanel(views)

        // Place it beside the logo, on the side facing into the screen.
        val (w, h) = screenSize()
        root.measure(
            View.MeasureSpec.makeMeasureSpec(dp(PANEL_WIDTH_DP) + 2 * shadowPad, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        val panelW = root.measuredWidth
        val panelH = root.measuredHeight
        val bx = anchor.params.x
        val by = anchor.params.y
        val bSize = dp(BUBBLE_WINDOW_DP)
        val onRight = bx + bSize / 2 > w / 2
        val below = by + bSize / 2 < h / 2
        val params = overlayParams(panelW, panelH, watchOutside = true).apply {
            x = (if (onRight) bx + bSize - panelW + shadowPad else bx - shadowPad)
                .coerceIn(0, maxOf(0, w - panelW))
            y = (if (below) by + bSize - dp(10) else by - panelH + dp(10))
                .coerceIn(0, maxOf(0, h - panelH))
        }
        root.setOnTouchListener { _, event ->
            if (event.actionMasked == MotionEvent.ACTION_OUTSIDE) {
                lastOutsideCollapse = SystemClock.uptimeMillis()
                collapsePanel()
                true
            } else {
                false
            }
        }
        try {
            wm.addView(root, params)
        } catch (e: Exception) {
            Log.w(TAG, "Could not show the controls", e)
            return
        }
        panel = views

        // Grows out of the logo, then the buttons pop in one by one.
        card.pivotX = if (onRight) dp(PANEL_WIDTH_DP).toFloat() else 0f
        card.pivotY = if (below) 0f else panelH.toFloat()
        card.alpha = 0f
        card.scaleX = 0.8f
        card.scaleY = 0.8f
        card.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(260)
            .setInterpolator(OvershootInterpolator(1.2f)).start()
        views.buttons.forEachIndexed { i, button ->
            button.scaleX = 0f
            button.scaleY = 0f
            button.animate().scaleX(1f).scaleY(1f).setStartDelay(90L + 70L * i)
                .setDuration(260).setInterpolator(OvershootInterpolator(2f)).start()
        }
    }

    private fun bindPanel(views: PanelViews) {
        views.title.text = recitation.title
        views.subtitle.text = recitation.subtitle
        views.playIcon.setImageResource(
            if (recitation.playing) R.drawable.ic_bubble_pause else R.drawable.ic_bubble_play,
        )
        views.next.isEnabled = recitation.hasNext
        views.next.alpha = if (recitation.hasNext) 1f else 0.4f
        val deep = blend(recitation.color, Color.BLACK, 0.35f)
        views.card.background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR, intArrayOf(recitation.color, deep),
        ).apply { cornerRadius = dp(26).toFloat() }
        views.buttons.forEach { button ->
            ((button as ViewGroup).getChildAt(0) as ImageView).imageTintList =
                ColorStateList.valueOf(recitation.color)
        }
    }

    private fun collapsePanel() {
        val views = panel ?: return
        panel = null
        val wm = windowManager ?: return
        views.card.animate().alpha(0f).scaleX(0.85f).scaleY(0.85f).setDuration(160)
            .withEndAction { safeRemove(wm, views.root) }.start()
    }

    private fun openApp() {
        val context = appContext ?: return
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not open the app", e)
        }
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private fun removeAll() {
        val wm = windowManager
        hideCloseTarget()
        panel?.let { views -> wm?.let { safeRemove(it, views.root) } }
        panel = null
        bubble?.let { views ->
            views.bob.cancel()
            views.pulse.cancel()
            restX = views.params.x
            restY = views.params.y
            wm?.let { safeRemove(it, views.root) }
        }
        bubble = null
        overClose = false
    }

    private fun overlayParams(
        width: Int,
        height: Int,
        touchable: Boolean = true,
        watchOutside: Boolean = false,
    ): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        var flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        if (!touchable) flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        if (watchOutside) flags = flags or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
        return WindowManager.LayoutParams(width, height, type, flags, PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.START
        }
    }

    private fun iconButton(
        context: Context,
        icon: Int,
        sizeDp: Int,
        iconDp: Int,
        background: Int,
        tint: Int,
        label: String,
        onTap: () -> Unit,
    ): FrameLayout {
        val mask = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.WHITE) }
        return FrameLayout(context).apply {
            this.background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(background)
            }
            foreground = RippleDrawable(ColorStateList.valueOf(0x33000000), null, mask)
            if (background != Color.TRANSPARENT) elevation = dp(4).toFloat()
            contentDescription = label
            isClickable = true
            setOnClickListener {
                it.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onTap()
            }
            addView(ImageView(context).apply {
                setImageResource(icon)
                imageTintList = ColorStateList.valueOf(tint)
            }, FrameLayout.LayoutParams(dp(iconDp), dp(iconDp), Gravity.CENTER))
            layoutParams = LinearLayout.LayoutParams(dp(sizeDp), dp(sizeDp))
        }
    }

    private fun chip(context: Context, icon: Int, label: String, onTap: () -> Unit): View {
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(7), dp(14), dp(7))
            background = GradientDrawable().apply {
                cornerRadius = dp(18).toFloat()
                setColor(0x2EFFFFFF)
            }
            foreground = RippleDrawable(
                ColorStateList.valueOf(0x33FFFFFF),
                null,
                GradientDrawable().apply { cornerRadius = dp(18).toFloat(); setColor(Color.WHITE) },
            )
            isClickable = true
            setOnClickListener { onTap() }
            addView(ImageView(context).apply { setImageResource(icon) }, LinearLayout.LayoutParams(dp(16), dp(16)))
            addView(TextView(context).apply {
                text = label
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                typeface = Typeface.DEFAULT_BOLD
            }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                leftMargin = dp(6)
            })
        }
    }

    private fun space(context: Context, widthDp: Int) =
        View(context).apply { layoutParams = LinearLayout.LayoutParams(dp(widthDp), 1) }

    private fun oval(color: Int) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
    }

    private fun logoBitmap(context: Context): Bitmap? {
        logo?.let { return it }
        return try {
            val options = BitmapFactory.Options().apply { inSampleSize = 2 }
            BitmapFactory.decodeResource(context.resources, R.raw.recitation_artwork, options)
                .also { logo = it }
        } catch (e: Exception) {
            Log.w(TAG, "Logo unavailable", e)
            null
        }
    }

    private fun screenSize(): Pair<Int, Int> {
        val wm = windowManager
        if (wm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = wm.currentWindowMetrics.bounds
            return bounds.width() to bounds.height()
        }
        val metrics = appContext?.resources?.displayMetrics ?: return 1080 to 1920
        return metrics.widthPixels to metrics.heightPixels
    }

    private fun safeUpdate(wm: WindowManager, view: View, params: WindowManager.LayoutParams) {
        try {
            if (view.isAttachedToWindow) wm.updateViewLayout(view, params)
        } catch (e: Exception) {
            Log.w(TAG, "Could not move the bubble", e)
        }
    }

    private fun safeRemove(wm: WindowManager, view: View) {
        try {
            if (view.isAttachedToWindow) wm.removeView(view)
        } catch (e: Exception) {
            Log.w(TAG, "Could not remove an overlay", e)
        }
    }

    private fun blend(from: Int, to: Int, amount: Float): Int {
        fun mix(a: Int, b: Int) = (a + (b - a) * amount).toInt()
        return Color.argb(
            Color.alpha(from),
            mix(Color.red(from), Color.red(to)),
            mix(Color.green(from), Color.green(to)),
            mix(Color.blue(from), Color.blue(to)),
        )
    }

    private fun dp(value: Int): Int {
        val metrics = appContext?.resources?.displayMetrics ?: return value
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), metrics).toInt()
    }
}
