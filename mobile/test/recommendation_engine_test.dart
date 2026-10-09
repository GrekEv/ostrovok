import 'package:flutter_test/flutter_test.dart';
import 'package:ostrovok/data/catalog.dart';
import 'package:ostrovok/models/models.dart';
import 'package:ostrovok/services/recommendation_engine.dart';

void main() {
  final engine = RecommendationEngine();

  test('universal profile starts with a mid-budget hotel', () {
    final ranked = engine.rank(
      localOffers,
      const UserPreferences(skipped: true, onboardingCompleted: true),
      const [],
    );

    expect(ranked, isNotEmpty);
    expect(ranked.first.kind, OfferKind.hotel);
    expect(ranked.first.budgetTier, BudgetTier.mid);
    expect(ranked.first.whyRecommended, contains('подбираем места'));
  });

  test('seen cards are removed and sea preference is learned', () {
    final ranked = engine.rank(
      localOffers,
      const UserPreferences(skipped: true, onboardingCompleted: true),
      const [
        SwipeEvent(
          id: '1',
          offerId: 'ht-santorini',
          liked: true,
          tags: ['море', 'пляж', 'люкс'],
          budgetTier: BudgetTier.high,
          kind: OfferKind.hotel,
          countryCode: 'GR',
        ),
        SwipeEvent(
          id: '2',
          offerId: 'hs-bangkok',
          liked: false,
          tags: ['город', 'бюджет'],
          budgetTier: BudgetTier.low,
          kind: OfferKind.hostel,
          countryCode: 'TH',
        ),
      ],
    );

    expect(ranked.map((e) => e.id), isNot(contains('ht-santorini')));
    expect(ranked.map((e) => e.id), isNot(contains('hs-bangkok')));
    expect(
      ranked.take(3).expand((e) => e.tags),
      anyOf(contains('море'), contains('пляж')),
    );
  });
}
