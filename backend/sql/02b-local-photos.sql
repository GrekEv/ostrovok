-- На случай старого датасета с https://unsplash.com — прямые локальные фото.
UPDATE travel_cards SET image_url = '/static/places/ht-florence.jpg' WHERE id = 1;
UPDATE travel_cards SET image_url = '/static/places/ht-dubai.jpg' WHERE id = 2;
UPDATE travel_cards SET image_url = '/static/places/tr-alps.jpg' WHERE id = 3;
UPDATE travel_cards SET image_url = '/static/places/hs-barcelona.jpg' WHERE id = 4;
UPDATE travel_cards SET image_url = '/static/places/tr-bali.jpg' WHERE id = 5;
UPDATE travel_cards
SET image_url = '/static/places/ht-porto.jpg'
WHERE image_url ILIKE '%unsplash%' AND id > 5;
