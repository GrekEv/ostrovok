package agent

import (
	"strings"

	"ostrovok/internal/domain"
)

type Intent string

const (
	IntentNone    Intent = "none"
	IntentPick    Intent = "pick"
	IntentBooking Intent = "booking"
	IntentDelayed Intent = "delayed"
	IntentManager Intent = "manager"
)

type Reply struct {
	Text         string   `json:"text"`
	QuickReplies []string `json:"quickReplies"`
	Intent       Intent   `json:"intent"`
	TicketID     string   `json:"ticketId,omitempty"`
	BookingID    string   `json:"bookingId,omitempty"`
}

func DetectIntent(message string) Intent {
	value := strings.ToLower(message)
	switch {
	case strings.Contains(value, "менедж"):
		return IntentManager
	case strings.Contains(value, "отлож") || strings.Contains(value, "потом"):
		return IntentDelayed
	case strings.Contains(value, "брон"):
		return IntentBooking
	case strings.Contains(value, "подобр") || strings.Contains(value, "вариант"):
		return IntentPick
	default:
		return IntentNone
	}
}

func Answer(message string, liked []domain.Offer) Reply {
	names := names(liked)
	switch DetectIntent(message) {
	case IntentManager:
		return Reply{
			Text:         "Соединяю с живым менеджером. Он видит лайки и приоритеты.",
			QuickReplies: []string{"Подобрать", "Забронировать"},
			Intent:       IntentManager,
		}
	case IntentDelayed:
		text := "Отложенная бронь: сначала добавьте карточку вправо — сохраню её и напомню позже."
		if len(liked) > 0 {
			text = "Отложу «" + liked[0].Title + "»: заявку поставим в очередь, оплату не списываем."
		}
		return Reply{Text: text, QuickReplies: []string{"Забронировать", "Менеджер"}, Intent: IntentDelayed}
	case IntentBooking:
		text := "Добавьте карточку вправо — тогда будет что бронировать."
		if len(liked) > 0 {
			text = "Начинаю заявку на «" + liked[0].Title + "». На тестах оплата не подключена — менеджер получит тикет."
		}
		return Reply{Text: text, QuickReplies: []string{"Менеджер", "Отложить бронь"}, Intent: IntentBooking}
	case IntentPick:
		text := "Свайпайте карточки. Пока могу опереться на универсальные городские отели и море."
		if names != "" {
			text = "По лайкам ближе всего: " + names + "."
		}
		return Reply{Text: text, QuickReplies: []string{"Забронировать", "Менеджер"}, Intent: IntentPick}
	default:
		return Reply{
			Text:         "Могу подобрать, забронировать, отложить или позвать менеджера. Напишите куда, когда и бюджет.",
			QuickReplies: []string{"Подобрать", "Забронировать", "Отложить бронь", "Менеджер"},
			Intent:       IntentNone,
		}
	}
}

func names(liked []domain.Offer) string {
	n := len(liked)
	if n > 3 {
		n = 3
	}
	parts := make([]string, 0, n)
	for i := 0; i < n; i++ {
		parts = append(parts, liked[i].Title)
	}
	return strings.Join(parts, ", ")
}

func ExtractFilters(message string) (city string, maxPrice int) {
	value := strings.ToLower(message)
	places := map[string]string{
		"сочи": "Сочи", "питер": "Санкт-Петербург", "петербург": "Санкт-Петербург",
		"москв": "Москва", "красн": "Сочи",
		"флоренц": "Флоренция", "итали": "Италия", "санторин": "Ойя", "грец": "Греция",
		"тбилис": "Сигнахи", "грузи": "Грузия", "бали": "Убуд", "индонез": "Индонезия",
		"дуба": "Дубай", "оаэ": "ОАЭ", "бангкок": "Бангкок", "таиланд": "Таиланд",
		"порту": "Порту", "барселон": "Барселона", "испан": "Испания", "стамбул": "Стамбул",
		"турц": "Турция", "котор": "Котор", "черногор": "Черногория", "токио": "Токио",
		"япон": "Япония", "праг": "Прага", "чехи": "Чехия", "берлин": "Берлин",
		"герман": "Германия", "хургад": "Хургада", "египет": "Египет", "мальдив": "Мальдивы",
		"ереван": "Ереван", "армен": "Армения", "шамони": "Шамони", "альп": "Франция",
		"сиен": "Сиена", "тоскан": "Италия",
	}
	for needle, name := range places {
		if strings.Contains(value, needle) {
			city = name
			break
		}
	}
	for _, token := range strings.Fields(value) {
		n := 0
		for _, r := range token {
			if r < '0' || r > '9' {
				n = 0
				break
			}
			n = n*10 + int(r-'0')
		}
		if n >= 1000 {
			maxPrice = n
		}
	}
	return city, maxPrice
}

func OfferIDs(liked []domain.Offer) []string {
	ids := make([]string, 0, len(liked))
	for _, offer := range liked {
		ids = append(ids, offer.ID)
	}
	return ids
}
