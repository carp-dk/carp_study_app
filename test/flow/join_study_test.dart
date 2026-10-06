import '../exports.dart';
import 'flow.dart';

void main() {
  flowTest('joining: consent, sensing starts, the tasks are listed', (tester, flow) async {
    await flow.signConsent();
    await flow.pumpUntil(() => bloc.study.isRunning, 'sensing to start');
    await flow.tap(find.text('Tasks'));

    expect(flow.events, containsAllInOrder(['route /consent', 'route /home', 'app configured', 'route /tasks']));
    // Asked in consent-section order (#699).
    expect(flow.permissions, [
      'Permission.locationWhenInUse',
      'Permission.locationAlways',
      'Permission.activity_recognition',
      'Permission.bluetoothScan',
      'Permission.bluetoothConnect',
      'Permission.microphone',
      'Permission.camera',
      'Permission.notification',
      'Permission.ignoreBatteryOptimizations',
    ]);
    final enqueued = flow.events.where((e) => e.endsWith(' enqueued'));
    expect(enqueued, hasLength(9), reason: 'each app task of the protocol, once');
    expect(find.byType(TaskListPage), findsOneWidget);
  });
}
