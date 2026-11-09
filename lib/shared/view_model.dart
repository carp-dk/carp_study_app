part of carp_study_app;

/// Base view model - a [ChangeNotifier] that notifies its listeners
/// (incl. [ListenableBuilder] widgets) when changed.
abstract class ViewModel extends ChangeNotifier {
  SmartphoneStudyController? _controller;

  SmartphoneStudyController? get controller => _controller;

  /// Initialize this view model before use.
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    _controller = ctrl;
  }

  /// Log and ignore measurement stream errors so sensing can continue.
  void onMeasurementStreamError(Object error, [StackTrace? stackTrace]) {
    warning('$runtimeType - measurement stream error: $error');
  }

  /// Clear this view model, i.e. delete all data incl. cached data.
  @mustCallSuper
  void clear() {}

  /// Called when this view model is disposed. Typically on app exit, incl. when
  /// closed by the OS.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }
}

/// A serializable data model to be used in a [SerializableViewModel].
abstract class DataModel {
  DataModel();
  DataModel fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

/// A view model holding an aggregated [DataModel] behind a card. Not
/// persisted - every card is rebuilt from backfill and/or live probes.
abstract class SerializableViewModel<D extends DataModel> extends ViewModel {
  /// The current data model, fresh on every [init].
  D get model => _model;
  late D _model;

  SerializableViewModel() {
    _model = createModel();
  }

  /// Create the [DataModel] this view model aggregates into.
  @protected
  D createModel();

  @override
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _model = createModel();
  }
}
