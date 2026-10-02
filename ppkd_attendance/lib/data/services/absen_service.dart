import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constant.dart';
import '../local/local_storage.dart';

class AbsenService {
  // ============================
  // ABSEN MASUK
  // ============================

  Future<Map<String, dynamic>> checkIn({
    required double latitude,

    required double longitude,

    required String address,
  }) async {
    final token = await LocalStorage.getToken();

    final response = await http.post(
      Uri.parse("${ApiConstant.baseUrl}/absen/check-in"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",

        "Authorization": "Bearer $token",
      },

      body: jsonEncode({
        "check_in_lat": latitude.toString(),

        "check_in_lng": longitude.toString(),

        "check_in_address": address,

        "status": "masuk",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Gagal absen masuk");
    }
  }

  // ============================
  // ABSEN IZIN
  // ============================

  Future<Map<String, dynamic>> izin({
    required double latitude,

    required double longitude,

    required String alasan,
  }) async {
    final token = await LocalStorage.getToken();

    final response = await http.post(
      Uri.parse("${ApiConstant.baseUrl}/absen/check-in"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",

        "Authorization": "Bearer $token",
      },

      body: jsonEncode({
        "check_in_lat": latitude.toString(),

        "check_in_lng": longitude.toString(),

        "check_in_address": "Lokasi pengguna",

        "status": "izin",

        "alasan_izin": alasan,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Gagal mengajukan izin");
    }
  }

  // ============================
  // ABSEN PULANG
  // ============================

  Future<Map<String, dynamic>> checkOut({
    required double latitude,

    required double longitude,

    required String address,
  }) async {
    final token = await LocalStorage.getToken();

    final response = await http.post(
      Uri.parse("${ApiConstant.baseUrl}/absen/check-out"),

      headers: {
        "Accept": "application/json",

        "Content-Type": "application/json",

        "Authorization": "Bearer $token",
      },

      body: jsonEncode({
        "check_out_lat": latitude.toString(),

        "check_out_lng": longitude.toString(),

        "check_out_location": "$latitude,$longitude",

        "check_out_address": address,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Gagal absen pulang");
    }
  }
}
