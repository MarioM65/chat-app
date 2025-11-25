
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String _baseUrl = dotenv.env['BASE_URL']!;
  void connect(String token) {
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
    });

    socket.onDisconnect((_) => print('Disconnected'));
  }

  // Listen for new messages
  void onChatMessage(Function(Map<String, dynamic>) handler) {
    socket.on('chatMessage', (data) => handler(data));
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    socket.emit('joinRoom', conversationId);
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    socket.emit('leaveRoom', conversationId);
  }

  // Send a message
  void sendMessage({
    required int conversationId,
    required String content,
  }) {
    final message = {
      'id_conversa': conversationId,
      'conteudo': content,
      'tipo': 'texto',
    };
    socket.emit('chatMessage', message);
  }

  void disconnect() {
    socket.disconnect();
  }
}
