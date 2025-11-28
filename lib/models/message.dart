
import 'package:app/models/user_model.dart';
import 'package:app/models/attachment.dart';

class Message {
  final int id;
  final String conteudo;
  final String tipo;
  final User remetente;
  final int idConversa;
  final DateTime criadoEm;
  final List<Attachment> anexos;
  final bool? isReadByAnyOtherParticipant;

  Message({
    required this.id,
    required this.conteudo,
    required this.tipo,
    required this.remetente,
    required this.idConversa,
    required this.criadoEm,
    required this.anexos,
    this.isReadByAnyOtherParticipant,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conteudo: json['conteudo'] ?? '',
      tipo: json['tipo'],
      remetente: User.fromMap(json['remetente']),
      idConversa: json['id_conversa'],
      criadoEm: DateTime.parse(json['criado_em']),
      anexos: (json['anexos'] as List)
          .map((anexo) => Attachment.fromJson(anexo))
          .toList(),
      isReadByAnyOtherParticipant: json['isReadByAnyOtherParticipant'],
    );
  }
}
