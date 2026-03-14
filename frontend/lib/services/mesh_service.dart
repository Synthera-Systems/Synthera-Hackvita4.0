// lib/services/mesh_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MeshService {

  final bool isHeroNode = true; 

  final String userName = "SafeNetNode_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  final Strategy strategy = Strategy.P2P_STAR; 
  
  List<String> connectedEndpoints = [];
  Function()? onRelaySuccess; 
  bool _isStopping = false;

  Future<void> initMesh() async {
    _isStopping = false;
    await _requestAggressivePermissions();
    
    // THE HALF-DUPLEX SPLIT
    if (isHeroNode) {
      print("🕸️ MESH [HERO NODE]: I am a Relay. Starting Advertising ONLY...");
      await _startAdvertising();
    } else {
      print("🕸️ MESH [VICTIM NODE]: I am in danger. Starting Discovery ONLY...");
      await _startDiscovery();
    }
  }

  Future<void> _requestAggressivePermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    print("🕸️ MESH: Permissions requested via permission_handler.");
  }

  void simulateRelaySuccess() {
    if (onRelaySuccess != null) {
      print("🕵️ SECRET: Forcing Hero Mode UI...");
      onRelaySuccess!();
    }
  }

  Future<void> _startAdvertising() async {
    if (_isStopping) return;
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          print("🕸️ MESH: Connection Initiated by Victim: ${info.endpointName}");
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              _handleIncomingPayload(payload);
            },
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            print("🕸️ MESH: Successfully Connected as HERO to Victim $id!");
            if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
          } else {
            connectedEndpoints.remove(id);
          }
        },
        onDisconnected: (String id) {
          print("🕸️ MESH: Victim $id disconnected.");
          connectedEndpoints.remove(id);
        },
      );
      print("🕸️ MESH: Hero Advertising Started: $a");
    } catch (e) {
      print("🕸️ MESH: Advertising error: $e");
    }
  }

  Future<void> _startDiscovery() async {
    if (_isStopping) return;
    try {
      bool d = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String name, String serviceId) async {
          print("🕸️ MESH: Found Hero Relay: $name. Requesting Connection...");
          try {
            await Nearby().requestConnection(
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
                  print("🕸️ MESH: Successfully Connected as VICTIM to Hero $id!");
                  if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
                }
              },
              onDisconnected: (id) {
                print("🕸️ MESH: Lost connection to Hero $id");
                connectedEndpoints.remove(id);
              },
            );
          } catch (e) {
            print("🕸️ MESH: Connection request failed: $e");
          }
        },
        onEndpointLost: (String? id) {
          print("🕸️ MESH: Hero endpoint lost $id");
        }, 
      );
      print("🕸️ MESH: Victim Discovery Started: $d");
    } catch (e) {
      print("🕸️ MESH: Discovery error: $e");
    }
  }

  void _handleIncomingPayload(Payload payload) async {
    if (payload.type == PayloadType.BYTES) {
      String data = String.fromCharCodes(payload.bytes!);
      print("🕸️ MESH: Caught Payload! Data: $data");
      
      // If we caught a payload, it means we are the Hero Node helping someone!
      if (onRelaySuccess != null) {
        onRelaySuccess!();
      }

      try {
        final Map<String, dynamic> sosData = jsonDecode(data);
        await ApiService.relayOfflineSOS(
          sosData['victim_uuid'] ?? "unknown", 
          sosData['lat'], 
          sosData['lon']
        );
      } catch (e) {
        print("🕸️ MESH: Payload Parsing Error: $e");
      }
    }
  }

  Future<bool> broadcastOfflineSOS(double lat, double lon, int battery) async {
    if (connectedEndpoints.isEmpty) {
      print("🕸️ MESH: Cannot broadcast, no Hero peers connected.");
      return false;
    }

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
      print("🕸️ MESH: Broadcasting SOS to ${connectedEndpoints.length} Hero Relays...");
      for (String endpoint in connectedEndpoints) {
        Nearby().sendBytesPayload(endpoint, Uint8List.fromList(sosPacket.codeUnits));
      }
      return true;
    } catch (e) {
      print("🕸️ MESH: Broadcast Error: $e");
      return false;
    }
  }
  
  void stopMesh() {
    _isStopping = true;
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedEndpoints.clear();
    print("🕸️ MESH: Stopped all operations.");
  }
}