// lib/services/mesh_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class MeshService {
  final String userName = "SafeNetNode_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  final Strategy strategy = Strategy.P2P_STAR; 
  
  List<String> connectedEndpoints = [];
  Function()? onRelaySuccess; 
  
  bool _isStopping = false;
  String? _pendingSOSPayload; // Holds the payload when switching to Victim mode
  
  // 🧠 MULTI-HOP MEMORY: Prevents the "Broadcast Storm" infinite loop
  final Set<String> _seenMessages = {}; 

  // =========================================================
  // 1. INITIALIZATION (HERO BY DEFAULT)
  // =========================================================
  Future<void> initMesh() async {
    _isStopping = false;
    await _requestAggressivePermissions();
    
    // EVERYONE starts as a Hero. No collisions. Pure silence.
    print("🕸️ MESH: Booting up in Peacetime. Starting HERO MODE (Advertising)...");
    await _startAdvertising();
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
  }

  // =========================================================
  // 2. THE DYNAMIC NETWORK FLIP
  // =========================================================
  Future<void> _triggerVictimMode(String payload) async {
    print("🚨 MESH: EMERGENCY TRIGGERED! Switching to VICTIM MODE...");
    _pendingSOSPayload = payload;
    
    // Stop being a Hero
    await Nearby().stopAdvertising();
    connectedEndpoints.clear();
    
    // Start screaming for help
    await _startDiscovery();
  }

  // =========================================================
  // 3. DISCOVERY & ADVERTISING LOGIC
  // =========================================================
  Future<void> _startAdvertising() async {
    if (_isStopping) return;
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) => _handleIncomingPayload(payload),
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            print("🦸‍♂️ MESH: Connected to a Victim ($id)! Ready to catch payload.");
            if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
          } else {
            connectedEndpoints.remove(id);
          }
        },
        onDisconnected: (String id) {
          connectedEndpoints.remove(id);
        },
      );
    } catch (e) {
      print("🕸️ MESH: Advertising error: $e");
    }
  }

  Future<void> _startDiscovery() async {
    if (_isStopping) return;
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String name, String serviceId) async {
          print("🆘 MESH: Found a Hero ($name)! Requesting lifeline...");
          try {
            await Nearby().requestConnection(
              userName,
              id,
              onConnectionInitiated: (id, info) {
                Nearby().acceptConnection(
                  id,
                  onPayLoadRecieved: (endpointId, payload) => _handleIncomingPayload(payload),
                );
              },
              onConnectionResult: (id, status) {
                if (status == Status.CONNECTED) {
                  print("🆘 MESH: Linked to Hero $id! Blasting payload...");
                  if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
                  
                  // 🔥 THE MAGIC: Blast the payload the millisecond we connect!
                  if (_pendingSOSPayload != null) {
                    Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(_pendingSOSPayload!)));
                  }
                }
              },
              onDisconnected: (id) => connectedEndpoints.remove(id),
            );
          } catch (e) {
            print("🕸️ MESH: Connection request failed: $e");
          }
        },
        onEndpointLost: (String? id) {}, 
      );
    } catch (e) {
      print("🕸️ MESH: Discovery error: $e");
    }
  }

  // =========================================================
  // 4. THE MULTI-HOP BRAIN (CATCHING THE PAYLOAD)
  // =========================================================
  void _handleIncomingPayload(Payload payload) async {
    if (payload.type != PayloadType.BYTES) return;
    
    String data = utf8.decode(payload.bytes!);
    print("🦸‍♂️ MESH: CAUGHT A PAYLOAD! Inspecting...");

    try {
      final Map<String, dynamic> sosData = jsonDecode(data);
      String msgId = sosData['msg_id'] ?? "unknown";
      
      // 1. AVOID BROADCAST STORMS
      if (_seenMessages.contains(msgId)) {
        print("🛑 MESH: Already processed this SOS ($msgId). Ignoring to prevent loop.");
        return;
      }
      _seenMessages.add(msgId); // Remember this message!

      // 2. CHECK FOR INTERNET
      bool hasInternet = await _checkInternetConnection();

      if (hasInternet) {
        print("✅ MESH: I have internet! Forwarding to Layer 1 Cloud...");
        
        bool success = await ApiService.relayOfflineSOS(
          sosData['victim_uuid'] ?? "unknown", 
          sosData['lat'], 
          sosData['lon']
        );
        
        // 🚨 ONLY FIRE UI POPUP IF CLOUD CONFIRMS RECEIPT
        if (success && onRelaySuccess != null) {
          onRelaySuccess!();
        }
      } else {
        // 3. THE MULTI-HOP PROXY PIVOT
        print("❌ MESH: No Internet. Checking TTL for Multi-Hop...");
        int ttl = sosData['ttl'] ?? 0;
        
        if (ttl > 0) {
          print("🔄 MESH: TTL is $ttl. I am becoming a Proxy Victim to pass it on!");
          sosData['ttl'] = ttl - 1; // Decrease TTL
          
          // Transform into a Victim and scream the updated payload to the next Hero
          await _triggerVictimMode(jsonEncode(sosData));
        } else {
          print("☠️ MESH: TTL hit 0. Payload died. Could not reach internet.");
        }
      }
    } catch (e) {
      print("🕸️ MESH: Payload Parsing Error: $e");
    }
  }

  // =========================================================
  // 5. LOCAL TRIGGERS & UTILS
  // =========================================================
  Future<bool> broadcastOfflineSOS(double lat, double lon, int battery) async {
    final prefs = await SharedPreferences.getInstance();
    final String? myUuid = prefs.getString('user_uuid');
    
    // Generate a unique ID for this specific emergency event
    String uniqueMsgId = "${myUuid ?? "anon"}_${DateTime.now().millisecondsSinceEpoch}";

    String sosPacket = jsonEncode({
      "msg_id": uniqueMsgId,
      "victim_uuid": myUuid ?? "anonymous",
      "lat": lat,
      "lon": lon,
      "battery": battery,
      "ttl": 3, // MAXIMUM HOPS (Victim -> Hero 1 -> Hero 2 -> Hero 3)
      "timestamp": DateTime.now().toIso8601String()
    });

    _seenMessages.add(uniqueMsgId); // Don't bounce our own message back to ourselves
    await _triggerVictimMode(sosPacket);
    return true; // We return true because the trigger sequence successfully initiated
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://8.8.8.8')).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void simulateRelaySuccess() {
    if (onRelaySuccess != null) onRelaySuccess!();
  }
  
  void stopMesh() {
    _isStopping = true;
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedEndpoints.clear();
  }
}