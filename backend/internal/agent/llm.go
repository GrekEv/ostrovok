package agent

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"ostrovok/internal/domain"
)

const defaultPrompt = `Ты — умный тревел-ассистент Островка. Проанализируй сообщение. Ответь СТРОГО JSON без markdown.
Формат: {"city":"город или null","type":"hotel|tour|flight|null","budget":число или null,"tags":["море","спа"],"reply":"короткий дружелюбный ответ по-русски"}`

type Extracted struct {
	City     string
	MaxPrice int
	Reply    string
}

type llmPayload struct {
	City   *string  `json:"city"`
	Budget *float64 `json:"budget"`
	Reply  string   `json:"reply"`
}

var llmClient = &http.Client{Timeout: 8 * time.Second}

func LLMConfigured() bool {
	return llmKey() != ""
}

func llmKey() string {
	if v := strings.TrimSpace(os.Getenv("OSTROVOK_LLM_API_KEY")); v != "" {
		return v
	}
	return strings.TrimSpace(os.Getenv("OPENAI_API_KEY"))
}

func TryLLM(ctx context.Context, message string) (Extracted, bool) {
	if !LLMConfigured() {
		return Extracted{}, false
	}
	parsed, err := completeLLM(ctx, message)
	if err != nil {
		return Extracted{}, false
	}
	out := Extracted{Reply: strings.TrimSpace(parsed.Reply)}
	if parsed.City != nil {
		out.City = strings.TrimSpace(*parsed.City)
	}
	if parsed.Budget != nil && *parsed.Budget >= 1000 {
		out.MaxPrice = int(*parsed.Budget)
	}
	return out, out.Reply != "" || out.City != "" || out.MaxPrice > 0
}

func WithResults(reply Reply, found []domain.Offer, llm Extracted) Reply {
	if llm.Reply != "" {
		reply.Text = llm.Reply
	} else if len(found) > 0 && (reply.Intent == IntentPick || reply.Intent == IntentNone) {
		n := min(3, len(found))
		names := make([]string, n)
		for i := 0; i < n; i++ {
			names[i] = found[i].Title + " (" + found[i].City + ")"
		}
		reply.Text += " По Postgres: " + strings.Join(names, "; ") + "."
	}
	if len(found) > 8 {
		found = found[:8]
	}
	reply.Offers = found
	return reply
}

func completeLLM(ctx context.Context, message string) (llmPayload, error) {
	baseURL := strings.TrimRight(strings.TrimSpace(os.Getenv("OSTROVOK_LLM_BASE_URL")), "/")
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}
	model := strings.TrimSpace(os.Getenv("OSTROVOK_LLM_MODEL"))
	if model == "" {
		model = "gpt-4o-mini"
	}
	body, err := json.Marshal(map[string]any{
		"model": model, "temperature": 0.2,
		"messages": []map[string]string{
			{"role": "system", "content": defaultPrompt},
			{"role": "user", "content": message},
		},
	})
	if err != nil {
		return llmPayload{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, baseURL+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return llmPayload{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+llmKey())
	resp, err := llmClient.Do(req)
	if err != nil {
		return llmPayload{}, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode >= 300 {
		return llmPayload{}, errLLM
	}
	var envelope struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &envelope); err != nil || len(envelope.Choices) == 0 {
		return llmPayload{}, errLLM
	}
	content := strings.TrimSpace(envelope.Choices[0].Message.Content)
	content = strings.TrimPrefix(content, "```json")
	content = strings.TrimPrefix(content, "```")
	content = strings.TrimSuffix(content, "```")
	var parsed llmPayload
	if err := json.Unmarshal([]byte(strings.TrimSpace(content)), &parsed); err != nil {
		parsed.Reply = strings.TrimSpace(content)
	}
	return parsed, nil
}

var errLLM = errString("llm http error")

type errString string

func (e errString) Error() string { return string(e) }
