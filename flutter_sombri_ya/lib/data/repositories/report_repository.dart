import 'dart:io';
import 'package:http/http.dart' as http;

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
}
