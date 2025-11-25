import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/conversations_screen.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.status == AuthStatus.Authenticated) {
      return ConversationsScreen();
    } else {
      return LoginScreen();
    }
  }
}