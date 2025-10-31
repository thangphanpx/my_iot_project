import 'dart:async';

/// Base class for reactive state management
/// Following Single Responsibility and Dependency Inversion principles
abstract class ReactiveState<T> {
  final StreamController<T> _stateController = StreamController<T>.broadcast();
  late T _currentState;

  /// Getter for current state
  T get state => _currentState;

  /// Stream for listening to state changes
  Stream<T> get stream => _stateController.stream;

  /// Stream for listening to state changes with initial state
  Stream<T> get streamWithInitial async* {
    yield _currentState;
    yield* stream;
  }

  ReactiveState(T initialState) {
    _currentState = initialState;
    _stateController.add(_currentState);
  }

  /// Update state and notify listeners
  void _updateState(T newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(_currentState);
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }

  /// Map current state to new state
  void update(T Function(T current) updater) {
    final newState = updater(_currentState);
    _updateState(newState);
  }

  /// Check if state equals another state
  bool isStateEqual(T other) => _currentState == other;
}
