import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';

import 'exports.dart';

void main() {
  // Reload translations per test - a cached load from the previous test never completes here.
  setUp(rootBundle.clear);

  testWidgets('live monitor shows Movesense heart rate, RR and taps from the study', (tester) async {
    final measurements = StreamController<Measurement>.broadcast();
    addTearDown(measurements.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [RPLocalizations.delegate],
        home: Scaffold(
          body: DeviceLiveMonitor(
            device: ConnectionViewModel(MovesenseDeviceManager(MovesenseDevice.DEVICE_TYPE)),
            measurements: measurements.stream,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('N/A'), findsNWidgets(2)); // BPM and RR before any data
    expect(find.text('ECG not available'), findsOneWidget); // no sensor connected

    measurements
      ..add(Measurement.fromData(MovesenseHR(71.6, 830)))
      ..add(Measurement.fromData(MovesenseStateChange(MovesenseDeviceState.tap)))
      ..add(Measurement.fromData(MovesenseStateChange(MovesenseDeviceState.tap)));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('72'), findsOneWidget);
    expect(find.text('830 ms'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);

    // Strap off: HR stops but other data (ECG flat line, taps) keeps coming - BPM goes N/A.
    for (var i = 0; i < 7; i++) {
      measurements.add(Measurement.fromData(MovesenseStateChange(MovesenseDeviceState.tap)));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('N/A'), findsNWidgets(2)); // BPM and RR

    // A strap that goes quiet is called out.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('live monitor shows Polar heart rate and N/A when the strap loses skin contact', (tester) async {
    final measurements = StreamController<Measurement>.broadcast();
    addTearDown(measurements.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [RPLocalizations.delegate],
        home: Scaffold(
          body: DeviceLiveMonitor(
            device: ConnectionViewModel(PolarDeviceManager(PolarDevice.DEVICE_TYPE)),
            measurements: measurements.stream,
          ),
        ),
      ),
    );
    PolarHR hr(int bpm, {bool contact = true}) => PolarHR(
      samples: [
        PolarHRSample(hr: bpm, rrsMs: [810], contactStatus: contact, contactStatusSupported: true),
      ],
    );

    await tester.pump();
    measurements.add(Measurement.fromData(hr(74)));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('74'), findsOneWidget);
    expect(find.text('810 ms'), findsOneWidget);
    expect(find.text('Taps'), findsNothing); // Movesense only

    measurements.add(Measurement.fromData(hr(74, contact: false)));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('74'), findsNothing);

    await tester.pump(const Duration(seconds: 7)); // let the ticker settle before teardown
  });
}
