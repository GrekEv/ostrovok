# SQL

- `init.sql` — `travel_cards`, `user_swipes`
- `mock_data.sql` — стартовый каталог
- `02b-local-photos.sql` — локальные фото `/static/places`
- `03-app_extras.sql` — сохранённое, брони, онбординг
- `04-extra-cards.sql` — дополнительные карточки
- `recommendations.sql` — пример ранжирования по лайкам

Пересоздать базу:

```bash
docker compose down -v
docker compose up --build
```
