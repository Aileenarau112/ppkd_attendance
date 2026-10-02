import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    Color bg;
    Color text;
    Color dot;
    String display = status;

    if (s.contains("hadir") || s.contains("masuk") || s.contains("tepat")) {
      bg = AppTheme.successLight;
      text = AppTheme.success;
      dot = AppTheme.success;
      display = status.isEmpty ? "Hadir" : status.toUpperCase();
    } else if (s.contains("izin")) {
      bg = AppTheme.infoLight;
      text = AppTheme.info;
      dot = AppTheme.info;
      display = "IZIN";
    } else if (s.contains("sakit")) {
      bg = AppTheme.warningLight;
      text = AppTheme.warning;
      dot = AppTheme.warning;
      display = "SAKIT";
    } else if (s.contains("pulang")) {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFEA580C);
      dot = const Color(0xFFEA580C);
      display = "SELESAI";
    } else if (s.contains("belum")) {
      bg = AppTheme.warningLight;
      text = AppTheme.warning;
      dot = AppTheme.warning;
      display = "BELUM ABSEN";
    } else {
      bg = const Color(0xFFF1F5F9);
      text = AppTheme.textSecondary;
      dot = AppTheme.textSecondary;
      display = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            display,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
