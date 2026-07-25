import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive_flutter/hive_flutter.dart';

class SocketService extends GetxService {
  static SocketService get to => Get.find<SocketService>();

  IO.Socket? _socket;

  // Observable state
  final RxBool isConnected = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;
  final RxString currentRoom = ''.obs;
  final RxString currentEvent = ''.obs;

  // Callback that controllers can register to react to incoming events
  Function(Map<String, dynamic> data)? onAttendanceCompleted;

  static const String _baseUrl = 'https://bio.ubroapi.space';

  // ─────────────────────────────────────────────
  //  Public: call after download API to (re)connect
  // ─────────────────────────────────────────────
  Future<void> connectAndJoinRoom({
    required String room,
    required String event,
    required String token,
  }) async {
    // Disconnect previous socket if any
    disconnect();

    currentRoom.value = room;
    currentEvent.value = event;
    connectionStatus.value = 'Connecting...';

    print('[Socket] Connecting to $_baseUrl | room=$room | event=$event');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      isConnected.value = true;
      connectionStatus.value = 'Connected';
      print('[Socket] Connected. Joining room: $room');
      _socket!.emit('join-room', room);
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      connectionStatus.value = 'Disconnected';
      print('[Socket] Disconnected');
    });

    _socket!.onConnectError((err) {
      isConnected.value = false;
      connectionStatus.value = 'Error';
      print('[Socket] Connection error: $err');
    });

    _socket!.onError((err) {
      print('[Socket] Error: $err');
    });

    // Listen to the dynamic event from API (e.g. 'attendance-completed')
    _socket!.on(event, (data) {
      print('[Socket] Event "$event" received: $data');
      _handleIncomingAttendanceEvent(data);
    });

    // Also listen to generic room-wide updates
    _socket!.on('room-update', (data) {
      print('[Socket] Room update: $data');
      _handleIncomingAttendanceEvent(data);
    });

    _socket!.connect();
  }

  // ─────────────────────────────────────────────
  //  Restore connection from saved prefs (on app start)
  // ─────────────────────────────────────────────
  Future<void> reconnectFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? room = prefs.getString('socket_room');
    final String? event = prefs.getString('socket_event');
    final String? token = prefs.getString('token');

    if (room != null && event != null && token != null && room.isNotEmpty) {
      await connectAndJoinRoom(room: room, event: event, token: token);
    } else {
      print('[Socket] No saved socket config found, skipping reconnect.');
    }
  }

  // ─────────────────────────────────────────────
  //  Emit attendance-completed event to the server
  // ─────────────────────────────────────────────
  void emitAttendanceCompleted({required Map<String, dynamic> studentData}) {
    if (_socket == null || !isConnected.value) {
      print('[Socket] Cannot emit — not connected.');
      return;
    }

    final payload = {
      'room': currentRoom.value,
      'studentId': studentData['id'] ?? studentData['_id'] ?? '',
      'rollNo': studentData['rollNo'] ?? studentData['rollno'] ?? '',
      'name': studentData['name'] ?? '',
      'attendanceTime': studentData['attendanceTime'] ?? '',
      'syncStatus': true,
    };

    print('[Socket] Emitting "${currentEvent.value}": $payload');
    _socket!.emit(currentEvent.value, payload);
  }

  // ─────────────────────────────────────────────
  //  Handle incoming events from server
  // ─────────────────────────────────────────────
  void _handleIncomingAttendanceEvent(dynamic rawData) {
    try {
      Map<String, dynamic> data = {};
      if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      }

      // If server says a student's attendance is confirmed, update local Hive
      final String? studentId = data['studentId']?.toString();
      if (studentId != null && studentId.isNotEmpty) {
        _updateLocalStudentSyncStatus(studentId);
      }

      // Fire registered callback so controllers can refresh UI
      if (onAttendanceCompleted != null) {
        onAttendanceCompleted!(data);
      }
    } catch (e) {
      print('[Socket] Error handling incoming event: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Update Hive student sync status when server confirms
  // ─────────────────────────────────────────────
  Future<void> _updateLocalStudentSyncStatus(String studentId) async {
    try {
      final box = Hive.box('candidates_box');
      for (int i = 0; i < box.length; i++) {
        var item = Map<String, dynamic>.from(box.getAt(i) as Map);
        final id = (item['id'] ?? item['_id'] ?? '').toString();
        if (id == studentId) {
          item['syncStatus'] = true;
          item['syncFailed'] = false;
          await box.putAt(i, item);
          print('[Socket] Updated syncStatus for student $studentId in Hive');
          break;
        }
      }
    } catch (e) {
      print('[Socket] Hive update error: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Disconnect
  // ─────────────────────────────────────────────
  void disconnect() {
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
      isConnected.value = false;
      connectionStatus.value = 'Disconnected';
      print('[Socket] Disconnected and disposed.');
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
