package store

import (
	"context"

	"ostrovok/internal/domain"
)

type Store interface {
	Ping(ctx context.Context) error
	Cards(ctx context.Context) ([]domain.Offer, error)
	Card(ctx context.Context, id string) (domain.Offer, bool, error)
	Rank(ctx context.Context, guestID string, prefs domain.Preferences) ([]domain.Offer, error)
	SaveSwipe(ctx context.Context, swipe domain.Swipe) error
	Liked(ctx context.Context, guestID string) ([]domain.Offer, error)
	DeleteLike(ctx context.Context, guestID, offerID string) error
	SwipeCounts(ctx context.Context, guestID string) (likes, swipes int, err error)
	Search(ctx context.Context, city string, maxPrice int) ([]domain.Offer, error)
	SavePreferences(ctx context.Context, guestID string, prefs domain.Preferences) error
	RequestStay(guestID string, offer domain.Offer, kind domain.BookingKind, dates, note, source string) (domain.Booking, domain.Ticket)
	CallManager(guestID, note, source string, offerIDs []string) domain.Ticket
	Bookings(guestID string) []domain.Booking
	Tickets(guestID string) []domain.Ticket
}
