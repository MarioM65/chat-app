
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/socket_service.dart';
import 'package:app/models/message.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;
  final AuthService _authService;

  List<Message> _messages = [];
  bool _isLoading = false;
  final int conversationId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider(this._apiService, this._socketService, this._authService, this.conversationId) {
    fetchMessages();
    _socketService.socketConnected.then((_) { // Wait for socket to connect
      _initSocketListeners();
    });
  }

  void _initSocketListeners() {
    _socketService.joinConversation(conversationId.toString());
    _socketService.onChatMessage((data) {
      print('ChatProvider received raw message data: $data');
      try {
        final message = Message.fromJson(data);
        print('ChatProvider parsed message: $message');
        if (message.idConversa == conversationId) {
          _messages.insert(0, message);
          notifyListeners();
        }
      } catch (e) {
        print('Error parsing message from socket: $e');
      }
    });
  }

  @override
  void dispose() {
    _socketService.leaveConversation(conversationId.toString());
    super.dispose();
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();
    try {
      final messagesData = await _apiService.getMessages(conversationId);
      _messages = messagesData.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // This method should primarily be used by the SocketService for real-time messaging
  void sendMessage(String content) {
    _socketService.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<void> sendAttachmentOnly(List<XFile> attachments) async {
    try {
      await _apiService.sendMessage(
        conversationId: conversationId,
        content: '', // No content for attachment-only messages
        messageType: 'anexo',
        attachments: attachments,
      );
      // Rely on WebSocket event from server for message to appear in chat
    } catch (e) {
      print('Error sending attachment: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  Future<void> sendAttachment(List<XFile> attachments) async {
    try {
      await _apiService.sendMessage(
        conversationId: conversationId,
        content: '',
        messageType: 'anexo',
        attachments: attachments,
      );
      // Do not fetch messages here. Rely on WebSocket event from server.
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendComposedMessage(String content, List<XFile> attachments) async {
    try {
      if (attachments.isNotEmpty) {
        await _apiService.sendMessage(
          conversationId: conversationId,
          content: content,
          messageType: 'anexo', // If attachments exist, treat as anexo
          attachments: attachments,
        );
        // Do not fetch messages here. Rely on WebSocket event from server.
      } else {
        // Text-only message, send via WebSocket
        _socketService.sendMessage(
          conversationId: conversationId,
          content: content,
        );
      }
    } catch (e) {
      // Handle error
    }
  }
}
