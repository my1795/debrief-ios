# Billing & Stats Architecture

**Version:** 2.0
**Date:** 2025-01-20
**Status:** Final Design

---

## 1. Overview

Bu doküman Debrief uygulamasının billing (faturalandırma) ve stats (istatistik) mimarisini tanımlar.

### Temel Prensipler

1. **Source of Truth:** `debriefs` collection - tüm hesaplamalar buradan türetilir
2. **Billing ve Stats ayrımı:** Farklı hafta tanımları, farklı amaçlar
3. **Lazy Evaluation:** Gereksiz scheduled job'lar yerine istek anında kontrol
4. **Eventual Consistency:** Stats için kabul edilebilir, billing için strict

---

## 2. İki Hafta Tipi

### 2.1 Billing Week (User-specific)

```
Amaç: Quota kontrolü (kullanıcı limit aştı mı?)

Başlangıç: User'ın ilk token exchange'i
Döngü: Her 7 gün (kullanıcıya özel)
Reset: Lazy (user istek yapınca kontrol edilir)

Örnek:
- User A: 15 Ocak'ta kayıt → 15-22 Ocak, 22-29 Ocak, ...
- User B: 18 Ocak'ta kayıt → 18-25 Ocak, 25 Ocak-1 Şubat, ...
```

### 2.2 Stats Week (Calendar)

```
Amaç: İstatistik gösterimi ve karşılaştırma

Başlangıç: Pazar 00:00:00 UTC
Bitiş: Cumartesi 23:59:59 UTC
Döngü: Evrensel, tüm kullanıcılar için aynı

Epoch hesaplama:
- Week start = Son Pazar 00:00 UTC (epoch ms)
- Week end = Sonraki Pazar 00:00 UTC (epoch ms)
```

---

## 3. Subscription & Tier Model

### 3.1 Subscription

| Alan | Değer |
|------|-------|
| Billing Cycle | **Monthly** (aylık ödeme) |
| Quota Period | **Weekly** (haftalık limit) |
| Grace Period | Yok |
| Expiry Trigger | App Store / Play Store Webhook |

### 3.2 Tier Limits

```kotlin
enum class SubscriptionTier(
    val weeklyDebriefs: Int,
    val weeklySeconds: Int,
    val storageLimitMB: Int
) {
    FREE(
        weeklyDebriefs = 50,
        weeklySeconds = 1800,       // 30 dakika
        storageLimitMB = 500
    ),
    PERSONAL(
        weeklyDebriefs = Int.MAX_VALUE,  // unlimited
        weeklySeconds = 9000,       // 150 dakika
        storageLimitMB = Int.MAX_VALUE
    ),
    PRO(
        weeklyDebriefs = Int.MAX_VALUE,
        weeklySeconds = Int.MAX_VALUE,
        storageLimitMB = Int.MAX_VALUE
    )
}
```

### 3.3 Global Constants

```kotlin
object BillingConstants {
    const val MAX_DEBRIEF_DURATION_SEC = 600  // 10 dakika, tüm tier'lar için
    const val BILLING_WEEK_DAYS = 7
    const val SUBSCRIPTION_MONTH_DAYS = 30
}
```

---

## 4. Data Model

### 4.1 Collections Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        COLLECTIONS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  user_plans            Tier, billing week, weekly usage        │
│  user_weekly_history   Geçmiş haftaların archive'ı             │
│  debriefs              Source of truth (mevcut)                │
│  usage_records         Event log (DEBRIEF_SAVED)               │
│  stats_cache           Query-based cache (epoch time)          │
│  pending_tasks         Outbox pattern (async işler)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 user_plans

```
Collection: user_plans
Document ID: {userId}

{
  odda: string,                    // User ID
  tier: "FREE" | "PERSONAL" | "PRO",

  // Billing week (user-specific, 7 gün döngüsü)
  billingWeekStart: number,       // epoch ms
  billingWeekEnd: number,         // epoch ms

  // Weekly usage (incremental, hızlı okuma için)
  weeklyUsage: {
    debriefCount: number,
    totalSeconds: number
  },

  // Storage (lifetime, reset olmaz)
  usedStorageMB: number,

  // Subscription (monthly)
  subscriptionStart: number,      // epoch ms
  subscriptionEnd: number | null, // epoch ms, FREE ise null

  createdAt: number               // epoch ms
}
```

### 4.3 user_weekly_history

```
Collection: user_weekly_history
Document ID: {userId}_{startTime}

{
  odda: string,
  startTime: number,              // epoch ms - billing week başı
  endTime: number,                // epoch ms - billing week sonu
  totalSeconds: number,
  debriefCount: number,
  tier: string                    // O haftaki tier
}
```

### 4.4 usage_records

