
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
    _socketService.joinConversation(conversationId.toString());
    _socketService.onChatMessage((data) {
      final message = Message.fromJson(data);
      if (message.idConversa == conversationId) {
        _messages.insert(0, message);
        notifyListeners();
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

  void sendMessage(String content) {
    _socketService.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<void> sendAttachment(List<XFile> attachments) async {
    try {
      await _apiService.sendMessage(
        conversationId: conversationId,
        content: '',
        messageType: 'anexo',
        attachments: attachments,
      );
      await fetchMessages(); // Refresh messages after sending attachment
    } catch (e) {
      // Handle error
    }
  }
}
