CREATE TABLE IF NOT EXISTS travel_cards (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    rating NUMERIC(3, 1) NOT NULL,
    image_url TEXT NOT NULL,
    amenities JSONB DEFAULT '[]'::jsonb,
    ai_summary TEXT,
    search_vector tsvector
);

CREATE INDEX IF NOT EXISTS travel_cards_search_idx ON travel_cards USING gin(search_vector);
CREATE INDEX IF NOT EXISTS travel_cards_amenities_idx ON travel_cards USING gin(amenities);

CREATE TABLE IF NOT EXISTS user_swipes (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    card_id INT NOT NULL REFERENCES travel_cards(id) ON DELETE CASCADE,
    action VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS user_swipes_user_idx ON user_swipes(user_id);
