import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/models/user_model.dart';
import 'package:app/models/new_group_participant.dart'; // Import NewGroupParticipant
import 'package:app/models/conversation.dart'; // Import Conversation

class CreateConversationScreen extends StatefulWidget {
  @override
  _CreateConversationScreenState createState() => _CreateConversationScreenState();
}

class _CreateConversationScreenState extends State<CreateConversationScreen> {
  bool _isGroupChat = false;
  final _groupNameController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final usersData = await apiService.getUsers();
      setState(() {
        _allUsers = usersData.map((json) => User.fromMap(json)).toList();
      });
    } catch (e) {
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createConversation() async {
    if (!_isGroupChat && _selectedUsers.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select exactly one participant for a one-on-one chat.')),
      );
      return;
    }

    if (_isGroupChat && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one participant for the group chat.')),
      );
      return;
    }

    if (_isGroupChat && _groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }
      
      List<NewGroupParticipant> participants = _selectedUsers.map((user) {
        return NewGroupParticipant(userId: user.id, role: 'MEMBRO');
      }).toList();

      // For individual chats, ensure the current user is added as a participant
      if (!_isGroupChat && !participants.any((p) => p.userId == currentUser.id)) {
        participants.insert(0, NewGroupParticipant(userId: currentUser.id, role: 'MEMBRO'));
      }
      // For group chats, the backend automatically adds the creator with 'CRIADOR' role
      // so we only need to pass the selected members with 'MEMBRO' role.

      String? conversationName;
      if (_isGroupChat) {
        conversationName = _groupNameController.text.trim();
      } else {
        final selectedUser = _selectedUsers.first;
        conversationName = 'Conversa entre ${currentUser.nomeUsuario} e ${selectedUser.nomeUsuario}'; // This name might not be used by backend for individual
      }

      final conversationResponse = await apiService.createConversation(
        tipoConversa: _isGroupChat ? 'grupo' : 'individual',
        nomeConversa: conversationName,
        participantes: participants, // Now passing NewGroupParticipant list
        // fotoConversaPath: _conversationImage?.path, // Placeholder for photo upload
      );

      // The backend returns the full conversation object now, including existing one for individual chats
      final newConversation = Conversation.fromJson(conversationResponse);
      Navigator.of(context).pop(newConversation); // Return the new or existing conversation

    } catch (e) {
      print('Error creating conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create conversation.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF101922) : Color(0xFFF6F7F8);
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    final inputBackgroundColor = isDarkMode ? Color(0xFF1A1A2E) : Colors.white;
    final primaryColor = Color(0xFF137fec);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Nova Conversa', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Conversa em Grupo', style: TextStyle(color: textColor, fontSize: 16)),
                      Switch(
                        value: _isGroupChat,
                        onChanged: (value) {
                          setState(() {
                            _isGroupChat = value;
                            if (!value) {
                              _selectedUsers.clear(); // Clear selection for 1:1 chat
                            }
                          });
                        },
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                  if (_isGroupChat)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: TextField(
                        controller: _groupNameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Grupo',
                          filled: true,
                          fillColor: inputBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    'Selecionar Participantes',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final isSelected = _selectedUsers.contains(user);
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final currentUserId = authService.user?.id;

                        if (user.id == currentUserId) {
                          return SizedBox.shrink(); // Don't show current user in selection
                        }

                        return CheckboxListTile(
                          title: Text(user.nomeUsuario, style: TextStyle(color: textColor)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!_isGroupChat && _selectedUsers.isNotEmpty) {
                                  // For 1:1 chat, only one user can be selected
                                  _selectedUsers.clear();
                                }
                                _selectedUsers.add(user);
                              } else {
                                _selectedUsers.remove(user);
                              }
                            });
                          },
                          activeColor: primaryColor,
                          checkColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createConversation,
                    child: Text('Criar Conversa'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
