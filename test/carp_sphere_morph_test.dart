import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'exports.dart';

/// The formed morph is the CARP mark: red with a white plus in the right half.
void main() {
  testWidgets('morph ends as the red CARP mark with its white plus', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: Colors.black,
            width: 184,
            height: 150,
            child: const CarpSphereMorph(mode: CarpMorphMode.sent),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final image = await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    Color at(double x, double y) {
      final i = ((y * 150).round() * 184 + (x * 184).round()) * 4;
      return Color.fromARGB(255, image!.getUint8(i), image.getUint8(i + 1), image.getUint8(i + 2));
    }

    // Plus centre (SVG 27.7, 15.6) and body (SVG 16, 15.6) on a 0.72-wide mark.
    expect(at(0.14 + 0.72 * 27.7 / 37.925, 0.5), const Color(0xFFFFFFFF));
    expect(at(0.14 + 0.72 * 16 / 37.925, 0.5), CarpSphereMorph.red);
    expect(at(0.05, 0.05), Colors.black);
    await tester.pumpWidget(const SizedBox());
  });
}
