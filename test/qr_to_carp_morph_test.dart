import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'exports.dart';

/// Renders the QR → CARP morph at a few points in time (to build/morph/ for
/// eyeballing) and checks the start is a white QR and the end a red mark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(QrToCarpMorph.load);

  Future<ByteData> render(double t, {String? saveAs}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 440, 440), Paint()..color = const Color(0xFF202020));
    canvas.translate(20, 20);
    QrToCarpMorph(progress: AlwaysStoppedAnimation(t)).painter.paint(canvas, const Size(400, 400));
    final image = await recorder.endRecording().toImage(440, 440);
    if (saveAs != null) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(saveAs).writeAsBytesSync(png!.buffer.asUint8List());
    }
    return (await image.toByteData())!;
  }

  bool hasRed(ByteData d) {
    for (var i = 0; i < d.lengthInBytes; i += 4) {
      if (d.getUint8(i) > 180 && d.getUint8(i + 1) < 80) return true;
    }
    return false;
  }

  test('QR silhouette morphs into the CARP mark', () async {
    Directory('build/morph').createSync(recursive: true);
    final frames = {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) t: await render(t, saveAs: 'build/morph/${(t * 100).round()}.png'),
    };
    expect(hasRed(frames[0.0]!), isFalse, reason: 'QR silhouette is white only');
    expect(hasRed(frames[1.0]!), isTrue, reason: 'CARP mark is red');
  });
}
