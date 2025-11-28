
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String _baseUrl = dotenv.env['BASE_URL']!;
  bool _isConnected = false;
  final Completer<void> _socketConnectedCompleter = Completer<void>();


  bool get isSocketConnected => _isConnected;
  Future<void> get socketConnected => _socketConnectedCompleter.future;

  void connect(String token) {
    // If already connected or connecting, do nothing
    if (_isConnected || _socketConnectedCompleter.isCompleted) {
      return;
    }

    // NOTE: Use your local IP if you're testing on an Android emulator.
    // Do not use 'localhost' or '127.0.0.1'.
    // For iOS, 'localhost' works if the server is on the same machine.
    socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token
      }
    });

    socket.onConnect((_) {
      print('Connected to WebSocket server');
      _isConnected = true;
      if (!_socketConnectedCompleter.isCompleted) {
        _socketConnectedCompleter.complete();
      }
    });

    socket.onDisconnect((_) {
      print('Disconnected');
      _isConnected = false;
      // Reset completer for potential future reconnections if needed
      // _socketConnectedCompleter = Completer<void>();
    });
    
    socket.onError((error) => print('Socket Error: $error'));
  }

  // Listen for new messages
  void onChatMessage(Function(Map<String, dynamic>) handler) {
    socket.on('chatMessage', (data) {
      print('SocketService received chatMessage: $data');
      handler(data);
    });
  }

  // Listen for conversation updates (e.g., new messages, read status, group changes)
  void onConversationUpdate(Function(Map<String, dynamic>) handler) {
    socket.on('conversationUpdate', (data) {
      print('SocketService received conversationUpdate: $data');
      handler(data);
    });
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    if (_isConnected) {
      socket.emit('joinRoom', conversationId);
    } else {
      print('Socket not connected. Cannot join room.');
    }
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_isConnected) {
      socket.emit('leaveRoom', conversationId);
    } else {
      print('Socket not connected. Cannot leave room.');
    }
  }

  // Send a message
  void sendMessage({
    required int conversationId,
    required String content,
  }) {
    if (_isConnected) {
      final message = {
        'id_conversa': conversationId,
        'conteudo': content,
        'tipo': 'texto',
      };
      socket.emit('chatMessage', message);
    } else {
      print('Socket not connected. Cannot send message.');
    }
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
    }
  }
}