```
Collection: usage_records
Document ID: auto-generated

{
  recordId: string,
  type: "DEBRIEF_SAVED",          // Şimdilik tek tip, gelecekte genişletilebilir
  userId: string,
  contactId: string | null,
  contactName: string | null,
  email: string | null,
  durationSec: number,
  wordCount: number,
  debriefId: string,
  createdAt: number               // epoch ms
}

Not: DEBRIEF_SAVED sadece processing READY olunca yazılır (failed sayılmaz)
```

### 4.5 stats_cache

```
Collection: stats_cache
Document ID: auto-generated

{
  userId: string,
  contactId: string | null,       // User-level ise null
  startTime: number,              // epoch ms - period başı
  endTime: number,                // epoch ms - period sonu
  totalSeconds: number,
  debriefCount: number,
  expiresAt: number               // TTL (epoch ms)
}

Query örneği:
  .where("userId", "==", userId)
  .where("contactId", "==", null)  // veya contactId
  .where("startTime", "==", periodStart)
  .where("endTime", "==", periodEnd)
```

### 4.6 pending_tasks

```
Collection: pending_tasks
Document ID: auto-generated

{
  taskId: string,
  type: "ARCHIVE_WEEKLY_HISTORY", // Task tipi
  status: "PENDING" | "PROCESSING" | "FAILED",
  payload: {
    odda: string,
    startTime: number,
    endTime: number,
    totalSeconds: number,
    debriefCount: number,
    tier: string
  },
  createdAt: number,              // epoch ms
  retryCount: number,
  lastError: string | null
}

Worker Schedule:
  - App startup
  - Günlük 03:00 UTC
```

---

## 5. Core Flows

### 5.1 İlk Kullanıcı Kaydı (First Token Exchange)

```
POST /v1/auth/token (ilk kez)
         │
         ▼
┌─────────────────────────────────────────────────┐
│  user_plans/{userId} oluştur                    │
│                                                 │
│  {                                              │
│    odda: userId,                                │
│    tier: "FREE",                                │
│    billingWeekStart: now(),                     │
│    billingWeekEnd: now() + 7 days,              │
│    weeklyUsage: { debriefCount: 0, totalSeconds: 0 },│
│    usedStorageMB: 0,                            │
│    subscriptionStart: now(),                    │
│    subscriptionEnd: null,                       │
│    createdAt: now()                             │
│  }                                              │
└─────────────────────────────────────────────────┘
```

### 5.2 Debrief Oluşturma

```
POST /v1/debriefs (durationSec, audio, ...)
         │
         ▼
┌─────────────────────────────────────────────────┐
│  1. VALIDATION                                  │
│     if (durationSec > MAX_DEBRIEF_DURATION_SEC) │
│       → 400 Bad Request                         │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  2. GET PLAN (with lazy week reset)             │
│                                                 │
│     plan = getUserPlan(userId)                  │
│     if (now > plan.billingWeekEnd) {            │
│       // Hafta dolmuş                           │
│       // Transaction: plan update + outbox task │
│       resetBillingWeek(plan)                    │
│     }                                           │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  3. QUOTA CHECK (soft limit - flexible)         │
│                                                 │
│     usage = plan.weeklyUsage                    │
│     limits = getTierLimits(plan.tier)           │
│                                                 │
│     if (usage.debriefCount >= limits.weekly)    │
│       → 402 { code: "QUOTA_EXCEEDED",           │
│               reason: "debrief_limit" }         │
│                                                 │
│     if (usage.totalSeconds + duration >         │
│         limits.weeklySeconds)                   │
│       → 402 { code: "QUOTA_EXCEEDED",           │
│               reason: "minutes_limit" }         │
│                                                 │
│     if (plan.usedStorageMB + audioMB >          │
│         limits.storageLimitMB)                  │
│       → 402 { code: "QUOTA_EXCEEDED",           │
│               reason: "storage_limit" }         │
│                                                 │
│     Not: Soft limit - race condition'da biraz   │
│          aşılabilir, sorun değil                │
└─────────────────────────────────────────────────┘
         │ OK
         ▼
┌─────────────────────────────────────────────────┐
│  4. SAVE DEBRIEF (status: CREATED)              │
│  5. UPLOAD AUDIO                                │
│  6. START BACKGROUND PROCESSING                 │
└─────────────────────────────────────────────────┘
         │
         ▼
   Return 202 Accepted
   (Quota henüz düşmedi - READY olunca düşecek)


[Background Processing - Async]
         │
         ├── FAILED → Quota düşmez, retry logic
         │
         └── SUCCESS (status: READY)
                  │
                  ▼
         ┌─────────────────────────────────────────┐
         │  ON READY:                              │
         │                                         │
         │  1. Increment plan.weeklyUsage          │
         │     • debriefCount++                    │
         │     • totalSeconds += duration          │
         │                                         │
         │  2. Increment plan.usedStorageMB        │
         │     • usedStorageMB += audioMB          │
         │                                         │
         │  3. Write usage_records                 │
         │     • type: DEBRIEF_SAVED               │
         │     • userId, contactId, duration, etc. │
         │                                         │
         └─────────────────────────────────────────┘
```

