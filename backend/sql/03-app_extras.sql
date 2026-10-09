-- Заявки приложения. Схему карточек и свайпов не трогает.
CREATE TABLE IF NOT EXISTS user_preferences (
    guest_id TEXT PRIMARY KEY,
    country_codes TEXT[] NOT NULL DEFAULT '{}',
    priority_ids TEXT[] NOT NULL DEFAULT '{}',
    skipped BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bookings (
    id TEXT PRIMARY KEY,
    guest_id TEXT NOT NULL,
    offer_id TEXT NOT NULL,
    offer_title TEXT NOT NULL,
    kind TEXT NOT NULL,
    status TEXT NOT NULL,
    dates TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tickets (
    id TEXT PRIMARY KEY,
    guest_id TEXT NOT NULL,
    source TEXT NOT NULL,
    note TEXT NOT NULL,
    offer_ids TEXT[] NOT NULL DEFAULT '{}',
    booking_id TEXT,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS ostrovok_id_seq START 1;
