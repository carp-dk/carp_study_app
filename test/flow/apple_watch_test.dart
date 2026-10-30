import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../exports.dart';
import 'flow.dart';

void main() {
  flowTest('the protocol Apple Watch is listed on iOS only, with its instructions', (tester, flow) async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await flow.signConsent();
    await flow.pumpUntil(() => bloc.study.isRunning, 'sensing to start');
    List<String> devices() => [for (final d in bloc.study.deploymentDevices) d.typeName];
    const watch = 'pages.connections.type.apple_watch.name';

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(devices(), isNot(contains(watch)));

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(devices(), contains(watch));

    // The Connections page needs Bluetooth, which the host lacks - open what its watch card opens.
    final device = bloc.study.deploymentDevices.singleWhere((d) => d.typeName == watch);
    Navigator.of(
      tester.element(find.byType(HomePage)),
    ).push(MaterialPageRoute<void>(builder: (_) => AppleWatchConnectPage(device: device)));
    await tester.pumpAndSettle();
    expect(find.text('How to connect'), findsOneWidget);
    expect(find.textContaining('install CARP under Available Apps'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
