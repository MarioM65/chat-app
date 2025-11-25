import 'dart:io' show File; // Only import File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  XFile? _profileImage; // Changed from File? to XFile?
  bool _isLoading = false;
  final String _baseUrl = dotenv.env['BASE_URL']!; // Define _baseUrl here

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.nomeUsuario);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.telefone);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile; // Store XFile directly
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      if (_passwordController.text.isNotEmpty &&
          _passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.user!;

        final response = await apiService.updateUser(
          nomeUsuario: _nameController.text,
          email: _emailController.text,
          telefone: _phoneController.text,
          senha: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          fotoPerfilFile: _profileImage, // Pass XFile directly
        );

        // Check for success field in API response
        if (response['success'] == true) {
          final updatedUser = User.fromMap(response['data']);
          authService.updateUser(updatedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop();
        } else {
          // If 'success' is false, it's an API-level error
          String errorMessage = response['message'] ?? 'Failed to update profile. Unknown API error.';
          print('API Error updating profile: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        // Catch network or parsing errors
        print('Network/Parsing Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Text('Editar Perfil', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? (kIsWeb ? NetworkImage(_profileImage!.path) : FileImage(File(_profileImage!.path)))
                            : (Provider.of<AuthService>(context).user?.fotoPerfil != null
                                ? Image.network(
                                    '$_baseUrl/${Provider.of<AuthService>(context).user!.fotoPerfil!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, size: 50, color: Colors.grey),
                                  ).image
                                : null) as ImageProvider?,
                        child: _profileImage == null && Provider.of<AuthService>(context).user?.fotoPerfil == null
                            ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nome'),
                      validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Telefone'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Nova Senha (deixe em branco para não alterar)'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Confirmar Nova Senha'),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Salvar Alterações'),
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
            ),
    );
  }
}