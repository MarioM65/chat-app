
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/user_model.dart';
import 'package:app/services/auth_service.dart'; // To exclude current user

class SelectUsersScreen extends StatefulWidget {
  @override
  _SelectUsersScreenState createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends State<SelectUsersScreen> {
  List<User> _allUsers = [];
  List<User> _selectedUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.user!.id;

      final usersData = await apiService.getUsers();
      setState(() {
        _allUsers = usersData
            .map((userJson) => User.fromMap(userJson))
            .where((user) => user.id != currentUserId) // Exclude current user
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuários: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    return _allUsers
        .where((user) =>
            user.nomeUsuario.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Usuários'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedUsers);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar usuários',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUsers.contains(user);
                      return ListTile(
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
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.blue)
                            : Icon(Icons.circle_outlined),
                        onTap: () => _toggleUserSelection(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
