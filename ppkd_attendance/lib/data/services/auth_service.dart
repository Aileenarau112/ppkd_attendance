import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constant.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConstant.baseUrl}/login"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",
      },

      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
    response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Login gagal");
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,

    required String email,

    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstant.baseUrl}/register"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",
      },

      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
    response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Register gagal");
    }
  }
}
