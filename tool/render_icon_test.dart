// Renders the Colophon launcher icon PNGs from code, so the logo is
// reproducible and editable. Run:
//   flutter test tool/render_icon_test.dart
// then: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _violet = Color(0xFF3E2A87);
const _paper = Color(0xFFF1EDFF);
const _red = Color(0xFFE5484D);

/// Draws the mark centred in a [size] canvas. Adaptive icons crop to the
/// central 66%, so the mark stays inside a circle of 0.30 * size radius.
void paintMark(Canvas canvas, double size, {required Color ink, Color? accent}) {
  final c = Offset(size / 2, size / 2);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(-6 * math.pi / 180); // a hand stamp is never straight
  final r = size * 0.27;
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..color = ink
    ..strokeWidth = size * 0.028;
  canvas.drawCircle(Offset.zero, r, ring);
  canvas.drawCircle(
    Offset.zero,
    r - size * 0.05,
    ring..strokeWidth = size * 0.010,
  );

  // Open book, centred: two pages meeting at a spine, outer corners
  // slightly raised.
  final fill = Paint()..color = ink;
  final w = size * 0.175, h = size * 0.15, gap = size * 0.014;
  final top = -h / 2 - size * 0.012;
  Path page(double dir) =>
      Path()
        ..moveTo(dir * gap, top + size * 0.016)
        ..quadraticBezierTo(dir * w * 0.5, top - size * 0.016, dir * w, top)
        ..lineTo(dir * w, top + h)
        ..quadraticBezierTo(
          dir * w * 0.5,
          top + h - size * 0.02,
          dir * gap,
          top + h + size * 0.01,
        )
        ..close();
  canvas.drawPath(page(-1), fill);
  canvas.drawPath(page(1), fill);

  // Bookmark ribbon hanging from the spine, with a notched end.
  final rw = size * 0.034;
  final ribbonTop = top + size * 0.03;
  final ribbonEnd = top + h + size * 0.075;
  final ribbon =
      Path()
        ..moveTo(-rw / 2, ribbonTop)
        ..lineTo(rw / 2, ribbonTop)
        ..lineTo(rw / 2, ribbonEnd)
        ..lineTo(0, ribbonEnd - rw * 0.7)
        ..lineTo(-rw / 2, ribbonEnd)
        ..close();
  canvas.drawPath(ribbon, Paint()..color = accent ?? ink);
  canvas.restore();
}

Future<void> _write(
  String path,
  double size,
  void Function(Canvas canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render Colophon icons', () async {
    const s = 1024.0;
    await _write('assets/icon/colophon_foreground.png', s, (canvas) {
      paintMark(canvas, s, ink: _paper, accent: _red);
    });
    await _write('assets/icon/colophon_monochrome.png', s, (canvas) {
      paintMark(canvas, s, ink: const Color(0xFFFFFFFF));
    });
    await _write('assets/icon/colophon_icon.png', s, (canvas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, s, s),
          const Radius.circular(s * 0.22),
        ),
        Paint()..color = _violet,
      );
      canvas.save();
      // Legacy icons show the whole canvas: scale the mark up to fill it.
      canvas.translate(s / 2, s / 2);
      canvas.scale(1.35);
      canvas.translate(-s / 2, -s / 2);
      paintMark(canvas, s, ink: _paper, accent: _red);
      canvas.restore();
    });
  });
}
