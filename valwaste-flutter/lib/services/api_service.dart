import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/waste_collection.dart';
import '../models/recycling_guide.dart';

class ApiService {
  static const String baseUrl =
      'http://your-php-backend.com/api'; // Replace with your PHP backend URL

  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // Authentication
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // User Profile
  static Future<UserModel> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body)['user']);
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<UserModel> updateUserProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: _authHeaders(token),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body)['user']);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Waste Collection
  static Future<List<WasteCollection>> getWasteCollections(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/waste-collections'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['collections'];
        return data.map((json) => WasteCollection.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get waste collections: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<WasteCollection> createWasteCollection(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/waste-collections'),
        headers: _authHeaders(token),
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return WasteCollection.fromJson(
          json.decode(response.body)['collection'],
        );
      } else {
        throw Exception('Failed to create waste collection: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<WasteCollection> updateWasteCollection(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/waste-collections/$id'),
        headers: _authHeaders(token),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return WasteCollection.fromJson(
          json.decode(response.body)['collection'],
        );
      } else {
        throw Exception('Failed to update waste collection: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> cancelWasteCollection(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/waste-collections/$id'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel waste collection: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Recycling Guide
  static Future<List<RecyclingGuide>> getRecyclingGuides() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recycling-guides'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['guides'];
        return data.map((json) => RecyclingGuide.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get recycling guides: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<RecyclingGuide>> searchRecyclingGuides(
    String query,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recycling-guides/search?q=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['guides'];
        return data.map((json) => RecyclingGuide.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search recycling guides: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
