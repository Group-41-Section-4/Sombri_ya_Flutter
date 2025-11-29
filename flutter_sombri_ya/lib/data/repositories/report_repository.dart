import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/rental_format_model.dart';

class ReportRepository {
  final String baseUrl;
  final http.Client _client;

  ReportRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<void> sendReport({
    required String rentalId,
    required int rating,
    String? description,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/rental-format');

    final request = http.MultipartRequest('POST', uri)
      ..fields['rentalId'] = rentalId
      ..fields['someInt'] = rating.toString();

    if (description != null && description.trim().isNotEmpty) {
      request.fields['description'] = description.trim();
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error enviando reporte: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<RentalFormat>> getFormatsByRentalId(String rentalId) async {
    final uri = Uri.parse('$baseUrl/rental-format/rental/$rentalId');

    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error obteniendo formatos de renta: '
            '${response.statusCode} - ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((e) => RentalFormat.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
