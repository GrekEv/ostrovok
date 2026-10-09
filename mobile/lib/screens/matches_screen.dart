import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final delayed =
        state.bookings.where((item) => item.kind == 'delayed').toList();
    final liked = state.likedOffers;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Отложенные матчи',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Карточки, которые вы отложили, и лайки без мгновенной брони.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        if (delayed.isEmpty && liked.isEmpty)
          const Card(
            child: ListTile(
              leading: Mascot(size: 52),
              title: Text('Пока пусто'),
              subtitle: Text('Свайпните вправо или нажмите «Отложить бронь».'),
            ),
          ),
        ...delayed.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.offerTitle),
              subtitle: Text('${item.kindLabel} · ${item.id}'),
            ),
          ),
        ),
        if (liked.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Лайки',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...liked.map(
            (offer) => Card(
              child: ListTile(
                title: Text(offer.title),
                subtitle: Text('${offer.city}, ${offer.country}'),
                trailing: TextButton(
                  onPressed: () => state.createBooking(offer, delayed: true),
                  child: const Text('Отложить'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
