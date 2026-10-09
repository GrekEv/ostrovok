TRUNCATE TABLE user_swipes, travel_cards CASCADE;

INSERT INTO travel_cards (id, type, name, country, city, price, rating, image_url, amenities, ai_summary, search_vector) VALUES
(1, 'hotel', 'Отель Астория', 'Россия', 'Санкт-Петербург', 12500.00, 4.9, 
 '/static/places/ht-florence.jpg', 
 '["spa", "pool", "luxury", "center"]'::jsonb, 
 'Вид на Исаакиевский собор, сильный сервис и спа. Завтраки дорогие.',
 to_tsvector('russian', 'Санкт-Петербург отель астория вид на собор спа бассейн люкс центр')),

(2, 'hotel', 'Сочи Парк Отель', 'Россия', 'Сочи', 5400.00, 4.5, 
 '/static/places/ht-dubai.jpg', 
 '["pool", "beach", "family", "all_inclusive"]'::jsonb, 
 'Большая территория, удобно с детьми, море рядом. Иногда очередь на ресепшн.',
 to_tsvector('russian', 'Сочи парк отель море пляж бассейн дети семейный отдых анимация всё включено')),

(3, 'tour', 'Выходные в горах Красной Поляны', 'Россия', 'Сочи', 18900.00, 4.8, 
 '/static/places/tr-alps.jpg', 
 '["mountains", "active", "nature"]'::jsonb, 
 'Трансфер, гид и подъёмники. Виды на хребты, нагрузка высокая.',
 to_tsvector('russian', 'Сочи тур горы красная поляна активный отдых природа гид экскурсия')),

(4, 'hostel', 'Хостел Друзья', 'Россия', 'Санкт-Петербург', 1500.00, 4.2, 
 '/static/places/hs-barcelona.jpg', 
 '["center", "budget", "kitchen"]'::jsonb, 
 'Недорого, центр Петербурга, общая кухня. Тонкие стены и общая ванная.',
 to_tsvector('russian', 'Санкт-Петербург хостел друзья дешево недорого бюджетно центр кухня общая')),

(5, 'tour', 'Weekend на глэмпинге', 'Россия', 'Москва', 14000.00, 4.7, 
 '/static/places/tr-bali.jpg', 
 '["nature", "pet_friendly", "romantic"]'::jsonb, 
 'Домики-сферы в лесу, костёр и барбекю. Без машины добираться сложно.',
 to_tsvector('russian', 'Москва подмосковье тур глэмпинг природа тишина романтика отдых домики животные'));

SELECT setval(pg_get_serial_sequence('travel_cards', 'id'), COALESCE(MAX(id), 1)) FROM travel_cards;
