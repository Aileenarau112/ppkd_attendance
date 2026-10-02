import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constant.dart';
import '../local/local_storage.dart';

class DeleteAbsenService {
  Future<Map<String, dynamic>> deleteAbsen({required int id}) async {
    final token = await LocalStorage.getToken();

    final response = await http.delete(
      Uri.parse("${ApiConstant.baseUrl}/absen/$id"),

      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Gagal menghapus absen");
    }
  }
}
