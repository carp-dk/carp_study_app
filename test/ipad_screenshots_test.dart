// Renders the real app pages at iPad size and writes PNGs - store screenshots
// without a simulator. Run: flutter test test/ipad_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carp_backend/carp_backend.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:carp_themes_package/carp_themes_package.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';
import 'test_utils.dart';

final outDir = Directory('${Platform.environment['HOME']}/Documents/carp_promo/ipad');
const sizes = {'12.9': Size(2048, 2732), '11': Size(1668, 2388)};

DateTime get _today => DateTime.now();
DateTime _day(int ago, [int hour = 8]) => DateTime(_today.year, _today.month, _today.day - ago, hour);
int _us(DateTime t) => t.microsecondsSinceEpoch;

// ---------- fakes ----------

base class _FakeBle extends FlutterBluePlusPlatform {}

class _FakeDevice extends HardwareDeviceManager<DeviceConfiguration, DeviceRegistration> {
  _FakeDevice(super.deviceType, DeviceStatus initial, {this.name = ''}) {
    status = initial;
  }
  final String name;
  @override
  String? get displayName => name;
  @override
  int? get batteryLevel => 82;
  @override
  bool get canConnect => true;
  @override
  DeviceRegistration createRegistration() => DeviceRegistration();
  @override
  void onConfigure() {}
  @override
  Future<void> onRequestPermissions() async {}
  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;
  @override
  Future<bool> onDisconnect() async => true;
}

class _FakeUserTask extends UserTask {
  _FakeUserTask(String type, String title, String description, {int? minutes, UserTaskState? state, int? doneDaysAgo})
    : super(
        AppTaskExecutor()..initialize(
          AppTask(
            type: type,
            title: title,
            description: description,
            minutesToComplete: minutes,
            expire: const Duration(days: 2),
          ),
        ),
      ) {
    triggerTime = _day(0);
    enqueued = triggerTime;
    this.state = state ?? UserTaskState.enqueued;
    if (doneDaysAgo != null) doneTime = _day(doneDaysAgo, 14);
  }
}

class _NoMessages extends MessageManager {
  @override
  void initialize() {}
  @override
  Future<Message?> getMessage(String messageId) async => null;
  @override
  Future<List<Message>> getMessages({DateTime? start, DateTime? end, int? count = 20}) async => [];
  @override
  Future<void> setMessage(Message message) async {}
  @override
  Future<void> deleteMessage(String messageId) async {}
  @override
  Future<void> deleteAllMessages() async {}
}

class _Home extends HomePageViewModel {
  _Home() : super(studyService: StudyService(), messageService: MessageService(_NoMessages()));
  @override
  bool get isLoaded => true;
  @override
  String get studyTitle => 'CARP Demo Study';
  @override
  String get studyDescription =>
      'A study of daily activity, sleep and heart rate using your phone and a wearable sensor.';
  @override
  StudyDeploymentStatusTypes? get deploymentStatus => StudyDeploymentStatusTypes.Running;
  @override
  int get activeDaysInStudy => 12;
  @override
  List<bool> get lastWeekActivity => const [true, true, false, true, true, true, true];
  @override
  int get taskCompleted => 14;
  @override
  int get taskPending => 3;
  @override
  bool get hasBackgroundSensing => true;
  @override
  bool get isBackgroundSensingActive => true;
  @override
  List<DeviceViewModel> get connectionSources => [
    DeviceViewModel(_FakeDevice(PolarDevice.DEVICE_TYPE, DeviceStatus.connected)),
    DeviceViewModel(_FakeDevice(HealthService.DEVICE_TYPE, DeviceStatus.connected)),
  ];
  @override
  List<Message> get messages => [
    Message(
      title: 'Welcome to the study',
      subTitle: 'Thank you for participating',
      message: 'Remember to wear your sensor during the day and keep the app running in the background.',
      timestamp: _day(1),
    ),
    Message(
      type: MessageType.article,
      title: 'Why sleep matters',
      subTitle: 'New article',
      message: 'Read about how sleep quality is linked to daily activity.',
      timestamp: _day(3),
    ),
  ];
  @override
  Future<void> configureStudy() async {}
}

