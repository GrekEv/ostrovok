import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class AgentReply {
  const AgentReply(
    this.text,
    this.quickReplies, {
    this.intent = 'none',
    this.ticketId,
    this.bookingId,
  });

  final String text;
  final List<String> quickReplies;
  final String intent;
  final String? ticketId;
  final String? bookingId;

  bool get createdRequest =>
      (ticketId != null && ticketId!.isNotEmpty) ||
      (bookingId != null && bookingId!.isNotEmpty);
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const configuredUrl = String.fromEnvironment('OSTROVOK_API_URL');

  static bool get hasRemoteApi {
    if (configuredUrl.isNotEmpty) return true;
    if (kIsWeb && _isPublicStaticHost(Uri.base.host)) return false;
    return true;
  }

  static String get baseUrl {
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isEmpty || _isPublicStaticHost(host)) {
        return 'http://127.0.0.1:8080';
      }
      return 'http://$host:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  static bool _isPublicStaticHost(String host) {
    return host.endsWith('github.io') ||
        host.endsWith('netlify.app') ||
        host.endsWith('pages.dev') ||
        host.endsWith('web.app') ||
        host.endsWith('firebaseapp.com') ||
        host.endsWith('vercel.app');
  }

  Future<List<Offer>> catalog() async {
    final response = await _get('/v1/catalog') as Map<String, dynamic>;
    return (response['offers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Offer.fromJson)
        .toList();
  }

  Future<List<Offer>> recommendations(
    UserPreferences preferences,
    List<SwipeEvent> swipes, {
    required String guestId,
  }) async {
    final response = await _post('/v1/recommendations', {
      'guestId': guestId,
      'countryCodes': preferences.countryCodes,
      'priorityIDs': preferences.priorityIds,
      'skipped': preferences.skipped,
      'swipes': swipes.map((e) => e.toJson()).toList(),
    });
    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Offer.fromJson)
        .toList();
  }

  Future<void> savePreferences(
    String guestId,
    UserPreferences preferences,
  ) async {
    await _post('/v1/preferences', {
      'guestId': guestId,
      'countryCodes': preferences.countryCodes,
      'priorityIDs': preferences.priorityIds,
      'skipped': preferences.skipped,
    });
  }

  Future<List<Offer>> recordSwipe({
    required String guestId,
    required Offer offer,
    required bool liked,
  }) async {
    final response = await _post('/v1/swipes', {
      'guestId': guestId,
      'offerId': offer.id,
      'liked': liked,
      'tags': offer.tags,
      'budgetTier': offer.budgetTier.name,
      'kind': offer.kind.name,
      'countryCode': offer.countryCode,
    }) as Map<String, dynamic>;
    return (response['deck'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Offer.fromJson)
        .toList();
  }

  Future<AgentReply> chat(
    String message,
    List<Offer> liked, {
    required String guestId,
  }) async {
    final response = await _post('/v1/agent/chat', {
      'message': message,
      'guestId': guestId,
      'liked': liked.map((e) => e.toJson()).toList(),
    }) as Map<String, dynamic>;
    return AgentReply(
      response['text'] as String,
      (response['quickReplies'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      intent: response['intent'] as String? ?? 'none',
      ticketId: response['ticketId'] as String?,
      bookingId: response['bookingId'] as String?,
    );
  }

  Future<List<Booking>> bookings(String guestId) async {
    final response = await _get('/v1/bookings', {'guestId': guestId});
    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList();
  }

  Future<BookingRequest> createBooking({
    required String guestId,
    required String offerId,
    required String kind,
    String dates = '',
    String note = '',
  }) async {
    final response = await _post('/v1/bookings', {
      'guestId': guestId,
      'offerId': offerId,
      'kind': kind,
      'dates': dates,
      'note': note,
    }) as Map<String, dynamic>;
    return BookingRequest.fromJson(response);
  }

  Future<ManagerTicket> callManager({
    required String guestId,
    required String note,
    List<String> offerIds = const [],
  }) async {
    final response = await _post('/v1/manager/tickets', {
      'guestId': guestId,
      'note': note,
      'offerIds': offerIds,
    }) as Map<String, dynamic>;
    return ManagerTicket.fromJson(response);
  }

  Future<Object?> _get(String path, [Map<String, String>? query]) async {
    _ensureRemoteApi();
    final uri = Uri.parse(baseUrl).resolve(path).replace(
          queryParameters: query == null || query.isEmpty ? null : query,
        );
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    return _decode(response);
  }

  Future<Object?> _post(String path, Object body) async {
    _ensureRemoteApi();
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
    return _decode(response);
  }

  void _ensureRemoteApi() {
    if (!hasRemoteApi) {
      throw Exception('Публичная веб-сборка без API: используется локальный каталог');
    }
  }

  Object? _decode(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String? ?? 'Неизвестная ошибка'
          : 'Неизвестная ошибка';
      throw Exception('HTTP ${response.statusCode}: $message');
    }
    return decoded;
  }
}
