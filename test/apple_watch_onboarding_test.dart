import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';

class _Watch extends AppleWatchDeviceManager {
  final events = StreamController<AppleWatchStatus>.broadcast();
  AppleWatchStatus current = AppleWatchStatus();

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
    addTearDown(watch.events.close);
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

    expect(next().onPressed, isNull);
    watch.emit(AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true, isCollectingData: true));
    await settle();
    await tapNext();

    expect(find.text('Waiting for the first data from the watch…'), findsOneWidget);
    expect(next().onPressed, isNull, reason: 'done only once data has arrived');
    watch.emit(
      AppleWatchStatus(
        isSupported: true,
        isPaired: true,
        isWatchAppInstalled: true,
        isCollectingData: true,
        lastFileTransferAt: DateTime.now(),
      ),
    );
    await settle();
    for (final ok in [
      'Apple Watch paired',
      'CARP installed on the watch',
      'Watch is collecting data',
      'First data received',
    ]) {
      expect(find.text(ok), findsOneWidget);
    }

    // Reopened while connected but not collecting: resumes at the start step, not "done".
    watch.current = AppleWatchStatus(isSupported: true, isPaired: true, isWatchAppInstalled: true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [RPLocalizations.delegate],
        home: AppleWatchConnectPage(key: UniqueKey(), device: ConnectionViewModel(watch)),
      ),
    );
    await settle();
    expect(find.text('Start CARP on the watch'), findsOneWidget);
  });
}
