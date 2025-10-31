import 'dart:async';

/// Repository interface for connection management operations
/// Following Dependency Inversion Principle (DIP)
abstract class ConnectionInterface {
  Future<void> initialize();
  Future<void> disconnect();
  bool get isConnected;
  String get connectionStatus;
  Stream<String> watchConnectionStatus();
  Stream<void> watchConnectivityChanges();
}
