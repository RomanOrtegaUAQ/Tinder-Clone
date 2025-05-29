import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character_model.dart';

class ApiService {
  final String _baseUrl = 'https://rickandmortyapi.com/api';

  Future<List<Character>> getCharacters({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/character?page=$page'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results
            .map((character) => Character.fromJson(character))
            .toList();
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load characters: $e');
    }
  }

  Future<Character> getCharacter(int id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/character/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Character.fromJson(data);
      } else {
        throw Exception('Failed to load character: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load character: $e');
    }
  }
}
