
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF101922) : Color(0xFFF6F7F8);
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    final secondaryTextColor = isDarkMode ? Color(0xFF9dabb9) : Color(0xFF617589);
    final primaryColor = Color(0xFF137fec);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 48),
                Icon(
                  Icons.forum,
                  size: 48,
                  color: primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  'InternConnect',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 48),
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBJu1gbxaK_QONDcmDhj4p3H9RTFnH2x03ej83oo4H8kgjO1jmsn6eJHAZJm1clb4jER78Z4fztzB6dnxLxGsN_hs8ANpOElJMOXtxaFQ3br-ilTJPkwbNQCEbf1dCx-rE5wVRhPuTYTnV-O8BTJMsFp2kJ2ixLLfoawL3kUaCS8gjb_0OPDpy_jsYl18jg5_3IovzxIIXKHssqrn9kGqjgVtyJduklSv4p5JSE9h2Ng8illWrmK6AVOlQBGJUEXUut34Ao4S-WjZNr',
                  height: 250,
                ),
                SizedBox(height: 48),
                Text(
                  'Conecte-se e Colabore com Outros Estagiários',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'O espaço definitivo para suas conversas, projetos e networking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/register');
                  },
                  child: Text('Vamos Começar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text(
                    'Já tenho conta',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
