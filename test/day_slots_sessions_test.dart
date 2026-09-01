import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/features/doctors/domain/practice_schedule.dart';

/// The real shape of GET /api/app/slots for a doctor with a morning and an
/// evening clinic (paramedic 61, SU-014): queue numbers restart per session.
Map<String, dynamic> twoSessionPayload() => {
      'date': '2026-09-02',
      'sessions': [
        {
          'session': 2,
          'start': '16:00',
          'end': '18:00',
          'available': [
            {'no': 1},
            {'no': 2},
          ],
        },
        {
          'session': 1,
          'start': '08:00',
          'end': '10:00',
          'available': [
            {'no': 1},
            {'no': 2},
          ],
        },
      ],
    };

void main() {
  group('DaySlots.sessions', () {
    test('groups repeated queue numbers under their own session', () {
      final day = DaySlots.fromJson(twoSessionPayload());

      // Flat, the four slots look like two duplicate pairs.
      expect(day.slots.length, 4);

      final sessions = day.sessions;
      expect(sessions.length, 2);
      expect(sessions.map((s) => s.session), [1, 2]);
      expect(sessions.first.timeLabel, '08:00 - 10:00');
      expect(sessions.first.slots.map((s) => s.number), [1, 2]);
      expect(sessions.last.slots.map((s) => s.number), [1, 2]);
    });

    test('orders sessions by start time, not payload order', () {
      // The payload lists the evening session first.
      final sessions = DaySlots.fromJson(twoSessionPayload()).sessions;
      expect(sessions.first.start, '08:00');
      expect(sessions.last.start, '16:00');
    });
  });

  group('SessionSlots.hasEndedOn', () {
    final day = DateTime(2026, 9, 2);
    final morning = SessionSlots(
      session: 1,
      start: '08:00',
      end: '10:00',
      slots: const [],
    );

    test('morning session has ended by the afternoon', () {
      expect(morning.hasEndedOn(day, DateTime(2026, 9, 2, 13, 0)), isTrue);
    });

    test('morning session is still open before it ends', () {
      expect(morning.hasEndedOn(day, DateTime(2026, 9, 2, 9, 30)), isFalse);
    });

    test('a future date is never treated as passed', () {
      // Same clock time, but the booking is for a later day.
      expect(
        morning.hasEndedOn(DateTime(2026, 9, 9), DateTime(2026, 9, 2, 23, 0)),
        isFalse,
      );
    });
  });
}
