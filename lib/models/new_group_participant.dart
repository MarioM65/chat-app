
class NewGroupParticipant {
  final int userId;
  final String role; // e.g., 'CRIADOR', 'ADMIN', 'MEMBRO'

  NewGroupParticipant({
    required this.userId,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': userId,
      'papel': role, // Matches the backend's 'papel' field
    };
  }
}
