
import 'package:flutter/material.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/services/auth_service.dart';

class ConversationProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  List<Conversation> _conversations = [];
  bool _isLoading = false;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  ConversationProvider(this._apiService, this._authService);

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      // The backend now filters conversations by participant and handles dynamic naming.
      final conversationsData = await _apiService.getConversations();
      _conversations = conversationsData
          .map((data) => Conversation.fromJson(data)) // Use Conversation.fromJson
          .toList();
    } catch (e) {
      // Handle error
      print('Error fetching conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
