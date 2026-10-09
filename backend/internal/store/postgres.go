package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/lib/pq"

	"ostrovok/internal/domain"
)

type Postgres struct {
	db *sql.DB
}

func Open(ctx context.Context, url string) (*Postgres, error) {
	db, err := sql.Open("postgres", url)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(8)
	db.SetMaxIdleConns(4)
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)
	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}
	return &Postgres{db: db}, nil
}

func (p *Postgres) Close() error { return p.db.Close() }

func (p *Postgres) Ping(ctx context.Context) error { return p.db.PingContext(ctx) }

func (p *Postgres) Cards(ctx context.Context) ([]domain.Offer, error) {
	return p.queryCards(ctx, `SELECT `+olgaColumns+` FROM travel_cards ORDER BY rating DESC`, nil)
}

func (p *Postgres) Card(ctx context.Context, id string) (domain.Offer, bool, error) {
	cardID, err := strconv.Atoi(id)
	if err != nil {
		return domain.Offer{}, false, nil
	}
	items, err := p.queryCards(ctx, `SELECT `+olgaColumns+` FROM travel_cards WHERE id = $1`, []any{cardID})
	if err != nil || len(items) == 0 {
		return domain.Offer{}, false, err
	}
	return items[0], true, nil
}

func (p *Postgres) Rank(ctx context.Context, guestID string, prefs domain.Preferences) ([]domain.Offer, error) {
	if stored, err := p.loadPrefs(ctx, guestID); err == nil {
		prefs = stored
	}
	countries := countryNames(prefs.CountryCodes)
	tags := amenityTags(prefs.PriorityIDs)
	query := `
WITH user_favorite_tags AS (
    SELECT jsonb_array_elements_text(tc.amenities) AS tag,
           COUNT(*) AS tag_weight
    FROM user_swipes us
    JOIN travel_cards tc ON us.card_id = tc.id
    WHERE us.user_id = $1 AND us.action = 'like'
    GROUP BY tag
)
SELECT ` + olgaColumnsPrefixed + `,
       COALESCE(SUM(uft.tag_weight), 0)
       + CASE WHEN cardinality($3::text[]) > 0 AND tc.amenities ?| $3 THEN 2 ELSE 0 END
       + CASE WHEN cardinality($2::text[]) > 0 AND tc.country = ANY($2) THEN 2.5 ELSE 0 END
       AS relevance_score
FROM travel_cards tc
LEFT JOIN user_favorite_tags uft ON tc.amenities ? uft.tag
WHERE tc.id NOT IN (SELECT card_id FROM user_swipes WHERE user_id = $1)
  AND (cardinality($2::text[]) = 0 OR tc.country = ANY($2))
GROUP BY tc.id
ORDER BY relevance_score DESC, tc.rating DESC
LIMIT 24`

	rows, err := p.db.QueryContext(ctx, query, guestID, pq.Array(countries), pq.Array(tags))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]domain.Offer, 0)
	for rows.Next() {
		offer, score, err := scanOlgaRanked(rows)
		if err != nil {
			return nil, err
		}
		offer.WhyRecommended = explainOlga(offer, score, prefs)
		out = append(out, offer)
	}
	return out, rows.Err()
}

func (p *Postgres) SaveSwipe(ctx context.Context, swipe domain.Swipe) error {
	cardID, err := strconv.Atoi(swipe.OfferID)
	if err != nil {
		return fmt.Errorf("card_id: %w", err)
	}
	action := "dislike"
	if swipe.Liked {
		action = "like"
	}
	_, err = p.db.ExecContext(ctx, `
INSERT INTO user_swipes (user_id, card_id, action)
VALUES ($1, $2, $3)
ON CONFLICT (user_id, card_id) DO UPDATE SET
    action = EXCLUDED.action,
    created_at = CURRENT_TIMESTAMP`, swipe.GuestID, cardID, action)
	return err
}

func (p *Postgres) Liked(ctx context.Context, guestID string) ([]domain.Offer, error) {
	return p.queryCards(ctx, `
SELECT `+olgaColumnsPrefixed+`
FROM travel_cards tc
JOIN user_swipes us ON us.card_id = tc.id
WHERE us.user_id = $1 AND us.action = 'like'
ORDER BY us.created_at DESC`, []any{guestID})
}

