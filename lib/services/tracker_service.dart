import 'package:uuid/uuid.dart';
import 'api_service.dart';

class TrackedPerson {
  final String id;
  final DateTime enteredAt;

  TrackedPerson({required this.id, required this.enteredAt});
}

class TrackerService {
  final _uuid = Uuid();
  final Map<String, TrackedPerson> _active = {};
  int _currentCount = 0;

  Future<void> update(
    int detectedCount,
    double avgConfidence,
    String gender,
    String age,
  ) async {
    final previousCount = _currentCount;

    if (detectedCount > previousCount) {
      for (int i = 0; i < detectedCount - previousCount; i++) {
        final id = _uuid.v4();
        _active[id] = TrackedPerson(id: id, enteredAt: DateTime.now());
        _currentCount++;

        await ApiService.pushDetectionEvent(
          eventType: 'enter',
          currentCount: _currentCount,
          confidence: avgConfidence,
          gender: gender,
          ageGroup: age,
        );
      }
    } else if (detectedCount < previousCount) {
      final toRemove =
          _active.entries.take(previousCount - detectedCount).toList();

      for (final entry in toRemove) {
        _active.remove(entry.key);
        _currentCount--;

        await ApiService.pushDetectionEvent(
          eventType: 'exit',
          currentCount: _currentCount,
          confidence: avgConfidence,
          gender: gender,
          ageGroup: age,
        );

        await ApiService.pushDwellRecord(
          trackId: entry.value.id,
          enteredAt: entry.value.enteredAt,
          exitedAt: DateTime.now(),
        );
      }
    }
  }

  int get currentCount => _currentCount;
}
