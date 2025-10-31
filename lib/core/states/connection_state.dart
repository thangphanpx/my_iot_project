import 'dart:async';
import '../base/reactive_state.dart';
import '../interfaces/connection_interface.dart';

/// Connection state management with fine-grained reactivity
/// Following Single Responsibility Principle (SRP)
class ConnectionState extends ReactiveState<ConnectionStateData> {
  final ConnectionInterface _connectionInterface;
  StreamSubscription<String>? _connectionStatusSubscription;
  StreamSubscription<void>? _connectivityChangesSubscription;

  ConnectionState(
    this._connectionInterface, {
    ConnectionStateData? initialState,
  }) : super(
          initialState ??
              const ConnectionStateData(
                connectionStatus: 'Disconnected',
                isConnected: false,
                isInitializing: false,
                error: null,
                lastConnectionAttempt: null,
              ),
        ) {
    _initialize();
  }

  void _initialize() {
    // Watch for connection status changes
    _connectionStatusSubscription =
        _connectionInterface.watchConnectionStatus().listen(
      (status) {
        update((current) => current.copyWith(
              connectionStatus: status,
              isConnected: status == 'Connected',
              isInitializing: false,
              error: null,
            ));
      },
      onError: (error) {
        update((current) => current.copyWith(
              error: error.toString(),
              isInitializing: false,
            ));
      },
    );

    // Watch for connectivity changes
    _connectivityChangesSubscription =
        _connectionInterface.watchConnectivityChanges().listen(
      (_) {
        // Handle connectivity changes if needed
        _checkConnectionStatus();
      },
      onError: (error) {
        update((current) => current.copyWith(error: error.toString()));
      },
    );

    // Initial connection status check
    _checkConnectionStatus();
  }

  void _checkConnectionStatus() {
    final isConnected = _connectionInterface.isConnected;
    final status = _connectionInterface.connectionStatus;

    update((current) => current.copyWith(
          isConnected: isConnected,
          connectionStatus: status,
        ));
  }

  /// Initialize connection
  Future<void> initializeConnection() async {
    update((current) => current.copyWith(
          isInitializing: true,
          error: null,
          lastConnectionAttempt: DateTime.now(),
        ));

    try {
      await _connectionInterface.initialize();
      // Connection status will be updated via stream subscription
    } catch (error) {
      update((current) => current.copyWith(
            error: error.toString(),
            isInitializing: false,
          ));
      rethrow;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    update((current) => current.copyWith(
          isInitializing: true,
          error: null,
        ));

    try {
      await _connectionInterface.disconnect();
      // Connection status will be updated via stream subscription
    } catch (error) {
      update((current) => current.copyWith(
            error: error.toString(),
            isInitializing: false,
          ));
      rethrow;
    }
  }

  /// Reconnect
  Future<void> reconnect() async {
    await disconnect();
    await initializeConnection();
  }

  /// Clear error state
  void clearError() {
    update((current) => current.copyWith(error: null));
  }

  /// Get connection health status
  ConnectionHealth get connectionHealth {
    if (state.isInitializing) return ConnectionHealth.initializing;
    if (state.error != null) return ConnectionHealth.error;
    if (state.isConnected) return ConnectionHealth.connected;
    return ConnectionHealth.disconnected;
  }

  /// Check if connection is healthy
  bool get isConnectionHealthy =>
      state.isConnected && state.error == null && !state.isInitializing;

  /// Get time since last connection attempt
  Duration? get timeSinceLastConnectionAttempt {
    if (state.lastConnectionAttempt == null) return null;
    return DateTime.now().difference(state.lastConnectionAttempt!);
  }

  /// Check if should attempt reconnection based on error and time
  bool get shouldAttemptReconnection {
    if (!state.isConnected && state.error != null) {
      final timeSinceAttempt = timeSinceLastConnectionAttempt;
      // Don't reconnect immediately, wait at least 30 seconds
      return timeSinceAttempt == null || timeSinceAttempt.inSeconds > 30;
    }
    return false;
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _connectivityChangesSubscription?.cancel();
    super.dispose();
  }
}

/// Immutable state data class for connection
/// Following Immutability principle
class ConnectionStateData {
  final String connectionStatus;
  final bool isConnected;
  final bool isInitializing;
  final String? error;
  final DateTime? lastConnectionAttempt;

  const ConnectionStateData({
    required this.connectionStatus,
    required this.isConnected,
    required this.isInitializing,
    this.error,
    this.lastConnectionAttempt,
  });

  ConnectionStateData copyWith({
    String? connectionStatus,
    bool? isConnected,
    bool? isInitializing,
    String? error,
    DateTime? lastConnectionAttempt,
  }) {
    return ConnectionStateData(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isConnected: isConnected ?? this.isConnected,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
      lastConnectionAttempt:
          lastConnectionAttempt ?? this.lastConnectionAttempt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStateData &&
          connectionStatus == other.connectionStatus &&
          isConnected == other.isConnected &&
          isInitializing == other.isInitializing &&
          error == other.error &&
          lastConnectionAttempt == other.lastConnectionAttempt;

  @override
  int get hashCode =>
      connectionStatus.hashCode ^
      isConnected.hashCode ^
      isInitializing.hashCode ^
      error.hashCode ^
      lastConnectionAttempt.hashCode;

  @override
  String toString() =>
      'ConnectionStateData(status: $connectionStatus, connected: $isConnected, initializing: $isInitializing, error: $error)';
}

/// Connection health enum
enum ConnectionHealth {
  connected,
  disconnected,
  initializing,
  error,
}

extension ConnectionHealthExtension on ConnectionHealth {
  String get displayName {
    switch (this) {
      case ConnectionHealth.connected:
        return 'Connected';
      case ConnectionHealth.disconnected:
        return 'Disconnected';
      case ConnectionHealth.initializing:
        return 'Connecting...';
      case ConnectionHealth.error:
        return 'Error';
    }
  }

  String get color {
    switch (this) {
      case ConnectionHealth.connected:
        return 'green';
      case ConnectionHealth.disconnected:
        return 'gray';
      case ConnectionHealth.initializing:
        return 'blue';
      case ConnectionHealth.error:
        return 'red';
    }
  }
}
