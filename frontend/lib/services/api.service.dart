import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl {
    if (Platform.isAndroid) {
       // If using 'adb reverse tcp:3000 tcp:3000', use localhost/127.0.0.1
       // If standard emulator without reverse, 10.0.2.2 is needed.
       // We can try to prefer localhost if we assume adb reverse is active.
       return "http://127.0.0.1:3000/api";
    }
    return "http://localhost:3000/api";
  }

  static Future<Map<String, dynamic>?> syncUserWithBackend(String firebaseToken) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      print("🔌 Syncing with Backend: $url");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Backend Sync Success: ${response.body}");
        final jsonResponse = json.decode(response.body);
        return jsonResponse['data'];
      } else {
        print("❌ Backend Sync Failed (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Connection Error: $e");
      return null;
    }
  }

  static Future<http.Response> scanPlant(
      String imagePath,
      String firebaseToken, {
      required double latitude,
      required double longitude,
      String? district,
      String? state,
      String? country,
  }) async {
    final uri = Uri.parse("$baseUrl/discover/scan");
    final request = http.MultipartRequest("POST", uri);

    request.headers['Authorization'] = 'Bearer $firebaseToken';

    final mimeType = imagePath.toLowerCase().endsWith(".png")
        ? MediaType("image", "png")
        : MediaType("image", "jpeg");

    request.files.add(
      await http.MultipartFile.fromPath(
        "photo",
        imagePath,
        contentType: mimeType,
      ),
    );

    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (district != null) request.fields['district'] = district;
    if (state != null) request.fields['state'] = state;
    if (country != null) request.fields['country'] = country;

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    return await http.Response.fromStream(streamedResponse);
  }
  static Future<List<dynamic>> getUserDiscoveries(String firebaseToken) async {
    try {
      final url = Uri.parse('$baseUrl/discover/my-discoveries');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['data'] ?? [];
      } else {
        print("❌ Fetch Discoveries Failed (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print("⚠️ Connection Error: $e");
      return [];
    }
  }
}