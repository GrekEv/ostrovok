# Frontend / Telegram Mini App update

## Changed
- Rebuilt `backend/webapp/index.html`, `app.css`, and `app.js` into a responsive Telegram Mini App with four tabs: discovery, saved places, AI assistant, and profile.
- Added swipe gestures plus explicit like/pass buttons, animated card exits, offer details, review summary, recommendation rationale, loading/error/retry states, and reduced-motion support.
- Connected swipes to `POST /v1/swipes` and recommendation loading to `POST /v1/recommendations`; AI assistant calls `POST /v1/agent/chat`.
- Persisted the anonymous browser guest ID, local saved places, and local swipe history across reloads.
- Removed unsafe string-based HTML rendering for offer content; card content is assembled with DOM APIs and `textContent`.
- Included `backend/webapp` in the API Docker image. Previously only the static photo folder was copied, so `/tg/` could be unavailable in the container.
- Changed API startup behavior: if PostgreSQL cannot be reached, startup fails instead of silently switching to an in-memory store. `OSTROVOK_ALLOW_MEMORY=true` is an explicit local-only escape hatch.
- Updated the root README with current functionality and known limitations.

## Run
```bash
docker compose up --build
```
Open `http://127.0.0.1:8080/` for the web app. For Telegram, deploy the API behind HTTPS and set the bot's Web App URL to the deployed root URL.

## Validation and known limitations
- `node --check backend/webapp/app.js` passes.
- `go test ./...` could not complete in the current environment because Go could not download `github.com/lib/pq` from `proxy.golang.org` (network/DNS unavailable). Re-run in a network-enabled environment.
- PostgreSQL/Telegram end-to-end testing and Flutter builds have not been run here.
- The AI helper is currently rule-based, not a connected LLM. Saved items and counters are browser-local; database-backed swipe history/recommendation is server-side. Telegram `initData` signature validation still needs to be added before production use.
