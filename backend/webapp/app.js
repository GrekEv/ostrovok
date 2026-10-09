(() => {
  'use strict';

  const tg = window.Telegram?.WebApp;
  if (tg) {
    tg.ready();
    tg.expand();
    if (typeof tg.disableVerticalSwipes === 'function') tg.disableVerticalSwipes();
    try {
      tg.setHeaderColor('#f7f8f5');
      tg.setBackgroundColor('#f7f8f5');
    } catch (_) {}
  }

  const telegramUser = tg?.initDataUnsafe?.user;
  const guestId = telegramUser?.id ? `tg-${telegramUser.id}` : guestFromStorage();
  const money = new Intl.NumberFormat('ru-RU');
  const state = {
    deck: [],
    saved: [],
    history: loadJSON('ostrovok-history', []),
    busy: false,
    chatBusy: false,
    toastTimer: 0,
  };

  const $ = (id) => document.getElementById(id);
  const stage = $('card-stage');

  function guestFromStorage() {
    let id = localStorage.getItem('ostrovok-guest-id');
    if (!id) {
      id = `guest-${crypto.randomUUID?.() || Date.now().toString(36)}`;
      localStorage.setItem('ostrovok-guest-id', id);
    }
    return id;
  }

  function loadJSON(key, fallback) {
    try {
      const value = JSON.parse(localStorage.getItem(key));
      return Array.isArray(value) ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  function persist() {
    localStorage.setItem('ostrovok-history', JSON.stringify(state.history.slice(0, 40)));
  }

  function setStatus(text, ok = true) {
    $('status').textContent = text;
    $('status').title = text;
    document.querySelector('.live-dot').style.background = ok ? '#8fbc3c' : '#ff7869';
  }

  function toast(text) {
    const el = $('toast');
    el.textContent = text;
    el.classList.add('show');
    clearTimeout(state.toastTimer);
    state.toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
  }

  async function api(path, options = {}) {
    const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
    if (tg?.initData) headers['X-Telegram-Init-Data'] = tg.initData;
    const response = await fetch(path, { ...options, headers });
    const raw = await response.text();
    let data = {};
    try {
      data = raw ? JSON.parse(raw) : {};
    } catch (_) {
      throw new Error('Сервер вернул некорректный ответ');
    }
    if (!response.ok) throw new Error(data.error || `Ошибка ${response.status}`);
    return data;
  }

  function photoUrl(offer) {
    const raw = offer.imageUrl || offer.image_url || '';
    if (raw && !/unsplash\.com\/?$/i.test(raw) && (/^https?:\/\//i.test(raw) || raw.startsWith('/'))) {
      return raw;
    }
    return `/static/places/${encodeURIComponent(offer.id)}.jpg`;
  }

  function setPhoto(node, offer) {
    node.style.backgroundImage = `url("${photoUrl(offer).replace(/["\\]/g, '')}")`;
    node.style.backgroundSize = 'cover';
    node.style.backgroundPosition = 'center';
  }

  function price(offer) {
    return `${money.format(Number(offer.pricePerNight ?? offer.price) || 0)} ₽`;
  }

  function tagsOf(offer) {
    const tags = Array.isArray(offer.tags) && offer.tags.length ? offer.tags : (offer.amenities || []);
    return tags.slice(0, 4);
  }

  function placeLine(offer) {
    return `${offer.city || ''}${offer.country ? `, ${offer.country}` : ''}`;
  }

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function addTags(parent, tags) {
    if (!tags.length) return;
    const row = el('div', 'card-tags');
    tags.forEach((tag) => row.appendChild(el('span', 'tag', tag)));
    parent.appendChild(row);
  }

  function emptyBox(symbol, title, text, action, label) {
    const box = el('div', 'empty-card');
    box.append(el('div', 'empty-symbol', symbol), el('h3', '', title), el('p', '', text));
    if (action) {
      const button = el('button', 'primary-small', label);
      button.onclick = action;
      box.appendChild(button);
    }
    return box;
  }

  function renderCard() {
    stage.replaceChildren();
    const offer = state.deck[0];
    $('deck-count').textContent = offer ? `${state.history.length + 1} · ТВОЯ ЛЕНТА` : 'ПОДБОРКА ОБНОВЛЕНА';
    if (!offer) {
      stage.appendChild(emptyBox('✳', 'Это пока все варианты', 'Мы уже учли твои предпочтения. Обнови ленту, чтобы посмотреть другие места.', reloadDeck, 'Обновить подборку'));
      updateProfile();
      return;
    }
    const card = el('article', 'offer-card');
    card.setAttribute('aria-label', `${offer.title}, ${offer.city}`);
    const photo = el('div', 'offer-photo');
    setPhoto(photo, offer);
    const rating = el('span', 'photo-rating');
    rating.append(el('span', '', '★'), document.createTextNode(` ${Number(offer.rating || 0).toFixed(1)}`));
    const yes = el('span', 'swipe-stamp yes', 'ХОЧУ');
    const no = el('span', 'swipe-stamp no', 'ПАС');
    photo.append(el('span', 'photo-label', offer.kind === 'tour' ? 'МАРШРУТ' : 'МЕСТО ДЛЯ ТЕБЯ'), rating, yes, no);

    const body = el('div', 'card-body');
    const top = el('div', 'card-topline');
    const text = el('div');
    text.append(el('h2', '', offer.title || 'Новое место'), el('p', 'card-location', placeLine(offer)));
    const cost = el('div', 'price');
    cost.append(document.createTextNode(price(offer)), el('small', '', 'за ночь'));
    top.append(text, cost);
    body.appendChild(top);
    addTags(body, tagsOf(offer));
    if (offer.whyRecommended || offer.shortDescription) {
      const why = el('div', 'recommendation');
      const line = el('span');
      line.append(el('b', '', 'Почему тебе подойдёт: '), document.createTextNode(offer.whyRecommended || offer.shortDescription));
      why.append(el('span', '', '✳'), line);
      body.appendChild(why);
    }
    card.append(photo, body);
    stage.appendChild(card);
    bindSwipe(card, offer, yes, no);
    updateProfile();
  }

  function bindSwipe(card, offer, yesStamp, noStamp) {
    let startX = 0, dx = 0, dragging = false, pointerId = null;
    card.addEventListener('pointerdown', (event) => {
      if (state.busy || event.button > 0) return;
      dragging = true;
      pointerId = event.pointerId;
      startX = event.clientX;
      dx = 0;
      card.classList.add('dragging');
      try { card.setPointerCapture(pointerId); } catch (_) {}
    });
    card.addEventListener('pointermove', (event) => {
      if (!dragging || event.pointerId !== pointerId) return;
      dx = event.clientX - startX;
      card.style.transform = `translate3d(${dx}px,0,0) rotate(${dx / 19}deg)`;
      yesStamp.style.opacity = String(Math.min(1, Math.max(0, dx / 90)));
      noStamp.style.opacity = String(Math.min(1, Math.max(0, -dx / 90)));
    });
    const finish = (event) => {
      if (!dragging || (event && event.pointerId !== pointerId)) return;
      dragging = false;
      card.classList.remove('dragging');
      if (dx > 85) return submitSwipe(offer, true);
      if (dx < -85) return submitSwipe(offer, false);
      card.style.transform = '';
      yesStamp.style.opacity = noStamp.style.opacity = '0';
    };
    card.addEventListener('pointerup', finish);
    card.addEventListener('pointercancel', finish);
  }

  async function submitSwipe(offer, liked) {
    if (state.busy || !offer) return;
    state.busy = true;
    const card = stage.querySelector('.offer-card');
    if (card) {
      card.style.transition = 'transform .24s ease, opacity .24s ease';
      card.style.transform = `translate3d(${liked ? 120 : -120}%,0,0) rotate(${liked ? 16 : -16}deg)`;
      card.style.opacity = '0';
    }
    setStatus('Сохраняем свайп…');
    try {
      const result = await api('/v1/swipes', {
        method: 'POST',
        body: JSON.stringify({
          guestId,
          offerId: String(offer.id),
          liked,
          tags: tagsOf(offer),
          budgetTier: offer.budgetTier || 'mid',
          kind: offer.kind || 'hotel',
          countryCode: offer.countryCode || '',
        }),
      });
      state.history.unshift({ offerId: String(offer.id), liked, title: offer.title, at: Date.now() });
      if (liked && !state.saved.some((item) => String(item.id) === String(offer.id))) state.saved.unshift(offer);
      if (typeof result.likes === 'number') state.serverLikes = result.likes;
      if (typeof result.swipes === 'number') state.serverSwipes = result.swipes;
      state.deck = Array.isArray(result.deck) ? result.deck.filter((item) => String(item.id) !== String(offer.id)) : state.deck.slice(1);
      if (!state.deck.length) {
        try { state.deck = await fetchDeck(); } catch (_) {}
      }
      persist();
      renderCard();
      renderSaved();
      setStatus('Свайп учтён · подборка обновлена');
      if (liked) toast('Добавили в сохранённое ♡');
    } catch (error) {
      if (card) {
        card.style.transform = '';
        card.style.opacity = '1';
      }
      setStatus('Нет связи с API', false);
      toast(`Не удалось сохранить свайп: ${error.message}`);
    } finally {
      state.busy = false;
    }
  }

  async function fetchDeck() {
    const data = await api('/v1/recommendations', {
      method: 'POST',
      body: JSON.stringify({ guestId, skipped: true, countryCodes: [], priorityIDs: [], swipes: [] }),
    });
    return Array.isArray(data) ? data : (data.deck || []);
  }

  async function reloadDeck() {
    if (state.busy) return;
    stage.innerHTML = '<div class="loading-card"><span class="loader"></span><p>Подбираем новые места…</p></div>';
    try {
      state.deck = await fetchDeck();
      if (!state.deck.length) state.deck = await api('/v1/offers');
      renderCard();
      setStatus('Подборка готова');
    } catch (error) {
      renderError(error.message);
    }
  }

  function renderError(message) {
    stage.replaceChildren();
    stage.appendChild(emptyBox('↻', 'Не удалось загрузить карточки', message || 'Проверьте подключение к серверу.', reloadDeck, 'Попробовать ещё раз'));
    setStatus('API недоступен', false);
  }

  function renderSaved() {
    const list = $('saved-list');
    list.replaceChildren();
    $('saved-count').textContent = state.saved.length;
    $('saved-badge').textContent = state.saved.length;
    $('saved-badge').classList.toggle('hidden', !state.saved.length);
    if (!state.saved.length) {
      const empty = el('div', 'blank-state');
      empty.append(el('div', 'empty-symbol', '♡'), el('h3', '', 'Здесь будет твой вишлист'), el('p', '', 'Свайпни понравившийся отель вправо — и он останется здесь.'));
      const button = el('button', 'primary-small', 'Смотреть места');
      button.onclick = () => switchView('discover');
      empty.appendChild(button);
      list.appendChild(empty);
      return;
    }
    state.saved.forEach((offer) => {
      const card = el('article', 'saved-card');
      const photo = el('div', 'saved-photo');
      setPhoto(photo, offer);
      const info = el('div', 'saved-info');
      info.append(el('h3', '', offer.title || ''), el('p', '', placeLine(offer)), el('div', 'saved-price', `${price(offer)} / ночь`));
      const actions = el('div', 'saved-actions');
      const detail = el('button', '', 'Подробнее');
      detail.onclick = () => showOffer(offer);
      const remove = el('button', '', 'Убрать ×');
      remove.onclick = () => removeSaved(offer);
      actions.append(detail, remove);
      info.appendChild(actions);
      card.append(photo, info);
      list.appendChild(card);
    });
  }

  async function removeSaved(offer) {
    try {
      await api(`/v1/saved?guestId=${encodeURIComponent(guestId)}&offerId=${encodeURIComponent(offer.id)}`, { method: 'DELETE' });
    } catch (_) {}
    state.saved = state.saved.filter((item) => String(item.id) !== String(offer.id));
    if (typeof state.serverLikes === 'number' && state.serverLikes > 0) state.serverLikes -= 1;
    renderSaved();
    updateProfile();
  }

  function travelerName() {
    if (!telegramUser) return 'Путешественник';
    return [telegramUser.first_name, telegramUser.last_name].filter(Boolean).join(' ') || 'Путешественник';
  }

  function updateProfile() {
    $('likes-count').textContent = state.serverLikes ?? state.history.filter((item) => item.liked).length;
    $('swipes-count').textContent = state.serverSwipes ?? state.history.length;
    $('saved-count').textContent = state.saved.length;
    $('profile-name').textContent = travelerName();
    $('profile-caption').textContent = telegramUser
      ? 'Профиль Telegram · рекомендации персонализируются'
      : 'Твоя подборка становится точнее с каждым свайпом';
  }

  function switchView(name) {
    document.querySelectorAll('.view').forEach((view) => view.classList.toggle('active', view.id === `view-${name}`));
    document.querySelectorAll('.tab').forEach((tab) => tab.classList.toggle('active', tab.dataset.view === name));
    if (name === 'saved') renderSaved();
    if (name === 'profile') updateProfile();
    if (!tg?.BackButton) return;
    if (name === 'discover') tg.BackButton.hide();
    else {
      tg.BackButton.show();
      tg.BackButton.onClick(() => switchView('discover'));
    }
  }

  function showOffer(offer) {
    const dialog = $('offer-dialog');
    const content = $('dialog-content');
    content.replaceChildren();
    const photo = el('div', 'dialog-photo');
    setPhoto(photo, offer);
    const body = el('div', 'dialog-body');
    body.append(
      el('p', 'eyebrow', offer.kind === 'tour' ? 'МАРШРУТ' : 'ПОДОБРАНО ДЛЯ ТЕБЯ'),
      el('h2', '', offer.title || ''),
      el('p', 'card-location', `${placeLine(offer)} · ★ ${Number(offer.rating || 0).toFixed(1)}`),
      el('p', 'dialog-description', offer.description || offer.shortDescription || 'Описание скоро появится.'),
      el('p', 'dialog-description', `${price(offer)} за ночь`),
    );
    addTags(body, tagsOf(offer));
    if (Array.isArray(offer.reviews) && offer.reviews.length) {
      const reviews = el('div', 'dialog-reviews');
      reviews.appendChild(el('h3', '', 'Что говорят гости'));
      offer.reviews.slice(0, 3).forEach((review) => {
        const item = el('div', 'review');
        item.append(
          el('strong', '', `${review.author || 'Гость'} · ★ ${Number(review.rating || 0).toFixed(1)}`),
          document.createTextNode(review.text || ''),
        );
        reviews.appendChild(item);
      });
      body.appendChild(reviews);
    }
    const like = el('button', 'dialog-like', state.saved.some((item) => String(item.id) === String(offer.id)) ? 'Уже в сохранённом ✓' : '♡ Сохранить место');
    like.onclick = () => {
      if (!state.saved.some((item) => String(item.id) === String(offer.id))) {
        state.saved.unshift(offer);
        renderSaved();
        updateProfile();
      }
      dialog.close();
      switchView('saved');
    };
    body.appendChild(like);
    content.append(photo, body);
    if (typeof dialog.showModal === 'function') dialog.showModal();
    else dialog.setAttribute('open', '');
  }

  function addMessage(text, role) {
    const row = el('div', `message ${role}`);
    if (role === 'assistant') row.appendChild(el('span', 'assistant-avatar', '✳'));
    row.appendChild(el('div', 'bubble', text));
    $('chat-messages').appendChild(row);
    $('chat-messages').scrollTop = $('chat-messages').scrollHeight;
    return row;
  }

  async function sendChat(message) {
    const text = message.trim();
    if (!text || state.chatBusy) return;
    state.chatBusy = true;
    addMessage(text, 'user');
    $('chat-input').value = '';
    const pending = addMessage('Секунду, ищу по каталогу…', 'assistant');
    try {
      const reply = await api('/v1/agent/chat', {
        method: 'POST',
        body: JSON.stringify({ guestId, message: text, liked: state.saved.slice(0, 10) }),
      });
      pending.querySelector('.bubble').textContent = reply.text || 'Уточни направление или бюджет.';
      (reply.offers || []).forEach((offer) => {
        const button = el('button', 'primary-small', `${offer.title} · ${price(offer)}`);
        button.style.margin = '6px 0 0 35px';
        button.onclick = () => showOffer(offer);
        $('chat-messages').appendChild(button);
      });
      if (reply.intent === 'booking') toast('Заявка на бронирование создана');
    } catch (error) {
      pending.querySelector('.bubble').textContent = `Не удалось связаться с помощником: ${error.message}`;
    } finally {
      state.chatBusy = false;
      $('chat-messages').scrollTop = $('chat-messages').scrollHeight;
    }
  }

  async function loadServerState() {
    const [items, profile] = await Promise.all([
      api(`/v1/saved?guestId=${encodeURIComponent(guestId)}`),
      api(`/v1/profile?guestId=${encodeURIComponent(guestId)}`),
    ]);
    if (Array.isArray(items)) state.saved = items;
    if (profile) {
      state.serverLikes = profile.likes;
      state.serverSwipes = profile.swipes;
    }
  }

  $('like').addEventListener('click', () => submitSwipe(state.deck[0], true));
  $('nope').addEventListener('click', () => submitSwipe(state.deck[0], false));
  $('details').addEventListener('click', () => state.deck[0] && showOffer(state.deck[0]));
  $('close-dialog').addEventListener('click', () => $('offer-dialog').close());
  $('profile-shortcut').addEventListener('click', () => switchView('profile'));
  document.querySelectorAll('.tab').forEach((tab) => tab.addEventListener('click', () => switchView(tab.dataset.view)));
  $('chat-form').addEventListener('submit', (event) => {
    event.preventDefault();
    sendChat($('chat-input').value);
  });
  document.querySelectorAll('[data-prompt]').forEach((button) => {
    button.addEventListener('click', () => sendChat(button.dataset.prompt));
  });
  $('reset-session').addEventListener('click', () => {
    if (!confirm('Очистить локальный кэш на этом устройстве? Лайки в PostgreSQL останутся.')) return;
    state.history = [];
    persist();
    updateProfile();
    toast('Локальный кэш очищен');
  });

  async function start() {
    setStatus(tg ? 'Telegram подключён' : 'Веб-режим');
    $('profile-name').textContent = travelerName();
    try {
      await api('/health');
      const [deck] = await Promise.all([fetchDeck(), loadServerState()]);
      state.deck = deck.length ? deck : await api('/v1/offers');
      const savedIds = new Set(state.saved.map((item) => String(item.id)));
      state.deck = state.deck.filter((offer) => !savedIds.has(String(offer.id)));
      renderCard();
      renderSaved();
      setStatus('Подборка готова');
    } catch (error) {
      renderError(`${error.message}. Проверь, что Go API и PostgreSQL запущены.`);
    }
    updateProfile();
  }

  start();
})();
