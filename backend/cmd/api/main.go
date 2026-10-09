package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"ostrovok/internal/httpapi"
	"ostrovok/internal/store"
)

func main() {
	addr := ":8080"
	if v := os.Getenv("PORT"); v != "" {
		addr = ":" + v
	}

	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()

	handler := httpapi.NewMux()
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://ostrovok_user:super_secret_password@127.0.0.1:5432/ostrovok_travel?sslmode=disable"
	}
	pg, err := store.Open(ctx, dbURL)
	if err != nil {
		if os.Getenv("OSTROVOK_ALLOW_MEMORY") == "true" {
			log.Printf("WARNING: PostgreSQL недоступна (%v) — включено явное разрешение на memory-store", err)
		} else {
			log.Fatalf("PostgreSQL недоступна: %v. Запустите docker compose up --build или задайте DATABASE_URL. Для локальной разработки без БД явно установите OSTROVOK_ALLOW_MEMORY=true", err)
		}
	} else {
		defer pg.Close()
		handler = httpapi.NewMuxWithStore(pg)
		log.Print("store: postgresql")
	}

	server := &http.Server{
		Addr:              addr,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	stopped := make(chan os.Signal, 1)
	signal.Notify(stopped, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-stopped
		log.Print("ostrovok api is shutting down")
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer shutdownCancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Printf("graceful shutdown: %v", err)
		}
	}()

	log.Printf("ostrovok api on %s", addr)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
