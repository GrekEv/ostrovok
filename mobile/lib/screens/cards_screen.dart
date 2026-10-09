import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/mascot.dart';
import '../widgets/offer_card.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.deck.isEmpty) {
      return const _EmptyDeck();
    }
    final offer = state.deck.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          const Text(
            'Вправо — нравится. ИИ учится после каждого свайпа.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Dismissible(
              key: ValueKey(offer.id),
              direction: DismissDirection.horizontal,
              background: const _SwipeBackground(
                alignment: Alignment.centerLeft,
                icon: Icons.favorite_rounded,
                label: 'НРАВИТСЯ',
                color: AppColors.leaf,
              ),
              secondaryBackground: const _SwipeBackground(
                alignment: Alignment.centerRight,
                icon: Icons.close_rounded,
                label: 'МИМО',
                color: AppColors.nope,
              ),
              onDismissed: (direction) {
                state.swipe(
                  offer,
                  direction == DismissDirection.startToEnd,
                );
              },
              child: OfferCard(
                offer: offer,
                onDetails: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OfferDetailScreen(
                      offer: offer,
                      state: state,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.nope,
                onPressed: () => state.swipe(offer, false),
              ),
              const SizedBox(width: 32),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.leaf,
                onPressed: () => state.swipe(offer, true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: color),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        iconSize: 30,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Mascot(size: 130, wink: true),
            SizedBox(height: 16),
            Text(
              'Карточки закончились',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Откройте агента: он сравнит понравившиеся варианты.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({
    required this.offer,
    required this.state,
    super.key,
  });

  final Offer offer;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(offer.kind.title)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: OfferHero(offer: offer, height: 230)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            sliver: SliverList.list(
              children: [
                Text(
                  offer.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${offer.city}, ${offer.country}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (offer.whyRecommended.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    offer.whyRecommended,
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.leaf, size: 20),
                    Text(
                      '${offer.rating.toStringAsFixed(1)} · '
                      '${offer.reviewCount} отзывов',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.priceLabel,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(offer.description),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final tag in offer.tags)
                      Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.mint,
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Что входит',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 8),
                for (final item in offer.amenities)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.leaf, size: 19),
                        const SizedBox(width: 8),
                        Text(item),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Отзывы',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 8),
                if (offer.reviews.isEmpty)
                  const Text(
                    'Подробные отзывы появятся после подключения поставщика.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                for (final review in offer.reviews)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${review.author} · ${review.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(review.text),
                          Text(
                            review.date,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    state.swipe(offer, false);
                    Navigator.pop(context);
                  },
                  child: const Text('Мимо'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    state.swipe(offer, true);
                    Navigator.pop(context);
                  },
                  child: const Text('Нравится'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
