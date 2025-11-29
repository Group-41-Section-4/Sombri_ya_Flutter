import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../services/offline_report_queue.dart';
import '../models/rental_format_model.dart';
import '../models/pending_report_model.dart';

class ReportRepository {
  final String baseUrl;
  final http.Client _client;
  final OfflineReportQueue _offlineQueue;

  ReportRepository({
    required this.baseUrl,
    http.Client? client,
    OfflineReportQueue? offlineQueue,
  })  : _client = client ?? http.Client(),
        _offlineQueue = offlineQueue ?? OfflineReportQueue();

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

  Future<void> sendOrQueueReport({
    required String rentalId,
    required int rating,
    String? description,
    File? imageFile,
    required bool isOnline,
  }) async {


    if (isOnline) {
      try {
        await sendReport(
          rentalId: rentalId,
          rating: rating,
          description: description,
          imageFile: imageFile,
        );

        return;
      } catch (e) {

      }
    } else {

    }

    final pending = PendingReport(
      rentalId: rentalId,
      rating: rating,
      description: description,
      imageBase64: imageFile?.path,
      createdAt: DateTime.now(),
    );


    await _offlineQueue.add(pending);
  }

  Future<void> syncOfflineReports() async {
    final pendingList = await _offlineQueue.getAll();

    if (pendingList.isEmpty) return;

    final stillPending = <PendingReport>[];

    for (final pending in pendingList) {
      File? imageFile;
      if (pending.imageBase64 != null && pending.imageBase64!.isNotEmpty) {
        imageFile = File(pending.imageBase64!);
        if (!imageFile.existsSync()) {
          imageFile = null;
        }
      }

      try {
        await sendReport(
          rentalId: pending.rentalId,
          rating: pending.rating,
          description: pending.description,
          imageFile: imageFile,
        );

      } catch (e) {

        stillPending.add(pending);
      }
    }

    if (stillPending.isEmpty) {

      await _offlineQueue.clear();
    } else {
      await _offlineQueue.replaceAll(stillPending);
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

    final formats = data
        .map((e) => RentalFormat.fromJson(e as Map<String, dynamic>))
        .toList();


    return formats;
  }
}
