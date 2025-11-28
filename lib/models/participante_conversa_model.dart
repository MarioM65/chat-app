
import 'package:app/models/user_model.dart';

class ParticipanteConversa {
  final User usuario;
  final String? papel; // Make papel nullable

  ParticipanteConversa({
    required this.usuario,
    this.papel, // Make papel optional in constructor
  });

  factory ParticipanteConversa.fromJson(Map<String, dynamic> json) {
    return ParticipanteConversa(
      usuario: User.fromMap(json['usuario']),
      papel: json['papel'] ?? 'MEMBRO', // Provide a default if papel is null
    );
  }
}
