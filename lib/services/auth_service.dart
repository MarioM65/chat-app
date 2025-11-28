import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/models/user_model.dart';
import 'package:app/services/socket_service.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile

enum AuthStatus { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthService with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;

  AuthStatus _status = AuthStatus.Uninitialized;
  String? _token;
  User? _user;

  AuthStatus get status => _status;
  String? get token => _token;
  User? get user => _user;

  AuthService(this._apiService, this._socketService);

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userData = prefs.getString('user');

    if (_token != null && userData != null) {
      _user = User.fromJson(userData);
      // You might want to add a token validation call to your API here
      _socketService.connect(_token!);
      _status = AuthStatus.Authenticated;
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.Authenticating;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _token = response['data']['access_token'];
      _user = User.fromMap(response['data']['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', _user!.toJson());

      _socketService.connect(_token!);
      await _apiService.updateUserStatus(_user!.id, 'Online');
      _status = AuthStatus.Authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nomeUsuario,
    required String email,
    required String senha,
    XFile? fotoPerfilFile, // Changed from String? fotoPerfil
    String? telefone,
  }) async {
    _status = AuthStatus.Authenticating;
    notifyListeners();

    try {
      final response = await _apiService.register(
        nomeUsuario: nomeUsuario,
        email: email,
        senha: senha,
        fotoPerfilFile: fotoPerfilFile, // Pass fotoPerfilFile
        telefone: telefone,
      );
      _token = response['data']['access_token'];
      _user = User.fromMap(response['data']['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', _user!.toJson());
      
      _socketService.connect(_token!);
      await _apiService.updateUserStatus(_user!.id, 'Online');
      _status = AuthStatus.Authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _user = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', _user!.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    if (_user != null) {
      await _apiService.updateUserStatus(_user!.id, 'Offline');
    }
    _status = AuthStatus.Unauthenticated;
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _socketService.disconnect();
    notifyListeners();
  }
}