func (p *Postgres) DeleteLike(ctx context.Context, guestID, offerID string) error {
	cardID, err := strconv.Atoi(offerID)
	if err != nil {
		return fmt.Errorf("card_id: %w", err)
	}
	_, err = p.db.ExecContext(ctx, `
DELETE FROM user_swipes WHERE user_id = $1 AND card_id = $2 AND action = 'like'`, guestID, cardID)
	return err
}

func (p *Postgres) SwipeCounts(ctx context.Context, guestID string) (int, int, error) {
	var likes, total int
	err := p.db.QueryRowContext(ctx, `
SELECT COUNT(*) FILTER (WHERE action = 'like'), COUNT(*)
FROM user_swipes WHERE user_id = $1`, guestID).Scan(&likes, &total)
	return likes, total, err
}

func (p *Postgres) Search(ctx context.Context, city string, maxPrice int) ([]domain.Offer, error) {
	needle := strings.TrimSpace(city)
	if maxPrice <= 0 {
		maxPrice = 1_000_000_000
	}
	return p.queryCards(ctx, `
SELECT `+olgaColumns+`
FROM travel_cards
WHERE ($1 = '' OR city ILIKE '%' || $1 || '%' OR country ILIKE '%' || $1 || '%'
        OR name ILIKE '%' || $1 || '%'
        OR ($1 <> '' AND search_vector @@ plainto_tsquery('russian', $1)))
  AND price <= $2
ORDER BY rating DESC
LIMIT 8`, []any{needle, maxPrice})
}

func (p *Postgres) SavePreferences(ctx context.Context, guestID string, prefs domain.Preferences) error {
	_, err := p.db.ExecContext(ctx, `
INSERT INTO user_preferences (guest_id, country_codes, priority_ids, skipped, updated_at)
VALUES ($1, $2, $3, $4, now())
ON CONFLICT (guest_id) DO UPDATE SET
    country_codes = EXCLUDED.country_codes,
    priority_ids = EXCLUDED.priority_ids,
    skipped = EXCLUDED.skipped,
    updated_at = now()`,
		guestID, pq.Array(prefs.CountryCodes), pq.Array(prefs.PriorityIDs), prefs.Skipped)
	return err
}

func (p *Postgres) RequestStay(guestID string, offer domain.Offer, kind domain.BookingKind, dates, note, source string) (domain.Booking, domain.Ticket) {
	ctx := context.Background()
	now := time.Now().UTC().Format(time.RFC3339)
	booking := domain.Booking{
		ID: p.nextID(ctx, "bkg"), GuestID: guestID, OfferID: offer.ID, OfferTitle: offer.Title,
		Kind: kind, Status: domain.BookingRequested, Dates: dates, Note: note, CreatedAt: now,
	}
	ticketNote := "Заявка на бронь «" + offer.Title + "»"
	if kind == domain.BookingDelayed {
		ticketNote = "Отложенная бронь «" + offer.Title + "»"
	}
	if note != "" {
		ticketNote += ". " + note
	}
	ticket := domain.Ticket{
		ID: p.nextID(ctx, "tkt"), GuestID: guestID, Source: source, Note: ticketNote,
		OfferIDs: []string{offer.ID}, BookingID: booking.ID, Status: "open", CreatedAt: now,
	}
	_, _ = p.db.ExecContext(ctx, `
INSERT INTO bookings (id, guest_id, offer_id, offer_title, kind, status, dates, note, created_at)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
		booking.ID, booking.GuestID, booking.OfferID, booking.OfferTitle, string(booking.Kind),
		string(booking.Status), booking.Dates, booking.Note, booking.CreatedAt)
	_, _ = p.db.ExecContext(ctx, `
INSERT INTO tickets (id, guest_id, source, note, offer_ids, booking_id, status, created_at)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
		ticket.ID, ticket.GuestID, ticket.Source, ticket.Note, pq.Array(ticket.OfferIDs),
		ticket.BookingID, ticket.Status, ticket.CreatedAt)
	return booking, ticket
}

func (p *Postgres) CallManager(guestID, note, source string, offerIDs []string) domain.Ticket {
	ctx := context.Background()
	if offerIDs == nil {
		offerIDs = []string{}
	}
	if note == "" {
		note = "Гость просит живого менеджера."
	}
	ticket := domain.Ticket{
		ID: p.nextID(ctx, "tkt"), GuestID: guestID, Source: source, Note: note,
		OfferIDs: append([]string{}, offerIDs...), Status: "open",
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	}
	_, _ = p.db.ExecContext(ctx, `
INSERT INTO tickets (id, guest_id, source, note, offer_ids, booking_id, status, created_at)
VALUES ($1,$2,$3,$4,$5,NULL,$6,$7)`,
		ticket.ID, ticket.GuestID, ticket.Source, ticket.Note, pq.Array(ticket.OfferIDs),
		ticket.Status, ticket.CreatedAt)
	return ticket
}

