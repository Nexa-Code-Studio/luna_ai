# Luna AI Mobile Specification (`apps/luna_mobile`)

> **Purpose:** Technical specification for the Flutter cross-platform mobile app, Clean Architecture layout, Riverpod state management, and Static-to-Dynamic backend switching mechanism.

---

## 1. Tech Stack & State Management

- **Framework:** Flutter (Dart 3.11+ / SDK ^3.11.5)
- **State Management & DI:** `flutter_riverpod` (^2.6.1)
- **HTTP Client:** `http` (^1.2.2) with custom `ApiClient` wrapper
- **Typography & UI:** Google Fonts (`google_fonts`), Cupertino Icons, Glassmorphism design system (`GlassCard`)
- **Serialization:** Pure Dart models with manual `fromJson`, `toJson`, and `copyWith` (zero `build_runner` code generation dependency).

---

## 2. Clean Architecture Directory Structure

All features reside under `lib/features/<feature_name>/` following strict layer separation:

```
apps/luna_mobile/lib/
  ├── core/
  │   ├── config/
  │   │   └── app_config.dart          # Environment config & useMockData toggle
  │   └── network/
  │       └── api_client.dart          # REST API HTTP wrapper
  │
  ├── features/
  │   ├── auth/                        # User authentication & crisis contacts
  │   ├── chat/                        # AI Counseling chat & conversation list
  │   ├── diary/                       # AI Diary entries, synthesis & detail
  │   ├── recommendations/             # Calmness & coping recommendations
  │   ├── voice_call/                  # Real-time VAD voice call session
  │   └── monitoring/                  # Emotional trend & mood analytics
  │       ├── domain/
  │       │   ├── entities/            # Immutable domain entities
  │       │   └── repositories/        # Abstract repository contracts (interfaces)
  │       ├── data/
  │       │   ├── models/              # DTOs with fromJson, toJson, copyWith
  │       │   ├── datasources/         # MockDataSource & RemoteDataSource
  │       │   └── repositories/        # Repository implementations
  │       └── presentation/
  │           └── providers/           # Riverpod Providers & Notifiers
  │
  ├── screens/                         # UI Screens (ConsumerWidget / ConsumerStatefulWidget)
  └── theme/                           # App colors & ThemeData
```

---

## 3. Static to Dynamic Mode Switcher (`AppConfig.useMockData`)

The switching mechanism is governed by `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  /// Global toggle: true = Static Mock Data, false = Remote Backend API
  static bool useMockData = true;

  static String baseUrl = 'http://localhost:8000/api/v1';
}
```

### How Riverpod me-resolve DataSources:
Every feature's Riverpod Provider checks `AppConfig.useMockData` at runtime:

```dart
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  if (AppConfig.useMockData) {
    return DiaryRepositoryImpl(MockDiaryDataSource());
  } else {
    return DiaryRepositoryImpl(RemoteDiaryDataSource());
  }
});
```

To connect the mobile app to a live FastAPI backend:
1. Set `AppConfig.useMockData = false;`
2. Update `AppConfig.baseUrl` to target the FastAPI host.
3. No UI code changes are needed.

---

## 4. Application Routes (`lib/main.dart`)

- `/` -> `SplashOnboardingScreen`
- `/login` -> `LoginScreen`
- `/register` -> `RegisterScreen`
- `/home` -> `MainShellScreen` (Bottom Navigation Shell)
- `/chat` -> `AiConversationScreen`
- `/voice_call` -> `VoiceCallScreen`
- `/diary` -> `AiDiaryScreen`
- `/diary_detail` -> `AiDiaryDetailScreen`
- `/monitoring` -> `MonitoringScreen`
- `/recommendation` -> `RecommendationScreen`
- `/support` -> `SupportEmergencyScreen`
- `/profile` -> `ProfileScreen`
- `/emergency_contacts` -> `EmergencyContactsScreen`

---

## 5. Data Contract Mapping to Backend API

Mapping of Flutter Clean Architecture DTO models to FastAPI REST Endpoints & backend tables:

- **`UserModel`** $\leftrightarrow$ `GET /auth/me` $\leftrightarrow$ PostgreSQL `users` table
- **`EmergencyContactModel`** $\leftrightarrow$ `GET /users/emergency-contacts` $\leftrightarrow$ PostgreSQL `emergency_contacts` table
- **`ConversationModel`** $\leftrightarrow$ `GET /conversations/{id}` $\leftrightarrow$ PostgreSQL `conversations` & `conversation_summaries`
- **`ChatMessageModel`** $\leftrightarrow$ `POST /conversations/{id}/messages` $\leftrightarrow$ PostgreSQL `messages` & `emotion_analyses`
- **`DiaryEntryModel`** $\leftrightarrow$ `GET /diaries` $\leftrightarrow$ PostgreSQL `conversation_summaries` & `memories`
- **`RiskWarningModel`** $\leftrightarrow$ `GET /diaries/{id}` $\leftrightarrow$ PostgreSQL `safety_events` & `safety_analyses`
- **`RecommendationModel`** $\leftrightarrow$ `GET /recommendations` $\leftrightarrow$ PostgreSQL `knowledge_chunks` (`rag.py`)
- **`VoiceSessionModel`** $\leftrightarrow$ `POST /voice/calls/start` $\leftrightarrow$ PostgreSQL `voice_sessions` & `voice_turns`
- **`MonitoringDataModel`** $\leftrightarrow$ `GET /analytics/monitoring` $\leftrightarrow$ Aggregated `emotion_analyses` & `safety_analyses`
