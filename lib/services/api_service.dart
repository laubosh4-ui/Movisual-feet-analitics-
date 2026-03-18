import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config.dart';

class ApiService {
  static final _uuid = Uuid();

  static Future<void> pushDetectionEvent({
    required String eventType,
    required int currentCount,
    required double confidence,
    String gender = 'unknown',
    String ageGroup = 'unknown',
  }) async {
    await http.post(
      Uri.parse('${Config.dashboardUrl}/api/entities/DetectionEvent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Config.apiKey}',
      },
      body: jsonEncode({
        'location_id': Config.locationId,
        'location_name': Config.locationName,
        'event_type': eventType,
        'person_track_id': _uuid.v4(),
        'timestamp': DateTime.now().toIso8601String(),
        'current_count': currentCount,
        'confidence': confidence,
        'gender': gender,
        'age_group': ageGroup,
      }),
    );
  }

  static Future<void> pushDwellRecord({
    required String trackId,
    required DateTime enteredAt,
    required DateTime exitedAt,
  }) async {
    final dwellSeconds = exitedAt.difference(enteredAt).inSeconds;

    await http.post(
      Uri.parse('${Config.dashboardUrl}/api/entities/DwellRecord'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Config.apiKey}',
      },
      body: jsonEncode({
        'location_id': Config.locationId,
        'location_name': Config.locationName,
        'person_track_id': trackId,
        'entered_at': enteredAt.toIso8601String(),
        'exited_at': exitedAt.toIso8601String(),
        'dwell_seconds': dwellSeconds,
        'date_label': enteredAt.toIso8601String().substring(0, 10),
        'hour_label': enteredAt.hour,
      }),
    );
  }
}
