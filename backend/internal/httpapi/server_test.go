package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"ostrovok/internal/agent"
	"ostrovok/internal/domain"
	"ostrovok/internal/httpapi"
)

func TestRootExplainsAPI(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	response := httptest.NewRecorder()
	httpapi.NewMux().ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("status: got %d, want %d", response.Code, http.StatusOK)
	}
	if !strings.Contains(response.Body.String(), "Островок") {
		t.Fatal("ожидали HTML-страницу сервиса")
	}
}

func TestHealth(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	response := httptest.NewRecorder()

	httpapi.NewMux().ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status: got %d, want %d", response.Code, http.StatusOK)
	}
}

func TestCatalogIncludesMotelAndCities(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/v1/catalog", nil)
	response := httptest.NewRecorder()
	httpapi.NewMux().ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("status: got %d, body: %s", response.Code, response.Body.String())
	}

	var payload struct {
		Offers []domain.Offer `json:"offers"`
	}
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if len(payload.Offers) < 14 {
		t.Fatalf("каталог слишком короткий: %d", len(payload.Offers))
	}
	seen := map[string]bool{}
	for _, offer := range payload.Offers {
		seen[offer.ID] = true
	}
	for _, id := range []string{"mt-tbilisi", "ht-porto", "hs-barcelona", "ht-kotor", "fl-barcelona", "tr-tuscany"} {
		if !seen[id] {
			t.Fatalf("нет предложения %s", id)
		}
	}
}

func TestOfferByID(t *testing.T) {
	mux := httpapi.NewMux()

	ok := httptest.NewRecorder()
	mux.ServeHTTP(ok, httptest.NewRequest(http.MethodGet, "/v1/offers/ht-florence", nil))
	if ok.Code != http.StatusOK {
		t.Fatalf("status: got %d", ok.Code)
	}

	missing := httptest.NewRecorder()
	mux.ServeHTTP(missing, httptest.NewRequest(http.MethodGet, "/v1/offers/no-such", nil))
	if missing.Code != http.StatusNotFound {
		t.Fatalf("status: got %d, want 404", missing.Code)
	}
}

func TestRecommendationsDoNotReturnSeenOffer(t *testing.T) {
	body := map[string]any{
		"skipped": true,
		"swipes": []domain.Swipe{
			{
				OfferID:     "ht-florence",
				Liked:       true,
				Tags:        []string{"город", "комфорт"},
				Budget:      domain.BudgetMid,
				Kind:        domain.KindHotel,
				CountryCode: "IT",
			},
		},
	}
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/recommendations",
		bytes.NewReader(payload),
	)
	response := httptest.NewRecorder()

	httpapi.NewMux().ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status: got %d, body: %s", response.Code, response.Body.String())
	}
	var offers []domain.Offer
	if err := json.NewDecoder(response.Body).Decode(&offers); err != nil {
		t.Fatal(err)
	}
	for _, offer := range offers {
		if offer.ID == "ht-florence" {
			t.Fatal("просмотренная карточка вернулась в рекомендации")
		}
	}
}

func TestAgentRejectsEmptyMessage(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/agent/chat",
		bytes.NewBufferString(`{"message":"   ","liked":[]}`),
	)
	response := httptest.NewRecorder()

	httpapi.NewMux().ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status: got %d, want %d", response.Code, http.StatusBadRequest)
	}
	if contentType := response.Header().Get("Content-Type"); contentType != "application/json; charset=utf-8" {
		t.Fatalf("unexpected content type: %s", contentType)
	}
}

