
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart'; // Add this import

class ApiService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'senha': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return data;
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<Map<String, dynamic>> register({
    required String nomeUsuario,
    required String email,
    required String senha,
    XFile? fotoPerfilFile, // Changed to XFile?
    String? telefone,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    if (fotoPerfilFile != null) {
      var request = http.MultipartRequest('POST', uri);
      // No auth token for register, as user is not yet authenticated
      // request.headers['Authorization'] = 'Bearer $token'; // Not needed for register

      request.fields['nome_usuario'] = nomeUsuario;
      request.fields['email'] = email;
      request.fields['senha'] = senha;
      if (telefone != null) request.fields['telefone'] = telefone;
      
      final fileBytes = await fotoPerfilFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'foto_perfil',
        fileBytes,
        filename: fotoPerfilFile.name,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register with photo');
      }
    } else {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String?>{
          'nome_usuario': nomeUsuario,
          'email': email,
          'senha': senha,
          'telefone': telefone,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register');
      }
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> getConversations() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/conversas'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  Future<Map<String, dynamic>> getConversationById(int conversationId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/conversas/$conversationId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']; // The API returns the conversation object directly under 'data'
    } else {
      throw Exception('Failed to load conversation details');
    }
  }

  Future<List<dynamic>> getParticipantConversations(int userId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/participante_conversas/usuario/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load participant conversations');
    }
  }

  Future<List<dynamic>> getUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<Map<String, dynamic>> createConversation({
    required String tipoConversa,
    String? nomeConversa,
    List<int>? idUsuarios,
    XFile? fotoConversaFile, // Changed to XFile?
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$_baseUrl/conversas');

    if (fotoConversaFile != null) { // Changed condition
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['tipo_conversa'] = tipoConversa;
      if (nomeConversa != null) request.fields['nome_conversa'] = nomeConversa;
      if (idUsuarios != null) {
        request.fields['id_usuarios'] = jsonEncode(idUsuarios);
      }
      
      final fileBytes = await fotoConversaFile.readAsBytes(); // Read bytes from XFile
      request.files.add(http.MultipartFile.fromBytes( // Use fromBytes
        'foto_conversa',
        fileBytes,
        filename: fotoConversaFile.name, // Use XFile's name
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create conversation with photo');
      }
    } else {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'tipo_conversa': tipoConversa,
          'nome_conversa': nomeConversa,
          'id_usuarios': idUsuarios,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create conversation');
      }
    }
  }

  Future<Map<String, dynamic>> updateUser({
    String? nomeUsuario,
    String? email,
    String? senha,
    String? telefone,
    XFile? fotoPerfilFile, // Changed to XFile?
  }) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$_baseUrl/users'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    if (nomeUsuario != null) request.fields['nome_usuario'] = nomeUsuario;
    if (email != null) request.fields['email'] = email;
    if (senha != null) request.fields['senha'] = senha;
    if (telefone != null) request.fields['telefone'] = telefone;

    if (fotoPerfilFile != null) { // Changed condition
      final fileBytes = await fotoPerfilFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes( // Use fromBytes
        'foto_perfil',
        fileBytes,
        filename: fotoPerfilFile.name, // Use XFile's name
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/mensagens/conversa/$conversationId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // LeituraMensagem (Message Read Receipts)
  Future<Map<String, dynamic>> createLeituraMensagem({
    required int idMensagem,
    required DateTime dataHoraLeitura,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/leitura_mensagens'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'id_mensagem': idMensagem,
        'data_hora_leitura': dataHoraLeitura.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create message read receipt');
    }
  }

  Future<Map<String, dynamic>> updateLeituraMensagem(
    int idLeituraMensagem, {
    int? idMensagem,
    DateTime? dataHoraLeitura,
  }) async {
    final token = await getToken();
    final Map<String, dynamic> bodyData = {};
    if (idMensagem != null) bodyData['id_mensagem'] = idMensagem;
    if (dataHoraLeitura != null) bodyData['data_hora_leitura'] = dataHoraLeitura.toIso8601String();

    final response = await http.put(
      Uri.parse('$_baseUrl/leitura_mensagens/$idLeituraMensagem'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update message read receipt');
    }
  }

  Future<Map<String, dynamic>> deleteLeituraMensagem(int idLeituraMensagem) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/leitura_mensagens/$idLeituraMensagem'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete message read receipt');
    }
  }

  // Notificacao (Notifications)
  Future<Map<String, dynamic>> createNotificacao({
    required int idMensagem,
    required String tipoNotificacao,
    required DateTime dataHoraCriacao,
    required String status,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/notificacoes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'id_mensagem': idMensagem,
        'tipo_notificacao': tipoNotificacao,
        'data_hora_criacao': dataHoraCriacao.toIso8601String(),
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create notification');
    }
  }

  Future<Map<String, dynamic>> updateNotificacao(
    int idNotificacao, {
    int? idMensagem,
    String? tipoNotificacao,
    DateTime? dataHoraCriacao,
    String? status,
  }) async {
    final token = await getToken();
    final Map<String, dynamic> bodyData = {};
    if (idMensagem != null) bodyData['id_mensagem'] = idMensagem;
    if (tipoNotificacao != null) bodyData['tipo_notificacao'] = tipoNotificacao;
    if (dataHoraCriacao != null) bodyData['data_hora_criacao'] = dataHoraCriacao.toIso8601String();
    if (status != null) bodyData['status'] = status;

    final response = await http.put(
      Uri.parse('$_baseUrl/notificacoes/$idNotificacao'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update notification');
    }
  }

  Future<Map<String, dynamic>> deleteNotificacao(int idNotificacao) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/notificacoes/$idNotificacao'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete notification');
    }
  }
}