class _Tasks extends TaskListPageViewModel {
  _Tasks() : super(studyService: StudyService());
  @override
  Future<void> checkParticipantData() async {}
  @override
  bool get showParticipantDataCard => false;
  @override
  Stream<UserTask> get userTaskEvents => const Stream.empty();
  @override
  List<UserTask> get pendingTasks => [
    _FakeUserTask(
      'survey',
      'Daily wellbeing',
      'How are you feeling today? A short survey about your mood and energy.',
      minutes: 3,
    ),
    _FakeUserTask('cognition', 'Cognitive assessment', 'A quick reaction-time and memory test.', minutes: 5),
    _FakeUserTask('audio', 'Voice recording', 'Read the short text aloud so we can record your voice.', minutes: 1),
  ];
  @override
  List<UserTask> get completedTasks => [
    _FakeUserTask('survey', 'Daily wellbeing', '', state: UserTaskState.done, doneDaysAgo: 1),
    _FakeUserTask('survey', 'Sleep diary', '', state: UserTaskState.done, doneDaysAgo: 2),
  ];
}

class _Stats extends StatisticsViewModel {
  _Stats() : super(studyService: StudyService()) {
    polarHeartRateCardDataModel.addMeasurements([
      for (var d = 6; d >= 0; d--)
        for (var h = 7; h < 22; h++)
          Measurement.fromData(
            PolarHR(
              samples: [
                PolarHRSample(
                  hr: 58 + ((h * 7 + d * 13) % 45),
                  rrsMs: const [],
                  contactStatus: true,
                  contactStatusSupported: true,
                ),
              ],
            ),
            _us(_day(d, h)),
          ),
    ]);
    stepsCardDataModel.addMeasurements([
      for (var d = 6; d >= 0; d--) ...[
        Measurement.fromData(StepCount(steps: 0), _us(_day(d, 6))),
        Measurement.fromData(StepCount(steps: 4200 + (d * 1731) % 6000), _us(_day(d, 22))),
      ],
    ]);
    activityCardDataModel.addMeasurements([
      for (var d = 6; d >= 0; d--) ...[
        Measurement.fromData(Activity(type: ActivityType.WALKING, confidence: 100), _us(_day(d, 8))),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _us(_day(d, 8).add(Duration(minutes: 30 + d * 9))),
        ),
        Measurement.fromData(Activity(type: ActivityType.RUNNING, confidence: 100), _us(_day(d, 17))),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _us(_day(d, 17).add(Duration(minutes: 15 + d * 5))),
        ),
        Measurement.fromData(Activity(type: ActivityType.ON_BICYCLE, confidence: 100), _us(_day(d, 18))),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _us(_day(d, 18).add(Duration(minutes: 20 + d * 4))),
        ),
      ],
    ]);
    sleepCardDataModel.addMeasurements([
      for (var d = 6; d >= 0; d--) ...[
        _sleep('SLEEP_DEEP', 80 + d * 5, _day(d + 1, 23)),
        _sleep('SLEEP_LIGHT', 200 + d * 7, _day(d, 1)),
        _sleep('SLEEP_REM', 90 + d * 3, _day(d, 5)),
      ],
    ]);
    mobilityCardDataModel.addMeasurements([
      for (var d = 6; d >= 0; d--)
        Measurement.fromData(
          Mobility(
            date: _day(d),
            numberOfPlaces: 2 + d % 3,
            homeStay: 0.45 + d * 0.05,
            distanceTraveled: 3500 + d * 1900,
          ),
          _us(_day(d, 23)),
        ),
    ]);
  }

  static Measurement _sleep(String type, int minutes, DateTime from) => Measurement.fromData(
    HealthData(
      uuid: '$type-$from',
      value: NumericHealthValue(numericValue: minutes),
      unit: 'MINUTE',
      healthDataType: type,
      dateFrom: from,
      dateTo: from.add(Duration(minutes: minutes)),
      platform: HealthPlatform.APPLE_HEALTH,
    ),
    _us(from),
  );

  @override
  Future<void> refresh() async {}
  @override
  bool get hasUserTasks => false;
  @override
  bool get hasPolarHeartRateMeasure => true;
  @override
  bool get hasStepsMeasure => true;
  @override
  bool get hasActivityMeasure => true;
  @override
  bool get hasSleepMeasure => true;
  @override
  bool get hasMobilityMeasure => true;
}

