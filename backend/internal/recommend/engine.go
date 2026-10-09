package recommend

import (
	"strings"

	"ostrovok/internal/catalog"
	"ostrovok/internal/domain"
)

// Engine — контентная ИИ-модель: онбординг + свайпы → профиль, затем MMR-ранжирование.
type Engine struct{}

type scored struct {
	offer domain.Offer
	value float64
}

func (Engine) Rank(offers []domain.Offer, prefs domain.Preferences, swipes []domain.Swipe) []domain.Offer {
	p := buildProfile(prefs, swipes)
	seen := make(map[string]struct{}, len(swipes))
	for _, swipe := range swipes {
		seen[swipe.OfferID] = struct{}{}
	}
	pool := make([]scored, 0, len(offers))
	for _, o := range offers {
		if _, alreadySeen := seen[o.ID]; alreadySeen {
			continue
		}
		pool = append(pool, scored{offer: o, value: score(o, p)})
	}

	out := make([]domain.Offer, 0, len(pool))
	for len(pool) > 0 {
		best := 0
		bestVal := adjusted(pool[0], out)
		for i := 1; i < len(pool); i++ {
			v := adjusted(pool[i], out)
			if v > bestVal || (v == bestVal && pool[i].offer.Rating > pool[best].offer.Rating) {
				best, bestVal = i, v
			}
		}
		chosen := pool[best].offer
		chosen.WhyRecommended = explain(chosen, p, prefs, swipes)
		out = append(out, chosen)
		pool = append(pool[:best], pool[best+1:]...)
	}
	return out
}

func adjusted(item scored, picked []domain.Offer) float64 {
	v := item.value
	for _, prev := range picked {
		if prev.Kind == item.offer.Kind {
			v -= 0.28
		}
		if prev.CountryCode == item.offer.CountryCode {
			v -= 0.18
		}
	}
	return v
}

type profile struct {
	tags      map[string]float64
	kinds     map[domain.Kind]float64
	budgets   map[domain.Budget]float64
	countries map[string]float64
}

func buildProfile(prefs domain.Preferences, swipes []domain.Swipe) profile {
	p := profile{
		tags:      map[string]float64{},
		kinds:     map[domain.Kind]float64{},
		budgets:   map[domain.Budget]float64{},
		countries: map[string]float64{},
	}

	empty := len(prefs.CountryCodes) == 0 && len(prefs.PriorityIDs) == 0
	if prefs.Skipped || empty {
		for _, t := range []string{"город", "комфорт", "море", "культура"} {
			p.tags[t] += 1.2
		}
		p.budgets[domain.BudgetMid] += 2
		p.kinds[domain.KindHotel] += 1
	} else {
		for _, code := range prefs.CountryCodes {
			p.countries[code] += 2.5
		}
		priorities := catalog.Priorities()
		lookup := map[string][]string{}
		for _, pr := range priorities {
			lookup[pr.ID] = pr.Tags
		}
		for _, id := range prefs.PriorityIDs {
			for _, t := range lookup[id] {
				p.tags[t] += 2
			}
		}
	}

	n := len(swipes)
	for i, s := range swipes {
		dir := 1.0
		if !s.Liked {
			dir = -1.4
		}
		recency := 1 + 0.12*float64(i)/float64(max(n, 1))
		w := dir * recency
		for _, t := range s.Tags {
			p.tags[t] += w
		}
		p.kinds[s.Kind] += w * 0.8
		p.budgets[s.Budget] += w * 0.9
		p.countries[s.CountryCode] += w * 0.7
	}
	return p
}

func score(o domain.Offer, p profile) float64 {
	v := o.Rating
	for _, t := range o.Tags {
		v += p.tags[t]
	}
	v += p.kinds[o.Kind]
	v += p.budgets[o.Budget]
	v += p.countries[o.CountryCode]
	return v
}

func explain(o domain.Offer, p profile, prefs domain.Preferences, swipes []domain.Swipe) string {
	liked := false
	for _, s := range swipes {
		if s.Liked {
			liked = true
			break
		}
	}
	var hits []string
	for _, t := range o.Tags {
		if p.tags[t] >= 1.5 {
			hits = append(hits, t)
		}
	}
	if len(hits) > 3 {
		hits = hits[:3]
	}
	switch {
	case liked && len(hits) > 0:
		return "ИИ: близко к вашим лайкам — " + strings.Join(hits, ", ") + "."
	case !prefs.Skipped && len(prefs.CountryCodes) > 0 && contains(prefs.CountryCodes, o.CountryCode):
		return "ИИ: страна из онбординга и высокий рейтинг."
	case p.budgets[domain.BudgetMid] > 0 && o.Budget == domain.BudgetMid && o.Kind == domain.KindHotel:
		return "ИИ: универсальный старт — средний отель, город и комфорт."
	case len(hits) > 0:
		return "ИИ: совпали приоритеты — " + strings.Join(hits, ", ") + "."
	default:
		return "ИИ: разнообразие колоды, чтобы не зациклиться на одном типе."
	}
}

func contains(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}
