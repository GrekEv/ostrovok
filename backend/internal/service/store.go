package service

import (
	"fmt"
	"sync"
	"time"

	"ostrovok/internal/domain"
)

type Store struct {
	mu       sync.Mutex
	seq      int
	bookings []domain.Booking
	tickets  []domain.Ticket
}

func NewStore() *Store {
	return &Store{
		bookings: []domain.Booking{},
		tickets:  []domain.Ticket{},
	}
}

func (s *Store) RequestStay(
	guestID string,
	offer domain.Offer,
	kind domain.BookingKind,
	dates, note, source string,
) (domain.Booking, domain.Ticket) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now().UTC().Format(time.RFC3339)
	booking := domain.Booking{
		ID:         s.nextLocked("bkg"),
		GuestID:    guestID,
		OfferID:    offer.ID,
		OfferTitle: offer.Title,
		Kind:       kind,
		Status:     domain.BookingRequested,
		Dates:      dates,
		Note:       note,
		CreatedAt:  now,
	}
	ticket := domain.Ticket{
		ID:        s.nextLocked("tkt"),
		GuestID:   guestID,
		Source:    source,
		Note:      noteForStay(kind, offer.Title, note),
		OfferIDs:  []string{offer.ID},
		BookingID: booking.ID,
		Status:    "open",
		CreatedAt: now,
	}
	s.bookings = append(s.bookings, booking)
	s.tickets = append(s.tickets, ticket)
	return booking, ticket
}

func (s *Store) CallManager(guestID, note, source string, offerIDs []string) domain.Ticket {
	s.mu.Lock()
	defer s.mu.Unlock()

	if offerIDs == nil {
		offerIDs = []string{}
	}
	copied := make([]string, len(offerIDs))
	copy(copied, offerIDs)
	if note == "" {
		note = "Гость просит живого менеджера."
	}
	ticket := domain.Ticket{
		ID:        s.nextLocked("tkt"),
		GuestID:   guestID,
		Source:    source,
		Note:      note,
		OfferIDs:  copied,
		Status:    "open",
		CreatedAt: time.Now().UTC().Format(time.RFC3339),
	}
	s.tickets = append(s.tickets, ticket)
	return ticket
}

func (s *Store) Bookings(guestID string) []domain.Booking {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]domain.Booking, 0)
	for _, item := range s.bookings {
		if guestID == "" || item.GuestID == guestID {
			out = append(out, item)
		}
	}
	return out
}

func (s *Store) Tickets(guestID string) []domain.Ticket {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]domain.Ticket, 0)
	for _, item := range s.tickets {
		if guestID == "" || item.GuestID == guestID {
			cloned := item
			cloned.OfferIDs = append([]string{}, item.OfferIDs...)
			out = append(out, cloned)
		}
	}
	return out
}

func (s *Store) nextLocked(prefix string) string {
	s.seq++
	return fmt.Sprintf("%s-%d", prefix, s.seq)
}

func noteForStay(kind domain.BookingKind, title, note string) string {
	prefix := "Заявка на бронь"
	if kind == domain.BookingDelayed {
		prefix = "Отложенная бронь"
	}
	text := prefix + " «" + title + "»"
	if note != "" {
		return text + ". " + note
	}
	return text
}
