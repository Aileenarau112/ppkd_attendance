import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constant.dart';
import '../local/local_storage.dart';

class ProfileService {
  // ==========================
  // GET PROFILE
  // ==========================

  Future<Map<String, dynamic>> getProfile() async {
    final token = await LocalStorage.getToken();

    final response = await http.get(
      Uri.parse("${ApiConstant.baseUrl}/profile"),

      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? {};
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil profile");
    }
  }

  // ==========================
  // UPDATE PROFILE
  // ==========================

  Future<Map<String, dynamic>> updateProfile({
    required String name,

    required String email,
  }) async {
    final token = await LocalStorage.getToken();

    final response = await http.put(
      Uri.parse("${ApiConstant.baseUrl}/profile"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",

        "Authorization": "Bearer $token",
      },

      body: jsonEncode({"name": name, "email": email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      String errorMsg = data["message"] ?? "Gagal update profile";
      if (data["errors"] != null && data["errors"] is Map) {
        final errMap = data["errors"] as Map;
        final list = <String>[];
        errMap.forEach((_, val) {
          if (val is List) {
            list.addAll(val.map((e) => e.toString()));
          } else {
            list.add(val.toString());
          }
        });
        if (list.isNotEmpty) {
          errorMsg = list.join(", ");
        }
      }
      throw Exception(errorMsg);
    }
  }
}
