const tg = window.Telegram && window.Telegram.WebApp;
if (tg) {
  tg.ready();
  tg.expand();
  if (typeof tg.disableVerticalSwipes === "function") {
    tg.disableVerticalSwipes();
  }
  tg.setHeaderColor("#0F6B4C");
  tg.setBackgroundColor("#F7FBF8");
}

const guestId = tg && tg.initDataUnsafe && tg.initDataUnsafe.user
  ? "tg-" + tg.initDataUnsafe.user.id
  : "guest-web-" + Date.now();

const stage = document.getElementById("card-stage");
const statusEl = document.getElementById("status");
let deck = [];
let busy = false;

function photoUrl(offer) {
  const raw = offer.imageUrl || offer.image_url || "";
  if (raw.startsWith("http")) return raw;
  if (raw.startsWith("/")) return raw;
  return "/static/places/" + offer.id + ".jpg";
}

function setStatus(text) {
  statusEl.textContent = text;
}

async function api(path, options) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error || response.statusText);
  }
  return data;
}

function render() {
  stage.innerHTML = "";
  const offer = deck[0];
  if (!offer) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = "Карточки закончились. Откройте мини-приложение заново — или свайпните ещё раз после сброса базы.";
    stage.appendChild(empty);
    return;
  }
  const card = document.createElement("article");
  card.className = "card";
  card.innerHTML =
    '<div class="photo" style="background-image:url(\'' + photoUrl(offer) + "')\"></div>" +
    '<div class="meta">' +
    "<h2>" + offer.title + "</h2>" +
    '<p class="place">' + offer.city + ", " + offer.country + "</p>" +
    '<p class="price">' + offer.pricePerNight + " ₽</p>" +
    '<p class="why">' + (offer.whyRecommended || offer.shortDescription || "") + "</p>" +
    "</div>";
  bindSwipe(card, offer);
  stage.appendChild(card);
}

function bindSwipe(card, offer) {
  let startX = 0;
  let dx = 0;
  let dragging = false;

  const onDown = (event) => {
    dragging = true;
    startX = event.clientX ?? event.touches[0].clientX;
    dx = 0;
  };
  const onMove = (event) => {
    if (!dragging) return;
    const x = event.clientX ?? event.touches[0].clientX;
    dx = x - startX;
    card.style.transform = "translateX(" + dx + "px) rotate(" + dx / 18 + "deg)";
  };
  const onUp = () => {
    if (!dragging) return;
    dragging = false;
    if (dx > 80) {
      swipe(offer, true);
      return;
    }
    if (dx < -80) {
      swipe(offer, false);
      return;
    }
    card.style.transform = "";
  };

  card.addEventListener("pointerdown", onDown);
  window.addEventListener("pointermove", onMove);
  window.addEventListener("pointerup", onUp);
}

async function swipe(offer, liked) {
  if (busy) return;
  busy = true;
  try {
    const result = await api("/v1/swipes", {
      method: "POST",
      body: JSON.stringify({
        guestId,
        offerId: String(offer.id),
        liked,
        tags: offer.tags || offer.amenities || [],
        budgetTier: offer.budgetTier || "mid",
        kind: offer.kind || offer.type || "hotel",
        countryCode: offer.countryCode || "",
      }),
    });
    deck = result.deck || [];
    setStatus(liked ? "лайк записан в Postgres" : "мимо записано в Postgres");
    render();
  } catch (error) {
    setStatus("ошибка свайпа: " + error.message);
  } finally {
    busy = false;
  }
}

async function start() {
  setStatus("гость " + guestId);
  try {
    await api("/v1/preferences", {
      method: "POST",
      body: JSON.stringify({
        guestId,
        skipped: true,
        countryCodes: [],
        priorityIDs: [],
      }),
    });
    deck = await api("/v1/recommendations", {
      method: "POST",
      body: JSON.stringify({
        guestId,
        skipped: true,
        countryCodes: [],
        priorityIDs: [],
        swipes: [],
      }),
    });
    if (!Array.isArray(deck) || deck.length === 0) {
      deck = await api("/v1/offers");
    }
    setStatus("карточек: " + deck.length);
    render();
  } catch (error) {
    setStatus("нет API: " + error.message);
    stage.innerHTML = '<div class="empty">Не удалось загрузить карточки. Запустите Go API.</div>';
  }
}

document.getElementById("like").onclick = () => deck[0] && swipe(deck[0], true);
document.getElementById("nope").onclick = () => deck[0] && swipe(deck[0], false);

start();
