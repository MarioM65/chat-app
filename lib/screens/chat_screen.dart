
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Conversation) {
      setState(() {
        _conversation = args;
        _isLoadingConversation = false;
      });
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
    } catch (e) {
      print('Error fetching conversation details: $e');
      setState(() {
        _isLoadingConversation = false;
      });
      // Optionally show an error and pop
      // Navigator.of(context).pop();
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
                          reverse: true,
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
                                    if (conversation.tipoConversa == 'grupo' && !isSentByMe)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          message.remetente.nomeUsuario,
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
                                          DateFormat('HH:mm').format(message.criadoEm),
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

  Widget _buildAttachmentPreview() {
    return Container(
      padding: EdgeInsets.all(8),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filesToSend.length,
          itemBuilder: (context, index) {
            final file = _filesToSend[index];
            return Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _filesToSend.removeAt(index);
                      });
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context, bool isDarkMode, Color primaryColor) {
    final _messageController = TextEditingController();

    return Column(
      children: [
        if (_filesToSend.isNotEmpty) _buildAttachmentPreview(),
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
                  if (_messageController.text.isNotEmpty || _filesToSend.isNotEmpty) {
                    Provider.of<ChatProvider>(context, listen: false).sendComposedMessage(
                      _messageController.text,
                      _filesToSend,
                    );
                    _messageController.clear();
                    setState(() {
                      _filesToSend.clear();
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
}
