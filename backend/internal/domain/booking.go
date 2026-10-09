package domain

type BookingKind string

const (
	BookingNow     BookingKind = "booking"
	BookingDelayed BookingKind = "delayed"
)

type BookingStatus string

const (
	BookingRequested BookingStatus = "requested"
)

type Booking struct {
	ID         string        `json:"id"`
	GuestID    string        `json:"guestId"`
	OfferID    string        `json:"offerId"`
	OfferTitle string        `json:"offerTitle"`
	Kind       BookingKind   `json:"kind"`
	Status     BookingStatus `json:"status"`
	Dates      string        `json:"dates"`
	Note       string        `json:"note"`
	CreatedAt  string        `json:"createdAt"`
}

type Ticket struct {
	ID        string   `json:"id"`
	GuestID   string   `json:"guestId"`
	Source    string   `json:"source"`
	Note      string   `json:"note"`
	OfferIDs  []string `json:"offerIds"`
	BookingID string   `json:"bookingId,omitempty"`
	Status    string   `json:"status"`
	CreatedAt string   `json:"createdAt"`
}
