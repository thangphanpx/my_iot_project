import 'interfaces/device_repository_interface.dart';
import 'interfaces/sensor_repository_interface.dart';
import 'interfaces/connection_interface.dart';
import 'repositories/device_repository.dart';
import 'repositories/sensor_repository.dart';
import 'repositories/connection_repository.dart';
import 'states/device_state.dart';
import 'states/sensor_state.dart';
import 'states/connection_state.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

/// Service locator following Dependency Inversion Principle
/// Provides centralized dependency management for the application
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Core services
  late final ApiService _apiService;
  late final MQTTService _mqttService;

  // Repositories
  late final DeviceRepositoryInterface _deviceRepository;
  late final SensorRepositoryInterface _sensorRepository;
  late final ConnectionInterface _connectionRepository;

  // State managers
  late final DeviceState _deviceState;
  late final SensorState _sensorState;
  late final ConnectionState _connectionState;

  /// Initialize the service locator with all dependencies
  void initialize() {
    // Initialize core services first
    _apiService = ApiService();
    _mqttService = MQTTService();

    // Initialize repositories
    _deviceRepository = DeviceRepository(_apiService, _mqttService);
    _sensorRepository = SensorRepository(_apiService, _mqttService);
    _connectionRepository = ConnectionRepository(_mqttService);

    // Initialize state managers
    _deviceState = DeviceState(_deviceRepository);
    _sensorState = SensorState(_sensorRepository);
    _connectionState = ConnectionState(_connectionRepository);

    // Initialize connection
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      await _connectionState.initializeConnection();
    } catch (e) {
      print('Error initializing connection: $e');
    }
  }

  // Getters for services
  ApiService get apiService => _apiService;
  MQTTService get mqttService => _mqttService;

  // Getters for repositories
  DeviceRepositoryInterface get deviceRepository => _deviceRepository;
  SensorRepositoryInterface get sensorRepository => _sensorRepository;
  ConnectionInterface get connectionRepository => _connectionRepository;

  // Getters for state managers
  DeviceState get deviceState => _deviceState;
  SensorState get sensorState => _sensorState;
  ConnectionState get connectionState => _connectionState;

  /// Dispose all services and clean up resources
  void dispose() {
    _deviceState.dispose();
    _sensorState.dispose();
    _connectionState.dispose();

    // Note: Repository dispose methods are implementation-specific
    // In a real app, you'd want to cast to concrete types or add dispose to interfaces

    _apiService.dispose();
    _mqttService.dispose();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
