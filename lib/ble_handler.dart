import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:typed_data';
import 'package:location_permissions/location_permissions.dart';

typedef UpdateDataCallback = void Function(double value);

class BLEDataHandler {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid characteristicUuid =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final Uuid tareCharacteristicUuid =
      Uuid.parse("156858ce-e2bf-4e1f-8d72-0b4df0a9f7e6");
  final Duration connectionTimeout = const Duration(seconds: 10);
  final String targetDeviceName = "ESP32_Counter";

  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  DiscoveredDevice? device;
  UpdateDataCallback? updateDataCallback;

  bool _connected = false;
  bool get isConnected => _connected;
  final connectionStatus = ValueNotifier<bool>(false);

  QualifiedCharacteristic get characteristic => QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: device!.id);
  QualifiedCharacteristic get tareCharacteristic => QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: tareCharacteristicUuid,
      deviceId: device!.id);

  BLEDataHandler();

  Future<bool> connect() async {
    await _ensureDeviceDiscovered();
    bool connectionSuccessful = await _ensureDeviceConnected();
    return connectionSuccessful;
  }

  Future<void> _ensureDeviceDiscovered() async {
    if (device != null) return;
    await LocationPermissions().requestPermissions();
    final deviceFoundCompleter = Completer<void>();

    _scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.balanced,
      requireLocationServicesEnabled: true,
    ).listen((discoveredDevice) async {
      if (discoveredDevice.name == targetDeviceName) {
        await _scanSubscription?.cancel();
        device = discoveredDevice;
        deviceFoundCompleter.complete();
      }
    });

    await deviceFoundCompleter.future;
  }

  Future<bool> _ensureDeviceConnected() async {
    if (isConnected) return true;

    await _scanSubscription?.cancel();
    final connectionCompleter = Completer<bool>();

    _connectionSubscription = flutterReactiveBle
        .connectToDevice(
      id: device!.id,
      connectionTimeout: connectionTimeout,
    )
        .listen((connectionState) async {
      switch (connectionState.connectionState) {
        case DeviceConnectionState.connecting:
        case DeviceConnectionState.disconnecting:
          break;
        case DeviceConnectionState.connected:
          _updateConnectionState(true);
          await _subscribeToCharacteristic();
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(true);
          }
          break;
        case DeviceConnectionState.disconnected:
          _updateConnectionState(false);
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false);
          }
          await reconnect();
          break;
      }
    });

    return connectionCompleter.future;
  }

  void _updateConnectionState(bool connected) {
    _connected = connected;
    connectionStatus.value = _connected;
  }

  Future<void> _subscribeToCharacteristic() async {
    _dataSubscription = flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) => updateDataCallback?.call(_processData(data)));
  }

  double _processData(List<int> data) {
    if (data.length < 8) {
      throw ArgumentError('The input list must have at least 8 bytes.');
    }

    Float64List floatList = Float64List(1);
    Uint8List byteList = floatList.buffer.asUint8List();
    for (int i = 0; i < 8; i++) {
      byteList[i] = data[i];
    }
    return floatList[0];
  }

  Future<void> sendTareValue(double tareValue) async {
    if (!isConnected) throw StateError('Not connected to a device.');

    await flutterReactiveBle.writeCharacteristicWithoutResponse(
      tareCharacteristic,
      value: Uint8List.fromList(
          Float64List.fromList([tareValue]).buffer.asInt8List()),
    );
  }

  Future<bool> disconnect() async {
    await _connectionSubscription?.cancel();
    _connected = false;
    return !_connected;
  }

  Future<void> reconnect() async {
    await disconnect();
    try {
      await connect();
    } catch (e) {
      print("Error reconnecting: $e");
    }
  }
}
