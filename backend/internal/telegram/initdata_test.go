package telegram_test

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"testing"
	"time"

	"ostrovok/internal/telegram"
)

func TestValidateAcceptsSignedPayload(t *testing.T) {
	token := "123456:TEST-TOKEN"
	user := `{"id":42,"first_name":"Оля"}`
	auth := fmt.Sprintf("%d", time.Now().Unix())
	fields := map[string]string{
		"auth_date": auth,
		"query_id":  "AAE",
		"user":      user,
	}
	initData := sign(token, fields)
	got, err := telegram.Validate(initData, token, time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	if got.ID != 42 || got.FirstName != "Оля" {
		t.Fatalf("user: %#v", got)
	}
}

func TestValidateRejectsBadHash(t *testing.T) {
	token := "123456:TEST-TOKEN"
	fields := map[string]string{
		"auth_date": fmt.Sprintf("%d", time.Now().Unix()),
		"user":      `{"id":1,"first_name":"A"}`,
	}
	initData := sign(token, fields) + "ffff"
	if _, err := telegram.Validate(initData, token, time.Hour); err == nil {
		t.Fatal("ожидали ошибку подписи")
	}
}

func sign(token string, fields map[string]string) string {
	pairs := make([]string, 0, len(fields))
	values := url.Values{}
	for k, v := range fields {
		pairs = append(pairs, k+"="+v)
		values.Set(k, v)
	}
	sort.Strings(pairs)
	mac := hmac.New(sha256.New, []byte("WebAppData"))
	mac.Write([]byte(token))
	secret := mac.Sum(nil)
	mac = hmac.New(sha256.New, secret)
	mac.Write([]byte(strings.Join(pairs, "\n")))
	values.Set("hash", hex.EncodeToString(mac.Sum(nil)))
	return values.Encode()
}