func (p *Postgres) Bookings(guestID string) []domain.Booking {
	rows, err := p.db.Query(`
SELECT id, guest_id, offer_id, offer_title, kind, status, dates, note, created_at
FROM bookings WHERE $1 = '' OR guest_id = $1 ORDER BY created_at`, guestID)
	if err != nil {
		return nil
	}
	defer rows.Close()
	out := make([]domain.Booking, 0)
	for rows.Next() {
		var item domain.Booking
		var kind, status string
		if err := rows.Scan(&item.ID, &item.GuestID, &item.OfferID, &item.OfferTitle,
			&kind, &status, &item.Dates, &item.Note, &item.CreatedAt); err != nil {
			return out
		}
		item.Kind = domain.BookingKind(kind)
		item.Status = domain.BookingStatus(status)
		out = append(out, item)
	}
	return out
}

func (p *Postgres) Tickets(guestID string) []domain.Ticket {
	rows, err := p.db.Query(`
SELECT id, guest_id, source, note, offer_ids, COALESCE(booking_id, ''), status, created_at
FROM tickets WHERE $1 = '' OR guest_id = $1 ORDER BY created_at`, guestID)
	if err != nil {
		return nil
	}
	defer rows.Close()
	out := make([]domain.Ticket, 0)
	for rows.Next() {
		var item domain.Ticket
		if err := rows.Scan(&item.ID, &item.GuestID, &item.Source, &item.Note,
			pq.Array(&item.OfferIDs), &item.BookingID, &item.Status, &item.CreatedAt); err != nil {
			return out
		}
		out = append(out, item)
	}
	return out
}

func (p *Postgres) loadPrefs(ctx context.Context, guestID string) (domain.Preferences, error) {
	var prefs domain.Preferences
	err := p.db.QueryRowContext(ctx, `
SELECT country_codes, priority_ids, skipped FROM user_preferences WHERE guest_id = $1`, guestID).
		Scan(pq.Array(&prefs.CountryCodes), pq.Array(&prefs.PriorityIDs), &prefs.Skipped)
	return prefs, err
}

func (p *Postgres) nextID(ctx context.Context, prefix string) string {
	var n int
	_ = p.db.QueryRowContext(ctx, `SELECT nextval('ostrovok_id_seq')`).Scan(&n)
	return fmt.Sprintf("%s-%d", prefix, n)
}

func (p *Postgres) queryCards(ctx context.Context, query string, args []any) ([]domain.Offer, error) {
	rows, err := p.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]domain.Offer, 0)
	for rows.Next() {
		offer, err := scanOlgaCard(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, offer)
	}
	return out, rows.Err()
}

const olgaColumns = `id, type, name, country, city, price, rating, image_url, amenities, COALESCE(ai_summary, '')`
const olgaColumnsPrefixed = `tc.id, tc.type, tc.name, tc.country, tc.city, tc.price, tc.rating, tc.image_url, tc.amenities, COALESCE(tc.ai_summary, '')`

type scanner interface {
	Scan(dest ...any) error
}

func scanOlgaCard(row scanner) (domain.Offer, error) {
	var (
		id      int
		kind    string
		price   float64
		rating  float64
		rawJSON []byte
		summary string
		offer   domain.Offer
	)
	if err := row.Scan(&id, &kind, &offer.Title, &offer.Country, &offer.City, &price, &rating,
		&offer.ImageURL, &rawJSON, &summary); err != nil {
		return domain.Offer{}, err
	}
	return mapOlgaCard(id, kind, price, rating, rawJSON, summary, offer), nil
}

func scanOlgaRanked(row scanner) (domain.Offer, float64, error) {
	var (
		id      int
		kind    string
		price   float64
		rating  float64
		score   float64
		rawJSON []byte
		summary string
		offer   domain.Offer
	)
	if err := row.Scan(&id, &kind, &offer.Title, &offer.Country, &offer.City, &price, &rating,
		&offer.ImageURL, &rawJSON, &summary, &score); err != nil {
		return domain.Offer{}, 0, err
	}
	return mapOlgaCard(id, kind, price, rating, rawJSON, summary, offer), score, nil
}

