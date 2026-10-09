import Foundation

enum Catalog {
    static let countries: [CountryOption] = [
        .init(code: "IT", name: "Италия", emoji: "🇮🇹"),
        .init(code: "FR", name: "Франция", emoji: "🇫🇷"),
        .init(code: "ES", name: "Испания", emoji: "🇪🇸"),
        .init(code: "GR", name: "Греция", emoji: "🇬🇷"),
        .init(code: "TR", name: "Турция", emoji: "🇹🇷"),
        .init(code: "TH", name: "Таиланд", emoji: "🇹🇭"),
        .init(code: "JP", name: "Япония", emoji: "🇯🇵"),
        .init(code: "GE", name: "Грузия", emoji: "🇬🇪"),
        .init(code: "AE", name: "ОАЭ", emoji: "🇦🇪"),
        .init(code: "ID", name: "Индонезия", emoji: "🇮🇩"),
        .init(code: "PT", name: "Португалия", emoji: "🇵🇹"),
        .init(code: "ME", name: "Черногория", emoji: "🇲🇪"),
        .init(code: "DE", name: "Германия", emoji: "🇩🇪"),
        .init(code: "AT", name: "Австрия", emoji: "🇦🇹"),
        .init(code: "CH", name: "Швейцария", emoji: "🇨🇭"),
        .init(code: "GB", name: "Великобритания", emoji: "🇬🇧"),
        .init(code: "CZ", name: "Чехия", emoji: "🇨🇿"),
        .init(code: "HR", name: "Хорватия", emoji: "🇭🇷"),
        .init(code: "NO", name: "Норвегия", emoji: "🇳🇴"),
        .init(code: "IS", name: "Исландия", emoji: "🇮🇸"),
        .init(code: "NL", name: "Нидерланды", emoji: "🇳🇱"),
        .init(code: "PL", name: "Польша", emoji: "🇵🇱"),
        .init(code: "HU", name: "Венгрия", emoji: "🇭🇺"),
        .init(code: "US", name: "США", emoji: "🇺🇸"),
        .init(code: "MX", name: "Мексика", emoji: "🇲🇽"),
        .init(code: "BR", name: "Бразилия", emoji: "🇧🇷"),
        .init(code: "MA", name: "Марокко", emoji: "🇲🇦"),
        .init(code: "EG", name: "Египет", emoji: "🇪🇬"),
        .init(code: "VN", name: "Вьетнам", emoji: "🇻🇳"),
        .init(code: "KR", name: "Южная Корея", emoji: "🇰🇷"),
        .init(code: "AU", name: "Австралия", emoji: "🇦🇺"),
        .init(code: "LK", name: "Шри-Ланка", emoji: "🇱🇰"),
        .init(code: "IN", name: "Индия", emoji: "🇮🇳"),
        .init(code: "MV", name: "Мальдивы", emoji: "🇲🇻"),
        .init(code: "AM", name: "Армения", emoji: "🇦🇲"),
        .init(code: "TZ", name: "Танзания", emoji: "🇹🇿")
    ]

    static let priorities: [TravelPriority] = [
        .init(id: "sea", title: "Море и пляж", subtitle: "Солнце, вода, неспешный ритм", symbol: "water.waves", tags: ["море", "пляж", "релакс"]),
        .init(id: "city", title: "Города и культура", subtitle: "Музеи, улицы, еда", symbol: "building.columns", tags: ["город", "культура", "гастрономия"]),
        .init(id: "nature", title: "Природа", subtitle: "Горы, острова, тишина", symbol: "leaf", tags: ["природа", "горы", "острова"]),
        .init(id: "budget", title: "Выгодная цена", subtitle: "Максимум впечатлений за бюджет", symbol: "banknote", tags: ["бюджет", "выгодно"]),
        .init(id: "comfort", title: "Комфорт", subtitle: "Сервис, тишина, удобство", symbol: "sparkles", tags: ["люкс", "комфорт", "сервис"]),
        .init(id: "family", title: "Семья", subtitle: "Детям и взрослым вместе", symbol: "figure.2.and.child.holdinghands", tags: ["семья", "дети"]),
        .init(id: "romance", title: "Для двоих", subtitle: "Спокойные и красивые места", symbol: "heart", tags: ["романтика", "для двоих"]),
        .init(id: "adventure", title: "Приключения", subtitle: "Новые маршруты и активности", symbol: "figure.hiking", tags: ["приключения", "активный"])
    ]

