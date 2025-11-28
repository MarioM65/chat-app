
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/conversation.dart';
import 'package:app/models/user_model.dart';
import 'package:app/models/participante_conversa_model.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/models/new_group_participant.dart'; // For adding new members
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class EditGroupScreen extends StatefulWidget {
  final Conversation conversation;

  EditGroupScreen({required this.conversation});

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late TextEditingController _groupNameController;
  XFile? _newGroupImage;
  late List<ParticipanteConversa> _currentParticipants;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.conversation.nomeConversa);
    _currentParticipants = List.from(widget.conversation.participantes);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newGroupImage = pickedFile;
      });
    }
  }

  Future<void> _addMembers() async {
    final List<User>? newlySelectedUsers = await Navigator.of(context).pushNamed(
      '/select_users',
      arguments: _currentParticipants.map((p) => p.usuario).toList(), // Pass existing members to exclude
    ) as List<User>?;

    if (newlySelectedUsers != null && newlySelectedUsers.isNotEmpty) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      for (var user in newlySelectedUsers) {
        if (!_currentParticipants.any((p) => p.usuario.id == user.id)) {
          try {
            await apiService.addMemberToConversation(
              conversationId: widget.conversation.idConversa,
              userId: user.id,
              role: 'MEMBRO', // Default role for new members
            );
            setState(() {
              _currentParticipants.add(ParticipanteConversa(usuario: user, papel: 'MEMBRO'));
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao adicionar ${user.nomeUsuario}: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.user!.id;

      // Update group name and image
      if (_groupNameController.text != widget.conversation.nomeConversa || _newGroupImage != null) {
        // Await the response to get the updated conversation details from the API
        final response = await apiService.updateConversation(
          widget.conversation.idConversa,
          nomeConversa: _groupNameController.text,
          fotoConversaFile: _newGroupImage,
        );
        // Assuming the API returns the updated conversation object
        final updatedConversation = Conversation.fromJson(response['data']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo atualizado com sucesso!')),
        );
        Navigator.of(context).pop(updatedConversation); // Return the updated conversation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhuma alteração para salvar.')),
        );
        Navigator.of(context).pop(); // Go back without changes
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar grupo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false); // Moved here for use in PopupMenuButton

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Grupo'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
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
                      backgroundImage: _newGroupImage != null
                          ? (kIsWeb
                              ? NetworkImage(_newGroupImage!.path)
                              : FileImage(File(_newGroupImage!.path)) as ImageProvider)
                          : (widget.conversation.fotoConversa != null
                              ? NetworkImage(widget.conversation.fotoConversa!)
                              : null),
                      child: _newGroupImage == null && widget.conversation.fotoConversa == null
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
                  Text('Membros do Grupo', style: Theme.of(context).textTheme.headlineSmall),
                  ..._currentParticipants.map((participant) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: participant.usuario.fotoPerfil != null
                            ? NetworkImage(participant.usuario.fotoPerfil!)
                            : null,
                        child: participant.usuario.fotoPerfil == null
                            ? Icon(Icons.person)
                            : null,
                      ),
                      title: Text(participant.usuario.nomeUsuario),
                      subtitle: Text(participant.papel ?? 'Função Desconhecida'), // Safely handle nullable papel
                      trailing: PopupMenuButton<String>(
                        onSelected: (String result) async {
                          if (result == 'remove') {
                            try {
                              await apiService.removeMemberFromConversation(
                                conversationId: widget.conversation.idConversa,
                                userId: participant.usuario.id,
                              );
                              setState(() {
                                _currentParticipants.removeWhere((p) => p.usuario.id == participant.usuario.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Membro removido com sucesso!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao remover membro: $e')),
                              );
                            }
                          } else {
                            // Change role
                            try {
                              await apiService.updateMemberRoleInConversation(
                                conversationId: widget.conversation.idConversa,
                                userId: participant.usuario.id,
                                role: result,
                              );
                              setState(() {
                                final index = _currentParticipants.indexWhere((p) => p.usuario.id == participant.usuario.id);
                                if (index != -1) {
                                  _currentParticipants[index] = ParticipanteConversa(usuario: participant.usuario, papel: result);
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Papel atualizado com sucesso!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao atualizar papel: $e')),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'ADMIN',
                            child: Text('Tornar Admin'),
                          ),
                          PopupMenuItem<String>(
                            value: 'MEMBRO',
                            child: Text('Tornar Membro'),
                          ),
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: Text('Remover'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Adicionar Membros'),
                    onTap: _addMembers,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    child: Text('Salvar Alterações'),
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