class _Devices extends DeviceListPageViewModel {
  _Devices() : super(studyService: StudyService());
  @override
  List<DeviceViewModel> get smartphoneDevice => [
    DeviceViewModel(_FakeDevice(Smartphone.DEVICE_TYPE, DeviceStatus.connected)),
  ];
  @override
  List<DeviceViewModel> get hardwareDevices => [
    DeviceViewModel(_FakeDevice(PolarDevice.DEVICE_TYPE, DeviceStatus.connected, name: 'Polar H10 B34B4B56')),
    DeviceViewModel(_FakeDevice(MovesenseDevice.DEVICE_TYPE, DeviceStatus.configured)),
  ];
  @override
  List<DeviceViewModel> get services => [
    DeviceViewModel(_FakeDevice(HealthService.DEVICE_TYPE, DeviceStatus.connected)),
    DeviceViewModel(_FakeDevice(LocationService.DEVICE_TYPE, DeviceStatus.connected)),
    DeviceViewModel(_FakeDevice(WeatherService.DEVICE_TYPE, DeviceStatus.configured)),
  ];
}

// ---------- harness ----------

final _shot = GlobalKey();

Widget _app(String route, HomePageViewModel home, Map<String, Widget> pages) => RepaintBoundary(
  key: _shot,
  child: ColoredBox(
    color: carpTheme.scaffoldBackgroundColor,
    child: MaterialApp.router(
      theme: carpTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        RPLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: GoRouter(
        initialLocation: route,
        routes: [
          ShellRoute(
            builder: (context, state, child) => CarpAppShell(model: home, child: child),
            routes: [for (final e in pages.entries) GoRoute(path: e.key, builder: (_, _) => e.value)],
          ),
        ],
      ),
    ),
  ),
);

Future<void> _loadFont(String family, String file) async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/fvm/default';
  final bytes = File('$root/bin/cache/artifacts/material_fonts/$file').readAsBytesSync();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

void main() {
  setUpAll(() async {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    await initTestSettings();
    AppConfig.deploymentMode = DeploymentMode.local;
    FlutterBluePlusPlatform.instance = _FakeBle();
    DeviceInfoService()
      ..deviceModel = 'iPad Pro'
      ..deviceManufacturer = 'Apple'
      ..sdk = '18.0'
      ..deviceID = 'iPad';
    outDir.createSync(recursive: true);
    // Ahem is the test font - load real ones under the theme's family names.
    await _loadFont('OpenSans', 'Roboto-Regular.ttf');
    await _loadFont('MaterialIcons', 'MaterialIcons-Regular.otf');
  });
  setUp(rootBundle.clear);

  final home = _Home();
  final pages = {
    HomePage.route: HomePage(model: home),
    TaskListPage.route: TaskListPage(model: _Tasks()),
    StatisticsPage.route: StatisticsPage(_Stats()),
    DeviceListPage.route: DeviceListPage(model: _Devices()),
  };
  final names = {
    HomePage.route: 'home',
    TaskListPage.route: 'tasks',
    StatisticsPage.route: 'statistics',
    DeviceListPage.route: 'connections',
  };

  for (final size in sizes.entries) {
    for (final route in pages.keys) {
      testWidgets('iPad ${size.key} $route', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        debugDisableShadows = false; // the test renderer draws shadows as solid black otherwise

        await tester.runAsync(() async {
          await tester.pumpWidget(_app(route, home, pages));
          // Real time so the logo asset decodes and chart animations finish.
          for (var i = 0; i < 10; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            await tester.pump(const Duration(milliseconds: 300));
          }
          final image = await (_shot.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(
            pixelRatio: 2,
          );
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${outDir.path}/ipad_${size.key.replaceAll('.', '_')}_${names[route]}.png');
          file.writeAsBytesSync(png!.buffer.asUint8List());
          expect(file.lengthSync(), greaterThan(10000));
        });
        debugDefaultTargetPlatformOverride = null;
        debugDisableShadows = true;
      });
    }
  }
}
