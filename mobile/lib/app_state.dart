import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/catalog.dart';
import 'models/models.dart';
import 'services/api_client.dart';
import 'services/recommendation_engine.dart';

enum ApiStatus { local, connecting, online, offline }

class AppState extends ChangeNotifier {
  AppState._(this._storage);

  static const _preferencesKey = 'ostrovok.preferences';
  static const _swipesKey = 'ostrovok.swipes';
  static const _guestIdKey = 'ostrovok.guestId';
  static const _bookingsKey = 'ostrovok.bookings';

  final SharedPreferences _storage;
  final ApiClient _api = ApiClient();
  final RecommendationEngine _engine = RecommendationEngine();

  String guestId = '';
  UserPreferences preferences = const UserPreferences();
  List<SwipeEvent> swipes = [];
  List<Offer> allOffers = List.of(localOffers);
  List<Offer> deck = [];
  List<Booking> bookings = [];
  ApiStatus apiStatus = ApiStatus.local;
  String? apiError;
  int _refreshGeneration = 0;

  static Future<AppState> create() async {
    final storage = await SharedPreferences.getInstance();
    final state = AppState._(storage).._restore();
    await state._persist();
    state._rebuildLocalDeck();
    if (state.preferences.onboardingCompleted) {
      unawaited(state.refreshRecommendations());
    }
    return state;
  }

  List<Offer> get likedOffers {
    final ids = swipes.where((e) => e.liked).map((e) => e.offerId).toSet();
    return allOffers.where((e) => ids.contains(e.id)).toList();
  }

  Future<void> completeOnboarding({
    required Iterable<String> countries,
    required Iterable<String> priorities,
    required bool skipped,
  }) async {
    preferences = UserPreferences(
      countryCodes: countries.toList(),
      priorityIds: priorities.toList(),
      skipped: skipped,
      onboardingCompleted: true,
    );
    _rebuildLocalDeck();
    await _persist();
    notifyListeners();
    if (ApiClient.hasRemoteApi) {
      unawaited(() async {
        try {
          await _api.savePreferences(guestId, preferences);
        } catch (_) {}
      }());
    }
    unawaited(refreshRecommendations());
  }

  Future<void> swipe(Offer offer, bool liked) async {
    swipes = [
      ...swipes,
      SwipeEvent(
        id: '${DateTime.now().microsecondsSinceEpoch}-${offer.id}',
        offerId: offer.id,
        liked: liked,
        tags: offer.tags,
        budgetTier: offer.budgetTier,
        kind: offer.kind,
        countryCode: offer.countryCode,
      ),
    ];
    _rebuildLocalDeck();
    await _persist();
    notifyListeners();
    if (!ApiClient.hasRemoteApi) {
      return;
    }
    try {
      final remote = await _api.recordSwipe(
        guestId: guestId,
        offer: offer,
        liked: liked,
      );
      _mergeCatalog(remote);
      deck = remote;
      apiStatus = ApiStatus.online;
      apiError = null;
      notifyListeners();
    } catch (error) {
      apiStatus = ApiStatus.offline;
      apiError = error.toString();
      notifyListeners();
    }
  }

  Future<void> refreshRecommendations() async {
    if (!preferences.onboardingCompleted) return;
    if (!ApiClient.hasRemoteApi) {
      _rebuildLocalDeck();
      apiStatus = ApiStatus.local;
      apiError = null;
      notifyListeners();
      return;
    }
    final generation = ++_refreshGeneration;
    apiStatus = ApiStatus.connecting;
    apiError = null;
    notifyListeners();
    try {
      final remoteCatalog = await _api.catalog();
      if (generation != _refreshGeneration) return;
      _mergeCatalog(remoteCatalog);
      final remote =
          await _api.recommendations(preferences, swipes, guestId: guestId);
      if (generation != _refreshGeneration) return;
      _mergeCatalog(remote);
      deck = remote;
      bookings = await _api.bookings(guestId);
      apiStatus = ApiStatus.online;
      await _persist();
      notifyListeners();
    } catch (error) {
      if (generation != _refreshGeneration) return;
      _rebuildLocalDeck();
      apiStatus = ApiStatus.offline;
      apiError = error.toString();
      notifyListeners();
    }
  }

  Future<AgentReply> chat(String text) async {
    try {
      final reply = await _api.chat(text, likedOffers, guestId: guestId);
      apiStatus = ApiStatus.online;
      apiError = null;
      if (reply.createdRequest) {
        try {
          bookings = await _api.bookings(guestId);
          await _persist();
        } catch (_) {}
      }
      notifyListeners();
      return reply;
    } catch (error) {
      apiStatus = ApiStatus.offline;
      apiError = error.toString();
      notifyListeners();
      return _localReply(text);
    }
  }

