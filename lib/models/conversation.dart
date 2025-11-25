
import 'package:app/models/user_model.dart';

class Conversation {
  final int idConversa; // Changed from 'id' to 'idConversa'
  final List<User> participantes;
  final String tipoConversa;
  final String? nomeConversa;
  final String? fotoConversa;
  final String displayName;
  final String? displayImage;

  Conversation({
    required this.idConversa, // Changed from 'id' to 'idConversa'
    required this.tipoConversa,
    this.nomeConversa,
    this.fotoConversa,
    required this.participantes,
    required this.displayName,
    this.displayImage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      idConversa: json['id_conversa'], // Mapped to id_conversa
      tipoConversa: json['tipo_conversa'],
      nomeConversa: json['nome_conversa'],
      fotoConversa: json['foto_conversa'], // Mapped to foto_conversa
      participantes: (json['participante_conversa'] as List?) // Changed to participante_conversa
              ?.map((participant) => User.fromMap(participant['usuario']))
              .toList() ??
          [],
      displayName: json['display_name'] ?? json['nome_conversa'],
      displayImage: json['display_image'],
    );
  }

  factory Conversation.fromParticipantJson(Map<String, dynamic> json) {
    final conversationJson = json['conversa'];
    return Conversation(
      idConversa: conversationJson['id_conversa'],
      tipoConversa: conversationJson['tipo_conversa'],
      nomeConversa: conversationJson['nome_conversa'],
      fotoConversa: conversationJson['foto_conversa'], // Mapped to foto_conversa
      participantes: [User.fromMap(json['usuario'])], // This factory is specifically for participant data
      displayName: json['display_name'],
      displayImage: json['display_image'],
    );
  }
}
