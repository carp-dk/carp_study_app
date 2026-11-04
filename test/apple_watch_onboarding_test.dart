import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';

class _Watch extends AppleWatchDeviceManager {
  final events = StreamController<AppleWatchStatus>.broadcast();
  final batches = StreamController<AppleWatchRecords>.broadcast();
  final transfers = StreamController<AppleWatchFileTransfer>.broadcast();
  AppleWatchStatus current = AppleWatchStatus();

  @override
  Stream<AppleWatchRecords> get records => batches.stream;
  @override
  Stream<AppleWatchFileTransfer> get fileTransferEvents => transfers.stream;

  @override
  AppleWatchStatus get watchStatus => current;
  @override
  Stream<AppleWatchStatus> get watchStatusEvents => events.stream;
  @override
  bool get canConnect => true;
  @override
  Future<DeviceStatus> onConnect() async => current.isAvailable ? DeviceStatus.connected : DeviceStatus.configured;

  void emit(AppleWatchStatus status) => events.add(current = status);
}

void main() {
  testWidgets('each step unlocks only once the watch reports it done', (tester) async {
    // The waiting spinners never settle - pump past the page animation instead.
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final watch = _Watch()..status = DeviceStatus.configured;
    addTearDown(() async {
      await watch.events.close();
      await watch.batches.close();
      await watch.transfers.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [RPLocalizations.delegate],
        home: AppleWatchConnectPage(device: ConnectionViewModel(watch)),
      ),
    );
    await settle();

    FilledButton next() => tester.widget<FilledButton>(find.byType(FilledButton));
    Future<void> tapNext() async {
      await tester.tap(find.byType(FilledButton));
      await settle();
    }

    expect(find.text('Looking for a paired Apple Watch…'), findsOneWidget);
    expect(next().onPressed, isNull);

    watch.emit(AppleWatchStatus(isSupported: true, isPaired: true));
    await settle();
    expect(find.text('Apple Watch paired'), findsOneWidget);
    await tapNext();

    expect(find.text('Waiting for CARP to be installed on the watch…'), findsOneWidget);
    expect(next().onPressed, isNull);
    watch.emit(AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true));
    await settle();
    expect(watch.isConnected, isTrue, reason: 'connects as soon as the watch can deliver data');
    await tapNext();

    // The watch app only sends data while open - reachability is that.
    expect(find.text('Waiting for CARP to open on the watch… keep the watch screen on'), findsOneWidget);
    expect(next().onPressed, isNull);
    watch.emit(
      AppleWatchStatus(
        isSupported: true,
        isPaired: true,
        isWatchAppInstalled: true,
        isReachable: true,
        isCollectingData: true,
      ),
    );
    await settle();
    expect(find.text('CARP is open on the watch'), findsOneWidget);
    await tapNext();

    expect(find.text('Waiting for data…'), findsOneWidget);
    expect(next().onPressed, isNull, reason: 'done only once data has arrived');
    watch.transfers.add(
      AppleWatchFileTransfer(
        table: AppleWatchTable.heartRate,
        fileName: 'hr.json',
        chunkIndex: 1,
        totalChunks: 4,
        state: WatchFileTransferState.received,
      ),
    );
    await settle();
    expect(find.text('Receiving data 25%'), findsOneWidget);
    watch.batches
      ..add(AppleWatchRecords(table: AppleWatchTable.heartRate, chunkIndex: 1, totalChunks: 1, records: [{}, {}]))
      ..add(AppleWatchRecords(table: AppleWatchTable.motion, chunkIndex: 1, totalChunks: 1, records: [{}, {}, {}]));
    watch.transfers.add(
      AppleWatchFileTransfer(
        table: AppleWatchTable.motion,
        fileName: 'motion.json',
        chunkIndex: 4,
        totalChunks: 4,
        state: WatchFileTransferState.decoded,
      ),
    );
    await settle();
    expect(find.text('5 measurements received'), findsOneWidget);
    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('Motion'), findsOneWidget);
    expect(next().onPressed, isNotNull);

    // Watch app closed: the data page says to open it again.
    watch.emit(AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true));
    await settle();
    expect(find.text('Waiting for CARP to open on the watch… keep the watch screen on'), findsOneWidget);
    expect(find.text('Watch screen off or CARP closed'), findsOneWidget);

    // Open but stopped on the watch: say how to start, like the watch does.
    watch.emit(AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true, isReachable: true));
    await settle();
    expect(find.text('Tap the CARP logo on the watch to start'), findsOneWidget);

    Future<void> reopen() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [RPLocalizations.delegate],
          home: AppleWatchConnectPage(key: UniqueKey(), device: ConnectionViewModel(watch)),
        ),
      );
      await settle();
    }

    // Reopened while connected: straight to the live data.
    await reopen();
    expect(find.text('Data from your watch'), findsOneWidget);

    // Reopened not connected, watch app closed, no data yet: resumes at the open step.
    watch.status = DeviceStatus.configured;
    watch.current = AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true);
    await reopen();
    expect(find.text('Open CARP on the watch'), findsOneWidget);
    // Stop the morph's ticker before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
