package recommend_test

import (
	"testing"

	"ostrovok/internal/catalog"
	"ostrovok/internal/domain"
	"ostrovok/internal/recommend"
)

func TestSkippedOnboardingPrefersUniversalMidHotels(t *testing.T) {
	engine := recommend.Engine{}
	ranked := engine.Rank(catalog.Offers(), domain.Preferences{Skipped: true}, nil)
	if len(ranked) == 0 {
		t.Fatal("empty rank")
	}
	if ranked[0].ID != "ht-florence" {
		t.Fatalf("ожидали универсальный отель первым, получили %s", ranked[0].ID)
	}
}

func TestSeaLikesBoostBeachOffers(t *testing.T) {
	engine := recommend.Engine{}
	swipes := []domain.Swipe{
		{OfferID: "ht-santorini", Liked: true, Tags: []string{"море", "пляж", "люкс"}, Budget: domain.BudgetHigh, Kind: domain.KindHotel, CountryCode: "GR"},
		{OfferID: "hs-bangkok", Liked: false, Tags: []string{"город", "бюджет"}, Budget: domain.BudgetLow, Kind: domain.KindHostel, CountryCode: "TH"},
	}
	ranked := engine.Rank(catalog.Offers(), domain.Preferences{Skipped: true}, swipes)
	for _, offer := range ranked {
		if offer.ID == "ht-santorini" || offer.ID == "hs-bangkok" {
			t.Fatalf("просмотренная карточка вернулась в выдачу: %s", offer.ID)
		}
	}
	if ranked[0].ID == "hs-bangkok" {
		t.Fatalf("хостел после дизлайка не должен быть первым: %#v", ranked[0])
	}
	foundSea := false
	for i, o := range ranked[:3] {
		for _, tag := range o.Tags {
			if tag == "море" || tag == "пляж" {
				foundSea = true
				t.Logf("sea-ish at %d: %s", i, o.ID)
			}
		}
	}
	if !foundSea {
		t.Fatal("ожидали море в топ-3 после лайка Санторини")
	}
}

func TestRankAddsReason(t *testing.T) {
	engine := recommend.Engine{}
	ranked := engine.Rank(catalog.Offers(), domain.Preferences{Skipped: true}, nil)
	if ranked[0].WhyRecommended == "" {
		t.Fatal("ожидали пояснение у первой карточки")
	}
}
