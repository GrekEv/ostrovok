package agent_test

import (
	"testing"

	"ostrovok/internal/agent"
	"ostrovok/internal/domain"
)

func TestDetectIntentOrder(t *testing.T) {
	if agent.DetectIntent("Отложить бронь") != agent.IntentDelayed {
		t.Fatal("отложить должно быть важнее слова бронь")
	}
	if agent.DetectIntent("Забронировать") != agent.IntentBooking {
		t.Fatal("ожидали бронь")
	}
	if agent.DetectIntent("Менеджер") != agent.IntentManager {
		t.Fatal("ожидали менеджера")
	}
}

func TestAnswerMentionsLikedTitle(t *testing.T) {
	reply := agent.Answer("Забронировать", []domain.Offer{{Title: "Casa Verde Florence"}})
	if reply.Intent != agent.IntentBooking {
		t.Fatalf("intent: %s", reply.Intent)
	}
	if reply.Text == "" {
		t.Fatal("пустой ответ")
	}
}