func mapOlgaCard(id int, kind string, price, rating float64, rawJSON []byte, summary string, offer domain.Offer) domain.Offer {
	offer.ID = strconv.Itoa(id)
	offer.Kind = domain.Kind(kind)
	offer.Price = int(price)
	offer.Rating = rating
	offer.Currency = "₽"
	offer.CountryCode = countryCode(offer.Country)
	offer.ShortDescription = summary
	offer.Description = summary
	offer.ImageURL = localPhoto(id, offer.ImageURL)
	var tags []string
	_ = json.Unmarshal(rawJSON, &tags)
	offer.Tags = tags
	offer.Amenities = tags
	offer.Budget = budgetFrom(price, tags)
	if summary != "" {
		offer.Reviews = []domain.Review{{
			ID: "ai-summary", Author: "ИИ", Rating: rating, Text: summary, Date: "сводка отзывов",
		}}
		offer.ReviewCount = 1
	}
	return offer
}

var photosByID = []string{
	"/static/places/ht-florence.jpg",
	"/static/places/ht-dubai.jpg",
	"/static/places/tr-alps.jpg",
	"/static/places/hs-barcelona.jpg",
	"/static/places/tr-bali.jpg",
	"/static/places/hs-bangkok.jpg",
	"/static/places/ht-istanbul.jpg",
	"/static/places/ht-kotor.jpg",
	"/static/places/fl-tokyo.jpg",
	"/static/places/fl-barcelona.jpg",
	"/static/places/tr-tuscany.jpg",
	"/static/places/mt-tbilisi.jpg",
	"/static/places/ht-santorini.jpg",
	"/static/places/ht-porto.jpg",
}

func localPhoto(id int, url string) string {
	if strings.Contains(url, "/static/places/") && !strings.Contains(strings.ToLower(url), "unsplash") {
		return url
	}
	if id > 0 {
		return photosByID[(id-1)%len(photosByID)]
	}
	if url == "" || strings.Contains(strings.ToLower(url), "unsplash") {
		return photosByID[0]
	}
	return url
}

var countryByName = map[string]string{
	"Россия": "RU", "Турция": "TR", "ОАЭ": "AE", "Таиланд": "TH", "Италия": "IT",
	"Португалия": "PT", "Испания": "ES", "Франция": "FR", "Япония": "JP",
	"Черногория": "ME", "Грузия": "GE", "Греция": "GR", "Египет": "EG",
	"Армения": "AM", "Германия": "DE", "Чехия": "CZ", "Индонезия": "ID",
	"Мальдивы": "MV",
}

func countryCode(name string) string {
	return countryByName[name]
}

func countryNames(codes []string) []string {
	out := make([]string, 0, len(codes))
	for _, code := range codes {
		for name, mapped := range countryByName {
			if mapped == code {
				out = append(out, name)
				break
			}
		}
	}
	return out
}

func amenityTags(priorityIDs []string) []string {
	mapping := map[string][]string{
		"sea":       {"beach", "pool"},
		"city":      {"center"},
		"nature":    {"nature", "mountains"},
		"budget":    {"budget"},
		"comfort":   {"luxury", "spa"},
		"family":    {"family"},
		"romance":   {"romantic"},
		"adventure": {"active", "mountains"},
	}
	seen := map[string]bool{}
	out := make([]string, 0)
	for _, id := range priorityIDs {
		for _, tag := range mapping[id] {
			if !seen[tag] {
				seen[tag] = true
				out = append(out, tag)
			}
		}
	}
	return out
}

func budgetFrom(price float64, tags []string) domain.Budget {
	for _, tag := range tags {
		if tag == "budget" {
			return domain.BudgetLow
		}
		if tag == "luxury" {
			return domain.BudgetHigh
		}
	}
	switch {
	case price < 4000:
		return domain.BudgetLow
	case price < 16000:
		return domain.BudgetMid
	default:
		return domain.BudgetHigh
	}
}

func explainOlga(offer domain.Offer, score float64, prefs domain.Preferences) string {
	if score >= 1 {
		hits := offer.Tags
		if len(hits) > 3 {
			hits = hits[:3]
		}
		return "ИИ: теги из ваших лайков в PostgreSQL — " + strings.Join(hits, ", ") + "."
	}
	for _, code := range prefs.CountryCodes {
		if code == offer.CountryCode {
			return "ИИ: страна из онбординга, рейтинг " + fmt.Sprintf("%.1f", offer.Rating) + "."
		}
	}
	return "ИИ: следующая карточка после пересчёта тегов в PostgreSQL."
}
