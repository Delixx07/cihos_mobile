import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vector illustrations drawn in code rather than shipped as image files.
///
/// Keeping them as painters means they stay sharp at any density, add nothing
/// to the bundle, and never go missing.
abstract final class Illustrations {
  /// Empty-state artwork: a calendar with a soft blob behind it.
  static Widget emptySchedule({double size = 200}) =>
      _Painted(size: size, painter: _EmptySchedulePainter());

  /// A stylised QR square — stands in until a real code is generated.
  static Widget qrCode({double size = 120, Color? color}) =>
      _Painted(size: size, painter: _QrPainter(color ?? Colors.black));

  /// Abstract wellness artwork for the Sehat-mu header.
  static Widget wellness({double size = 120}) =>
      _Painted(size: size, painter: _WellnessPainter());

  /// A clinician at a desk — the header on the doctor-finder screens.
  static Widget doctorAtDesk({double width = 300}) => _Painted(
    size: width,
    aspectRatio: 300 / 240,
    painter: _DoctorAtDeskPainter(),
  );
}

class _Painted extends StatelessWidget {
  const _Painted({
    required this.size,
    required this.painter,
    this.aspectRatio = 1,
  });

  final double size;
  final CustomPainter painter;

  /// Width over height; square unless a painter needs otherwise.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size / aspectRatio,
      child: CustomPaint(painter: painter),
    );
  }
}

