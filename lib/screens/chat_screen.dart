
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/chat_provider.dart';
import 'package:app/models/message.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/socket_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/models/user_model.dart';
import 'package:app/models/participante_conversa_model.dart'; // Import the new participant model
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/widgets/attachment_view.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _conversation;
  bool _isLoadingConversation = true;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _filesToSend = [];
  final String _baseUrl = dotenv.env['BASE_URL']!; // Add base URL
  late TextEditingController _messageController; // Declare here
  Message? _replyingToMessage; // Track message being replied to
  Message? _editingMessage; // Track message being edited

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(); // Initialize in initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Conversation) {
      setState(() {
        _conversation = args;
        _isLoadingConversation = false;
      });
      _markMessagesAsRead(args.idConversa); // Mark messages as read
    } else if (args is int) {
      _fetchConversationDetails(args);
    } else {
      // Handle the case where arguments are null or of a different type
      setState(() {
        _isLoadingConversation = false;
      });
    }
  }

  Future<void> _fetchConversationDetails(int conversationId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final conversationData = await apiService.getConversationById(conversationId);
      
      setState(() {
        _conversation = Conversation.fromJson(conversationData);
        _isLoadingConversation = false;
      });
      _markMessagesAsRead(conversationId); // Mark messages as read
    } catch (e) {
      print('Error fetching conversation details: $e');
      setState(() {
        _isLoadingConversation = false;
      });
      // Optionally show an error and pop
      // Navigator.of(context).pop();
    }
  }

  Future<void> _markMessagesAsRead(int conversationId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markConversationAsRead(conversationId);
      // Optionally, refresh conversations in the parent screen (ConversationsScreen)
      // to update unread counts immediately.
      // This would require a callback or a global state update.
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose(); // Dispose controller
    super.dispose();
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Imagens'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final List<XFile>? images = await _picker.pickMultiImage();
                  if (images != null && images.isNotEmpty) {
                    setState(() {
                      _filesToSend.addAll(images);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Vídeo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    setState(() {
                      _filesToSend.add(video);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Documentos'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement document picking
                },
              ),
              ListTile(
                leading: Icon(Icons.mic),
                title: Text('Áudio'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement audio picking
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // New method to show message options
  void _showMessageOptions(Message message, int currentUserId, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        bool isMyMessage = message.remetente?.id == currentUserId;
        bool canDelete = isMyMessage; // Owner can always delete

        // Check if current user is admin/creator for group messages
        if (!isMyMessage && conversation.tipoConversa == 'grupo') {
          final currentUserParticipant = conversation.participantes.firstWhere(
            (p) => p.usuario.id == currentUserId,
            orElse: () => ParticipanteConversa(usuario: User(id: -1, nomeUsuario: '', email: ''), papel: 'MEMBRO'),
          );
          if (currentUserParticipant.papel == 'ADMIN' || currentUserParticipant.papel == 'CRIADOR') {
            canDelete = true;
          }
        }

        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.reply),
                title: Text('Responder'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _replyingToMessage = message;
                  });
                  FocusScope.of(context).requestFocus(FocusNode()); // Focus text input
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _editingMessage = message;
                      _messageController.text = message.conteudo;
                    });
                    FocusScope.of(context).requestFocus(FocusNode()); // Focus text input
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Apagar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteMessage(messageId);
      // Refresh messages after deletion
      Provider.of<ChatProvider>(context, listen: false).fetchMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensagem apagada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar mensagem: $e')),
      );
    }
  }

  Future<void> _editMessage(int messageId, String newContent) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateMessage(messageId, newContent);
      // Refresh messages after editing
      Provider.of<ChatProvider>(context, listen: false).fetchMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensagem editada.')),
      );
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar mensagem: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingConversation) {
      return Scaffold(
        appBar: AppBar(title: Text('Carregando Conversa...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Erro')),
        body: Center(child: Text('Não foi possível carregar a conversa.')),
      );
    }

    final conversation = _conversation!;
    final authService = context.read<AuthService>();
    final currentUserId = authService.user!.id;

    // Determine the other participant for individual chats
    User? otherParticipant;
    if (conversation.tipoConversa == 'individual') {
      otherParticipant = conversation.participantes
          .firstWhere((p) => p.usuario.id != currentUserId, orElse: () => ParticipanteConversa(usuario: User(id: -1, nomeUsuario: '', email: ''), papel: 'MEMBRO')) // Provide a default if no other participant found
          .usuario;
    }

    return ChangeNotifierProvider(
      create: (context) => ChatProvider(
        context.read<ApiService>(),
        context.read<SocketService>(),
        authService,
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
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: conversation.displayImage != null
                        ? Image.network(
                            '$_baseUrl/${conversation.displayImage!}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.group, color: Colors.white), // Fallback icon for groups
                          ).image
                        : null,
                    child: conversation.displayImage == null
                        ? Icon(
                            conversation.tipoConversa == 'grupo' ? Icons.group : Icons.person,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName,
                        style: TextStyle(
                            color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (conversation.tipoConversa == 'individual' && otherParticipant != null)
                        Text(
                          otherParticipant.status, // Display other participant's status
                          style: TextStyle(
                            color: otherParticipant.status == 'Online' ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                _buildPopupMenuButton(context, conversation, currentUserId, textColor),
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
                          reverse: true,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            final isSentByMe = message.remetente?.id == currentUserId;

                            return GestureDetector(
                              onLongPress: () => _showMessageOptions(message, currentUserId, conversation), // Long press to show options
                              child: Align(
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
                                      if (conversation.tipoConversa == 'grupo' && !isSentByMe)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            message.remetente?.nomeUsuario ?? 'Usuário Desconhecido',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.cyanAccent : Colors.blueAccent, // Distinct color for sender name
                                            ),
                                          ),
                                        ),
                                      if (message.anexos.isNotEmpty)
                                        ...message.anexos.map((anexo) => AttachmentView(attachment: anexo)).toList(),
                                      if (message.conteudo.isNotEmpty)
                                        Text(
                                          message.conteudo,
                                          style: TextStyle(color: isSentByMe ? Colors.white : textColor),
                                        ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(message.criadoEm ?? DateTime.now()), // Safely handle nullable criadoEm
                                            style: TextStyle(
                                              color: isSentByMe ? Colors.white70 : Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (isSentByMe) ...[
                                            SizedBox(width: 4),
                                            Icon(
                                              message.isReadByAnyOtherParticipant == true ? Icons.done_all : Icons.done,
                                              size: 15,
                                              color: message.isReadByAnyOtherParticipant == true ? primaryColor : Colors.white70,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
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
    // Moved _messageController declaration to class level

    return Column(
      children: [
        if (_replyingToMessage != null) // Display reply indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respondendo a ${_replyingToMessage!.remetente?.nomeUsuario ?? 'Usuário Desconhecido'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _replyingToMessage!.conteudo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Corrected
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _replyingToMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: isDarkMode ? Color(0xFF1A202C) : Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: primaryColor),
                onPressed: () => _showAttachmentMenu(context),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF2D3748) : Color(0xFFF1F1F2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                        onPressed: () {
                          // TODO: Implement emoji picker
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: primaryColor),
                onPressed: () {
                  if (_editingMessage != null) {
                    _editMessage(_editingMessage!.id, _messageController.text);
                  } else if (_messageController.text.isNotEmpty || _filesToSend.isNotEmpty) {
                    Provider.of<ChatProvider>(context, listen: false).sendComposedMessage(
                      _messageController.text,
                      _filesToSend,
                    );
                    _messageController.clear();
                    setState(() {
                      _filesToSend.clear();
                      _replyingToMessage = null; // Clear replying state after sending
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenuButton(BuildContext context, Conversation conversation, int currentUserId, Color iconColor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (String result) async { // Make it async
        // Handle the selected option
        switch (result) {
          case 'block_user':
            // TODO: Implement block user functionality
            print('Block User');
            break;
          case 'unblock_user':
            // TODO: Implement unblock user functionality
            print('Unblock User');
            break;
          case 'delete_conversation':
            // TODO: Implement delete conversation functionality
            print('Delete Conversation');
            break;
          case 'edit_group':
            final updatedConversation = await Navigator.of(context).pushNamed(
              '/edit_group',
              arguments: conversation,
            );
            if (updatedConversation != null && updatedConversation is Conversation) {
              setState(() {
                _conversation = updatedConversation; // Update the conversation after editing
              });
            }
            break;
          case 'leave_group':
            // TODO: Implement leave group functionality
            print('Leave Group');
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        if (conversation.tipoConversa == 'individual') {
          // For individual chats, offer Block/Unblock and Delete Conversation
          // Determine if the other user is blocked (requires state management or API call)
          // For now, let's assume a simple block option
          items.add(
            PopupMenuItem<String>(
              value: 'block_user', // Or 'unblock_user'
              child: Text('Bloquear usuário'),
            ),
          );
          items.add(
            PopupMenuItem<String>(
              value: 'delete_conversation',
              child: Text('Apagar conversa'),
            ),
          );
        } else if (conversation.tipoConversa == 'grupo') {
          // For group chats, check user role
          final currentUserParticipant = conversation.participantes.firstWhere(
            (p) => p.usuario.id == currentUserId,
            orElse: () => ParticipanteConversa(usuario: User(id: -1, nomeUsuario: '', email: ''), papel: 'MEMBRO'), // Default to member if not found
          );

          if (currentUserParticipant.papel == 'ADMIN' || currentUserParticipant.papel == 'CRIADOR') {
            // Admin/Creator options
            items.add(
              PopupMenuItem<String>(
                value: 'edit_group',
                child: Text('Editar Grupo'),
              ),
            );
          }
          // All group members can leave
          items.add(
            PopupMenuItem<String>(
              value: 'leave_group',
              child: Text('Sair do Grupo'),
            ),
          );
        }
        return items;
      },
    );
  }
}
