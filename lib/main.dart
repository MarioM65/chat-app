
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/api/api_service.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/wrapper.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/screens/onboarding_screen.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/register_screen.dart';
import 'package:app/screens/conversations_screen.dart';
import 'package:app/screens/chat_screen.dart';
import 'package:app/screens/edit_profile_screen.dart';
import 'package:app/screens/create_conversation_screen.dart';
import 'package:app/screens/create_group_screen.dart'; // Import new screen
import 'package:app/screens/select_users_screen.dart'; // Import new screen
import 'package:app/screens/edit_group_screen.dart'; // Import new screen
import 'package:app/models/conversation.dart'; // Import Conversation model for route arguments

import 'package:app/providers/chat_provider.dart';
import 'package:app/providers/conversation_provider.dart';
import 'package:app/services/socket_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<SocketService>(
          create: (_) => SocketService(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (context) =>
              AuthService(context.read<ApiService>(), context.read<SocketService>()),
        ),
        ChangeNotifierProvider<ConversationProvider>(
          create: (context) => ConversationProvider(
              context.read<ApiService>(), context.read<AuthService>(), context.read<SocketService>()), // Added SocketService
        ),
      ],
      child: MaterialApp(
        title: 'InternChat',
        theme: ThemeData(
          primaryColor: Color(0xFF137fec),
          scaffoldBackgroundColor: Color(0xFFF6F7F8),
          colorScheme: ColorScheme.light(
            primary: Color(0xFF137fec),
            secondary: Color(0xFF137fec),
          ),
          fontFamily: 'PlusJakartaSans',
        ),
        darkTheme: ThemeData(
          primaryColor: Color(0xFF137fec),
          scaffoldBackgroundColor: Color(0xFF101922),
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF137fec),
            secondary: Color(0xFF137fec),
            surface: Color(0xFF1A202C),
          ),
          fontFamily: 'PlusJakartaSans',
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/': (context) => Wrapper(),
          '/onboarding': (context) => OnboardingScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/conversations': (context) => ConversationsScreen(),
          '/chat': (context) => ChatScreen(),
          '/edit-profile': (context) => EditProfileScreen(),
          '/create-conversation': (context) => CreateConversationScreen(),
          '/create_group': (context) => CreateGroupScreen(),
          '/select_users': (context) => SelectUsersScreen(),
          '/edit_group': (context) => EditGroupScreen(conversation: ModalRoute.of(context)!.settings.arguments as Conversation), // New route
        },
      ),
    );
  }
}
