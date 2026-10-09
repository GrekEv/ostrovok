package store

import (
	"context"
	"strings"

	"ostrovok/internal/catalog"
	"ostrovok/internal/domain"
	"ostrovok/internal/recommend"
	"ostrovok/internal/service"
)

type Memory struct {
	engine recommend.Engine
	inner  *service.Store
	swipes map[string][]domain.Swipe
	prefs  map[string]domain.Preferences
}

func NewMemory() *Memory {
	return &Memory{
		inner:  service.NewStore(),
		swipes: map[string][]domain.Swipe{},
		prefs:  map[string]domain.Preferences{},
	}
}

func (m *Memory) Ping(context.Context) error { return nil }

func (m *Memory) Cards(context.Context) ([]domain.Offer, error) {
	return catalog.Offers(), nil
}

func (m *Memory) Card(_ context.Context, id string) (domain.Offer, bool, error) {
	offer, ok := catalog.ByID(id)
	return offer, ok, nil
}

func (m *Memory) Rank(_ context.Context, guestID string, prefs domain.Preferences) ([]domain.Offer, error) {
	if stored, ok := m.prefs[guestID]; ok {
		prefs = stored
	}
	return m.engine.Rank(catalog.Offers(), prefs, m.swipes[guestID]), nil
}

func (m *Memory) SaveSwipe(_ context.Context, swipe domain.Swipe) error {
	guest := swipe.GuestID
	list := m.swipes[guest]
	for i, item := range list {
		if item.OfferID == swipe.OfferID {
			list[i] = swipe
			m.swipes[guest] = list
			return nil
		}
	}
	m.swipes[guest] = append(list, swipe)
	return nil
}

func (m *Memory) Liked(_ context.Context, guestID string) ([]domain.Offer, error) {
	out := make([]domain.Offer, 0)
	for i := len(m.swipes[guestID]) - 1; i >= 0; i-- {
		swipe := m.swipes[guestID][i]
		if !swipe.Liked {
			continue
		}
		if offer, ok := catalog.ByID(swipe.OfferID); ok {
			out = append(out, offer)
		}
	}
	return out, nil
}

func (m *Memory) DeleteLike(_ context.Context, guestID, offerID string) error {
	list := m.swipes[guestID]
	next := list[:0]
	for _, swipe := range list {
		if swipe.OfferID == offerID && swipe.Liked {
			continue
		}
		next = append(next, swipe)
	}
	m.swipes[guestID] = next
	return nil
}

func (m *Memory) SwipeCounts(_ context.Context, guestID string) (int, int, error) {
	likes := 0
	for _, swipe := range m.swipes[guestID] {
		if swipe.Liked {
			likes++
		}
	}
	return likes, len(m.swipes[guestID]), nil
}

func (m *Memory) Search(_ context.Context, city string, maxPrice int) ([]domain.Offer, error) {
	needle := strings.ToLower(strings.TrimSpace(city))
	out := make([]domain.Offer, 0)
	for _, offer := range catalog.Offers() {
		if needle != "" &&
			!strings.Contains(strings.ToLower(offer.City), needle) &&
			!strings.Contains(strings.ToLower(offer.Country), needle) {
			continue
		}
		if maxPrice > 0 && offer.Price > maxPrice {
			continue
		}
		out = append(out, offer)
	}
	return out, nil
}

func (m *Memory) SavePreferences(_ context.Context, guestID string, prefs domain.Preferences) error {
	m.prefs[guestID] = prefs
	return nil
}

func (m *Memory) RequestStay(guestID string, offer domain.Offer, kind domain.BookingKind, dates, note, source string) (domain.Booking, domain.Ticket) {
	return m.inner.RequestStay(guestID, offer, kind, dates, note, source)
}

func (m *Memory) CallManager(guestID, note, source string, offerIDs []string) domain.Ticket {
	return m.inner.CallManager(guestID, note, source, offerIDs)
}

func (m *Memory) Bookings(guestID string) []domain.Booking { return m.inner.Bookings(guestID) }

func (m *Memory) Tickets(guestID string) []domain.Ticket { return m.inner.Tickets(guestID) }
