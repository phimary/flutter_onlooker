part of flutter_onlooker;

/// A function that creates an object of type [T].
typedef Create<T> = T Function(BuildContext context);

/// A function that listens for navigation events.
/// Return navigation `result` from this function to get that in [StateNotifier].
typedef Router<T> = Future<T>? Function(
  BuildContext context,
  dynamic route,
);

/// Exposes the [read] method.
extension ReadContext on BuildContext {
  /// Obtain a value from the nearest ancestor provider of type [StateNotifier].
  N? read<N extends StateNotifier>({bool listen = false}) =>
      Provider.of<N>(this, listen: listen);
}

/// A generic implementation of [InheritedWidget] that allows to obtain [StateNotifier]
/// using [Provider.of] for any descendant of this widget.
class Provider<N extends StateNotifier> extends InheritedWidget {
  final N stateNotifier;

  const Provider._({
    Key? key,
    required this.stateNotifier,
    required Widget child,
  }) : super(key: key, child: child);

  /// Obtains the nearest [StateNotifier]. Returns null if no such element is found.
  /// The build context is rebuilt when [StateNotifier] is changed if [listen] set to `true`.
  static N? of<N extends StateNotifier>(
    BuildContext context, {
    bool listen = false,
  }) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<Provider<N>>()
        : context.getElementForInheritedWidgetOfExactType<Provider<N>>()?.widget
            as Provider<N>;
    return provider?.stateNotifier;
  }

  @override
  bool updateShouldNotify(Provider<N> oldWidget) =>
      oldWidget.stateNotifier != stateNotifier;
}

/// Takes a [Create] function that is responsible for creating the [StateNotifier],
/// [child] which will have access to the instance via `Provider.of<StateNotifier>(context)` or
/// `context.read<StateNotifier>()` and optional [router] function that will receive navigation events.
class StateNotifierProvider<N extends StateNotifier>
    extends StateNotifierSubscriber<N, NavigationItem> {
  final Create<N> create;
  final Widget child;
  final Router? router;

  const StateNotifierProvider({
    Key? key,
    required this.create,
    required this.child,
    this.router,
  }) : super(key: key);

  @override
  _StateNotifierProviderState<N> createState() =>
      _StateNotifierProviderState<N>();
}

class _StateNotifierProviderState<N extends StateNotifier>
    extends StateNotifierSubscriberState<N, NavigationItem,
        StateNotifierProvider<N>> {
  late final N _stateNotifier;

  @override
  void initState() {
    _stateNotifier = widget.create(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Provider._(
      stateNotifier: _stateNotifier,
      child: widget.child,
    );
  }

  @override
  Stream<NavigationItem>? get stream =>
      widget.router == null ? null : _stateNotifier.getNavigationStream();

  @override
  void onNewState(NavigationItem state) {
    final result = widget.router?.call(context, state.route);
    state.resultConsumer(result);
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    super.dispose();
  }
}