### 5.3 Debrief Silme

```
DELETE /v1/debriefs/{debriefId}
         │
         ▼
┌─────────────────────────────────────────────────┐
│  1. Get debrief (need audioSizeBytes)           │
│  2. Delete audio from storage                   │
│  3. Delete debrief document                     │
│  4. Decrement plan.usedStorageMB                │
│                                                 │
│  NOT: weeklyUsage düşmez (count/seconds)        │
│       Sadece storage iade edilir                │
└─────────────────────────────────────────────────┘
```

### 5.4 Billing Week Reset (Lazy)

```
User istek yaptı, billingWeekEnd < now()
         │
         ▼
┌─────────────────────────────────────────────────┐
│  TRANSACTION (atomic)                           │
│                                                 │
│  1. user_plans/{userId} güncelle:               │
│     • billingWeekStart = now                    │
│     • billingWeekEnd = now + 7 days             │
│     • weeklyUsage = { count: 0, seconds: 0 }    │
│                                                 │
│  2. pending_tasks oluştur:                      │
│     • type: ARCHIVE_WEEKLY_HISTORY              │
│     • status: PENDING                           │
│     • payload: { eski hafta verileri }          │
│                                                 │
└─────────────────────────────────────────────────┘
         │
         ▼
   Devam et (quota check, vs.)
   Archive işlemi background worker'da yapılacak
```

### 5.5 Tier Upgrade

```
Webhook: User upgraded FREE → PERSONAL
         │
         ▼
┌─────────────────────────────────────────────────┐
│  TRANSACTION (atomic)                           │
│                                                 │
│  1. Eski haftayı archive et (pending_task)      │
│                                                 │
│  2. user_plans/{userId} güncelle:               │
│     • tier = PERSONAL                           │
│     • billingWeekStart = now (RESET)            │
│     • billingWeekEnd = now + 7 days             │
│     • weeklyUsage = { count: 0, seconds: 0 }    │
│     • subscriptionStart = now                   │
│     • subscriptionEnd = now + 30 days           │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 5.6 Tier Downgrade (Subscription Expired)

```
Webhook: Subscription expired (PERSONAL → FREE)
         │
         ▼
┌─────────────────────────────────────────────────┐
│  TRANSACTION (atomic)                           │
│                                                 │
│  1. Eski haftayı archive et (pending_task)      │
│                                                 │
│  2. user_plans/{userId} güncelle:               │
│     • tier = FREE                               │
│     • billingWeekStart = now (RESET)            │
│     • billingWeekEnd = now + 7 days             │
│     • weeklyUsage = { count: 0, seconds: 0 }    │
│     • subscriptionEnd = null                    │
│                                                 │
│  Not: usedStorageMB reset olmaz (lifetime)      │
│       Eğer limit aşıyorsa yeni debrief          │
│       oluşturamaz, silmesi gerekir              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 5.7 Stats Query (Weekly Comparison)

```
GET /v1/stats/weekly-comparison
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Calculate CALENDAR weeks (Pazar-Pazar UTC)     │
│                                                 │
│  thisWeekStart = lastSunday(now)  // epoch ms   │
│  lastWeekStart = thisWeekStart - 7 days         │
│  lastWeekEnd = thisWeekStart                    │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  1. Check stats_cache                           │
│     .where("userId", "==", userId)              │
│     .where("startTime", "==", weekStart)        │
│     .where("endTime", "==", weekEnd)            │
│                                                 │
│  2. Cache miss → Query debriefs                 │
│     .where("userId", "==", userId)              │
│     .where("createdAt", ">=", weekStart)        │
│     .where("createdAt", "<", weekEnd)           │
│     .where("status", "==", "READY")             │
│                                                 │
│  3. Aggregate: SUM(duration), COUNT(*)          │
│  4. Write to stats_cache (with TTL)             │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Response:                                      │
│  {                                              │
│    thisWeek: {                                  │
│      startTime: 1737158400000,                  │
│      endTime: 1737763200000,                    │
│      totalSeconds: 450,                         │
│      debriefCount: 3                            │
│    },                                           │
│    lastWeek: {                                  │
│      startTime: 1736553600000,                  │
│      endTime: 1737158400000,                    │
│      totalSeconds: 600,                         │
│      debriefCount: 5                            │
│    },                                           │
│    comparison: {                                │
│      secondsDiff: -150,                         │
│      percentChange: -25.0                       │
│    }                                            │
│  }                                              │
└─────────────────────────────────────────────────┘
```

---

## 6. Background Worker

### 6.1 Pending Task Worker

