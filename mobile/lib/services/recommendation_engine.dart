import '../data/catalog.dart';
import '../models/models.dart';

class RecommendationEngine {
  List<Offer> rank(
    List<Offer> offers,
    UserPreferences preferences,
    List<SwipeEvent> swipes,
  ) {
    final profile = _buildProfile(preferences, swipes);
    final seen = swipes.map((e) => e.offerId).toSet();
    final pool = offers
        .where((offer) => !seen.contains(offer.id))
        .map((offer) => (offer: offer, value: _score(offer, profile)))
        .toList();

    final out = <Offer>[];
    while (pool.isNotEmpty) {
      var best = 0;
      var bestVal = _adjusted(pool[0], out);
      for (var i = 1; i < pool.length; i++) {
        final value = _adjusted(pool[i], out);
        if (value > bestVal ||
            (value == bestVal &&
                pool[i].offer.rating > pool[best].offer.rating)) {
          best = i;
          bestVal = value;
        }
      }
      final chosen = pool.removeAt(best).offer;
      out.add(
        chosen.copyWith(
          whyRecommended: _explain(chosen, profile, preferences, swipes),
        ),
      );
    }
    return out;
  }

  double _adjusted(
    ({Offer offer, double value}) item,
    List<Offer> picked,
  ) {
    var value = item.value;
    for (final prev in picked) {
      if (prev.kind == item.offer.kind) value -= 0.28;
      if (prev.countryCode == item.offer.countryCode) value -= 0.18;
    }
    return value;
  }

  _Profile _buildProfile(
    UserPreferences preferences,
    List<SwipeEvent> swipes,
  ) {
    final profile = _Profile();
    final isUniversal = preferences.skipped ||
        (preferences.countryCodes.isEmpty && preferences.priorityIds.isEmpty);

    if (isUniversal) {
      for (final tag in ['город', 'комфорт', 'море', 'культура']) {
        profile.tags[tag] = (profile.tags[tag] ?? 0) + 1.2;
      }
      profile.budgets[BudgetTier.mid] = 2;
      profile.kinds[OfferKind.hotel] = 1;
    } else {
      for (final country in preferences.countryCodes) {
        profile.countries[country] = (profile.countries[country] ?? 0) + 2.5;
      }
      for (final id in preferences.priorityIds) {
        final matching = priorities.where((item) => item.id == id);
        if (matching.isEmpty) continue;
        for (final tag in matching.first.tags) {
          profile.tags[tag] = (profile.tags[tag] ?? 0) + 2;
        }
      }
    }

    final n = swipes.length;
    for (var i = 0; i < swipes.length; i++) {
      final swipe = swipes[i];
      final direction = swipe.liked ? 1.0 : -1.4;
      final recency = 1 + 0.12 * i / (n == 0 ? 1 : n);
      final weight = direction * recency;
      for (final tag in swipe.tags) {
        profile.tags[tag] = (profile.tags[tag] ?? 0) + weight;
      }
      profile.kinds[swipe.kind] =
          (profile.kinds[swipe.kind] ?? 0) + weight * .8;
      profile.budgets[swipe.budgetTier] =
          (profile.budgets[swipe.budgetTier] ?? 0) + weight * .9;
      profile.countries[swipe.countryCode] =
          (profile.countries[swipe.countryCode] ?? 0) + weight * .7;
    }
    return profile;
  }

  double _score(Offer offer, _Profile profile) {
    var result = offer.rating;
    for (final tag in offer.tags) {
      result += profile.tags[tag] ?? 0;
    }
    result += profile.kinds[offer.kind] ?? 0;
    result += profile.budgets[offer.budgetTier] ?? 0;
    result += profile.countries[offer.countryCode] ?? 0;
    return result;
  }

  String _explain(
    Offer offer,
    _Profile profile,
    UserPreferences preferences,
    List<SwipeEvent> swipes,
  ) {
    return 'мы подбираем места под твои желания и карточки свайпа';
  }
}

class _Profile {
  final tags = <String, double>{};
  final kinds = <OfferKind, double>{};
  final budgets = <BudgetTier, double>{};
  final countries = <String, double>{};
}
