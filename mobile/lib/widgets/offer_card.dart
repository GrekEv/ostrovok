import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../theme.dart';

IconData offerIcon(OfferKind kind) => switch (kind) {
      OfferKind.hotel => Icons.apartment_rounded,
      OfferKind.motel => Icons.local_parking_rounded,
      OfferKind.hostel => Icons.bed_rounded,
      OfferKind.tour => Icons.map_rounded,
      OfferKind.flight => Icons.flight_rounded,
    };

class OfferHero extends StatelessWidget {
  const OfferHero({required this.offer, this.height = 250, super.key});

  final Offer offer;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.forest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PlacePhoto(offer: offer),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final photo = offer.photo;
    final network = photo.startsWith('http')
        ? photo
        : photo.startsWith('/static')
            ? '${ApiClient.baseUrl}$photo'
            : null;
    if (network != null) {
      return Image.network(
        network,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetOrFallback(offer),
      );
    }
    return _assetOrFallback(offer);
  }

  Widget _assetOrFallback(Offer offer) {
    return Image.asset(
      'assets/places/${offer.id}.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        final hue = (offer.id.hashCode.abs() % 360).toDouble();
        final accent = HSVColor.fromAHSV(1, hue, .45, .72).toColor();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(offerIcon(offer.kind), size: 78, color: Colors.white),
          ),
        );
      },
    );
  }
}

class OfferCard extends StatelessWidget {
  const OfferCard({
    required this.offer,
    required this.onDetails,
    super.key,
  });

  final Offer offer;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              OfferHero(offer: offer),
              Positioned(
                left: 14,
                top: 14,
                child: Chip(
                  label: Text(offer.kind.title.toUpperCase()),
                  backgroundColor: Colors.white.withValues(alpha: .92),
                  labelStyle: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide.none,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          color: AppColors.leaf, size: 20),
                      Text(offer.rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${offer.city}, ${offer.country}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.shortDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (offer.whyRecommended.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      offer.whyRecommended,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.priceLabel,
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onDetails,
                        child: const Text('Подробнее'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
