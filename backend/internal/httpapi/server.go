package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"ostrovok/internal/agent"
	"ostrovok/internal/catalog"
	"ostrovok/internal/domain"
	"ostrovok/internal/recommend"
	"ostrovok/internal/store"
	"ostrovok/internal/telegram"
)

type api struct {
	engine recommend.Engine
	store  store.Store
}

func NewMux() http.Handler {
	return NewMuxWithStore(store.NewMemory())
}

func NewMuxWithStore(st store.Store) http.Handler {
	app := &api{store: st}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", app.root)
	mux.HandleFunc("GET /app/{$}", app.root)
	mux.HandleFunc("GET /health", app.health)
	mux.HandleFunc("GET /v1/catalog", app.catalog)
	mux.HandleFunc("GET /v1/offers", app.offers)
	mux.HandleFunc("GET /v1/offers/{id}", app.offerByID)
	mux.HandleFunc("POST /v1/recommendations", app.recommendations)
	mux.HandleFunc("POST /v1/swipes", app.createSwipe)
	mux.HandleFunc("GET /v1/saved", app.listSaved)
	mux.HandleFunc("DELETE /v1/saved", app.deleteSaved)
	mux.HandleFunc("GET /v1/profile", app.profile)
	mux.HandleFunc("POST /v1/preferences", app.savePreferences)
	mux.HandleFunc("POST /v1/agent/chat", app.chat)
	mux.HandleFunc("POST /api/v1/chat/message", app.chatContract)
	mux.HandleFunc("POST /v1/bookings", app.createBooking)
	mux.HandleFunc("GET /v1/bookings", app.listBookings)
	mux.HandleFunc("POST /v1/manager/tickets", app.createTicket)
	mux.HandleFunc("GET /v1/manager/tickets", app.listTickets)
	mux.Handle("GET /static/", http.StripPrefix("/static/", http.FileServer(http.Dir(staticRoot()))))
	mux.Handle("GET /tg/", http.StripPrefix("/tg/", http.FileServer(http.Dir(webappRoot()))))
	return middleware(mux)
}

func (a *api) root(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, filepath.Join(webappRoot(), "index.html"))
}

func (a *api) health(w http.ResponseWriter, r *http.Request) {
	if err := a.store.Ping(r.Context()); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"status": "degraded", "service": "ostrovok-api", "error": err.Error(),
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok", "service": "ostrovok-api",
		"time": time.Now().UTC().Format(time.RFC3339), "store": storeName(a.store),
	})
}

func (a *api) catalog(w http.ResponseWriter, r *http.Request) {
	offers, ok := a.cards(w, r)
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"offers": offers, "countries": catalog.Countries(), "priorities": catalog.Priorities(),
	})
}

func (a *api) offers(w http.ResponseWriter, r *http.Request) {
	offers, ok := a.cards(w, r)
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, offers)
}

func (a *api) offerByID(w http.ResponseWriter, r *http.Request) {
	offer, found, err := a.store.Card(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if !found {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}
	writeJSON(w, http.StatusOK, offer)
}

func (a *api) recommendations(w http.ResponseWriter, r *http.Request) {
	var req struct {
		domain.Preferences
		GuestID string         `json:"guestId"`
		Swipes  []domain.Swipe `json:"swipes"`
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	guest, ok := a.guest(w, r, req.GuestID)
	if !ok {
		return
	}
	if guest == "" {
		writeJSON(w, http.StatusOK, a.engine.Rank(catalog.Offers(), req.Preferences, req.Swipes))
		return
	}
	ctx := r.Context()
	_ = a.store.SavePreferences(ctx, guest, req.Preferences)
	for _, swipe := range req.Swipes {
		swipe.GuestID = guest
		if err := a.store.SaveSwipe(ctx, swipe); err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
	}
	ranked, err := a.store.Rank(ctx, guest, req.Preferences)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, ranked)
}

func (a *api) createSwipe(w http.ResponseWriter, r *http.Request) {
	var req domain.Swipe
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	guest, ok := a.guest(w, r, req.GuestID)
	if !ok {
		return
	}
	req.GuestID, req.OfferID = guest, strings.TrimSpace(req.OfferID)
	if req.GuestID == "" || req.OfferID == "" {
		writeError(w, http.StatusBadRequest, "guestId and offerId are required")
		return
	}
	ctx := r.Context()
	if _, found, err := a.store.Card(ctx, req.OfferID); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	} else if !found {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}
	if err := a.store.SaveSwipe(ctx, req); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	ranked, err := a.store.Rank(ctx, req.GuestID, domain.Preferences{})
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	likes, swipes, _ := a.store.SwipeCounts(ctx, req.GuestID)
	writeJSON(w, http.StatusCreated, map[string]any{
		"saved": true, "deck": ranked, "likes": likes, "swipes": swipes,
	})
}

