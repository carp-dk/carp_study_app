import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../exports.dart';
import 'flow.dart';

void main() {
  flowTest('the protocol Apple Watch is listed on iOS only, with its onboarding', (tester, flow) async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await flow.signConsent();
    await flow.pumpUntil(() => bloc.study.isRunning, 'sensing to start');
    List<String> devices() => [for (final d in bloc.study.deploymentDevices) deviceTypeName(d.deviceType)];
    const watch = 'Apple Watch';

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(devices(), isNot(contains(watch)));

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(devices(), contains(watch));

    // The Connections page needs Bluetooth, which the host lacks - open what its watch card opens.
    final device = ConnectionViewModel(bloc.study.deploymentDevices.whereType<AppleWatchDeviceManager>().single);
    Navigator.of(
      tester.element(find.byType(HomePage)),
    ).push(MaterialPageRoute<void>(builder: (_) => AppleWatchConnectPage(device: device)));
    await flow.pumpUntil(() => find.text('Pair your Apple Watch').evaluate().isNotEmpty, 'the watch onboarding');
    expect(find.text('Looking for a paired Apple Watch…'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
