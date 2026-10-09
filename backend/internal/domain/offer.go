package domain

type Kind string

const (
	KindHotel  Kind = "hotel"
	KindMotel  Kind = "motel"
	KindHostel Kind = "hostel"
	KindTour   Kind = "tour"
	KindFlight Kind = "flight"
)

type Budget string

const (
	BudgetLow  Budget = "low"
	BudgetMid  Budget = "mid"
	BudgetHigh Budget = "high"
)

type Review struct {
	ID     string  `json:"id"`
	Author string  `json:"author"`
	Rating float64 `json:"rating"`
	Text   string  `json:"text"`
	Date   string  `json:"date"`
}

type Offer struct {
	ID               string   `json:"id"`
	Kind             Kind     `json:"kind"`
	Title            string   `json:"title"`
	City             string   `json:"city"`
	Country          string   `json:"country"`
	CountryCode      string   `json:"countryCode"`
	ShortDescription string   `json:"shortDescription"`
	Description      string   `json:"description"`
	Price            int      `json:"pricePerNight"`
	Currency         string   `json:"currency"`
	Rating           float64  `json:"rating"`
	ReviewCount      int      `json:"reviewCount"`
	Tags             []string `json:"tags"`
	Amenities        []string `json:"amenities"`
	ImageSymbol      string   `json:"imageSymbol"`
	ImageHue         float64  `json:"imageHue"`
	ImageURL         string   `json:"imageUrl"`
	WhyRecommended   string   `json:"whyRecommended,omitempty"`
	Reviews          []Review `json:"reviews"`
	Budget           Budget   `json:"budgetTier"`
}

type Swipe struct {
	ID          string   `json:"id,omitempty"`
	GuestID     string   `json:"guestId,omitempty"`
	OfferID     string   `json:"offerId"`
	Liked       bool     `json:"liked"`
	Tags        []string `json:"tags"`
	Budget      Budget   `json:"budgetTier"`
	Kind        Kind     `json:"kind"`
	CountryCode string   `json:"countryCode"`
}

type Preferences struct {
	CountryCodes []string `json:"countryCodes"`
	PriorityIDs  []string `json:"priorityIDs"`
	Skipped      bool     `json:"skipped"`
}

type Country struct {
	Code  string `json:"code"`
	Name  string `json:"name"`
	Emoji string `json:"emoji"`
}

type Priority struct {
	ID       string   `json:"id"`
	Title    string   `json:"title"`
	Subtitle string   `json:"subtitle"`
	Tags     []string `json:"tags"`
}
