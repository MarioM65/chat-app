
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/new_group_participant.dart';
import 'package:app/models/user_model.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/models/conversation.dart'; // Import Conversation model
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  XFile? _groupImage;
  List<User> _selectedUsers = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _groupImage = pickedFile;
      });
    }
  }

  Future<void> _selectParticipants() async {
    final List<User>? result = await Navigator.of(context).pushNamed('/select_users');
    if (result != null) {
      setState(() {
        _selectedUsers = result;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira o nome do grupo')),
      );
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione pelo menos um membro para o grupo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.user!.id;

      List<NewGroupParticipant> participants = _selectedUsers.map((user) {
        // The creator of the group is the current user, others are members
        return NewGroupParticipant(
          userId: user.id,
          role: user.id == currentUserId ? 'CRIADOR' : 'MEMBRO',
        );
      }).toList();

      // Ensure the current user is always included as CRIADOR if not already selected
      if (!_selectedUsers.any((user) => user.id == currentUserId)) {
        participants.insert(0, NewGroupParticipant(userId: currentUserId, role: 'CRIADOR'));
      }

      final response = await apiService.createConversation(
        tipoConversa: 'grupo',
        nomeConversa: _groupNameController.text,
        participantes: participants,
        fotoConversaFile: _groupImage,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grupo criado com sucesso!')),
      );
      Navigator.of(context).pop(Conversation.fromJson(response['data'])); // Pass the new conversation back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Novo Grupo'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _groupImage != null
                          ? (kIsWeb
                              ? NetworkImage(_groupImage!.path)
                              : FileImage(File(_groupImage!.path)) as ImageProvider)
                          : null,
                      child: _groupImage == null
                          ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Grupo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text('Adicionar Participantes'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _selectParticipants,
                  ),
                  ..._selectedUsers.map((user) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.fotoPerfil != null
                              ? NetworkImage(user.fotoPerfil!)
                              : null,
                          child: user.fotoPerfil == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user.nomeUsuario),
                        subtitle: Text(user.email),
                        // Potentially add a dropdown for roles if needed in creation, but for now, creator is admin, others member.
                      )),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: Text('Criar Grupo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
