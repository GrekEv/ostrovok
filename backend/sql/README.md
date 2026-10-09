# SQL аналитики Ольги

Файлы из https://github.com/Olga1998-power/Ostrovok/tree/main/analytics

- `init.sql` и `mock_data.sql` — без правок, как в её репозитории.
- `recommendations.sql` — эталон алгоритма лайков по JSONB-тегам; в Go он параметризован в `internal/store/postgres.go`.
- `02b-local-photos.sql` — подмена `https://unsplash.com` на фото `/static/places`.
- `03-app_extras.sql` — заявки и онбординг, поверх её схемы.

Пересоздать базу после смены SQL:

```bash
docker compose down -v
docker compose up --build
```
