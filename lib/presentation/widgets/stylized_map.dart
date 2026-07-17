import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../domain/models/detection.dart';
import '../../domain/repositories/species_repository.dart';

/// A fully-offline, stylised detection map. Pins are placed by normalising each
/// detection's GPS into the frame, with a graceful fallback layout when a fix is
/// missing. This keeps History working with zero network.
///
/// DROP-IN: for real tiles, replace the painted background with a
/// `flutter_map` FlutterMap + TileLayer (Mapbox/OSM) and a MarkerLayer built
/// from these same detections. See README → "Real map tiles".
class StylizedMap extends StatelessWidget {
  const StylizedMap({
    super.key,
    required this.detections,
    required this.species,
  });

  final List<Detection> detections;
  final SpeciesRepository species;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 186,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: c.surface3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Stack(
        children: [
          // Dotted grid + faux streets.
          Positioned.fill(
            child: CustomPaint(
              painter: _MapBackgroundPainter(c.accentMix(9), c.fill),
            ),
          ),
          ..._pins(context),
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xB3080B11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.l.detectionsNear,
                style: MozzType.mono(size: 10.5, color: c.text4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pins(BuildContext context) {
    final located = detections.where((d) => d.latitude != null).toList();
    if (located.isEmpty) return const [];

    final lats = located.map((d) => d.latitude!);
    final lngs = located.map((d) => d.longitude!);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    double span(double v, double lo, double hi) =>
        hi - lo < 1e-9 ? 0.5 : (v - lo) / (hi - lo);

    return [
      for (final d in located)
        Align(
          alignment: Alignment(
            (0.12 + 0.76 * span(d.longitude!, minLng, maxLng)) * 2 - 1,
            (0.15 + 0.6 * (1 - span(d.latitude!, minLat, maxLat))) * 2 - 1,
          ),
          child: _Pin(color: species.byId(d.speciesId)?.dotColor ?? context.c.accent),
        ),
    ];
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Transform.rotate(
      angle: -0.785398, // -45°
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(11),
            topRight: Radius.circular(11),
            bottomLeft: Radius.circular(11),
          ),
          border: Border.all(color: c.bg, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: -2)],
        ),
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  _MapBackgroundPainter(this.dot, this.street);
  final Color dot;
  final Color street;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = dot;
    const gap = 22.0;
    for (var x = 0.0; x < size.width; x += gap) {
      for (var y = 0.0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
    final streetPaint = Paint()..color = street;
    canvas.save();
    canvas.translate(size.width * 0.16, 0);
    canvas.transform(_skewX(-0.24));
    canvas.drawRect(Rect.fromLTWH(0, 0, 30, size.height), streetPaint);
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.44, size.width, 24),
      streetPaint,
    );
  }

  Float64List _skewX(double s) => Float64List.fromList([
        1, 0, 0, 0,
        s, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  @override
  bool shouldRepaint(_MapBackgroundPainter old) =>
      old.dot != dot || old.street != street;
}
