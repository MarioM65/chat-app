
import 'package:flutter/material.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/socket_service.dart'; // Import SocketService

class ConversationProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final SocketService _socketService; // Inject SocketService

  List<Conversation> _conversations = [];
  bool _isLoading = false;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  ConversationProvider(this._apiService, this._authService, this._socketService) { // Add SocketService to constructor
    _socketService.socketConnected.then((_) { // Wait for socket to connect
      _initSocketListeners();
    });
  }

  void _initSocketListeners() {
    _socketService.onConversationUpdate((data) {
      try {
        final updatedConversation = Conversation.fromJson(data);
        final index = _conversations.indexWhere((conv) => conv.idConversa == updatedConversation.idConversa);
        if (index != -1) {
          _conversations[index] = updatedConversation;
          // Sort conversations again if the order might change based on last message
          _conversations.sort((a, b) {
            final dateA = a.lastMessage?.criadoEm ?? DateTime.now();
            final dateB = b.lastMessage?.criadoEm ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          notifyListeners();
        } else {
          // If it's a new conversation, add it
          _conversations.insert(0, updatedConversation);
          // Sort conversations again
          _conversations.sort((a, b) {
            final dateA = a.lastMessage?.criadoEm ?? DateTime.now();
            final dateB = b.lastMessage?.criadoEm ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          notifyListeners();
        }
      } catch (e) {
        print('Error parsing conversation update from socket: $e');
      }
    });
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      // The backend now filters conversations by participant and handles dynamic naming.
      final conversationsData = await _apiService.getConversations();
      _conversations = conversationsData
          .map((data) => Conversation.fromJson(data)) // Use Conversation.fromJson
          .toList();
      print('Number of conversations fetched: ${_conversations.length}');
      // Initial sort after fetching all conversations
      _conversations.sort((a, b) {
        final dateA = a.lastMessage?.criadoEm ?? DateTime.now();
        final dateB = b.lastMessage?.criadoEm ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      // Handle error
      print('Error fetching conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addConversation(Conversation conversation) {
    _conversations.insert(0, conversation); // Add new conversation to the top
    // Sort conversations again
    _conversations.sort((a, b) {
      final dateA = a.lastMessage?.criadoEm ?? DateTime.now();
      final dateB = b.lastMessage?.criadoEm ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    notifyListeners();
  }

  void updateConversation(Conversation updatedConversation) {
    final index = _conversations.indexWhere((conv) => conv.idConversa == updatedConversation.idConversa);
    if (index != -1) {
      _conversations[index] = updatedConversation;
      // Sort conversations again if the order might change based on last message
      _conversations.sort((a, b) {
        final dateA = a.lastMessage?.criadoEm ?? DateTime.now();
        final dateB = b.lastMessage?.criadoEm ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      notifyListeners();
    }
  }
}
