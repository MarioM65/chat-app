import 'dart:convert';

class User {
  final int id;
  final String nomeUsuario;
  final String email;
  final String? fotoPerfil;
  final String? telefone;
  final String status;

  User({
    required this.id,
    required this.nomeUsuario,
    required this.email,
    this.fotoPerfil,
    this.telefone,
    this.status = 'Offline',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nomeUsuario: map['nome_usuario'],
      email: map['email'],
      fotoPerfil: map['foto_perfil'],
      telefone: map['telefone'],
      status: map['status'] ?? 'Offline',
    );
  }

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_usuario': nomeUsuario,
      'email': email,
      'foto_perfil': fotoPerfil,
      'telefone': telefone,
      'status': status,
    };
  }

  String toJson() => json.encode(toMap());
}