  Future<Booking?> createBooking(Offer offer, {bool delayed = false}) async {
    try {
      final created = await _api.createBooking(
        guestId: guestId,
        offerId: offer.id,
        kind: delayed ? 'delayed' : 'booking',
        note: delayed ? 'Отложить с карточки' : 'Заявка с карточки',
      );
      bookings = [
        ...bookings.where((e) => e.id != created.booking.id),
        created.booking
      ];
      apiStatus = ApiStatus.online;
      apiError = null;
      await _persist();
      notifyListeners();
      return created.booking;
    } catch (error) {
      apiStatus = ApiStatus.offline;
      apiError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> reset() async {
    _refreshGeneration++;
    preferences = const UserPreferences();
    swipes = [];
    allOffers = List.of(localOffers);
    apiStatus = ApiStatus.local;
    apiError = null;
    _rebuildLocalDeck();
    await _persist();
    notifyListeners();
  }

  void _rebuildLocalDeck() {
    deck = _engine.rank(allOffers, preferences, swipes);
  }

  void _mergeCatalog(List<Offer> remote) {
    final byId = {for (final offer in remote) offer.id: offer};
    allOffers = [
      for (final offer in allOffers) byId.remove(offer.id) ?? offer,
      ...byId.values,
    ];
  }

  AgentReply _localReply(String text) {
    final value = text.toLowerCase();
    if (value.contains('менедж')) {
      return const AgentReply(
        'Соединяю с менеджером. В офлайне заявка сохранится, когда API снова ответит.',
        ['Подобрать', 'Забронировать'],
        intent: 'manager',
      );
    }
    if (value.contains('отлож') || value.contains('потом')) {
      return const AgentReply(
        'Сохраню выбранные карточки. Напишите город и желаемые даты.',
        ['Забронировать', 'Менеджер'],
        intent: 'delayed',
      );
    }
    if (value.contains('брон')) {
      final text = likedOffers.isEmpty
          ? 'Сначала добавьте хотя бы одну карточку вправо.'
          : 'Могу начать заявку на «${likedOffers.first.title}». Оплата в тестовой версии отключена.';
      return AgentReply(text, const ['Менеджер', 'Отложить бронь'],
          intent: 'booking');
    }
    if (value.contains('подобр') || value.contains('вариант')) {
      return AgentReply(
        likedOffers.isEmpty
            ? 'Свайпайте карточки — подбор будет уточняться после каждого жеста.'
            : 'Ваши фавориты: ${likedOffers.take(3).map((e) => e.title).join(', ')}.',
        const ['Забронировать', 'Менеджер'],
        intent: 'pick',
      );
    }
    return const AgentReply(
      'Напишите, куда, когда, с кем и какой бюджет. Я помогу с подбором.',
      ['Подобрать', 'Забронировать', 'Отложить бронь', 'Менеджер'],
    );
  }

  void _restore() {
    guestId = _storage.getString(_guestIdKey) ?? '';
    if (guestId.isEmpty) {
      guestId = 'guest-${DateTime.now().microsecondsSinceEpoch}';
    }
    try {
      final rawPreferences = _storage.getString(_preferencesKey);
      if (rawPreferences != null) {
        preferences = UserPreferences.fromJson(
          jsonDecode(rawPreferences) as Map<String, dynamic>,
        );
      }
      final rawSwipes = _storage.getString(_swipesKey);
      if (rawSwipes != null) {
        swipes = (jsonDecode(rawSwipes) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(SwipeEvent.fromJson)
            .toList();
      }
      final rawBookings = _storage.getString(_bookingsKey);
      if (rawBookings != null) {
        bookings = (jsonDecode(rawBookings) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(Booking.fromJson)
            .toList();
      }
    } catch (_) {
      preferences = const UserPreferences();
      swipes = [];
      bookings = [];
    }
  }

  Future<void> _persist() async {
    await Future.wait([
      _storage.setString(_guestIdKey, guestId),
      _storage.setString(_preferencesKey, jsonEncode(preferences.toJson())),
      _storage.setString(
        _swipesKey,
        jsonEncode(swipes.map((e) => e.toJson()).toList()),
      ),
      _storage.setString(
        _bookingsKey,
        jsonEncode(bookings.map((e) => e.toJson()).toList()),
      ),
    ]);
  }
}