func TestRecommendationsRejectUnknownFields(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/recommendations",
		bytes.NewBufferString(`{"skipped":true,"swipes":[],"surprise":1}`),
	)
	response := httptest.NewRecorder()

	httpapi.NewMux().ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status: got %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestBookingAndManagerQueue(t *testing.T) {
	mux := httpapi.NewMux()
	liked, _ := json.Marshal(map[string]any{
		"message": "Забронировать",
		"guestId": "guest-test",
		"liked": []domain.Offer{{
			ID: "ht-florence", Kind: domain.KindHotel, Title: "Casa Verde Florence",
			City: "Флоренция", Country: "Италия", CountryCode: "IT",
			ShortDescription: "Тихий отель", Description: "Описание",
			Price: 18900, Currency: "₽", Rating: 4.8, ReviewCount: 1,
			Tags: []string{"город"}, Amenities: []string{}, Reviews: []domain.Review{},
			Budget: domain.BudgetMid,
		}},
	})

	chat := httptest.NewRecorder()
	mux.ServeHTTP(chat, httptest.NewRequest(http.MethodPost, "/v1/agent/chat", bytes.NewReader(liked)))
	if chat.Code != http.StatusOK {
		t.Fatalf("chat status: %d %s", chat.Code, chat.Body.String())
	}
	var reply agent.Reply
	if err := json.NewDecoder(chat.Body).Decode(&reply); err != nil {
		t.Fatal(err)
	}
	if reply.Intent != agent.IntentBooking {
		t.Fatalf("intent: %s", reply.Intent)
	}
	if reply.BookingID == "" || reply.TicketID == "" {
		t.Fatalf("агент не создал заявку: %#v", reply)
	}

	bookings := httptest.NewRecorder()
	mux.ServeHTTP(bookings, httptest.NewRequest(http.MethodGet, "/v1/bookings?guestId=guest-test", nil))
	if bookings.Code != http.StatusOK {
		t.Fatalf("bookings status: %d", bookings.Code)
	}
	var items []domain.Booking
	if err := json.NewDecoder(bookings.Body).Decode(&items); err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 || items[0].Kind != domain.BookingNow {
		t.Fatalf("ожидали одну бронь, получили %#v", items)
	}

	delayed, _ := json.Marshal(map[string]any{
		"guestId": "guest-test",
		"offerId": "ht-kotor",
		"kind":    "delayed",
		"dates":   "июнь",
		"note":    "позже",
	})
	created := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/bookings", bytes.NewReader(delayed))
	mux.ServeHTTP(created, req)
	if created.Code != http.StatusCreated {
		t.Fatalf("create booking: %d %s", created.Code, created.Body.String())
	}

	tickets := httptest.NewRecorder()
	mux.ServeHTTP(tickets, httptest.NewRequest(http.MethodGet, "/v1/manager/tickets?guestId=guest-test", nil))
	var queue []domain.Ticket
	if err := json.NewDecoder(tickets.Body).Decode(&queue); err != nil {
		t.Fatal(err)
	}
	if len(queue) != 2 {
		t.Fatalf("очередь менеджера: %#v", queue)
	}
}

func TestSwipeIsSavedAndNextCardChanges(t *testing.T) {
	mux := httpapi.NewMux()
	first := httptest.NewRecorder()
	mux.ServeHTTP(first, httptest.NewRequest(http.MethodGet, "/v1/offers", nil))
	if first.Code != http.StatusOK {
		t.Fatalf("offers: %d", first.Code)
	}

	body, _ := json.Marshal(map[string]any{
		"guestId":     "guest-swipe",
		"offerId":     "ht-santorini",
		"liked":       true,
		"tags":        []string{"море", "пляж"},
		"budgetTier":  "high",
		"kind":        "hotel",
		"countryCode": "GR",
	})
	created := httptest.NewRecorder()
	mux.ServeHTTP(created, httptest.NewRequest(http.MethodPost, "/v1/swipes", bytes.NewReader(body)))
	if created.Code != http.StatusCreated {
		t.Fatalf("swipe: %d %s", created.Code, created.Body.String())
	}
	var payload struct {
		Saved bool           `json:"saved"`
		Deck  []domain.Offer `json:"deck"`
	}
	if err := json.NewDecoder(created.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if !payload.Saved || len(payload.Deck) == 0 {
		t.Fatalf("ожидали новую колоду: %#v", payload)
	}
	for _, offer := range payload.Deck {
		if offer.ID == "ht-santorini" {
			t.Fatal("лайкнутая карточка не должна вернуться")
		}
	}
}

func TestSavedCollectionFollowsLikes(t *testing.T) {
	mux := httpapi.NewMux()
	body, _ := json.Marshal(map[string]any{
		"guestId":     "guest-saved",
		"offerId":     "ht-santorini",
		"liked":       true,
		"tags":        []string{"море"},
		"budgetTier":  "high",
		"kind":        "hotel",
		"countryCode": "GR",
	})
	created := httptest.NewRecorder()
	mux.ServeHTTP(created, httptest.NewRequest(http.MethodPost, "/v1/swipes", bytes.NewReader(body)))
	if created.Code != http.StatusCreated {
		t.Fatalf("swipe: %d %s", created.Code, created.Body.String())
	}

	saved := httptest.NewRecorder()
	mux.ServeHTTP(saved, httptest.NewRequest(http.MethodGet, "/v1/saved?guestId=guest-saved", nil))
	if saved.Code != http.StatusOK {
		t.Fatalf("saved: %d %s", saved.Code, saved.Body.String())
	}
	var items []domain.Offer
	if err := json.NewDecoder(saved.Body).Decode(&items); err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 || items[0].ID != "ht-santorini" {
		t.Fatalf("ожидали сохранённую карточку: %#v", items)
	}

	removed := httptest.NewRecorder()
	mux.ServeHTTP(removed, httptest.NewRequest(http.MethodDelete, "/v1/saved?guestId=guest-saved&offerId=ht-santorini", nil))
	if removed.Code != http.StatusOK {
		t.Fatalf("delete saved: %d %s", removed.Code, removed.Body.String())
	}
}

func TestManagerTicketWithoutGuestIsRejected(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/manager/tickets",
		bytes.NewBufferString(`{"note":"нужен человек"}`),
	)
	response := httptest.NewRecorder()
	httpapi.NewMux().ServeHTTP(response, request)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("status: got %d, want 400", response.Code)
	}
}
