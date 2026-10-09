import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final selectedCountries = countries
        .where((e) => state.preferences.countryCodes.contains(e.code))
        .map((e) => e.name)
        .join(', ');
    final selectedPriorities = priorities
        .where((e) => state.preferences.priorityIds.contains(e.id))
        .map((e) => e.title)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Mascot(size: 58),
            title: const Text(
              'Гость Островка',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Тестовый вход · ${state.guestId}'),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Рекомендации',
          children: [
            if (state.preferences.skipped)
              const Text(
                'Онбординг пропущен: начинаем с универсальных вариантов.',
              )
            else ...[
              Text(selectedCountries.isEmpty
                  ? 'Страны не выбраны'
                  : 'Страны: $selectedCountries'),
              const SizedBox(height: 6),
              Text(selectedPriorities.isEmpty
                  ? 'Приоритеты не выбраны'
                  : 'Важно: $selectedPriorities'),
            ],
            const SizedBox(height: 6),
            Text(
              'Лайков: ${state.likedOffers.length} · '
              'свайпов: ${state.swipes.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Подключение',
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor),
                const SizedBox(width: 8),
                Text(
                  _statusTitle,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              ApiClient.baseUrl,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (state.apiError != null) ...[
              const SizedBox(height: 6),
              Text(
                state.apiError!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.apiStatus == ApiStatus.connecting
                  ? null
                  : state.refreshRecommendations,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить подключение'),
            ),
          ],
        ),
        if (state.likedOffers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Понравившиеся',
            children: [
              for (final offer in state.likedOffers) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.leaf,
                  ),
                  title: Text(offer.title),
                  subtitle: Text('${offer.kind.title} · ${offer.city}'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _requestStay(context, offer),
                      child: const Text('Заявка'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _requestStay(context, offer, delayed: true),
                      child: const Text('Отложить'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
        if (state.bookings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Заявки',
            children: [
              for (final booking in state.bookings.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    booking.kind == 'delayed'
                        ? Icons.schedule_rounded
                        : Icons.bookmark_added_rounded,
                    color: AppColors.leaf,
                  ),
                  title: Text(booking.offerTitle),
                  subtitle: Text(
                    '${booking.kindLabel} · ${booking.id} · ${booking.status}',
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Сбросить онбординг и свайпы'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.nope),
        ),
      ],
    );
  }

  String get _statusTitle => switch (state.apiStatus) {
        ApiStatus.local => 'Локальный каталог',
        ApiStatus.connecting => 'Подключение…',
        ApiStatus.online => 'API подключён',
        ApiStatus.offline => 'Офлайн-режим',
      };

  IconData get _statusIcon => switch (state.apiStatus) {
        ApiStatus.local => Icons.phone_android_rounded,
        ApiStatus.connecting => Icons.sync_rounded,
        ApiStatus.online => Icons.check_circle_rounded,
        ApiStatus.offline => Icons.wifi_off_rounded,
      };

  Color get _statusColor => switch (state.apiStatus) {
        ApiStatus.online => AppColors.leaf,
        ApiStatus.offline => AppColors.nope,
        _ => AppColors.muted,
      };

  Future<void> _requestStay(
    BuildContext context,
    Offer offer, {
    bool delayed = false,
  }) async {
    final booking = await state.createBooking(offer, delayed: delayed);
    if (!context.mounted) return;
    final message = booking == null
        ? 'Не удалось отправить заявку. Проверьте API.'
        : delayed
            ? 'Отложили «${offer.title}» (${booking.id}).'
            : 'Заявка на «${offer.title}» (${booking.id}) у менеджера.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text(
          'Онбординг, лайки и история свайпов будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.reset();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
