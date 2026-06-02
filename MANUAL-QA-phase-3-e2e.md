# Manual QA — Phase 3 E2E (после Step 3.8)

**Когда прогонять:** после merge **Step 3.8** (`ActiveCallScreen` + способ инициировать звонок из UI).

**Цель одного прогона:** закрыть deferred manual acceptance для **3.6**, **3.7**, **3.8** и проверить **Phase 3 DoD** (PLAN §8).

---

## Prerequisites

| Что | Проверка |
|-----|----------|
| Supabase project | Edge Functions задеплоены (3.3), migration 0010 pg_cron (3.4) |
| LiveKit dev | `LIVEKIT_WS_URL=wss://vibecall-lk-dev.visitufa.online` в `client/.env` |
| Docker / tunnel | LiveKit + Cloudflare Tunnel подняты (Step 3.2) |
| 2 аккаунта | **User A** (caller), **User B** (receiver) — разные email, onboarding пройден |
| Контакты | A и B в контактах друг у друга (accepted) |
| Браузер | Chrome: обычное окно + **Incognito** (или второй профиль) |
| Микрофон/кamera | Разрешения выданы в обоих окнах |

```powershell
cd client
flutter pub get
# Окно 1 (User A)
flutter run -d chrome --dart-define-from-file=.env
# Окно 2 (User B) — другой порт если нужно, или второй flutter run
flutter run -d chrome --dart-define-from-file=.env --web-port=8081
```

> Если кнопки «Позвонить» ещё нет в UI после 3.8 — **не начинать QA**; дождаться PR с кнопкой в contacts/search или добавить в scope 3.8.

---

## Чеклист

Отмечайте `[x]` по факту. Скриншот/короткое видео для первого успешного video-call — полезно для PR/issue.

### A. Step 3.7 — Incoming overlay + BroadcastChannel

| # | Сценарий | Шаги | OK |
|---|----------|------|-----|
| A1 | **Leader election (2 вкладки)** | User B: залогиниться, открыть **2 вкладки** на `/home`. User A: видеозвонок → B. | [ ] Overlay «Входящий звонок» виден **только в одной** вкладке B |
| A2 | **Reject + dismiss sync** | В leader-вкладке B нажать **Отклонить**. | [ ] Overlay закрылся в leader; во **второй** вкладке B overlay **не висит** |
| A3 | **Повторный incoming** | User A звонит B снова (без перезагрузки). | [ ] Overlay снова появляется (idle после reject) |
| A4 | **Accept → переход** | User A звонит, B нажимает **Ответить**. | [ ] Overlay закрылся, открылся **ActiveCallScreen** (3.8) |

### B. Step 3.6 — CallController + LiveKit

| # | Сценарий | Шаги | OK |
|---|----------|------|-----|
| B1 | **Connect (video)** | A звонит, B принимает. | [ ] Оба видят local + remote video, слышат audio |
| B2 | **Mute** | B включает mute на ActiveCallScreen. | [ ] A **не слышит** B; индикатор mute у B |
| B3 | **Camera off** | B выключает camera. | [ ] У A remote video **пропадает/заморожено**; у B local preview off |
| B4 | **Hangup (callee)** | B завершает звонок. | [ ] Оба → экран «Звонок завершён» / idle; LiveKit room disconnected |
| B5 | **Hangup (caller)** | A звонит, B принимает, **A** кладёт трубку. | [ ] Оба корректно выходят из звонка |
| B6 | **Cancel (caller до accept)** | A звонит, B **не** отвечает, A отменяет (если есть UI cancel / back). | [ ] У B overlay исчезает; state idle |
| B7 | **Reject (API path)** | A звонит, B **Отклонить** (не из A1–A3, отдельный прогон). | [ ] У A outcome rejected / звонок завершён; повторный звонок возможен |

### C. Step 3.8 — Active call screen

| # | Сценарий | Шаги | OK |
|---|----------|------|-----|
| C1 | **Video UI** | Активный видеозвонок. | [ ] Два `VideoTrackWidget`, HUD (mute, camera, end) |
| C2 | **Audio-only** | Аудиозвонок (`has_video=false`). | [ ] Аватар + индикатор audio (без обязательного video) |
| C3 | **Ended screen** | Завершить звонок после ≥5 сек разговора. | [ ] Экран «Завершён» с **длительностью** |
| C4 | **Mute/camera e2e** | Дублирует B2/B3 — подтверждение на UI 3.8. | [ ] Трек реально перестаёт публиковаться |

### D. Phase 3 DoD — доп. сценарии (PLAN)

| # | Сценарий | Шаги | OK |
|---|----------|------|-----|
| D1 | **Busy** | B уже в активном звонке с C (или симуляция busy 409). A звонит B. | [ ] A видит busy / звонок не установлен |
| D2 | **Timeout** | A звонит B, B **не** отвечает ~45+ сек (pg_cron). | [ ] Invitation → missed/timeout; overlay у B закрывается |
| D3 | **Аудио-звонок e2e** | A → B audio-only, accept, hangup. | [ ] Работает без video |

### E. Step 3.9 — Call history

| # | Сценарий | Шаги | OK |
|---|----------|------|-----|
| E1 | **История: accept + hangup** | Завершить принятый звонок (B4/C3). Открыть `/call-history`. | [x] user QA 2026-06-02 — запись в «Все» с duration mm:ss |
| E2 | **История: terminal outcomes** | Провести сценарии B6 (cancel), B7 (reject), D2 (timeout). | [x] user QA 2026-06-02 — все три попадают в `call_history` (trigger 0015) |
| E3 | **Фильтр «Пропущенные»** | На `/call-history` переключить на «Пропущенные». | [x] user QA 2026-06-02 — только входящие missed/timeout/cancelled; rejected скрыт |
| E4 | **Pull-to-refresh** | Потянуть список вниз. | [ ] optional (не прогонялся явно) |

---

## После успешного прогона

1. **PLAN.md** — вручную или docs-PR: поставить `[x]` на deferred manual в Step 3.6, 3.7, 3.8 (с датой / «user QA YYYY-MM-DD»).
2. **README / Phase 3** — при полном DoD можно отметить «Phase 3 manual e2e verified».
3. Опционально: комментарий в закрытом PR #48 / issue с «QA passed».
4. **Step 3.9** — см. секцию E (выше); docs-close: PR по `docs(plan): close Step 3.9 call history`.

---

## Troubleshooting

| Симптом | Что проверить |
|---------|----------------|
| Нет incoming overlay | B в ShellRoute (`/home`), session active, Realtime подключён |
| Overlay в обеих вкладках | BroadcastChannel / leader election — bug, зафиксировать |
| Black video | Camera permission, `LIVEKIT_WS_URL`, tunnel LiveKit |
| 409 busy | `call_invitations` stuck `ringing` — reject/cancel или ждать timeout |
| Edge 401/500 | Supabase auth session, Edge secrets, LiveKit keys |
| `flutter run` l10n noise | `git restore client/lib/l10n/*` после run |

---

## Минимальный smoke (если мало времени)

Обязательный минимум перед merge docs «Phase 3 QA done»:

1. **A1** — одна вкладка rings  
2. **A2 + A3** — reject + повторный incoming  
3. **B1 + B4** — video connect + hangup  
4. **C3** — ended screen с duration  

Остальное — по возможности в том же сеансе.