func (a *api) savePreferences(w http.ResponseWriter, r *http.Request) {
	var req struct {
		domain.Preferences
		GuestID string `json:"guestId"`
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	guest, ok := a.requireGuest(w, r, req.GuestID)
	if !ok {
		return
	}
	if err := a.store.SavePreferences(r.Context(), guest, req.Preferences); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"saved": true})
}

func (a *api) chat(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Message string         `json:"message"`
		GuestID string         `json:"guestId"`
		Liked   []domain.Offer `json:"liked"`
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	req.Message = strings.TrimSpace(req.Message)
	guest, ok := a.guest(w, r, req.GuestID)
	if !ok {
		return
	}
	if req.Message == "" {
		writeError(w, http.StatusBadRequest, "message is required")
		return
	}
	reply := a.composeReply(r.Context(), req.Message, req.Liked, false)
	if guest == "" {
		writeJSON(w, http.StatusOK, reply)
		return
	}
	switch reply.Intent {
	case agent.IntentBooking, agent.IntentDelayed:
		if len(req.Liked) == 0 {
			break
		}
		kind := domain.BookingNow
		if reply.Intent == agent.IntentDelayed {
			kind = domain.BookingDelayed
		}
		booking, ticket := a.store.RequestStay(guest, req.Liked[0], kind, "", req.Message, "agent")
		reply.BookingID, reply.TicketID = booking.ID, ticket.ID
		reply.Text += " Заявка " + booking.ID + ", тикет менеджера " + ticket.ID + "."
	case agent.IntentManager:
		ticket := a.store.CallManager(guest, req.Message, "agent", agent.OfferIDs(req.Liked))
		reply.TicketID = ticket.ID
		reply.Text += " Тикет " + ticket.ID + " уже в очереди."
	}
	writeJSON(w, http.StatusOK, reply)
}

func (a *api) chatContract(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID  string `json:"user_id"`
		Message string `json:"message"`
	}
	decoder := json.NewDecoder(http.MaxBytesReader(nil, r.Body, 1<<20))
	if err := decoder.Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}
	req.Message = strings.TrimSpace(req.Message)
	if req.Message == "" {
		writeError(w, http.StatusBadRequest, "message is required")
		return
	}
	reply := a.composeReply(r.Context(), req.Message, nil, true)
	cards := make([]map[string]any, 0, len(reply.Offers))
	for _, offer := range reply.Offers {
		cards = append(cards, map[string]any{
			"id": offer.ID, "type": string(offer.Kind), "name": offer.Title,
			"price": offer.Price, "image_url": offer.ImageURL, "ai_summary": offer.ShortDescription,
		})
	}
	if len(cards) > 0 && (reply.Intent == agent.IntentPick || reply.Intent == agent.IntentNone) {
		reply.Text = "Нашёл варианты в Postgres по вашему запросу."
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ai_reply": reply.Text, "suggested_cards": cards, "text": reply.Text,
		"quickReplies": reply.QuickReplies, "intent": reply.Intent, "user_id": strings.TrimSpace(req.UserID),
	})
}

func (a *api) listSaved(w http.ResponseWriter, r *http.Request) {
	guest, ok := a.requireGuest(w, r, r.URL.Query().Get("guestId"))
	if !ok {
		return
	}
	items, err := a.store.Liked(r.Context(), guest)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *api) deleteSaved(w http.ResponseWriter, r *http.Request) {
	guest, ok := a.requireGuest(w, r, r.URL.Query().Get("guestId"))
	if !ok {
		return
	}
	offerID := strings.TrimSpace(r.URL.Query().Get("offerId"))
	if offerID == "" {
		writeError(w, http.StatusBadRequest, "guestId and offerId are required")
		return
	}
	if err := a.store.DeleteLike(r.Context(), guest, offerID); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"removed": true})
}

