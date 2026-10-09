enum OfferKind {
  hotel,
  motel,
  hostel,
  tour,
  flight;

  String get title => switch (this) {
        hotel => 'Отель',
        motel => 'Мотель',
        hostel => 'Хостел',
        tour => 'Тур',
        flight => 'Перелёт',
      };
}

enum BudgetTier { low, mid, high }

class Review {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.text,
    required this.date,
  });

  final String id;
  final String author;
  final double rating;
  final String text;
  final String date;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String? ?? '',
        author: json['author'] as String? ?? 'Гость',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        text: json['text'] as String? ?? '',
        date: json['date'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'rating': rating,
        'text': text,
        'date': date,
      };
}

class Offer {
  const Offer({
    required this.id,
    required this.kind,
    required this.title,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.shortDescription,
    required this.description,
    required this.pricePerNight,
    required this.currency,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.amenities,
    required this.reviews,
    required this.budgetTier,
    this.imageUrl = '',
    this.whyRecommended = '',
  });

  final String id;
  final OfferKind kind;
  final String title;
  final String city;
  final String country;
  final String countryCode;
  final String shortDescription;
  final String description;
  final int pricePerNight;
  final String currency;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final List<String> amenities;
  final List<Review> reviews;
  final BudgetTier budgetTier;
  final String imageUrl;
  final String whyRecommended;

  String get photo {
    if (imageUrl.isNotEmpty) return imageUrl;
    return 'assets/places/$id.jpg';
  }

  String get priceLabel {
    final formatted = pricePerNight
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return switch (kind) {
      OfferKind.flight => 'от $formatted $currency',
      OfferKind.tour => '$formatted $currency / тур',
      _ => '$formatted $currency / ночь',
    };
  }

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: '${json['id']}',
        kind: OfferKind.values.byName(
          (json['kind'] as String?) ?? (json['type'] as String?) ?? 'hotel',
        ),
        title: (json['title'] as String?) ?? (json['name'] as String?) ?? '',
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        countryCode: json['countryCode'] as String? ?? '',
        shortDescription: json['shortDescription'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pricePerNight:
            ((json['pricePerNight'] as num?) ?? (json['price'] as num?))
                    ?.toInt() ??
                0,
        currency: json['currency'] as String? ?? '₽',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        tags: _strings(json['tags']),
        amenities: _strings(json['amenities']),
        reviews: (json['reviews'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Review.fromJson)
            .toList(),
        budgetTier: BudgetTier.values.byName(
          json['budgetTier'] as String? ?? 'mid',
        ),
        imageUrl: json['imageUrl'] as String? ?? '',
        whyRecommended: json['whyRecommended'] as String? ?? '',
      );

  Offer copyWith({String? imageUrl, String? whyRecommended}) => Offer(
        id: id,
        kind: kind,
        title: title,
        city: city,
        country: country,
        countryCode: countryCode,
        shortDescription: shortDescription,
        description: description,
        pricePerNight: pricePerNight,
        currency: currency,
        rating: rating,
        reviewCount: reviewCount,
        tags: tags,
        amenities: amenities,
        reviews: reviews,
        budgetTier: budgetTier,
        imageUrl: imageUrl ?? this.imageUrl,
        whyRecommended: whyRecommended ?? this.whyRecommended,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'city': city,
        'country': country,
        'countryCode': countryCode,
        'shortDescription': shortDescription,
        'description': description,
        'pricePerNight': pricePerNight,
        'currency': currency,
        'rating': rating,
        'reviewCount': reviewCount,
        'tags': tags,
        'amenities': amenities,
        'imageSymbol': '',
        'imageHue': 0.0,
        'reviews': reviews.map((e) => e.toJson()).toList(),
        'budgetTier': budgetTier.name,
        'imageUrl': photo.startsWith('http') || photo.startsWith('/static')
            ? photo
            : '',
        if (whyRecommended.isNotEmpty) 'whyRecommended': whyRecommended,
      };

  static List<String> _strings(Object? value) =>
      (value as List<dynamic>? ?? const []).whereType<String>().toList();
}

class CountryOption {
  const CountryOption(this.code, this.name, this.emoji);
  final String code;
  final String name;
  final String emoji;
}

class TravelPriority {
  const TravelPriority(this.id, this.title, this.subtitle, this.tags);
  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
}

class UserPreferences {
  const UserPreferences({
    this.countryCodes = const [],
    this.priorityIds = const [],
    this.skipped = false,
    this.onboardingCompleted = false,
  });

