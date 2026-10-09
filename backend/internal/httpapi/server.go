package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"ostrovok/internal/agent"
	"ostrovok/internal/catalog"
	"ostrovok/internal/domain"
	"ostrovok/internal/recommend"
	"ostrovok/internal/store"
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
	mux.HandleFunc("GET /health", app.health)
	mux.HandleFunc("GET /v1/catalog", app.catalog)
	mux.HandleFunc("GET /v1/offers", app.offers)
	mux.HandleFunc("GET /v1/offers/{id}", app.offerByID)
	mux.HandleFunc("POST /v1/recommendations", app.recommendations)
	mux.HandleFunc("POST /v1/swipes", app.createSwipe)
	mux.HandleFunc("POST /v1/preferences", app.savePreferences)
	mux.HandleFunc("POST /v1/agent/chat", app.chat)
	mux.HandleFunc("POST /api/v1/chat/message", app.chatContract)
	mux.HandleFunc("POST /v1/bookings", app.createBooking)
	mux.HandleFunc("GET /v1/bookings", app.listBookings)
	mux.HandleFunc("POST /v1/manager/tickets", app.createTicket)
	mux.HandleFunc("GET /v1/manager/tickets", app.listTickets)
	mux.Handle("GET /static/", http.StripPrefix("/static/", http.FileServer(http.Dir(staticRoot()))))
	mux.Handle("GET /tg/", http.StripPrefix("/tg/", http.FileServer(http.Dir(webappRoot()))))
	mux.HandleFunc("GET /app/{$}", app.root)

	return middleware(mux)
}

func (a *api) health(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	status := "ok"
	if err := a.store.Ping(ctx); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"status":  "degraded",
			"service": "ostrovok-api",
			"error":   err.Error(),
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  status,
		"service": "ostrovok-api",
		"time":    time.Now().UTC().Format(time.RFC3339),
		"store":   storeName(a.store),
	})
}

func storeName(st store.Store) string {
	if _, ok := st.(*store.Postgres); ok {
		return "postgresql"
	}
	return "memory"
}

func staticRoot() string {
	return firstDir("static")
}

func webappRoot() string {
	return firstDir("webapp")
}

func firstDir(name string) string {
	for _, dir := range []string{
		name,
		filepath.Join("..", name),
		filepath.Join("..", "..", name),
		filepath.Join("..", "..", "..", name),
	} {
		if info, err := os.Stat(dir); err == nil && info.IsDir() {
			return dir
		}
	}
	return name
}

func (a *api) root(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, filepath.Join(webappRoot(), "index.html"))
}

func (a *api) catalog(w http.ResponseWriter, r *http.Request) {
	offers, err := a.store.Cards(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"offers":     offers,
		"countries":  catalog.Countries(),
		"priorities": catalog.Priorities(),
	})
}

func (a *api) offers(w http.ResponseWriter, r *http.Request) {
	offers, err := a.store.Cards(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, offers)
}

