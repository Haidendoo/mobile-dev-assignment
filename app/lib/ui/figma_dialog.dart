import 'package:material_ui/material_ui.dart';

import 'dart:ui' as ui;

/// Shared confirmation surface from S21+ · Restart · In progress (7:13711).
class FigmaDialog extends StatelessWidget {
  const FigmaDialog({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  });
  final String title, body, action;
  final VoidCallback onConfirm, onCancel;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 376),
      child: Material(
        color: const Color(0xff172c23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xff52715b)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 17, 24, 21),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 39,
                    fontWeight: FontWeight.w700,
                    fontVariations: [ui.FontVariation('wght', 700)],
                    color: Color(0xfffff1d2),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    color: Color(0xffc5d0b2),
                  ),
                ),
                const SizedBox(height: 16),
                _button(action, onConfirm, true),
                const SizedBox(height: 12),
                _button('Cancel', onCancel, false),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _button(String label, VoidCallback action, bool primary) => SizedBox(
    height: 48,
    child: TextButton(
      onPressed: action,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Color(primary ? 0xffeacb80 : 0xff243d31),
        foregroundColor: Color(primary ? 0xff111e19 : 0xfffff1d2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Color(primary ? 0xfffde6ab : 0xff52715b)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontVariations: [
            ui.FontVariation('wght', 700),
            ui.FontVariation('opsz', 14),
          ],
          fontSize: 15,
        ),
      ),
      child: Text(label),
    ),
  );
}