  final List<String> countryCodes;
  final List<String> priorityIds;
  final bool skipped;
  final bool onboardingCompleted;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        countryCodes: Offer._strings(json['countryCodes']),
        priorityIds: Offer._strings(json['priorityIds']),
        skipped: json['skipped'] as bool? ?? false,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'countryCodes': countryCodes,
        'priorityIds': priorityIds,
        'skipped': skipped,
        'onboardingCompleted': onboardingCompleted,
      };
}

class SwipeEvent {
  const SwipeEvent({
    required this.id,
    required this.offerId,
    required this.liked,
    required this.tags,
    required this.budgetTier,
    required this.kind,
    required this.countryCode,
  });

  final String id;
  final String offerId;
  final bool liked;
  final List<String> tags;
  final BudgetTier budgetTier;
  final OfferKind kind;
  final String countryCode;

  factory SwipeEvent.fromJson(Map<String, dynamic> json) => SwipeEvent(
        id: json['id'] as String? ?? '',
        offerId: json['offerId'] as String,
        liked: json['liked'] as bool,
        tags: Offer._strings(json['tags']),
        budgetTier: BudgetTier.values.byName(json['budgetTier'] as String),
        kind: OfferKind.values.byName(json['kind'] as String),
        countryCode: json['countryCode'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'offerId': offerId,
        'liked': liked,
        'tags': tags,
        'budgetTier': budgetTier.name,
        'kind': kind.name,
        'countryCode': countryCode,
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.quickReplies = const [],
  });

  final String id;
  final bool fromUser;
  final String text;
  final List<String> quickReplies;
}

class Booking {
  const Booking({
    required this.id,
    required this.guestId,
    required this.offerId,
    required this.offerTitle,
    required this.kind,
    required this.status,
    this.dates = '',
    this.note = '',
    this.createdAt = '',
  });

  final String id;
  final String guestId;
  final String offerId;
  final String offerTitle;
  final String kind;
  final String status;
  final String dates;
  final String note;
  final String createdAt;

  String get kindLabel => kind == 'delayed' ? 'Отложена' : 'Заявка';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String? ?? '',
        guestId: json['guestId'] as String? ?? '',
        offerId: json['offerId'] as String? ?? '',
        offerTitle: json['offerTitle'] as String? ?? '',
        kind: json['kind'] as String? ?? 'booking',
        status: json['status'] as String? ?? 'requested',
        dates: json['dates'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'guestId': guestId,
        'offerId': offerId,
        'offerTitle': offerTitle,
        'kind': kind,
        'status': status,
        'dates': dates,
        'note': note,
        'createdAt': createdAt,
      };
}

class ManagerTicket {
  const ManagerTicket({
    required this.id,
    required this.guestId,
    required this.note,
    this.source = 'guest',
    this.offerIds = const [],
    this.bookingId,
    this.status = 'open',
  });

  final String id;
  final String guestId;
  final String note;
  final String source;
  final List<String> offerIds;
  final String? bookingId;
  final String status;

  factory ManagerTicket.fromJson(Map<String, dynamic> json) => ManagerTicket(
        id: json['id'] as String? ?? '',
        guestId: json['guestId'] as String? ?? '',
        note: json['note'] as String? ?? '',
        source: json['source'] as String? ?? 'guest',
        offerIds: Offer._strings(json['offerIds']),
        bookingId: json['bookingId'] as String?,
        status: json['status'] as String? ?? 'open',
      );
}

class BookingRequest {
  const BookingRequest({required this.booking, required this.ticket});
  final Booking booking;
  final ManagerTicket ticket;

  factory BookingRequest.fromJson(Map<String, dynamic> json) => BookingRequest(
        booking: Booking.fromJson(json['booking'] as Map<String, dynamic>),
        ticket: ManagerTicket.fromJson(json['ticket'] as Map<String, dynamic>),
      );
}