    static let offers: [Offer] = [
        Offer(
            id: "ht-florence",
            kind: .hotel,
            title: "Casa Verde Florence",
            city: "Флоренция",
            country: "Италия",
            countryCode: "IT",
            shortDescription: "Тихий отель у садов Боболи, завтрак с видом на крыши.",
            description: "Небольшой семейный отель в зелёном дворе. Номера с высокими потолками, итальянский завтрак и прогулка до Дуомо за 12 минут. Подходит, если важны тишина и расположение, а не огромный спа.",
            pricePerNight: 18_900,
            currency: "₽",
            rating: 4.8,
            reviewCount: 312,
            tags: ["город", "культура", "комфорт", "гастрономия"],
            amenities: ["Завтрак", "Wi‑Fi", "Двор", "Кондиционер"],
            imageSymbol: "building.columns.fill",
            imageHue: 0.38,
            reviews: [
                Review(id: "r1", author: "Анна", rating: 5, text: "Идеально для пары дней во Флоренции. Завтрак свежий, персонал спокойный.", date: "май 2026"),
                Review(id: "r2", author: "Кирилл", rating: 4.5, text: "Номер чуть компактный, но чисто и очень удобно до центра.", date: "апрель 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "ht-santorini",
            kind: .hotel,
            title: "White Cliff Suites",
            city: "Ойя",
            country: "Греция",
            countryCode: "GR",
            shortDescription: "Белые террасы над Эгейским морем, закаты и завтрак в номере.",
            description: "Камерный отель на клифе. Каждый номер с собственной террасой. Лучше всего заходит тем, кто ищет море, романтику и готов платить за вид, а не за анимацию.",
            pricePerNight: 34_500,
            currency: "₽",
            rating: 4.9,
            reviewCount: 188,
            tags: ["море", "пляж", "романтика", "для двоих", "люкс"],
            amenities: ["Вид на море", "Терраса", "Завтрак", "Трансфер"],
            imageSymbol: "sun.horizon.fill",
            imageHue: 0.48,
            reviews: [
                Review(id: "r3", author: "Мария", rating: 5, text: "Закат с террасы стоил каждой минуты. Тихо и красиво.", date: "июнь 2026"),
                Review(id: "r4", author: "Павел", rating: 4.7, text: "До пляжа спуск, но вид и сервис выше ожиданий.", date: "май 2026")
            ],
            budgetTier: .high
        ),
        Offer(
            id: "hs-bangkok",
            kind: .hostel,
            title: "River Pod Hostel",
            city: "Бангкок",
            country: "Таиланд",
            countryCode: "TH",
            shortDescription: "Чистые капсулы у реки, общая кухня и вечерние маршруты по городу.",
            description: "Современный хостел для тех, кто хочет город дёшево и без хаоса. Капсулы с шторкой и розеткой, общие зоны светлые. Рядом лодочный транспорт.",
            pricePerNight: 2_400,
            currency: "₽",
            rating: 4.6,
            reviewCount: 540,
            tags: ["город", "бюджет", "выгодно", "приключения"],
            amenities: ["Кухня", "Капсулы", "Замок", "Туры"],
            imageSymbol: "bed.double.fill",
            imageHue: 0.42,
            reviews: [
                Review(id: "r5", author: "Даша", rating: 4.6, text: "Для цены — отлично. Тихо после 23:00, что редкость.", date: "март 2026")
            ],
            budgetTier: .low
        ),
        Offer(
            id: "mt-tbilisi",
            kind: .motel,
            title: "Kakheti Road Motel",
            city: "Сигнахи",
            country: "Грузия",
            countryCode: "GE",
            shortDescription: "Мотель у виноградников, парковка у двери и домашний ужин.",
            description: "Удобная точка, если едете по Кахетии на машине. Простые номера, хорошая кровать, вино от хозяев. Не курорт — дорожный комфорт с видом на долину.",
            pricePerNight: 4_800,
            currency: "₽",
            rating: 4.4,
            reviewCount: 97,
            tags: ["природа", "бюджет", "гастрономия", "комфорт"],
            amenities: ["Парковка", "Ужин", "Wi‑Fi"],
            imageSymbol: "car.fill",
            imageHue: 0.32,
            reviews: [
                Review(id: "r6", author: "Игорь", rating: 4.4, text: "Остановились на ночь — остались на две. Ужин домашний.", date: "сентябрь 2025")
            ],
            budgetTier: .low
        ),
        Offer(
            id: "tr-bali",
            kind: .tour,
            title: "Бали: 8 дней без спешки",
            city: "Убуд — Чангу",
            country: "Индонезия",
            countryCode: "ID",
            shortDescription: "Рисовые террасы, океан и свободные дни без плотного графика.",
            description: "Группа до 10 человек. Три ночи в Убуде, четыре у океана. Экскурсии по желанию, много свободного времени. Для тех, кому важны природа и море, а не чек-лист храмов.",
            pricePerNight: 89_000,
            currency: "₽",
            rating: 4.7,
            reviewCount: 64,
            tags: ["острова", "природа", "релакс", "море", "пляж"],
            amenities: ["Гид", "Трансферы", "Отели 3–4*", "Завтраки"],
            imageSymbol: "leaf.fill",
            imageHue: 0.36,
            reviews: [
                Review(id: "r7", author: "Ольга", rating: 4.8, text: "Не гоняли по точкам. Убуд зашёл сильнее пляжа — как и обещали.", date: "февраль 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "fl-tokyo",
            kind: .flight,
            title: "Москва — Токио, прямые даты",
            city: "Токио",
            country: "Япония",
            countryCode: "JP",
            shortDescription: "Прямой рейс, удобное прибытие утром, багаж включён.",
            description: "Подборка дат на ближайшие месяцы. Вылет вечером, прилёт утром. Подходит как старт к городскому маршруту: Шибуя, Киото на синкансене, еда и храмы.",
            pricePerNight: 52_400,
            currency: "₽",
            rating: 4.5,
            reviewCount: 210,
            tags: ["город", "культура", "гастрономия", "приключения"],
            amenities: ["Багаж 23 кг", "Питание", "Выбор места"],
            imageSymbol: "airplane",
            imageHue: 0.55,
            reviews: [
                Review(id: "r8", author: "Никита", rating: 4.5, text: "Прилетели без задержки. Утренний прилёт — сразу в город.", date: "январь 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "ht-dubai",
            kind: .hotel,
            title: "Palm Garden Hotel",
            city: "Дубай",
            country: "ОАЭ",
            countryCode: "AE",
            shortDescription: "Семейный отель у пляжа, мелкое море и детский клуб.",
            description: "Большая территория, свой пляж, номера с двумя спальнями. Сервис ровный, еда без сюрпризов. Универсальный вариант, если важны море и семья.",
            pricePerNight: 27_800,
            currency: "₽",
            rating: 4.6,
            reviewCount: 890,
            tags: ["море", "пляж", "семья", "дети", "комфорт", "сервис"],
            amenities: ["Пляж", "Бассейн", "Детский клуб", "All inclusive"],
            imageSymbol: "beach.umbrella.fill",
            imageHue: 0.5,
            reviews: [
                Review(id: "r9", author: "Елена", rating: 4.6, text: "С детьми 5 и 8 — спокойно. Море мелкое, анимация не орёт.", date: "август 2026")
            ],
            budgetTier: .high
        ),
        Offer(
            id: "ht-porto",
            kind: .hotel,
            title: "Ribeira Light",
            city: "Порту",
            country: "Португалия",
            countryCode: "PT",
            shortDescription: "Бутик у набережной, портвейн и прогулки по лестницам.",
            description: "12 номеров в старом доме. Завтрак с паштел-де-ната, вид на Дору. Для тех, кто любит города, еду и не гонится за пятизвёздочным спа.",
            pricePerNight: 16_200,
            currency: "₽",
            rating: 4.7,
            reviewCount: 143,
            tags: ["город", "культура", "гастрономия", "романтика"],
            amenities: ["Завтрак", "Вид на реку", "Wi‑Fi"],
            imageSymbol: "sailboat.fill",
            imageHue: 0.58,
            reviews: [
                Review(id: "r10", author: "Света", rating: 4.7, text: "Шумно вечером с набережной, но атмосфера того стоит.", date: "июль 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "tr-alps",
            kind: .tour,
            title: "Альпы: треккинг 6 дней",
            city: "Шамони",
            country: "Франция",
            countryCode: "FR",
            shortDescription: "Маршруты средней сложности, хижины и гид-инструктор.",
            description: "Для активных, но не альпинистов. Ходим 5–7 часов в день, ночёвки в приютах. Рюкзак лёгкий, основное везёт трансфер. Природа и приключения без экстремального риска.",
            pricePerNight: 112_000,
            currency: "₽",
            rating: 4.8,
            reviewCount: 41,
            tags: ["горы", "природа", "приключения", "активный"],
            amenities: ["Гид", "Приюты", "Трансфер", "Страховка"],
            imageSymbol: "mountain.2.fill",
            imageHue: 0.34,
            reviews: [
                Review(id: "r11", author: "Артём", rating: 5, text: "Ноги устали правильно. Виды лучше любой открытки.", date: "сентябрь 2026")
            ],
            budgetTier: .high
        ),
        Offer(
            id: "hs-barcelona",
            kind: .hostel,
            title: "Gothic Yard",
            city: "Барселона",
            country: "Испания",
            countryCode: "ES",
            shortDescription: "Хостел во внутреннем дворе Готического квартала.",
            description: "Смешанные комнаты и пару двухместных. Кухня, вечерние тапа-прогулки. Бюджетный город с характером.",
            pricePerNight: 3_100,
            currency: "₽",
            rating: 4.3,
            reviewCount: 402,
            tags: ["город", "бюджет", "культура", "гастрономия"],
            amenities: ["Кухня", "Двор", "Замок"],
            imageSymbol: "building.2.fill",
            imageHue: 0.46,
            reviews: [
                Review(id: "r12", author: "Лена", rating: 4.2, text: "Место супер, душ один на этаж — учитывайте.", date: "июнь 2026")
            ],
            budgetTier: .low
        ),
        Offer(
            id: "ht-istanbul",
            kind: .hotel,
            title: "Galata Soft",
            city: "Стамбул",
            country: "Турция",
            countryCode: "TR",
            shortDescription: "Отель в Галате, крыша с видом на залив и кофе по утрам.",
            description: "Универсальный городской отель: удобно до трамвая, завтрак сытный, номера тихие внутри квартала. Хорошая база, если не выбрали море или горы.",
            pricePerNight: 11_400,
            currency: "₽",
            rating: 4.5,
            reviewCount: 276,
            tags: ["город", "культура", "гастрономия", "комфорт", "выгодно"],
            amenities: ["Завтрак", "Терраса", "Wi‑Fi"],
            imageSymbol: "moon.stars.fill",
            imageHue: 0.4,
            reviews: [
                Review(id: "r13", author: "Максим", rating: 4.5, text: "Крыша вечером — отдельная причина остаться ещё на ночь.", date: "апрель 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "ht-kotor",
            kind: .hotel,
            title: "Bay Pine Hotel",
            city: "Котор",
            country: "Черногория",
            countryCode: "ME",
            shortDescription: "Отель у бухты, сосны и лодки до Пераста.",
            description: "Спокойный берег, не огромный курорт. Номера с балконами, вода чистая. Для моря и природы без толпы.",
            pricePerNight: 9_800,
            currency: "₽",
            rating: 4.6,
            reviewCount: 155,
            tags: ["море", "природа", "релакс", "для двоих", "выгодно"],
            amenities: ["Балкон", "Пляж рядом", "Парковка"],
            imageSymbol: "tree.fill",
            imageHue: 0.37,
            reviews: [
                Review(id: "r14", author: "Вика", rating: 4.6, text: "Тихо, красиво, до старого города 15 минут на машине.", date: "июль 2026")
            ],
            budgetTier: .low
        ),
        Offer(
            id: "fl-barcelona",
            kind: .flight,
            title: "Москва — Барселона",
            city: "Барселона",
            country: "Испания",
            countryCode: "ES",
            shortDescription: "Прямой утренний рейс, удобно сразу в город.",
            description: "Короткий перелёт для городского уикенда или старта к морю. Багаж можно добавить. Универсальный вариант, если Испания в списке желаний.",
            pricePerNight: 28_900,
            currency: "₽",
            rating: 4.4,
            reviewCount: 330,
            tags: ["город", "море", "культура"],
            amenities: ["Ручная кладь", "Выбор места"],
            imageSymbol: "airplane.departure",
            imageHue: 0.52,
            reviews: [
                Review(id: "r15", author: "Юля", rating: 4.4, text: "Утро — сразу на Рамблу. Нормальный прямой рейс.", date: "май 2026")
            ],
            budgetTier: .mid
        ),
        Offer(
            id: "tr-tuscany",
            kind: .tour,
            title: "Тоскана: вино и деревни",
            city: "Сиена",
            country: "Италия",
            countryCode: "IT",
            shortDescription: "Неделя по холмам, дегустации и медленные обеды.",
            description: "Небольшой групповой тур. Ночёвки на агротуризмах, дни без ранних подъёмов. Для гастрономии, культуры и спокойного двоих.",
            pricePerNight: 98_500,
            currency: "₽",
            rating: 4.9,
            reviewCount: 38,
            tags: ["культура", "гастрономия", "романтика", "для двоих", "комфорт"],
            amenities: ["Дегустации", "Агротуризм", "Гид", "Трансфер"],
            imageSymbol: "wineglass.fill",
            imageHue: 0.3,
            reviews: [
                Review(id: "r16", author: "Алина", rating: 5, text: "Ели больше, чем ходили. И это был план.", date: "октябрь 2025")
            ],
            budgetTier: .high
        ),
        Offer(
            id: "ht-berlin", kind: .hotel, title: "Spree Court",
            city: "Берлин", country: "Германия", countryCode: "DE",
            shortDescription: "Двор в Кройцберге, рядом с каналами.",
            description: "Городская база для музеев и вечерних районов.",
            pricePerNight: 14_200, currency: "₽", rating: 4.5, reviewCount: 410,
            tags: ["город", "культура", "выгодно"], amenities: ["Wi‑Fi", "Завтрак"],
            imageSymbol: "building.2.fill", imageHue: 0.42, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-vienna", kind: .hotel, title: "Ringgarden Hotel",
            city: "Вена", country: "Австрия", countryCode: "AT",
            shortDescription: "Тихий отель у Ринга, венский завтрак.",
            description: "Для культуры, концертов и неспешных прогулок.",
            pricePerNight: 19_800, currency: "₽", rating: 4.7, reviewCount: 288,
            tags: ["город", "культура", "комфорт", "гастрономия"], amenities: ["Завтрак", "Wi‑Fi"],
            imageSymbol: "building.columns.fill", imageHue: 0.35, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-zurich", kind: .hotel, title: "Lake Quiet Suites",
            city: "Цюрих", country: "Швейцария", countryCode: "CH",
            shortDescription: "Номера к озеру, спокойный сервис.",
            description: "Комфорт и природа рядом с городом.",
            pricePerNight: 41_200, currency: "₽", rating: 4.8, reviewCount: 156,
            tags: ["комфорт", "люкс", "природа", "релакс"], amenities: ["Вид на озеро", "Спа"],
            imageSymbol: "leaf.fill", imageHue: 0.48, reviews: [], budgetTier: .high
        ),
        Offer(
            id: "ht-london", kind: .hotel, title: "Canal House Inn",
            city: "Лондон", country: "Великобритания", countryCode: "GB",
            shortDescription: "Камерный дом у канала в Ислингтоне.",
            description: "Удобно до метро и вечерних рынков.",
            pricePerNight: 26_700, currency: "₽", rating: 4.4, reviewCount: 520,
            tags: ["город", "культура", "гастрономия"], amenities: ["Wi‑Fi", "Чай"],
            imageSymbol: "building.2.fill", imageHue: 0.55, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-prague", kind: .hotel, title: "Vltava Soft",
            city: "Прага", country: "Чехия", countryCode: "CZ",
            shortDescription: "Отель у набережной, до центра пешком.",
            description: "Выгодная городская база без шума главной площади.",
            pricePerNight: 8_900, currency: "₽", rating: 4.5, reviewCount: 670,
            tags: ["город", "бюджет", "культура", "выгодно"], amenities: ["Завтрак", "Wi‑Fi"],
            imageSymbol: "building.columns.fill", imageHue: 0.4, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-dubrovnik", kind: .hotel, title: "Walls & Sea",
            city: "Дубровник", country: "Хорватия", countryCode: "HR",
            shortDescription: "Вид на стены и Адриатику.",
            description: "Море и городские прогулки без большого курорта.",
            pricePerNight: 22_100, currency: "₽", rating: 4.6, reviewCount: 198,
            tags: ["море", "город", "романтика", "для двоих"], amenities: ["Терраса", "Завтрак"],
            imageSymbol: "water.waves", imageHue: 0.52, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-bergen", kind: .hotel, title: "Fjord Pine Lodge",
            city: "Берген", country: "Норвегия", countryCode: "NO",
            shortDescription: "Дом у фьорда, дождь и крутые улицы.",
            description: "Природа и городской старт к фьордам.",
            pricePerNight: 25_400, currency: "₽", rating: 4.6, reviewCount: 142,
            tags: ["природа", "горы", "релакс"], amenities: ["Завтрак", "Сушилка"],
            imageSymbol: "leaf.fill", imageHue: 0.45, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-reykjavik", kind: .hotel, title: "Lava Light Hotel",
            city: "Рейкьявик", country: "Исландия", countryCode: "IS",
            shortDescription: "База к водопадам и горячим источникам.",
            description: "Город маленький, природа вокруг — главное.",
            pricePerNight: 28_900, currency: "₽", rating: 4.5, reviewCount: 211,
            tags: ["природа", "приключения", "активный"], amenities: ["Завтрак", "Трансфер"],
            imageSymbol: "figure.hiking", imageHue: 0.58, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-amsterdam", kind: .hotel, title: "Gracht Studio",
            city: "Амстердам", country: "Нидерланды", countryCode: "NL",
            shortDescription: "Студии у канала, велосипеды у двери.",
            description: "Город, музеи и спокойные дворы.",
            pricePerNight: 23_100, currency: "₽", rating: 4.5, reviewCount: 390,
            tags: ["город", "культура", "комфорт"], amenities: ["Велосипед", "Wi‑Fi"],
            imageSymbol: "building.2.fill", imageHue: 0.5, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-krakow", kind: .hotel, title: "Kazimierz Yard",
            city: "Краков", country: "Польша", countryCode: "PL",
            shortDescription: "Двор в Казимеже, выгодно и вкусно.",
            description: "Бюджетный город с характером.",
            pricePerNight: 6_200, currency: "₽", rating: 4.4, reviewCount: 480,
            tags: ["город", "бюджет", "гастрономия", "выгодно"], amenities: ["Завтрак", "Wi‑Fi"],
            imageSymbol: "building.columns.fill", imageHue: 0.38, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-budapest", kind: .hotel, title: "Danube Bath Hotel",
            city: "Будапешт", country: "Венгрия", countryCode: "HU",
            shortDescription: "Отель к термам и набережной.",
            description: "Город, купальни и вечерний Дунай.",
            pricePerNight: 9_800, currency: "₽", rating: 4.6, reviewCount: 355,
            tags: ["город", "релакс", "выгодно", "комфорт"], amenities: ["Термы рядом", "Завтрак"],
            imageSymbol: "drop.fill", imageHue: 0.44, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-nyc", kind: .hotel, title: "Hudson Pocket",
            city: "Нью-Йорк", country: "США", countryCode: "US",
            shortDescription: "Компактный отель в Челси.",
            description: "Городская база без огромного лобби.",
            pricePerNight: 38_900, currency: "₽", rating: 4.3, reviewCount: 710,
            tags: ["город", "культура", "комфорт"], amenities: ["Wi‑Fi", "Кофе"],
            imageSymbol: "building.2.fill", imageHue: 0.62, reviews: [], budgetTier: .high
        ),
        Offer(
            id: "ht-cancun", kind: .hotel, title: "Laguna Family Reef",
            city: "Канкун", country: "Мексика", countryCode: "MX",
            shortDescription: "Семейный берег, мелкое море.",
            description: "Пляж, анимация без крика, удобно с детьми.",
            pricePerNight: 19_600, currency: "₽", rating: 4.5, reviewCount: 880,
            tags: ["море", "пляж", "семья", "дети"], amenities: ["Пляж", "Бассейн", "Детский клуб"],
            imageSymbol: "water.waves", imageHue: 0.5, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-rio", kind: .hotel, title: "Ipanema Soft",
            city: "Рио-де-Жанейро", country: "Бразилия", countryCode: "BR",
            shortDescription: "Квартиры-студии к Ипанеме.",
            description: "Море и город в одной прогулке.",
            pricePerNight: 17_800, currency: "₽", rating: 4.4, reviewCount: 260,
            tags: ["море", "город", "пляж"], amenities: ["Кухня", "Wi‑Fi"],
            imageSymbol: "sun.max.fill", imageHue: 0.12, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-marrakech", kind: .hotel, title: "Riad Atlas Quiet",
            city: "Марракеш", country: "Марокко", countryCode: "MA",
            shortDescription: "Риад во дворе, чай и тень.",
            description: "Культура и гастрономия без спешки.",
            pricePerNight: 11_200, currency: "₽", rating: 4.7, reviewCount: 190,
            tags: ["культура", "гастрономия", "комфорт", "романтика"], amenities: ["Двор", "Завтрак"],
            imageSymbol: "building.columns.fill", imageHue: 0.18, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-hurghada", kind: .hotel, title: "Red Sea Garden",
            city: "Хургада", country: "Египет", countryCode: "EG",
            shortDescription: "Семейный отель у рифа.",
            description: "Море, все включено, ровный сервис.",
            pricePerNight: 13_400, currency: "₽", rating: 4.4, reviewCount: 1200,
            tags: ["море", "пляж", "семья", "дети", "выгодно"], amenities: ["Риф", "Бассейн", "All inclusive"],
            imageSymbol: "water.waves", imageHue: 0.48, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-hanoi", kind: .hotel, title: "Old Quarter Pod",
            city: "Ханой", country: "Вьетнам", countryCode: "VN",
            shortDescription: "Чистый дом в старом квартале.",
            description: "Бюджетный город, еда и ночные улицы.",
            pricePerNight: 3_100, currency: "₽", rating: 4.5, reviewCount: 640,
            tags: ["город", "бюджет", "гастрономия", "приключения"], amenities: ["Wi‑Fi", "Туры"],
            imageSymbol: "building.2.fill", imageHue: 0.32, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-seoul", kind: .hotel, title: "Han River Soft",
            city: "Сеул", country: "Южная Корея", countryCode: "KR",
            shortDescription: "Отель к реке, удобно до метро.",
            description: "Город, еда и ночные районы.",
            pricePerNight: 16_800, currency: "₽", rating: 4.6, reviewCount: 430,
            tags: ["город", "гастрономия", "культура", "комфорт"], amenities: ["Завтрак", "Wi‑Fi"],
            imageSymbol: "building.2.fill", imageHue: 0.6, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-sydney", kind: .hotel, title: "Harbour Leaf",
            city: "Сидней", country: "Австралия", countryCode: "AU",
            shortDescription: "Вид к бухте, до парома 10 минут.",
            description: "Город и океан в одном маршруте.",
            pricePerNight: 27_400, currency: "₽", rating: 4.5, reviewCount: 305,
            tags: ["город", "море", "комфорт"], amenities: ["Завтрак", "Терраса"],
            imageSymbol: "water.waves", imageHue: 0.54, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "tr-srilanka", kind: .tour, title: "Шри-Ланка: чай и океан",
            city: "Канди — Мирисса", country: "Шри-Ланка", countryCode: "LK",
            shortDescription: "Холмы, поезда и несколько дней у моря.",
            description: "Небольшая группа, природа и пляж.",
            pricePerNight: 118_000, currency: "₽", rating: 4.7, reviewCount: 52,
            tags: ["природа", "море", "пляж", "релакс"], amenities: ["Гид", "Поезда", "Отели"],
            imageSymbol: "map.fill", imageHue: 0.28, reviews: [], budgetTier: .mid
        ),
        Offer(
            id: "ht-goa", kind: .hotel, title: "Palm Quiet Goa",
            city: "Северный Гоа", country: "Индия", countryCode: "IN",
            shortDescription: "Дом в пальмах, не главная тусовка.",
            description: "Море и спокойный двор за разумные деньги.",
            pricePerNight: 5_400, currency: "₽", rating: 4.3, reviewCount: 277,
            tags: ["море", "пляж", "бюджет", "релакс"], amenities: ["Двор", "Велосипед"],
            imageSymbol: "leaf.fill", imageHue: 0.3, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "ht-maldives", kind: .hotel, title: "Atoll Two Villa",
            city: "Южный Ari", country: "Мальдивы", countryCode: "MV",
            shortDescription: "Водные виллы, для двоих без анимации.",
            description: "Море, тишина, люкс без огромного острова.",
            pricePerNight: 89_000, currency: "₽", rating: 4.9, reviewCount: 94,
            tags: ["море", "пляж", "люкс", "романтика", "для двоих"], amenities: ["Вилла", "Снорклинг", "Полупансион"],
            imageSymbol: "water.waves", imageHue: 0.5, reviews: [], budgetTier: .high
        ),
        Offer(
            id: "ht-yerevan", kind: .hotel, title: "Cascade Garden",
            city: "Ереван", country: "Армения", countryCode: "AM",
            shortDescription: "Отель у Каскада, дворик и вино.",
            description: "Город, еда и короткие выезды в горы.",
            pricePerNight: 7_200, currency: "₽", rating: 4.6, reviewCount: 184,
            tags: ["город", "гастрономия", "комфорт", "выгодно"], amenities: ["Завтрак", "Двор"],
            imageSymbol: "building.columns.fill", imageHue: 0.22, reviews: [], budgetTier: .low
        ),
        Offer(
            id: "tr-serengeti", kind: .tour, title: "Танзания: сафари 7 дней",
            city: "Серенгети", country: "Танзания", countryCode: "TZ",
            shortDescription: "Лоджи и ранние выезды к стадам.",
            description: "Природа и приключения, группа до 8 человек.",
            pricePerNight: 245_000, currency: "₽", rating: 4.8, reviewCount: 29,
            tags: ["природа", "приключения", "активный"], amenities: ["Гид", "Лоджи", "Трансфер"],
            imageSymbol: "map.fill", imageHue: 0.26, reviews: [], budgetTier: .high
        )
    ]
}
