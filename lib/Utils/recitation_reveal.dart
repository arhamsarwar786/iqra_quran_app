import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../Widgets/audio_controller_overlay.dart';

/// Scrolling helpers that keep the verse being recited in view.

const double _topGapFraction = 0.12;
const double _clearance = 12;

/// Alignment for [Scrollable.ensureVisible] that places [target] near the top
/// of its scroll view, below the mini player when it is parked over that area.
double recitationAlignment(BuildContext target) {
  final targetBox = target.findRenderObject();
  final viewportBox = Scrollable.maybeOf(target)?.context.findRenderObject();
  if (targetBox is! RenderBox ||
      viewportBox is! RenderBox ||
      !targetBox.hasSize ||
      !viewportBox.hasSize) {
    return _topGapFraction;
  }

  final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
  final viewportHeight = viewportBox.size.height;
  var gap = viewportHeight * _topGapFraction;

  final player = QuranMiniPlayer.occupiedArea;
  if (player != null &&
      player.bottom > viewportTop &&
      player.top < viewportTop + viewportHeight / 2) {
    gap = (player.bottom - viewportTop + _clearance).clamp(gap, viewportHeight);
  }

  // ensureVisible places the target's top at alignment * (viewport - target).
  final free = viewportHeight - targetBox.size.height;
  if (free <= 0) return 0;
  return (gap / free).clamp(0.0, 1.0);
}

Future<void> revealRecitation(BuildContext target) {
  return Scrollable.ensureVisible(
    target,
    duration: const Duration(milliseconds: 350),
    alignment: recitationAlignment(target),
    alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    curve: Curves.easeInOut,
  );
}

/// Reveals item [index] of [count] in a lazily built list, where an item only
/// has a context once it is near the viewport. [keys] holds the keys of the
/// list items. Until the target is built, it steps from the nearest built item
/// using the measured item height, so each jump lands closer.
Future<void> revealLazyRecitation({
  required ScrollController controller,
  required Map<int, GlobalKey> keys,
  required int index,
  required int count,
}) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    final target = keys[index]?.currentContext;
    if (target != null && target.mounted) {
      await revealRecitation(target);
      return;
    }
    if (!controller.hasClients || count <= 1) return;
    final position = controller.position;
    final estimate = _offsetFromBuiltItems(keys, index) ??
        position.maxScrollExtent * index / (count - 1);
    controller.jumpTo(
        estimate.clamp(position.minScrollExtent, position.maxScrollExtent));
    await SchedulerBinding.instance.endOfFrame;
  }
}

/// Scroll offset of item [index], extrapolated from the built item nearest to
/// it and the average height of the built items.
double? _offsetFromBuiltItems(Map<int, GlobalKey> keys, int index) {
  int? nearest;
  double nearestOffset = 0;
  double totalHeight = 0;
  var built = 0;
  for (final entry in keys.entries) {
    final box = entry.value.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) continue;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) continue;
    built++;
    totalHeight += box.size.height;
    if (nearest == null ||
        (entry.key - index).abs() < (nearest - index).abs()) {
      nearest = entry.key;
      nearestOffset = viewport.getOffsetToReveal(box, 0).offset;
    }
  }
  if (nearest == null) return null;
  return nearestOffset + (index - nearest) * (totalHeight / built);
}
