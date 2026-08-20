import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_notification.dart';

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super(_seed);

  static final _seed = [
    AppNotification(
      id: 'n1',
      title: 'Janji Temu Berhasil Dibuat',
      body: 'Anda akan mendapatkan Booking ID & QR CODE untuk dipakai saat '
          'Check in. Silahkan Lihat Riwayat Janji Temu untuk detail lebih '
          'lanjut.',
      date: DateTime(2025, 2, 13),
    ),
    AppNotification(
      id: 'n2',
      title: 'Janji Temu Berhasil Dibuat',
      body: 'Anda akan mendapatkan Booking ID & QR CODE untuk dipakai saat '
          'Check in. Silahkan Lihat Riwayat Janji Temu untuk detail lebih '
          'lanjut.',
      date: DateTime(2025, 2, 12),
    ),
    AppNotification(
      id: 'n3',
      title: 'Janji Temu Berhasil Dibuat',
      body: 'Anda akan mendapatkan Booking ID & QR CODE untuk dipakai saat '
          'Check in. Silahkan Lihat Riwayat Janji Temu untuk detail lebih '
          'lanjut.',
      date: DateTime(2025, 2, 10),
    ),
  ];

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
      (ref) => NotificationsController(),
    );

/// How many notifications are still unread — drives the bell badge on home.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
