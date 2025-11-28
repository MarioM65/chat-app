
import 'package:app/models/user_model.dart';
import 'package:app/models/message.dart'; // Import the Message model

class Conversation {
  final int idConversa; // Changed from 'id' to 'idConversa'
  final List<User> participantes;
  final String tipoConversa;
  final String? nomeConversa;
  final String? fotoConversa;
  final String displayName;
  final String? displayImage;
  final Message? lastMessage; // New field for the last message
  final int unreadCount; // New field for unread messages count

  Conversation({
    required this.idConversa, // Changed from 'id' to 'idConversa'
    required this.tipoConversa,
    this.nomeConversa,
    this.fotoConversa,
    required this.participantes,
    required this.displayName,
    this.displayImage,
    this.lastMessage, // Initialize lastMessage
    this.unreadCount = 0, // Initialize unreadCount with a default
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
      lastMessage: json['last_message'] != null ? Message.fromJson(json['last_message']) : null,
      unreadCount: json['unread_count'] ?? 0,
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
      lastMessage: null, // Default for this factory
      unreadCount: 0,    // Default for this factory
    );
  }
}
