# Arquitectura Flutter - Escritor App

## Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura en Capas](#arquitectura-en-capas)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Diagrama de Dependencias](#diagrama-de-dependencias)
6. [Patrones de Diseño](#patrones-de-diseño)
7. [Modelo de Datos](#modelo-de-datos)
8. [Flujo de Sincronización](#flujo-de-sincronización)
9. [Módulo de Autenticación](#módulo-de-autenticación)
10. [Módulo de Proyectos](#módulo-de-proyectos)
11. [Módulo de Capítulos](#módulo-de-capítulos)
12. [Módulo de Editor](#módulo-de-editor)
13. [Routing y Navegación](#routing-y-navegación)
14. [Tema y UI](#tema-y-ui)
15. [Code Generation](#code-generation)
16. [Configuración y Ejecución](#configuración-y-ejecución)

---

## Visión General

Escritor App es una aplicación Flutter multiplataforma para gestión de proyectos literarios. Permite a los usuarios crear proyectos, organizar capítulos y editar contenido con un editor rico, todo con soporte **offline-first** y sincronización automática.

**Características principales:**
- Autenticación con JWT
- Gestión de proyectos literarios (CRUD)
- Gestión de capítulos/escritos (CRUD)
- Editor enriquecido con soporte Markdown
- Offline-first con SQLite (Drift)
- Sincronización automática con cola de reintentos
- Upload de imágenes al backend

---

## Stack Tecnológico

| Capa | Tecnología | Versión | Propósito |
|------|-----------|---------|-----------|
| **Framework** | Flutter | 3.x | UI multiplataforma |
| **Lenguaje** | Dart | 3.11+ | Lenguaje principal |
| **State Management** | Riverpod | 2.6+ | Gestión de estado reactivo |
| **Routing** | go_router | 14.7+ | Navegación declarativa con guards |
| **HTTP Client** | Dio | 5.7+ | Cliente HTTP con interceptores |
| **Base de Datos Local** | Drift | 2.20+ | ORM SQLite type-safe |
| **SQLite Native** | sqlite3 + sqlite3_flutter_libs | 2.4+ / 0.5+ | Motor de base de datos |
| **Almacenamiento Seguro** | flutter_secure_storage | 9.2+ | Token JWT cifrado |
| **Preferencias** | shared_preferences | 2.3+ | Datos simples persistentes |
| **Editor Rico** | flutter_quill | 11.5+ | Editor de texto enriquecido |
| **Markdown** | markdown_quill + markdown | 4.3+ / 7.3+ | Conversión Markdown ↔ Quill |
| **Fuentes** | google_fonts | 6.3+ | Tipografías Lora + Manrope |
| **Imágenes** | image_picker | 1.2+ | Selección de imágenes |
| **Code Generation** | build_runner | 2.4+ | Generador de código |
| **Riverpod Generator** | riverpod_generator | 2.6+ | Providers a partir de annotations |
| **Drift Dev** | drift_dev | 2.20+ | Código Drift a partir de schema |
| **JSON Serialización** | json_serializable | 6.9+ | Serialización JSON type-safe |

---

## Arquitectura en Capas

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION                                │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ Onboarding   │  │ AuthScreen   │  │ RegisterScreen           │  │
│  │ Screen       │  │ (Login)      │  │                          │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
│                                                                      │
│  ┌──────────────┐  ┌──────────────────────┐  ┌──────────────────┐  │
│  │ Dashboard    │  │ ChapterListScreen    │  │ EditorScreen     │  │
│  │ Screen       │  │                      │  │ (flutter_quill)  │  │
│  └──────────────┘  └──────────────────────┘  └──────────────────┘  │
│                                                                      │
│  ConsumerWidget / ConsumerStatefulWidget → ref.watch()               │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ consume providers
┌──────────────────────────────▼──────────────────────────────────────┐
│                        APPLICATION (Riverpod)                        │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ AuthNotifier (AsyncNotifier<bool>)                           │   │
│  │   build()    → verifica token en secure storage              │   │
│  │   login()    → POST /auth/login + salva token                │   │
│  │   register() → POST /auth/register + salva token             │   │
│  │   logout()   → limpia secure storage                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ DashboardNotifier (Notifier)                                 │   │
│  │   build()          → refreshFromBackend() al iniciar         │   │
│  │   createProject()  → ProjectRepository.createProject()       │   │
│  │   softDeleteProject() → ProjectRepository.deleteProject()    │   │
│  │                                                              │   │
│  │ dashboardProjects (Stream Provider)                          │   │
│  │   → ProjectRepository.watchAllProjects()                     │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ChaptersNotifier (Notifier)                                  │   │
│  │   createChapter() → ChapterRepository.createLocalChapter()   │   │
│  │   deleteChapter() → ChapterRepository.deleteChapter()        │   │
│  │                                                              │   │
│  │ chaptersByProject (Stream Provider)                          │   │
│  │   → ChapterRepository.watchChaptersByProject()               │   │
│  │   + refreshChaptersForProject() al iniciar                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ EditorNotifier (AsyncNotifier<Chapter?>)                     │   │
│  │   build(chapterId) → getChapterById()                        │   │
│  │   saveChapter()    → ChapterRepository.updateLocalChapter()  │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ usa repositorios
┌──────────────────────────────▼──────────────────────────────────────┐
│                           DATA LAYER                                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ProjectRepository                                            │   │
│  │   watchAllProjects()     → Stream<Project> (DAO)             │   │
│  │   getProjectByLocalId()  → Future<Project?> (DAO)            │   │
│  │   refreshFromBackend()   → GET /proyectos + upsert local     │   │
│  │   createProject()        → INSERT local + POST remoto + sync │   │
│  │   updateLocalProject()   → UPDATE local + PUT remoto + sync  │   │
│  │   deleteProject()        → soft delete local + DELETE remoto │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ChapterRepository                                            │   │
│  │   watchChaptersByProject() → Stream<Chapter> (DAO)           │   │
│  │   getChapterById()         → Future<Chapter?> (DAO)          │   │
│  │   createLocalChapter()     → INSERT local + POST remoto      │   │
│  │   updateLocalChapter()     → UPDATE local + PUT remoto       │   │
│  │   deleteChapter()          → soft delete local + DELETE      │   │
│  │   refreshChaptersForProject() → GET /escritos/proyecto/:id   │   │
│  │   getNextOrderForProject() → MAX(orden) + 1                  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ SessionStore                                                 │   │
│  │   saveToken() / getToken()       → flutter_secure_storage    │   │
│  │   saveUserId() / getUserId()     → flutter_secure_storage    │   │
│  │   clearSession()                 → borra ambos               │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────┬───────────────────────────────┬──────────────────────────┘
           │                               │
┌──────────▼──────────────┐   ┌────────────▼─────────────────────────┐
│   LOCAL (Drift SQLite)  │   │      REMOTE (Dio + Backend)          │
│                         │   │                                      │
│  AppDatabase            │   │  Dio Client                          │
│  ├── Projects Table     │   │  ├── baseUrl: ApiConfig.baseUrl      │
│  ├── Chapters Table     │   │  ├── connectTimeout: 15s             │
│  └── SyncQueue Table    │   │  ├── receiveTimeout: 15s             │
│                         │   │  └── Interceptor: Bearer token       │
│  DAOs:                  │   │                                      │
│  ├── ProjectDao         │   │  UploadService                       │
│  │   watchAllProjects() │   │  └── POST /api/upload (multipart)    │
│  │   insertProject()    │   │                                      │
│  │   getProjectBy*()    │   │  Endpoints:                          │
│  │   updateProject()    │   │  ├── POST /api/auth/login            │
│  │   softDeleteProject()│   │  ├── POST /api/auth/register         │
│  │                      │   │  ├── CRUD /api/proyectos             │
│  ├── ChapterDao         │   │  ├── CRUD /api/escritos              │
│  │   watchChaptersBy*() │   │  └── POST /api/upload                │
│  │   insertChapter()    │   │                                      │
│  │   getChapterById()   │   │                                      │
│  │   updateChapter()    │   │                                      │
│  │   softDeleteChapter()│   │                                      │
│  │   softDeleteByProj() │   │                                      │
│  │   getNextOrderFor()  │   │                                      │
│  │                      │   │                                      │
│  └── SyncQueueDao       │   │                                      │
│      getAllPending()    │   │                                      │
│      enqueue()          │   │                                      │
│      removeById()       │   │                                      │
│      updateAttempt()    │   │                                      │
└─────────────────────────┘   └──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        SYNC ENGINE                                   │
│                                                                      │
│  SyncEngine (keepAlive: true)                                       │
│  ├── processQueue()         → procesa todos los pendientes          │
│  ├── enqueueForRetry()      → encola para reintento                 │
│  ├── _checkDependencies()   → verifica remoteId/remoteProjectId     │
│  ├── _executeOperation()    → dispatch project/chapter op           │
│  ├── _executeProjectOp()    → POST/PUT/DELETE /proyectos            │
│  └── _executeChapterOp()    → POST/PUT/DELETE /escritos             │
│                                                                      │
│  Política:                                                          │
│  ├── Máximo 3 reintentos por operación                              │
│  ├── Proyectos se sincronizan antes que capítulos                   │
│  ├── Capítulos diferidos si proyecto no tiene remoteId              │
│  └── Update/Delete diferidos si entidad no tiene remoteId           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Estructura de Carpetas

```
lib/
├── main.dart                          # void main() → await bootstrap()
├── app/
│   ├── bootstrap/
│   │   └── bootstrap.dart             # WidgetsFlutterBinding + ProviderScope + App
│   ├── router/
│   │   ├── app_router.dart            # GoRouter con redirect guard
│   │   └── app_router.g.dart          # Generado
│   └── theme/
│       └── stitch_theme.dart          # ThemeData Material 3 personalizado
├── core/
│   ├── config/
│   │   └── api_config.dart            # ApiConfig.baseUrl (dart-define)
│   └── network/
│       ├── dio_client.dart            # Dio instance + auth interceptor
│       ├── dio_client.g.dart          # Generado
│       ├── auth_interceptor.dart      # Interceptor: Bearer token + 401 handler
│       ├── auth_interceptor.g.dart    # Generado
│       ├── upload_service.dart        # Multipart image upload
│       └── upload_service.g.dart      # Generado
├── data/
│   └── local/
│       └── drift/
│           ├── app_database.dart      # Schema: Projects, Chapters, SyncQueue
│           ├── app_database.g.dart    # Generado
│           ├── database_provider.dart # Providers: AppDatabase, DAOs
│           ├── database_provider.g.dart # Generado
│           └── daos/
│               ├── project_dao.dart   # CRUD proyectos
│               ├── project_dao.g.dart # Generado
│               ├── chapter_dao.dart   # CRUD capítulos
│               ├── chapter_dao.g.dart # Generado
│               ├── sync_queue_dao.dart # Cola de sync
│               └── sync_queue_dao.g.dart # Generado
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── session_store.dart     # Token + userId (secure storage)
│   │   │   └── session_store.g.dart   # Generado
│   │   ├── application/
│   │   │   ├── auth_notifier.dart     # login, register, logout
│   │   │   └── auth_notifier.g.dart   # Generado
│   │   └── presentation/
│   │       ├── onboarding_screen.dart
│   │       ├── auth_screen.dart
│   │       └── register_screen.dart
│   ├── dashboard/
│   │   ├── application/
│   │   │   ├── dashboard_notifier.dart # createProject, softDeleteProject
│   │   │   └── dashboard_notifier.g.dart # Generado
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│   ├── projects/
│   │   ├── domain/
│   │   │   ├── project_model.dart
│   │   │   └── project_model.g.dart   # Generado
│   │   └── data/
│   │       ├── project_repository.dart # CRUD local+remoto+sync
│   │       └── project_repository.g.dart # Generado
│   ├── chapters/
│   │   ├── application/
│   │   │   ├── chapters_notifier.dart  # createChapter, deleteChapter
│   │   │   └── chapters_notifier.g.dart # Generado
│   │   ├── data/
│   │   │   ├── chapter_repository.dart # CRUD local+remoto+sync
│   │   │   └── chapter_repository.g.dart # Generado
│   │   └── presentation/
│   │       └── chapter_list_screen.dart
│   └── editor/
│       ├── application/
│       │   ├── editor_notifier.dart    # saveChapter(title, content)
│       │   └── editor_notifier.g.dart  # Generado
│       └── presentation/
│           └── editor_screen.dart
├── sync/
│   └── engine/
│       ├── sync_engine.dart            # Motor de sincronización
│       └── sync_engine.g.dart          # Generado
└── test/
```

---

## Diagrama de Dependencias

```
main.dart
  └── bootstrap.dart
        ├── ProviderScope
        │     ├── sessionStoreProvider (keepAlive)
        │     │     └── FlutterSecureStorage
        │     │
        │     ├── appDatabaseProvider (keepAlive)
        │     │     └── AppDatabase()
        │     │           ├── ProjectDao
        │     │           ├── ChapterDao
        │     │           └── SyncQueueDao
        │     │
        │     ├── projectDaoProvider (keepAlive) → appDatabaseProvider.projectDao
        │     ├── chapterDaoProvider (keepAlive) → appDatabaseProvider.chapterDao
        │     ├── syncQueueDaoProvider (keepAlive) → appDatabaseProvider.syncQueueDao
        │     │
        │     ├── authInterceptorProvider
        │     │     └── sessionStoreProvider
        │     │
        │     ├── dioClientProvider
        │     │     └── authInterceptorProvider
        │     │
        │     ├── uploadServiceProvider
        │     │     └── dioClientProvider
        │     │
        │     ├── syncEngineProvider (keepAlive)
        │     │     ├── syncQueueDaoProvider
        │     │     ├── projectDaoProvider
        │     │     ├── chapterDaoProvider
        │     │     └── dioClientProvider
        │     │
        │     ├── authNotifierProvider (AsyncNotifier<bool>)
        │     │     ├── sessionStoreProvider
        │     │     └── dioClientProvider
        │     │
        │     ├── appRouterProvider
        │     │     └── authNotifierProvider
        │     │
        │     ├── projectRepositoryProvider
        │     │     ├── projectDaoProvider
        │     │     ├── chapterDaoProvider
        │     │     ├── dioClientProvider
        │     │     ├── sessionStoreProvider
        │     │     └── syncEngineProvider
        │     │
        │     ├── chapterRepositoryProvider
        │     │     ├── chapterDaoProvider
        │     │     ├── projectDaoProvider
        │     │     ├── dioClientProvider
        │     │     └── syncEngineProvider
        │     │
        │     ├── dashboardProjectsProvider (Stream)
        │     │     └── projectRepositoryProvider
        │     │
        │     ├── dashboardNotifierProvider
        │     │     └── projectRepositoryProvider
        │     │     └── sessionStoreProvider
        │     │
        │     ├── chaptersByProjectProvider (Stream, family)
        │     │     └── chapterRepositoryProvider
        │     │
        │     ├── chaptersNotifierProvider
        │     │     └── chapterRepositoryProvider
        │     │
        │     └── editorNotifierProvider (family)
        │           └── chapterRepositoryProvider
        │
        └── MaterialApp.router
              └── GoRouter (appRouterProvider)
```

---

## Patrones de Diseño

### 1. Feature-First + Clean Architecture Ligera

Cada feature (`auth/`, `dashboard/`, `projects/`, `chapters/`, `editor/`) contiene su propia capa de presentación, aplicación y datos.

### 2. Repository Pattern

Los repositorios (`ProjectRepository`, `ChapterRepository`) abstraen el acceso a datos, combinando fuente local (Drift) y remota (Dio).

### 3. Offline-First (Write-Local-First)

Todas las escrituras se realizan primero en la base de datos local SQLite. La sincronización con el backend es un efecto secundario que puede fallar sin afectar la experiencia del usuario.

### 4. Sync Queue Pattern

Las operaciones fallidas se encolan en `SyncQueue` con un snapshot del payload. El `SyncEngine` procesa la cola al iniciar la app con reintentos limitados.

### 5. Soft Delete

Los registros nunca se eliminan físicamente de la base de datos local. Se marca `isDeleted = true` y `isSynced = false` para que la operación de delete se propague al backend.

### 6. Reactive Streams (Drift)

Los DAOs exponen `Stream<List<T>>` que emiten automáticamente cuando la base de datos cambia. Los providers de Riverpod consumen estos streams con `ref.watch()`.

---

## Modelo de Datos

### Relaciones

```
Usuario (1) ──────── (N) Project
                         │
                         └─── (1) ──────── (N) Chapter
```

### Projects (Tabla Drift)

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|:--:|:--------:|---------|-------------|
| `localId` | TEXT | Sí | No | - | ID único generado por la app (timestamp ms) |
| `remoteId` | INT | | Sí | null | ID asignado por el backend |
| `titulo` | TEXT | | No | - | Título del proyecto |
| `genero` | TEXT | | Sí | null | Género literario |
| `usuarioId` | INT | | Sí | null | ID del propietario |
| `isSynced` | BOOL | | No | false | Sincronizado con backend |
| `isDeleted` | BOOL | | No | false | Borrado lógico |
| `lastModified` | INT | | No | - | Unix timestamp ms |

### Chapters (Tabla Drift)

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|:--:|:--------:|---------|-------------|
| `localId` | TEXT | Sí | No | - | ID único (timestamp µs) |
| `remoteId` | INT | | Sí | null | ID del backend |
| `tituloCapitulo` | TEXT | | No | - | Título del capítulo |
| `contenido` | TEXT | | No | - | Contenido HTML/Markdown |
| `orden` | INT | | No | - | Posición secuencial |
| `projectLocalId` | TEXT | | No | - | FK → Projects.localId |
| `remoteProjectId` | INT | | Sí | null | ID remoto del proyecto padre |
| `isSynced` | BOOL | | No | false | Sincronizado |
| `isDeleted` | BOOL | | No | false | Borrado lógico |
| `lastModified` | INT | | No | - | Unix timestamp ms |

### SyncQueue (Tabla Drift)

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|:--:|:--------:|---------|-------------|
| `id` | INT | Auto | No | - | ID auto-incremental |
| `entityType` | TEXT | | No | - | `project` o `chapter` |
| `entityLocalId` | TEXT | | No | - | ID local de la entidad |
| `operation` | TEXT | | No | - | `create`, `update`, `delete` |
| `payloadSnapshot` | TEXT | | No | - | JSON del payload |
| `attemptCount` | INT | | No | 0 | Intentos (máx 3) |
| `lastError` | TEXT | | Sí | null | Último error |
| `createdAt` | INT | | No | - | Unix timestamp ms |

---

## Flujo de Sincronización

### Escritura de Datos

```
Usuario crea/edita/elimina
          │
          ▼
┌─────────────────────────┐
│ 1. Guardado local (DB)  │ ← Siempre funciona offline
│    isSynced = false     │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ 2. Intento sync directo │
│    (Dio → backend)      │
└────────────┬────────────┘
             │
      ┌──────┴──────┐
      │             │
     SÍ            NO (DioException)
      │             │
      ▼             ▼
┌───────────┐  ┌──────────────────────┐
│ Éxito     │  │ enqueueForRetry()    │
│ isSynced  │  │ SyncQueue.insert()   │
│ remoteId  │  │ payloadSnapshot JSON │
│ set       │  │ attemptCount = 0     │
└───────────┘  └──────────────────────┘
```

### Procesamiento de Cola

```
bootstrap() → syncEngine.processQueue()
        │
        ▼
┌─────────────────────────────────┐
│ getAllPending() (ordenado por   │
│ createdAt ASC)                  │
└───────────────┬─────────────────┘
                │
         ┌──────▼──────┐
         │ Por cada    │
         │ item        │
         └──────┬──────┘
                │
                ▼
     ┌──────────────────────┐
     │ attemptCount >= 3?   │
     └──────┬───────────────┘
            │
     ┌──────┴──────┐
     │             │
    SÍ            NO
     │             │
     ▼             ▼
┌─────────┐  ┌──────────────────────────┐
│DESCARTAR│  │ _checkDependencies()     │
│(silente)│  │                          │
└─────────┘  │ chapter create/update:   │
             │   necesita remoteProjId  │
             │                          │
             │ update/delete:           │
             │   necesita remoteId      │
             └────────┬─────────────────┘
                      │
               ┌──────┴──────┐
               │             │
              NO            SÍ
               │             │
               ▼             ▼
        ┌──────────┐  ┌──────────────────────┐
        │ DIFERIR  │  │ _executeOperation()  │
        │(esperar) │  │                      │
        └──────────┘  │ entityType=project:  │
                      │   POST/PUT/DELETE    │
                      │   /proyectos         │
                      │                      │
                      │ entityType=chapter:  │
                      │   POST/PUT/DELETE    │
                      │   /escritos          │
                      └──────────┬───────────┘
                                 │
                          ┌──────┴──────┐
                          │             │
                         SÍ            NO
                          │             │
                          ▼             ▼
                   ┌───────────┐  ┌──────────────┐
                   │ removeById│  │updateAttempt │
                   │ update    │  │ attemptCount++│
                   │ local     │  │ lastError    │
                   └───────────┘  └──────────────┘
```

### Orden de Sincronización

1. **Proyectos primero** - Los capítulos dependen del `remoteId` del proyecto padre
2. **Capítulos después** - Se diferir si el proyecto padre aún no tiene `remoteId`
3. **Reintentos** - Máximo 3 intentos por operación; si se agotan, se descarta

---

## Módulo de Autenticación

### Componentes

| Archivo | Tipo | Responsabilidad |
|---------|------|-----------------|
| `session_store.dart` | `SessionStore` + provider | Persistencia segura de token y userId |
| `auth_notifier.dart` | `AsyncNotifier<bool>` | Login, registro, logout |
| `auth_screen.dart` | `ConsumerWidget` | UI de login |
| `register_screen.dart` | `ConsumerWidget` | UI de registro |
| `onboarding_screen.dart` | `ConsumerWidget` | Pantalla de bienvenida |

### AuthNotifier

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<bool> build() async {
    // Verifica si existe token en secure storage
    final token = await ref.read(sessionStoreProvider).getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String email, String password) async;
  Future<void> register(String email, String password, String pseudonimo) async;
  Future<void> logout() async;
}
```

### SessionStore

- Usa `FlutterSecureStorage` con encriptación AES-GCM en Android y Keychain en iOS
- Almacena: `auth_token` (JWT) y `auth_user_id` (int como string)
- `clearSession()` borra ambos valores (usado en logout y en interceptor 401)

### AuthInterceptor

- Adjunta `Authorization: Bearer <token>` a cada request
- En respuesta 401: llama a `clearSession()` automáticamente

---

## Módulo de Proyectos

### ProjectRepository

| Método | Descripción | Sync |
|--------|-------------|------|
| `watchAllProjects()` | Stream reactivo de proyectos no eliminados | Local |
| `getProjectByLocalId()` | Obtener por ID local | Local |
| `refreshFromBackend()` | GET `/proyectos?usuario_id=N` + upsert local | Remoto |
| `createProject()` | INSERT local + POST `/proyectos` + update remoteId | Local + Remoto |
| `updateLocalProject()` | UPDATE local + PUT `/proyectos/:id` | Local + Remoto |
| `deleteProject()` | Soft delete local + capítulos + DELETE `/proyectos/:id` | Local + Remoto |

### Estrategia de Sync

1. **Siempre** se guarda primero en local (Drift)
2. Se intenta sync inmediato con el backend
3. Si falla (`DioException`): se encola en `SyncQueue` para reintento

---

## Módulo de Capítulos

### ChapterRepository

| Método | Descripción | Sync |
|--------|-------------|------|
| `watchChaptersByProject()` | Stream reactivo ordenado por `orden` | Local |
| `getChapterById()` | Obtener por ID local | Local |
| `createLocalChapter()` | INSERT local + POST `/escritos` | Local + Remoto |
| `updateLocalChapter()` | UPDATE local + PUT `/escritos/:id` | Local + Remoto |
| `deleteChapter()` | Soft delete local + DELETE `/escritos/:id` | Local + Remoto |
| `refreshChaptersForProject()` | GET `/escritos/proyecto/:id` + upsert | Remoto |
| `getNextOrderForProject()` | `MAX(orden) + 1` para nuevo capítulo | Local |

### ChaptersNotifier

- `createChapter()`: genera `localId` con microsegundos, contenido inicial `# titulo\n\n`, orden automático
- `deleteChapter()`: soft delete con propagación a backend

---

## Módulo de Editor

### EditorNotifier

```dart
@riverpod
class EditorNotifier extends _$EditorNotifier {
  @override
  FutureOr<Chapter?> build(String chapterLocalId) {
    return ref.read(chapterRepositoryProvider).getChapterById(chapterLocalId);
  }

  Future<void> saveChapter({
    required String title,
    required String markdownContent,
  }) async;
}
```

- Carga el capítulo por `localId` al construirse
- `saveChapter()` actualiza título y contenido, marca `isSynced = false`
- El repositorio maneja el sync remoto en segundo plano

---

## Routing y Navegación

### GoRouter Configuration

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      // Lógica de redirección basada en auth
    },
    routes: [
      GoRoute(path: '/onboarding', ...),
      GoRoute(path: '/auth', ...),
      GoRoute(path: '/register', ...),
      GoRoute(path: '/dashboard', ...),
      GoRoute(path: '/chapters/:projectLocalId/:projectTitle', ...),
      GoRoute(path: '/editor/:projectLocalId/:chapterLocalId', ...),
    ],
  );
}
```

### Redirect Guard

| Condición | Acción |
|-----------|--------|
| `authState.isLoading` | No redirige (espera resolución) |
| No autenticado + ruta protegida | → `/onboarding` |
| Autenticado + ruta auth/onboarding/register | → `/dashboard` |
| Otro caso | No redirige |

### Parámetros de Ruta

| Ruta | Parámetros | Ejemplo |
|------|-----------|---------|
| `/chapters/:projectLocalId/:projectTitle` | `projectLocalId` (string), `projectTitle` (URL-encoded) | `/chapters/1715000000000/Mi%20Novela` |
| `/editor/:projectLocalId/:chapterLocalId` | `projectLocalId` (string), `chapterLocalId` (string) | `/editor/1715000000000/1715000001234` |

---

## Tema y UI

### StitchTheme

| Propiedad | Valor |
|-----------|-------|
| **Material** | Material 3 |
| **Font Serif** | Google Fonts - Lora (cuerpo, títulos) |
| **Font Sans** | Google Fonts - Manrope (labels, hints) |
| **Primary** | `#1B263B` (azul oscuro) |
| **Primary Container** | `#2A3B57` |
| **Secondary** | `#606872` (gris) |
| **Surface** | `#F5F5F3` (crema) |
| **Surface Card** | `#FFFFFF` (blanco) |
| **Accent** | `#FF9800` (naranja Jotterpad) |
| **Accent Soft** | `#FFE0B2` |
| **Outline** | `#7F7F78` |
| **Error** | `#BA1A1A` |

### Componentes de UI

| Componente | Estilo |
|------------|--------|
| **Card** | Blanco, sin elevación, border radius 20px |
| **Input** | Pill shape (radius 999px), sin border, fondo surface |
| **AppBar** | Transparente, sin elevación |
| **Cursor/Selection** | Naranja (`#FF9800`) |
| **SnackBar** | Fondo primary, texto blanco (Manrope) |
| **Divider** | Espacio 1px, grosor 0.6px |
| **Body Text** | 16px, line-height 1.6, Lora |

---

## Code Generation

### Herramientas

| Herramienta | Input | Output | Comando |
|-------------|-------|--------|---------|
| `riverpod_generator` | `@riverpod`, `@Riverpod` | `*.g.dart` (providers) | `dart run build_runner build` |
| `drift_dev` | `Table`, `@DriftAccessor` | `*.g.dart` (SQL, DAOs) | `dart run build_runner build` |
| `json_serializable` | `@JsonSerializable` | `*.g.dart` (from/to JSON) | `dart run build_runner build` |

### Archivos Generados (18 archivos)

| Source | Generated |
|--------|-----------|
| `app/router/app_router.dart` | `app/router/app_router.g.dart` |
| `core/network/dio_client.dart` | `core/network/dio_client.g.dart` |
| `core/network/auth_interceptor.dart` | `core/network/auth_interceptor.g.dart` |
| `core/network/upload_service.dart` | `core/network/upload_service.g.dart` |
| `data/local/drift/app_database.dart` | `data/local/drift/app_database.g.dart` |
| `data/local/drift/database_provider.dart` | `data/local/drift/database_provider.g.dart` |
| `data/local/drift/daos/project_dao.dart` | `data/local/drift/daos/project_dao.g.dart` |
| `data/local/drift/daos/chapter_dao.dart` | `data/local/drift/daos/chapter_dao.g.dart` |
| `data/local/drift/daos/sync_queue_dao.dart` | `data/local/drift/daos/sync_queue_dao.g.dart` |
| `features/auth/application/auth_notifier.dart` | `features/auth/application/auth_notifier.g.dart` |
| `features/auth/data/session_store.dart` | `features/auth/data/session_store.g.dart` |
| `features/dashboard/application/dashboard_notifier.dart` | `features/dashboard/application/dashboard_notifier.g.dart` |
| `features/projects/data/project_repository.dart` | `features/projects/data/project_repository.g.dart` |
| `features/projects/domain/project_model.dart` | `features/projects/domain/project_model.g.dart` |
| `features/chapters/application/chapters_notifier.dart` | `features/chapters/application/chapters_notifier.g.dart` |
| `features/chapters/data/chapter_repository.dart` | `features/chapters/data/chapter_repository.g.dart` |
| `features/editor/application/editor_notifier.dart` | `features/editor/application/editor_notifier.g.dart` |
| `sync/engine/sync_engine.dart` | `sync/engine/sync_engine.g.dart` |

### Comandos

```bash
# Build único
dart run build_runner build --delete-conflicting-outputs

# Watch mode (regenera en cada cambio)
dart run build_runner watch
```

---

## Configuración y Ejecución

### Requisitos

- Flutter SDK 3.11+
- Dart SDK 3.11+
- Backend corriendo (ver [ARQUITECTURA-backend.md](./ARQUITECTURA-backend.md))

### Instalación

```bash
flutter pub get
```

### Generar código

```bash
# Una vez
dart run build_runner build --delete-conflicting-outputs

# Modo watch (desarrollo)
dart run build_runner watch
```

### Ejecutar

```bash
# Default (ngrok)
flutter run

# Con URL personalizada
flutter run --dart-define=API_BASE_URL=http://tu-servidor:3000/api
```

### Build Release

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS
```

### Testing

```bash
flutter analyze                      # Análisis estático
flutter test                         # Unit + widget tests
flutter test --coverage              # Con cobertura
```

---

## Documentos Relacionados

| Documento | Descripción |
|-----------|-------------|
| [README.md](../README.md) | Documentación general del proyecto |
| [ARQUITECTURA-backend.md](../ARQUITECTURA-backend.md) | Documentación del backend Express.js + PostgreSQL |
| [PLAN_MAESTRO_FLUTTER.md](../PLAN_MAESTRO_FLUTTER.md) | Plan de migración de 12 semanas |
