
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/chat_provider.dart';
import 'package:app/models/message.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/socket_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/models/user_model.dart';

class ChatScreen extends StatefulWidget { // Converted to StatefulWidget
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _conversation;
  bool _isLoadingConversation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchConversationDetails();
    });
  }

  Future<void> _fetchConversationDetails() async {
    final conversationId = ModalRoute.of(context)!.settings.arguments as int; // Expecting int

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final conversationData = await apiService.getConversationById(conversationId);
      
      setState(() {
        _conversation = Conversation.fromJson(conversationData); // Map the fetched data
        _isLoadingConversation = false;
      });
    } catch (e) {
      print('Error fetching conversation details: $e');
      // Handle error, e.g., show a snackbar and pop
      setState(() {
        _isLoadingConversation = false;
      });
      // Optionally navigate back if conversation can't be loaded
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConversation) {
      return Scaffold(
        appBar: AppBar(title: Text('Carregando Conversa.')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Erro')),
        body: Center(child: Text('Conversa não encontrada.')),
      );
    }

    final conversation = _conversation!; // Use the fetched conversation
    final currentUserId = context.read<AuthService>().user!.id;
    // final currentUser = context.read<AuthService>().user!; // Not used directly in build

    return ChangeNotifierProvider(
      create: (context) => ChatProvider(
        context.read<ApiService>(),
        context.read<SocketService>(),
        conversation.idConversa,
      ),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final backgroundColor =
              isDarkMode ? Color(0xFF101922) : Color(0xFFF6F7F8);
          final textColor = isDarkMode ? Colors.white : Colors.black;
          final primaryColor = Color(0xFF137fec);
          final receivedMessageColor =
              isDarkMode ? Color(0xFF2D3748) : Colors.white;
          final sentMessageColor = primaryColor;

          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: isDarkMode ? Color(0xFF1A202C) : Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                conversation.displayName,
                style: TextStyle(
                    color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: textColor),
                  onPressed: () {},
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: chatProvider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: chatProvider.messages.length,
                          reverse: true, // Show latest messages at the bottom
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            final isSentByMe = message.remetente.id == currentUserId;

                            return Align(
                              alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSentByMe ? sentMessageColor : receivedMessageColor,
                                  borderRadius: BorderRadius.circular(20).copyWith(
                                    bottomRight: isSentByMe ? Radius.circular(4) : Radius.circular(20),
                                    bottomLeft: isSentByMe ? Radius.circular(20) : Radius.circular(4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.conteudo,
                                      style: TextStyle(color: isSentByMe ? Colors.white : textColor),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(message.criadoEm),
                                      style: TextStyle(
                                        color: isSentByMe ? Colors.white70 : Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                _buildMessageComposer(context, isDarkMode, primaryColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context, bool isDarkMode, Color primaryColor) {
    final _messageController = TextEditingController();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isDarkMode ? Color(0xFF1A202C) : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: primaryColor),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...', 
                filled: true,
                fillColor: isDarkMode ? Color(0xFF2D3748) : Color(0xFFF1F1F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: primaryColor),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                Provider.of<ChatProvider>(context, listen: false).sendMessage(
                  _messageController.text,
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