```kotlin
@Service
class PendingTaskWorker {

    // App başladığında
    @PostConstruct
    fun onStartup() {
        processPendingTasks()
    }

    // Günde 1 kez, 03:00 UTC
    @Scheduled(cron = "0 0 3 * * *", zone = "UTC")
    fun dailyProcess() {
        processPendingTasks()
    }

    private fun processPendingTasks() {
        // Query: status == PENDING
        // Process each task
        // On success: delete task
        // On failure: increment retryCount, mark FAILED after 3 retries
    }
}
```

### 6.2 Task Types

```kotlin
enum class TaskType {
    ARCHIVE_WEEKLY_HISTORY,
    // Gelecekte eklenebilir:
    // SEND_QUOTA_WARNING_EMAIL,
    // CLEANUP_EXPIRED_CACHE,
    // GENERATE_MONTHLY_REPORT,
}
```

---

## 7. Firestore Indexes

```
// user_plans
(userId) - Primary key

// debriefs - quota check & stats
(userId, createdAt DESC)
(userId, status, createdAt DESC)

// stats_cache
(userId, contactId, startTime, endTime)

// pending_tasks
(status, type, createdAt)

// usage_records
(userId, createdAt DESC)
(userId, contactId, createdAt DESC)

// user_weekly_history
(userId, startTime DESC)
```

---

## 8. Error Codes

```kotlin
enum class BillingErrorCode {
    QUOTA_EXCEEDED,           // 402 - Limit aşıldı
    INVALID_DURATION,         // 400 - Duration > 600 sec
    SUBSCRIPTION_REQUIRED,    // 402 - Bu özellik için upgrade gerekli
    STORAGE_LIMIT_EXCEEDED,   // 402 - Storage dolu
}

// Response format
{
    "code": "QUOTA_EXCEEDED",
    "reason": "minutes_limit",  // veya "debrief_limit", "storage_limit"
    "message": "Weekly recording limit exceeded",
    "currentUsage": {
        "debriefCount": 50,
        "totalSeconds": 1800,
        "storageMB": 450
    },
    "limits": {
        "weeklyDebriefs": 50,
        "weeklySeconds": 1800,
        "storageLimitMB": 500
    }
}
```

---

## 9. Migration Plan

### Phase 1: Data Model (Mevcut → Yeni)

```
Mevcut: user_quotas
Yeni: user_plans

Migration:
1. user_plans collection oluştur
2. Mevcut user_quotas'tan tier, usage bilgilerini migrate et
3. billingWeekStart/End hesapla (mevcut period bilgisinden)
4. Test et
5. Eski collection'ı deprecate et
```

### Phase 2: Code Changes

```
1. UserPlanService oluştur (yeni logic)
2. DebriefService'i güncelle (READY'de quota increment)
3. StatsService'i güncelle (calendar week)
4. PendingTaskWorker ekle
5. Webhook handler'ları güncelle
```

---

## 10. Appendix

### A. Epoch Time Utilities

```kotlin
object EpochUtils {
    const val WEEK_MS = 7 * 24 * 60 * 60 * 1000L
    const val DAY_MS = 24 * 60 * 60 * 1000L

    fun now(): Long = Instant.now().toEpochMilli()

    fun getCalendarWeekStart(timestamp: Long = now()): Long {
        val zdt = Instant.ofEpochMilli(timestamp)
            .atZone(ZoneOffset.UTC)
        val sunday = zdt.with(DayOfWeek.SUNDAY)
            .truncatedTo(ChronoUnit.DAYS)
        // Eğer bugün Pazar değilse, geçen Pazar'a git
        return if (zdt.dayOfWeek == DayOfWeek.SUNDAY) {
            sunday.toInstant().toEpochMilli()
        } else {
            sunday.minusWeeks(1).toInstant().toEpochMilli()
        }
    }

    fun getCalendarWeekEnd(timestamp: Long = now()): Long {
        return getCalendarWeekStart(timestamp) + WEEK_MS
    }
}
```

### B. Soft Limit Rationale

```
Neden soft limit?
─────────────────
1. Race condition'da strict check için distributed lock gerekir
2. Distributed lock = complexity + latency
3. Biraz aşım (1-2 debrief) kabul edilebilir
4. Kullanıcı deneyimi daha iyi (hata yerine işlem tamamlanır)
5. Abuse riski düşük (haftalık reset var)
```

### C. Why Quota on READY (not CREATED)?

```
Neden READY'de quota düşülüyor?
───────────────────────────────
1. CREATED'da düşsek, fail eden debrief'ler kullanıcıyı cezalandırır
2. Retry mekanizması var - aynı debrief birden fazla kez fail edebilir
3. Kullanıcı açısından adil: sadece başarılı işlemler sayılır
4. Storage da aynı mantık: sadece READY olunca sayılır
```
