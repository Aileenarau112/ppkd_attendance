import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constant.dart';
import '../local/local_storage.dart';

class HistoryService {
  // ============================
  // GET HISTORY ABSEN
  // ============================

  Future<List<dynamic>> getHistory({
    required String start,
    required String end,
  }) async {
    final token = await LocalStorage.getToken();

    final response = await http.get(
      Uri.parse("${ApiConstant.baseUrl}/absen/history?start=$start&end=$end"),

      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil history");
    }
  }

  // ============================
  // DELETE ABSEN
  // ============================

  Future<Map<String, dynamic>> deleteAbsen({required int id}) async {
    final token = await LocalStorage.getToken();

    final response = await http.delete(
      Uri.parse("${ApiConstant.baseUrl}/delete-absen?id=$id"),

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
