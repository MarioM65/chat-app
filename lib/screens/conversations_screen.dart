
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/conversation_provider.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConversationsScreen extends StatefulWidget {
  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final String _baseUrl = dotenv.env['BASE_URL']!;
  @override
  void initState() {
    super.initState();
    // Fetch conversations when the screen is initialized
    // Ensure AuthService is initialized before calling fetchConversations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConversationProvider>(context, listen: false).fetchConversations();
    });
  }

  String _formatConversationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Ontem';
      } else {
        return DateFormat('dd/MM/yy').format(time);
      }
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF101922) : Color(0xFFF6F7F8);
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = Color(0xFF137fec);
    final conversationProvider = Provider.of<ConversationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.user; // Get the logged-in user

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: currentUser.fotoPerfil != null
                ? Image.network(
                    '$_baseUrl/${currentUser.fotoPerfil!}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white), // Fallback icon
                  ).image
                : null,
            child: currentUser.fotoPerfil == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        title: Text('Conversas', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (String result) async {
              if (result == 'logout') {
                await authService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              } else if (result == 'edit_profile') {
                Navigator.of(context).pushNamed('/edit-profile');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit_profile',
                child: Text('Editar Perfil'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Sair'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar conversas ou contatos',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: conversationProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: conversationProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversationProvider.conversations[index];
                      final lastMessage = conversation.lastMessage;
                      final unreadCount = conversation.unreadCount;
                      final lastMessageTime = lastMessage?.criadoEm;
                      
                      String subtitleText = "Nenhuma mensagem.";
                      if (lastMessage != null) {
                        if (lastMessage.conteudo.isNotEmpty) {
                          subtitleText = lastMessage.conteudo;
                        } else if (lastMessage.anexos.isNotEmpty) {
                          subtitleText = "Anexo";
                        }
                      }
                      
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pushNamed('/chat', arguments: conversation);
                        },
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: conversation.displayImage != null
                              ? Image.network(
                                  '$_baseUrl/${conversation.displayImage!}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(conversation.displayName[0], style: const TextStyle(color: Colors.white)), // Fallback text
                                ).image
                              : null,
                          child: conversation.displayImage == null
                              ? Text(conversation.displayName[0], style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        title: Text(
                          conversation.displayName,
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        subtitle: Text(
                          subtitleText,
                          style: TextStyle(
                            color: unreadCount > 0 ? primaryColor : secondaryTextColor,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (lastMessageTime != null)
                              Text(
                                _formatConversationTime(lastMessageTime),
                                style: TextStyle(
                                  color: unreadCount > 0 ? primaryColor : secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            SizedBox(height: 4),
                            if (unreadCount > 0)
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-conversation');
        },
        child: Icon(Icons.edit),
        backgroundColor: primaryColor,
      ),
    );
  }
}
