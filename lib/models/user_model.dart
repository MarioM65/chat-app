import 'dart:convert';

class User {
  final int id;
  final String nomeUsuario;
  final String email;
  final String? fotoPerfil;
  final String? telefone;

  User({
    required this.id,
    required this.nomeUsuario,
    required this.email,
    this.fotoPerfil,
    this.telefone,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nomeUsuario: map['nome_usuario'],
      email: map['email'],
      fotoPerfil: map['foto_perfil'],
      telefone: map['telefone'],
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
    };
  }

  String toJson() => json.encode(toMap());
}