/// A calendar page over an organic blob, with a rising arrow to suggest
/// "nothing booked yet, go make one".
class _EmptySchedulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft blob behind everything.
    final blob = Path()
      ..moveTo(w * 0.10, h * 0.55)
      ..cubicTo(w * 0.02, h * 0.28, w * 0.28, h * 0.06, w * 0.52, h * 0.10)
      ..cubicTo(w * 0.80, h * 0.14, w * 1.00, h * 0.36, w * 0.92, h * 0.62)
      ..cubicTo(w * 0.85, h * 0.86, w * 0.55, h * 0.98, w * 0.32, h * 0.90)
      ..cubicTo(w * 0.16, h * 0.84, w * 0.14, h * 0.70, w * 0.10, h * 0.55)
      ..close();

    canvas.drawPath(
      blob,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFFFFF), Color(0x14FFFFFF)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Calendar body.
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.30, w * 0.52, h * 0.44),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(card, Paint()..color = Colors.white);

    // Header band.
    final header = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.24, h * 0.30, w * 0.52, h * 0.11),
      topLeft: Radius.circular(w * 0.05),
      topRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(header, Paint()..color = AppColors.link);

    // Binder rings.
    final ring = Paint()..color = AppColors.accentSoft;
    for (final dx in [0.36, 0.64]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * dx, h * 0.25, w * 0.035, h * 0.10),
          Radius.circular(w * 0.02),
        ),
        ring,
      );
    }

    // Date grid.
    final dot = Paint()..color = AppColors.textPrimary.withValues(alpha: 0.18);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(w * (0.32 + col * 0.12), h * (0.49 + row * 0.09)),
          w * 0.018,
          dot,
        );
      }
    }

    // Rising arrow across the card.
    final arrow = Path()
      ..moveTo(w * 0.30, h * 0.66)
      ..lineTo(w * 0.44, h * 0.52)
      ..lineTo(w * 0.56, h * 0.60)
      ..lineTo(w * 0.76, h * 0.34);

    canvas.drawPath(
      arrow,
      Paint()
        ..color = AppColors.link
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Arrow head.
    final head = Path()
      ..moveTo(w * 0.76, h * 0.34)
      ..lineTo(w * 0.66, h * 0.35)
      ..lineTo(w * 0.75, h * 0.45)
      ..close();
    canvas.drawPath(head, Paint()..color = AppColors.link);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A deterministic QR-like pattern: three finder squares plus a fixed field of
/// modules. Not scannable — a placeholder for a real code.
class _QrPainter extends CustomPainter {
  _QrPainter(this.color);

  final Color color;

  static const _modules = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = color;

    void square(int col, int row, [int span = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(col * cell, row * cell, cell * span, cell * span),
        paint,
      );
    }

    // Finder patterns at three corners.
    void finder(int col, int row) {
      square(col, row, 7);
      canvas.drawRect(
        Rect.fromLTWH(
          (col + 1) * cell,
          (row + 1) * cell,
          cell * 5,
          cell * 5,
        ),
        Paint()..color = Colors.white,
      );
      square(col + 2, row + 2, 3);
    }

    finder(0, 0);
    finder(_modules - 7, 0);
    finder(0, _modules - 7);

    // Timing strips.
    for (var i = 8; i < _modules - 8; i += 2) {
      square(i, 6);
      square(6, i);
    }

    // Data field, seeded so the pattern is stable between builds.
    final random = math.Random(42);
    for (var row = 0; row < _modules; row++) {
      for (var col = 0; col < _modules; col++) {
        final inFinder =
            (col < 8 && row < 8) ||
            (col > _modules - 9 && row < 8) ||
            (col < 8 && row > _modules - 9);
        if (inFinder || col == 6 || row == 6) continue;
        if (random.nextBool()) square(col, row);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Overlapping translucent rings with a heart pulse — the Sehat-mu motif.
class _WellnessPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w / 2, h / 2);

    canvas.drawCircle(
      centre,
      w * 0.44,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      centre,
      w * 0.33,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // Heart.
    final heart = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..cubicTo(w * 0.26, h * 0.46, w * 0.34, h * 0.28, w * 0.50, h * 0.40)
      ..cubicTo(w * 0.66, h * 0.28, w * 0.74, h * 0.46, w * 0.50, h * 0.62)
      ..close();
    canvas.drawPath(heart, Paint()..color = AppColors.link);

    // Pulse line through the lower half.
    final pulse = Path()
      ..moveTo(w * 0.20, h * 0.72)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.45, h * 0.62)
      ..lineTo(w * 0.54, h * 0.82)
      ..lineTo(w * 0.61, h * 0.72)
      ..lineTo(w * 0.80, h * 0.72);

    canvas.drawPath(
      pulse,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A seated clinician working at a desk, with a speech bubble holding a
/// clipboard. Built from simple shapes so it stays crisp at any size.
class _DoctorAtDeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skin = Paint()..color = const Color(0xFFE8B08A);
    final coat = Paint()..color = AppColors.white;
    final slate = Paint()..color = AppColors.accentSoft;
    final desk = Paint()..color = AppColors.accentLight;

    // Speech bubble.
    final bubbleCentre = Offset(w * 0.76, h * 0.20);
    canvas.drawCircle(
      bubbleCentre,
      w * 0.15,
      Paint()
        ..color = AppColors.accentSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.006,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, h * 0.30)
        ..quadraticBezierTo(w * 0.56, h * 0.40, w * 0.50, h * 0.36),
      Paint()
        ..color = AppColors.accentSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.006,
    );

    // Clipboard inside the bubble.
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.70, h * 0.12, w * 0.12, h * 0.14),
      Radius.circular(w * 0.012),
    );
    canvas.drawRRect(board, Paint()..color = AppColors.link);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          w * 0.725,
          h * (0.155 + i * 0.028),
          w * 0.07,
          h * 0.010,
        ),
        coat,
      );
    }

    // Chair back.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.46, w * 0.20, h * 0.34),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = AppColors.accentLight,
    );

    // Legs.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.72, w * 0.30, h * 0.09),
        Radius.circular(w * 0.03),
      ),
      slate,
    );

    // Torso in a white coat.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.40, w * 0.22, h * 0.34),
        Radius.circular(w * 0.04),
      ),
      coat,
    );

    // Head and hair.
    final headCentre = Offset(w * 0.33, h * 0.33);
    canvas.drawCircle(headCentre, w * 0.065, skin);
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: headCentre, radius: w * 0.068),
          math.pi,
          math.pi,
        )
        ..close(),
      Paint()..color = AppColors.accentSoft,
    );

    // Arm reaching to the laptop.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, h * 0.50)
        ..quadraticBezierTo(w * 0.52, h * 0.52, w * 0.55, h * 0.58),
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );

    // Desk top and leg.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.62, w * 0.44, h * 0.035),
        Radius.circular(w * 0.01),
      ),
      desk,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.80, h * 0.655, w * 0.03, h * 0.20),
      desk,
    );

    // Laptop.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.52, h * 0.48, w * 0.16, h * 0.13),
        Radius.circular(w * 0.008),
      ),
      slate,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.50, h * 0.60, w * 0.20, h * 0.022),
        Radius.circular(w * 0.006),
      ),
      Paint()..color = AppColors.accentLight,
    );

    // Potted plant on the right.
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.48),
      w * 0.055,
      Paint()..color = AppColors.success,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.885, h * 0.52, w * 0.012, h * 0.09),
      Paint()..color = AppColors.accentSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.855, h * 0.60, w * 0.075, h * 0.06),
        Radius.circular(w * 0.01),
      ),
      Paint()..color = AppColors.accentLight,
    );

    // Floor line.
    canvas.drawLine(
      Offset(w * 0.04, h * 0.86),
      Offset(w * 0.96, h * 0.86),
      Paint()
        ..color = AppColors.accentSoft.withValues(alpha: 0.25)
        ..strokeWidth = w * 0.004,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
