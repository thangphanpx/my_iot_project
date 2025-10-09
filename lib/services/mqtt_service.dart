import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';

class MQTTService {
  MqttServerClient? _client;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  // Stream controllers for real-time updates
  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  final StreamController<Device> _deviceStatusController =
      StreamController<Device>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<Device> get deviceStatusStream => _deviceStatusController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _client = MqttServerClient(AppConfig.mqttBroker, AppConfig.mqttClientId);
    _client!.port = AppConfig.mqttPort;
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(AppConfig.mqttClientId)
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    await _connect();
  }

  Future<void> _connect() async {
    try {
      _connectionStatusController.add('Connecting to MQTT broker...');
      await _client!.connect();
    } catch (e) {
      _connectionStatusController.add('Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    _isConnected = true;
    _connectionStatusController.add('Connected to MQTT broker');
    _reconnectTimer?.cancel();

    // Subscribe to topics
    _subscribeToTopics();
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionStatusController.add('Disconnected from MQTT broker');
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        _connect();
      }
    });
  }

  void _subscribeToTopics() {
    if (_client != null && _isConnected) {
      // Subscribe to sensor data topic
      _client!.subscribe(AppConfig.sensorDataTopic, MqttQos.atLeastOnce);
      _client!.subscribe(AppConfig.deviceStatusTopic, MqttQos.atLeastOnce);

      // Listen for messages
      _client!.updates!.listen(_onMessageReceived);
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final MqttPublishMessage payload = message.payload as MqttPublishMessage;
      final String messageData = utf8.decode(payload.payload.message);

      try {
        final data = json.decode(messageData);

        if (message.topic == AppConfig.sensorDataTopic) {
          final sensorData = SensorData.fromJson(data);
          _sensorDataController.add(sensorData);
        } else if (message.topic == AppConfig.deviceStatusTopic) {
          final device = Device.fromJson(data);
          _deviceStatusController.add(device);
        }
      } catch (e) {
        print('Error parsing MQTT message: $e');
      }
    }
  }

  Future<void> publishSensorData(SensorData sensorData) async {
    if (!_isConnected || _client == null) {
      print('MQTT client not connected');
      return;
    }

    final topic = '${AppConfig.sensorDataTopic}/${sensorData.deviceId}';
    final payload = json.encode(sensorData.toJson());

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> publishDeviceStatus(Device device) async {
    if (!_isConnected || _client == null) {
      print('MQTT client not connected');
      return;
    }

    final payload = json.encode(device.toJson());

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
        AppConfig.deviceStatusTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _client?.disconnect();
    _sensorDataController.close();
    _deviceStatusController.close();
    _connectionStatusController.close();
    _reconnectTimer?.cancel();
  }

  void dispose() {
    disconnect();
  }
}