func (a *api) offerByID(w http.ResponseWriter, r *http.Request) {
	offer, ok, err := a.store.Card(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if !ok {
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
	ctx := r.Context()
	if req.GuestID != "" {
		_ = a.store.SavePreferences(ctx, req.GuestID, req.Preferences)
		for _, swipe := range req.Swipes {
			swipe.GuestID = req.GuestID
			if err := a.store.SaveSwipe(ctx, swipe); err != nil {
				writeError(w, http.StatusInternalServerError, err.Error())
				return
			}
		}
		ranked, err := a.store.Rank(ctx, req.GuestID, req.Preferences)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, ranked)
		return
	}
	ranked := a.engine.Rank(catalog.Offers(), req.Preferences, req.Swipes)
	writeJSON(w, http.StatusOK, ranked)
}

func (a *api) createSwipe(w http.ResponseWriter, r *http.Request) {
	var req domain.Swipe
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	req.GuestID = strings.TrimSpace(req.GuestID)
	req.OfferID = strings.TrimSpace(req.OfferID)
	if req.GuestID == "" || req.OfferID == "" {
		writeError(w, http.StatusBadRequest, "guestId and offerId are required")
		return
	}
	ctx := r.Context()
	if _, ok, err := a.store.Card(ctx, req.OfferID); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	} else if !ok {
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
	writeJSON(w, http.StatusCreated, map[string]any{
		"saved": true,
		"deck":  ranked,
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
	req.GuestID = strings.TrimSpace(req.GuestID)
	if req.GuestID == "" {
		writeError(w, http.StatusBadRequest, "guestId is required")
		return
	}
	if err := a.store.SavePreferences(r.Context(), req.GuestID, req.Preferences); err != nil {
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
	req.GuestID = strings.TrimSpace(req.GuestID)
	if req.Message == "" {
		writeError(w, http.StatusBadRequest, "message is required")
		return
	}

	reply := agent.Answer(req.Message, req.Liked)
	city, maxPrice := agent.ExtractFilters(req.Message)
	if found, err := a.store.Search(r.Context(), city, maxPrice); err == nil && len(found) > 0 &&
		(reply.Intent == agent.IntentPick || reply.Intent == agent.IntentNone) {
		names := make([]string, 0, 3)
		for i, offer := range found {
			if i == 3 {
				break
			}
			names = append(names, offer.Title+" ("+offer.City+")")
		}
		reply.Text += " По Postgres: " + strings.Join(names, "; ") + "."
	}
	if req.GuestID == "" {
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
		booking, ticket := a.store.RequestStay(
			req.GuestID,
			req.Liked[0],
			kind,
			"",
			req.Message,
			"agent",
		)
		reply.BookingID = booking.ID
		reply.TicketID = ticket.ID
		reply.Text += " Заявка " + booking.ID + ", тикет менеджера " + ticket.ID + "."
	case agent.IntentManager:
		ticket := a.store.CallManager(req.GuestID, req.Message, "agent", agent.OfferIDs(req.Liked))
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
	reply := agent.Answer(req.Message, nil)
	city, maxPrice := agent.ExtractFilters(req.Message)
	found, _ := a.store.Search(r.Context(), city, maxPrice)
	if city == "" {
		found, _ = a.store.Search(r.Context(), req.Message, maxPrice)
	}
	cards := make([]map[string]any, 0, len(found))
	for i, offer := range found {
		if i == 5 {
			break
		}
		cards = append(cards, map[string]any{
			"id":         offer.ID,
			"type":       string(offer.Kind),
			"name":       offer.Title,
			"price":      offer.Price,
			"image_url":  offer.ImageURL,
			"ai_summary": offer.ShortDescription,
		})
	}
	if len(cards) > 0 && (reply.Intent == agent.IntentPick || reply.Intent == agent.IntentNone) {
		reply.Text = "Нашёл варианты в Postgres по вашему запросу."
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ai_reply":        reply.Text,
		"suggested_cards": cards,
		"text":            reply.Text,
		"quickReplies":    reply.QuickReplies,
		"intent":          reply.Intent,
		"user_id":         strings.TrimSpace(req.UserID),
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
	req.GuestID = strings.TrimSpace(req.GuestID)
	req.OfferID = strings.TrimSpace(req.OfferID)
	if req.GuestID == "" {
		writeError(w, http.StatusBadRequest, "guestId is required")
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
	offer, ok, err := a.store.Card(r.Context(), req.OfferID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if !ok {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}
	booking, ticket := a.store.RequestStay(req.GuestID, offer, kind, req.Dates, req.Note, "guest")
	writeJSON(w, http.StatusCreated, map[string]any{
		"booking": booking,
		"ticket":  ticket,
	})
}

func (a *api) listBookings(w http.ResponseWriter, r *http.Request) {
	guestID := strings.TrimSpace(r.URL.Query().Get("guestId"))
	if guestID == "" {
		writeError(w, http.StatusBadRequest, "guestId is required")
		return
	}
	writeJSON(w, http.StatusOK, a.store.Bookings(guestID))
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
	req.GuestID = strings.TrimSpace(req.GuestID)
	if req.GuestID == "" {
		writeError(w, http.StatusBadRequest, "guestId is required")
		return
	}
	ticket := a.store.CallManager(req.GuestID, strings.TrimSpace(req.Note), "guest", req.OfferIDs)
	writeJSON(w, http.StatusCreated, ticket)
}

func (a *api) listTickets(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, a.store.Tickets(strings.TrimSpace(r.URL.Query().Get("guestId"))))
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func decodeJSON(r *http.Request, target any) error {
	r.Body = http.MaxBytesReader(nil, r.Body, 1<<20)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return errors.New("invalid JSON: " + err.Error())
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain one JSON object")
	}
	return nil
}

func middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("X-Content-Type-Options", "nosniff")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start).Round(time.Millisecond))
	})
}
