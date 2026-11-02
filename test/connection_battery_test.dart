import 'package:flutter/material.dart';

import 'exports.dart';

class _Watch extends AppleWatchDeviceManager {
  final batteries = StreamController<int>.broadcast();
  final batches = StreamController<AppleWatchRecords>.broadcast();
  int? level;
  AppleWatchDeviceInfo? info;

  @override
  int? get batteryLevel => level;
  @override
  Stream<int> get batteryEvents => batteries.stream;
  @override
  Stream<AppleWatchRecords> get records => batches.stream;
  @override
  AppleWatchDeviceInfo? get watchInfo => info;
}

void main() {
  testWidgets('battery and watch identity update without a connection status change', (tester) async {
    final watch = _Watch()..status = DeviceStatus.connected;
    final model = ConnectionViewModel(watch);
    addTearDown(() async {
      model.dispose();
      await watch.batteries.close();
      await watch.batches.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: model,
          builder: (context, _) => Column(
            children: [
              Text(model.name),
              if (model.batteryLevel != null) BatteryPercentage(batteryLevel: model.batteryLevel!),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(BatteryPercentage), findsNothing);
    expect(model.name, isEmpty); // Do not repeat the generic Apple Watch title.
    expect(watch.batteries.hasListener, isTrue);
    expect(watch.batches.hasListener, isTrue);

    watch.level = 75;
    watch.batteries.add(75);
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);

    watch.info = AppleWatchDeviceInfo(name: 'CARP Watch', model: 'Apple Watch', systemVersion: '27.0');
    watch.batches.add(AppleWatchRecords(table: AppleWatchTable.device, chunkIndex: 1, totalChunks: 1, records: []));
    await tester.pumpAndSettle();
    expect(model.name, 'CARP Watch · watchOS 27.0');
    await tester.pumpAndSettle();
    expect(find.text('CARP Watch · watchOS 27.0'), findsOneWidget);

    watch.level = 0;
    watch.batteries.add(0);
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(watch.batteries.hasListener, isFalse);
    expect(watch.batches.hasListener, isFalse);
  });
}