func (a *api) profile(w http.ResponseWriter, r *http.Request) {
	guest, ok := a.requireGuest(w, r, r.URL.Query().Get("guestId"))
	if !ok {
		return
	}
	likes, swipes, err := a.store.SwipeCounts(r.Context(), guest)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"guestId": guest, "likes": likes, "swipes": swipes, "saved": likes,
	})
}

func (a *api) createBooking(w http.ResponseWriter, r *http.Request) {
	var req struct {
		GuestID string `json:"guestId"`
		OfferID string `json:"offerId"`
		Kind    string `json:"kind"`
		Dates   string `json:"dates"`
		Note    string `json:"note"`
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	guest, ok := a.requireGuest(w, r, req.GuestID)
	if !ok {
		return
	}
	kind := domain.BookingKind(strings.TrimSpace(req.Kind))
	if kind == "" {
		kind = domain.BookingNow
	}
	if kind != domain.BookingNow && kind != domain.BookingDelayed {
		writeError(w, http.StatusBadRequest, "kind must be booking or delayed")
		return
	}
	offer, found, err := a.store.Card(r.Context(), strings.TrimSpace(req.OfferID))
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if !found {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}
	booking, ticket := a.store.RequestStay(guest, offer, kind, req.Dates, req.Note, "guest")
	writeJSON(w, http.StatusCreated, map[string]any{"booking": booking, "ticket": ticket})
}

func (a *api) listBookings(w http.ResponseWriter, r *http.Request) {
	guest, ok := a.requireGuest(w, r, r.URL.Query().Get("guestId"))
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, a.store.Bookings(guest))
}

func (a *api) createTicket(w http.ResponseWriter, r *http.Request) {
	var req struct {
		GuestID  string   `json:"guestId"`
		Note     string   `json:"note"`
		OfferIDs []string `json:"offerIds"`
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	guest, ok := a.requireGuest(w, r, req.GuestID)
	if !ok {
		return
	}
	writeJSON(w, http.StatusCreated, a.store.CallManager(guest, strings.TrimSpace(req.Note), "guest", req.OfferIDs))
}

func (a *api) listTickets(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, a.store.Tickets(strings.TrimSpace(r.URL.Query().Get("guestId"))))
}

func (a *api) composeReply(ctx context.Context, message string, liked []domain.Offer, fallbackFullText bool) agent.Reply {
	reply := agent.Answer(message, liked)
	city, maxPrice := agent.ExtractFilters(message)
	llmCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	extracted, llmOK := agent.TryLLM(llmCtx, message)
	if llmOK {
		if extracted.City != "" {
			city = extracted.City
		}
		if extracted.MaxPrice > 0 {
			maxPrice = extracted.MaxPrice
		}
	}
	found, err := a.store.Search(ctx, city, maxPrice)
	if err != nil {
		found = nil
	}
	if fallbackFullText && city == "" {
		if extra, extraErr := a.store.Search(ctx, message, maxPrice); extraErr == nil && len(extra) > 0 {
			found = extra
		}
	}
	return agent.WithResults(reply, found, extracted)
}

func (a *api) cards(w http.ResponseWriter, r *http.Request) ([]domain.Offer, bool) {
	offers, err := a.store.Cards(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return nil, false
	}
	return offers, true
}

func (a *api) guest(w http.ResponseWriter, r *http.Request, claimed string) (string, bool) {
	guest, err := telegram.Resolve(r.Header.Get("X-Telegram-Init-Data"), claimed)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err.Error())
		return "", false
	}
	return guest, true
}

func (a *api) requireGuest(w http.ResponseWriter, r *http.Request, claimed string) (string, bool) {
	guest, ok := a.guest(w, r, claimed)
	if !ok {
		return "", false
	}
	if guest == "" {
		writeError(w, http.StatusBadRequest, "guestId is required")
		return "", false
	}
	return guest, true
}
