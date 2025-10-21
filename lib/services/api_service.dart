import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String baseUrl;
  ApiService({this.baseUrl = 'http://10.0.2.2:3000'}); // emulador Android: 10.0.2.2, iOS/desktop: localhost

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'Content-Type': 'application/json'};
    final idToken = await user.getIdToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'};
  }

  Future<String> getSaludo() async {
    final res = await http.get(Uri.parse('$baseUrl/api/saludo'));
    if (res.statusCode == 200) return jsonDecode(res.body)['mensaje'] ?? '';
    throw Exception('Error ${res.statusCode}');
  }

  Future<List<dynamic>> getCategories() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/categories'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Error ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/categories'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Error ${res.statusCode}');
  }

  Future<List<dynamic>> getCredentials(String categoryId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/categories/$categoryId/credentials'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Error ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createCredential(String categoryId, String username, String password) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/categories/$categoryId/credentials'),
      headers: headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Error ${res.statusCode}');
  }
}