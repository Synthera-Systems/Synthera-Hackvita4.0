// lib/services/mesh_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MeshService {
  final String userName = "SafeNetNode_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  final Strategy strategy = Strategy.P2P_CLUSTER;
  List<String> connectedEndpoints = [];
  Function()? onRelaySuccess; 

  Future<void> initMesh() async {
    await checkPermissions();
    _startAdvertising();
    _startDiscovery();
  }

  Future<void> checkPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
  }

  void simulateRelaySuccess() {
    if (onRelaySuccess != null) {
      print("🕵️ SECRET: Forcing Hero Mode UI...");
      onRelaySuccess!();
    }
  }

  void _startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              _handleIncomingPayload(payload);
            },
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
          } else {
            connectedEndpoints.remove(id);
          }
        },
        onDisconnected: (String id) => connectedEndpoints.remove(id),
      );
    } catch (e) {
      print("MESH: Advertising error: $e");
    }
  }

  void _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String name, String serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endpointId, payload) {
                  _handleIncomingPayload(payload);
                },
              );
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
              }
            },
            onDisconnected: (id) => connectedEndpoints.remove(id),
          );
        },
        onEndpointLost: (String? id) {
          print("MESH: Lost connection to node $id");
        }, // FIXED: Added required parameter
      );
    } catch (e) {
      print("MESH: Discovery error: $e");
    }
  }

  void _handleIncomingPayload(Payload payload) async {
    if (payload.type == PayloadType.BYTES) {
      String data = String.fromCharCodes(payload.bytes!);
      
      // TRIGGER UI IMMEDIATELY FOR DEMO IMPACT
      if (onRelaySuccess != null) {
        onRelaySuccess!();
      }

      try {
        final Map<String, dynamic> sosData = jsonDecode(data);
        
        // Background relay to cloud
        await ApiService.relayOfflineSOS(
          sosData['victim_uuid'] ?? "unknown", 
          sosData['lat'], 
          sosData['lon']
        );
      } catch (e) {
        print("MESH: Payload Error: $e");
      }
    }
  }

  Future<bool> broadcastOfflineSOS(double lat, double lon, int battery) async {
    if (connectedEndpoints.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final String? myUuid = prefs.getString('user_uuid');

    String sosPacket = jsonEncode({
      "victim_uuid": myUuid ?? "anonymous",
      "lat": lat,
      "lon": lon,
      "battery": battery,
      "timestamp": DateTime.now().toIso8601String()
    });

    try {
      for (String endpoint in connectedEndpoints) {
        Nearby().sendBytesPayload(endpoint, Uint8List.fromList(sosPacket.codeUnits));
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  void stopMesh() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
  }
}