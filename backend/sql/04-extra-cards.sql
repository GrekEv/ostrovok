INSERT INTO travel_cards (type, name, country, city, price, rating, image_url, amenities, ai_summary, search_vector) VALUES
('hostel', 'River Pod Hostel', 'Таиланд', 'Бангкок', 2400.00, 4.6,
 '/static/places/hs-bangkok.jpg',
 '["center","budget","kitchen"]'::jsonb,
 'Чисто, дёшево, удобно до реки и ночных рынков. Минус — шум вечером.',
 to_tsvector('russian', 'Бангкок Таиланд хостел река бюджет кухня город')),

('hotel', 'Galata Soft', 'Турция', 'Стамбул', 11400.00, 4.5,
 '/static/places/ht-istanbul.jpg',
 '["center","spa","luxury"]'::jsonb,
 'Сытный завтрак, удобно до трамвая, крыша со видом на залив.',
 to_tsvector('russian', 'Стамбул Турция отель Галата крыша завтрак город')),

('hotel', 'Bay Pine Hotel', 'Черногория', 'Котор', 9800.00, 4.6,
 '/static/places/ht-kotor.jpg',
 '["beach","nature","romantic"]'::jsonb,
 'Тихо, сосны, лодка до Пераста без суеты большого отеля.',
 to_tsvector('russian', 'Котор Черногория отель бухта пляж природа романтика')),

('flight', 'Москва — Токио', 'Япония', 'Токио', 52400.00, 4.5,
 '/static/places/fl-tokyo.jpg',
 '["center","active"]'::jsonb,
 'Удобное утро в городе, питание на борту без сюрпризов.',
 to_tsvector('russian', 'Токио Япония перелёт авиа рейс Москва')),

('flight', 'Москва — Барселона', 'Испания', 'Барселона', 28900.00, 4.4,
 '/static/places/fl-barcelona.jpg',
 '["center","beach"]'::jsonb,
 'Утренний прилёт — сразу на Рамблу.',
 to_tsvector('russian', 'Барселона Испания перелёт авиа рейс Москва море')),

('tour', 'Тоскана: вино и деревни', 'Италия', 'Сиена', 98500.00, 4.9,
 '/static/places/tr-tuscany.jpg',
 '["romantic","luxury","nature"]'::jsonb,
 'Ели больше, чем ходили — и это был план. Медленные обеды и холмы.',
 to_tsvector('russian', 'Сиена Тоскана Италия тур вино деревни романтика')),

('hotel', 'Кахетия Yard', 'Грузия', 'Сигнахи', 6100.00, 4.7,
 '/static/places/mt-tbilisi.jpg',
 '["nature","romantic","center"]'::jsonb,
 'Двор, вино, вид на Алазанскую долину. Спокойная база без туристического шума.',
 to_tsvector('russian', 'Сигнахи Грузия отель Кахетия вино двор природа')),

('hotel', 'Oia White Court', 'Греция', 'Ойя', 27400.00, 4.8,
 '/static/places/ht-santorini.jpg',
 '["beach","romantic","luxury","spa"]'::jsonb,
 'Закат стоит очереди, завтрак на террасе, для двоих без анимации.',
 to_tsvector('russian', 'Ойя Санторини Греция отель закат море люкс романтика')),

('hotel', 'Ribeira Light', 'Португалия', 'Порту', 16200.00, 4.7,
 '/static/places/ht-porto.jpg',
 '["center","romantic"]'::jsonb,
 'Вид на Дору и спокойный завтрак, до центра пешком.',
 to_tsvector('russian', 'Порту Португалия отель набережная портвейн город')),

('hotel', 'Casa Verde Florence', 'Италия', 'Флоренция', 18900.00, 4.8,
 '/static/places/ht-florence.jpg',
 '["center","luxury","spa"]'::jsonb,
 'Тихий двор в пяти минутах от Дуомо, сильный завтрак, номера без лишнего декора.',
 to_tsvector('russian', 'Флоренция Италия отель Дуомо двор завтрак город люкс')),

('hotel', 'Red Sea Garden', 'Египет', 'Хургада', 13400.00, 4.4,
 '/static/places/ht-dubai.jpg',
 '["beach","family","pool","all_inclusive"]'::jsonb,
 'Риф рядом, детям бассейн, еда стабильная на все включено.',
 to_tsvector('russian', 'Хургада Египет отель море пляж семья бассейн всё включено')),

('hotel', 'Cascade Garden', 'Армения', 'Ереван', 7200.00, 4.6,
 '/static/places/hs-barcelona.jpg',
 '["center","budget"]'::jsonb,
 'Двор, вино, удобно гулять до Каскада.',
 to_tsvector('russian', 'Ереван Армения отель Каскад двор город бюджет'));

SELECT setval(pg_get_serial_sequence('travel_cards', 'id'), COALESCE((SELECT MAX(id) FROM travel_cards), 1));
