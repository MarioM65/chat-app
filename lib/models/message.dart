
import 'package:app/models/user_model.dart';
import 'package:app/models/attachment.dart';

class Message {
  final int id;
  final String conteudo;
  final String tipo;
  final User? remetente; // Make remetente nullable
  final int idConversa;
  final DateTime? criadoEm; // Make criadoEm nullable
  final List<Attachment> anexos;
  final bool? isReadByAnyOtherParticipant;

  Message({
    required this.id,
    required this.conteudo,
    required this.tipo,
    this.remetente, // Make remetente optional in constructor
    required this.idConversa,
    this.criadoEm, // Make criadoEm optional in constructor
    required this.anexos,
    this.isReadByAnyOtherParticipant,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conteudo: json['conteudo'] ?? '',
      tipo: json['tipo'],
      remetente: json['remetente'] is Map<String, dynamic> ? User.fromMap(json['remetente']) : null, // Safely parse remetente
      idConversa: json['id_conversa'],
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null, // Safely parse criado_em
      anexos: (json['anexos'] as List? ?? []) // Handle null anexos list
          .map((anexo) => Attachment.fromJson(anexo))
          .toList(),
      isReadByAnyOtherParticipant: json['isReadByAnyOtherParticipant'],
    );
  }
}
