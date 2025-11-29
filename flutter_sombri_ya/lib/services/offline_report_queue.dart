import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/pending_report_model.dart';

class OfflineReportQueue {
  static const _key = 'pending_reports';

  Future<List<PendingReport>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => PendingReport.fromJson(e)).toList();
  }

  Future<void> add(PendingReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(report.toJson());
    await prefs.setStringList(_key, list);
  }

  Future<void> replaceAll(List<PendingReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final list = reports.map((e) => e.toJson()).toList();
    await prefs.setStringList(_key, list);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
