package telegram

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

var (
	ErrMissing     = errors.New("нет Telegram initData")
	ErrBadHash     = errors.New("подпись Telegram initData не совпала")
	ErrExpired     = errors.New("Telegram initData устарела")
	ErrNoToken     = errors.New("не задан TELEGRAM_BOT_TOKEN")
	ErrNoUser      = errors.New("в initData нет пользователя")
)

type User struct {
	ID        int64  `json:"id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Username  string `json:"username"`
}

func BotToken() string {
	return strings.TrimSpace(os.Getenv("TELEGRAM_BOT_TOKEN"))
}

func RequireInitData() bool {
	v := strings.ToLower(strings.TrimSpace(os.Getenv("TELEGRAM_REQUIRE_INITDATA")))
	return v == "1" || v == "true" || v == "yes"
}

func GuestID(user User) string {
	return fmt.Sprintf("tg-%d", user.ID)
}

func Resolve(initData, claimed string) (string, error) {
	initData = strings.TrimSpace(initData)
	token := BotToken()
	if initData != "" {
		if token == "" {
			if RequireInitData() {
				return "", ErrNoToken
			}
			return strings.TrimSpace(claimed), nil
		}
		user, err := Validate(initData, token, 24*time.Hour)
		if err != nil {
			return "", err
		}
		return GuestID(user), nil
	}
	if RequireInitData() && token != "" {
		return "", ErrMissing
	}
	return strings.TrimSpace(claimed), nil
}

func Validate(initData, botToken string, maxAge time.Duration) (User, error) {
	initData = strings.TrimSpace(initData)
	if initData == "" {
		return User{}, ErrMissing
	}
	if strings.TrimSpace(botToken) == "" {
		return User{}, ErrNoToken
	}
	values, err := url.ParseQuery(initData)
	if err != nil {
		return User{}, ErrBadHash
	}
	hash := values.Get("hash")
	if hash == "" {
		return User{}, ErrBadHash
	}
	pairs := make([]string, 0, len(values))
	for key, list := range values {
		if key == "hash" || len(list) == 0 {
			continue
		}
		pairs = append(pairs, key+"="+list[0])
	}
	sort.Strings(pairs)
	dataCheck := strings.Join(pairs, "\n")

	secret := hmacSHA256([]byte("WebAppData"), []byte(botToken))
	sum := hmacSHA256(secret, []byte(dataCheck))
	got, err := hex.DecodeString(hash)
	if err != nil || !hmac.Equal(got, sum) {
		return User{}, ErrBadHash
	}

	if maxAge > 0 {
		auth, _ := strconv.ParseInt(values.Get("auth_date"), 10, 64)
		if auth <= 0 || time.Since(time.Unix(auth, 0)) > maxAge {
			return User{}, ErrExpired
		}
	}

	rawUser := values.Get("user")
	if rawUser == "" {
		return User{}, ErrNoUser
	}
	var user User
	if err := json.Unmarshal([]byte(rawUser), &user); err != nil || user.ID == 0 {
		return User{}, ErrNoUser
	}
	return user, nil
}

func hmacSHA256(key, message []byte) []byte {
	mac := hmac.New(sha256.New, key)
	mac.Write(message)
	return mac.Sum(nil)
}
