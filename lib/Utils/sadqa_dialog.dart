import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/theme_provider.dart';

class SadqaDialog {
  /// Shows the Sadqa Jariya dialog every time this is called.
  /// Call it from Home's initState via addPostFrameCallback.
  static void show(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => const _SadqaDialogWidget(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Dialog Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SadqaDialogWidget extends StatefulWidget {
  const _SadqaDialogWidget({Key? key}) : super(key: key);

  @override
  State<_SadqaDialogWidget> createState() => _SadqaDialogWidgetState();
}

class _SadqaDialogWidgetState extends State<_SadqaDialogWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  bool _showBankDetails = false;

  // ── Bank Info ──────────────────────────────────────────────────────────────
  static const String _bank = 'UBL';
  static const String _accountName = 'DevsinnTechnologies';
  static const String _iban = 'PK90UNIL0109000313694453';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅  Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share() {
    Share.share(
      '🤍 Support IQRA QURAN – Sadqa Jariya\n\n'
      'Bank: $_bank\n'
      'Account Name: $_accountName\n'
      'IBAN: $_iban\n\n'
      'JazakAllah Khair! Every contribution keeps the app free for everyone. 🕌',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primary = theme.selectedTheme;
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              width: size.width * 0.88,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.18),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header banner ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, primary.withOpacity(0.75)],
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        // App logo
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/logo-app.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'IQRA QURAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '— Sadqa Jariya —',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ───────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                    child: Column(
                      children: [
                        Text(
                          'This app is built with love to make the Holy Quran accessible to everyone — completely free, no ads. Your support keeps it alive and earns you Sadqa Jariya (ongoing reward).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── View Bank Details button ───────────────────────
                        _GradientButton(
                          label: _showBankDetails
                              ? 'Hide Bank Details'
                              : '🏦  View Bank Details',
                          color: primary,
                          onTap: () => setState(
                              () => _showBankDetails = !_showBankDetails),
                        ),

                        // ── Expandable bank card ───────────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _showBankDetails
                              ? Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: primary.withOpacity(0.2),
                                        width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      _BankRow(
                                          label: 'Bank',
                                          value: _bank,
                                          color: primary,
                                          onCopy: _copy),
                                      Divider(
                                          height: 18, color: Colors.grey[200]),
                                      _BankRow(
                                          label: 'Account Name',
                                          value: _accountName,
                                          color: primary,
                                          onCopy: _copy),
                                      Divider(
                                          height: 18, color: Colors.grey[200]),
                                      _BankRow(
                                          label: 'IBAN',
                                          value: _iban,
                                          color: primary,
                                          onCopy: _copy),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 12),

                        // ── Share button ───────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _share,
                            icon: Icon(Icons.share_rounded,
                                color: primary, size: 20),
                            label: Text(
                              'Share & Spread Reward',
                              style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        // ── Close ──────────────────────────────────────────
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton(
      {required this.label, required this.color, required this.onTap, Key? key})
      : super(key: key);

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.onCopy,
      Key? key})
      : super(key: key);

  final String label;
  final String value;
  final Color color;
  final void Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy_rounded, size: 18, color: color),
          onPressed: () => onCopy(value),
          tooltip: 'Copy $label',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
