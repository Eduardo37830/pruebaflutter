# Escritor App - Flutter

Aplicación Flutter multiplataforma para gestión de proyectos literarios, con soporte offline-first, editor enriquecido y sincronización automática con backend.

## Descripción

Escritor App permite a los usuarios crear proyectos de escritura, organizar capítulos y editar contenido con un editor rico. La aplicación funciona completamente sin conexión a internet y sincroniza los cambios cuando la conectividad se restaura.

## Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| **Framework** | Flutter | 3.x |
| **Lenguaje** | Dart | 3.11+ |
| **State Management** | Riverpod (Notifier / AsyncNotifier) | 2.6+ |
| **Routing** | go_router | 14.7+ |
| **HTTP Client** | Dio | 5.7+ |
| **Base de Datos Local** | Drift (SQLite) | 2.20+ |
| **Almacenamiento Seguro** | flutter_secure_storage | 9.2+ |
| **Preferencias** | shared_preferences | 2.3+ |
| **Editor Rico** | flutter_quill | 11.5+ |
| **Markdown** | markdown_quill + markdown | 4.3+ / 7.3+ |
| **Fuentes** | google_fonts | 6.3+ |
| **Imágenes** | image_picker | 1.2+ |
| **Code Generation** | build_runner, riverpod_generator, drift_dev, json_serializable | - |

## Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada → bootstrap()
├── app/
│   ├── bootstrap/bootstrap.dart       # Inicialización de Widgets + ProviderScope + SyncEngine
│   ├── router/app_router.dart         # go_router con redirect guard de autenticación
│   └── theme/stitch_theme.dart        # Tema Material 3 (Google Fonts: Lora + Manrope)
├── core/
│   ├── config/
│   │   └── api_config.dart            # API base URL (dart-define, ngrok por defecto)
│   └── network/
│       ├── dio_client.dart            # Dio con timeouts de 15s + auth interceptor
│       ├── auth_interceptor.dart      # Bearer token automático + clear session en 401
│       └── upload_service.dart        # Multipart upload de imágenes al backend
├── data/
│   └── local/drift/
│       ├── app_database.dart          # Schema Drift: Projects, Chapters, SyncQueue
│       ├── database_provider.dart     # Riverpod provider de la base de datos
│       └── daos/
│           ├── project_dao.dart       # CRUD proyectos + soft delete + watch reactivo
│           ├── chapter_dao.dart       # CRUD capítulos + soft delete + orden automático
│           └── sync_queue_dao.dart    # Cola de sincronización con reintentos
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── session_store.dart     # Token + userId en FlutterSecureStorage
│   │   ├── application/
│   │   │   └── auth_notifier.dart     # login, register, logout (AsyncNotifier)
│   │   └── presentation/
│   │       ├── onboarding_screen.dart
│   │       ├── auth_screen.dart
│   │       └── register_screen.dart
│   ├── dashboard/
│   │   ├── application/
│   │   │   └── dashboard_notifier.dart
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│   ├── projects/
│   │   ├── domain/
│   │   │   └── project_model.dart
│   │   └── data/
│   │       └── project_repository.dart  # CRUD local+remoto+sync queue
│   ├── chapters/
│   │   ├── application/
│   │   │   └── chapters_notifier.dart
│   │   ├── data/
│   │   │   └── chapter_repository.dart  # CRUD local+remoto+sync queue
│   │   └── presentation/
│   │       └── chapter_list_screen.dart
│   └── editor/
│       ├── application/
│       │   └── editor_notifier.dart
│       └── presentation/
│           └── editor_screen.dart
├── sync/
│   └── engine/
│       └── sync_engine.dart           # Motor de sync con cola, reintentos y dependencias
└── test/
```

## Rutas de la Aplicación

| Ruta | Pantalla | Acceso | Descripción |
|------|----------|--------|-------------|
| `/onboarding` | OnboardingScreen | Público | Pantalla de bienvenida |
| `/auth` | AuthScreen | Público | Login con email y contraseña |
| `/register` | RegisterScreen | Público | Registro con pseudónimo |
| `/dashboard` | DashboardScreen | Autenticado | Lista de proyectos literarios |
| `/chapters/:projectLocalId/:projectTitle` | ChapterListScreen | Autenticado | Lista de capítulos de un proyecto |
| `/editor/:projectLocalId/:chapterLocalId` | EditorScreen | Autenticado | Editor enriquecido de capítulo |

### Redirect Guard

El router implementa protección de rutas con `go_router.redirect`:

- Si **no autenticado** y navega a ruta protegida → redirige a `/onboarding`
- Si **autenticado** y navega a `/auth`, `/onboarding` o `/register` → redirige a `/dashboard`
- Durante la carga del estado de auth (`isLoading`) → no redirige

## Modelo de Datos Local (Drift SQLite)

### Projects

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|----|----------|---------|-------------|
| `localId` | TEXT | Sí | No | - | ID único generado por la app |
| `remoteId` | INT | | Sí | null | ID asignado por el backend tras sync |
| `titulo` | TEXT | | No | - | Título del proyecto literario |
| `genero` | TEXT | | Sí | null | Género literario (novela, cuento, etc.) |
| `usuarioId` | INT | | Sí | null | ID del usuario propietario |
| `isSynced` | BOOL | | No | false | Indicador de sincronización con backend |
| `isDeleted` | BOOL | | No | false | Borrado lógico (soft delete) |
| `lastModified` | INT | | No | - | Timestamp unix en milisegundos |

### Chapters

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|----|----------|---------|-------------|
| `localId` | TEXT | Sí | No | - | ID único generado por la app |
| `remoteId` | INT | | Sí | null | ID asignado por el backend |
| `tituloCapitulo` | TEXT | | No | - | Título del capítulo |
| `contenido` | TEXT | | No | - | Contenido en formato HTML/markdown |
| `orden` | INT | | No | - | Posición secuencial en el proyecto |
| `projectLocalId` | TEXT | | No | - | FK al `localId` del proyecto padre |
| `remoteProjectId` | INT | | Sí | null | ID remoto del proyecto padre |
| `isSynced` | BOOL | | No | false | Indicador de sincronización |
| `isDeleted` | BOOL | | No | false | Borrado lógico |
| `lastModified` | INT | | No | - | Timestamp unix en milisegundos |

### SyncQueue

| Campo | Tipo | PK | Nullable | Default | Descripción |
|-------|------|----|----------|---------|-------------|
| `id` | INT | Auto | No | - | ID auto-incremental de la entrada |
| `entityType` | TEXT | | No | - | Tipo: `project` o `chapter` |
| `entityLocalId` | TEXT | | No | - | ID local de la entidad afectada |
| `operation` | TEXT | | No | - | Operación: `create`, `update`, `delete` |
| `payloadSnapshot` | TEXT | | No | - | JSON serializado del payload a enviar |
| `attemptCount` | INT | | No | 0 | Número de intentos realizados (máx. 3) |
| `lastError` | TEXT | | Sí | null | Mensaje del último error |
| `createdAt` | INT | | No | - | Timestamp unix de creación |

## Endpoints del Backend

Base URL configurable vía `--dart-define=API_BASE_URL`. Default:
`https://unrife-sinless-latesha.ngrok-free.dev/api`

> Documentación completa y detallada en [ARQUITECTURA-backend.md](./ARQUITECTURA-backend.md)

### Resumen de Endpoints

| Método | Endpoint | Descripción | Auth Requerida |
|--------|----------|-------------|:--------------:|
| POST | `/api/auth/register` | Registro de usuario (email, password, pseudonimo) | No |
| POST | `/api/auth/login` | Login (email, password) → retorna JWT token | No |
| GET | `/api/proyectos?usuario_id=N` | Listar proyectos del usuario | No* |
| GET | `/api/proyectos/:id` | Obtener un proyecto por ID | No* |
| POST | `/api/proyectos` | Crear proyecto (titulo, genero, usuario_id) | No* |
| PUT | `/api/proyectos/:id` | Actualizar proyecto | No* |
| DELETE | `/api/proyectos/:id` | Eliminar proyecto (cascada a escritos) | No* |
| GET | `/api/escritos/proyecto/:id` | Listar capítulos de un proyecto (ordenados) | No* |
| GET | `/api/escritos/:id` | Obtener un capítulo por ID | No* |
| POST | `/api/escritos` | Crear capítulo (titulo_capitulo, contenido, orden, proyecto_id) | No* |
| PUT | `/api/escritos/:id` | Actualizar capítulo | No* |
| DELETE | `/api/escritos/:id` | Eliminar capítulo | No* |
| POST | `/api/upload` | Subir imagen (multipart/form-data, campo: `imagen`) | No* |

> *El interceptor de auth adjunta automáticamente el Bearer token en todas las peticiones. El backend actualmente no valida JWT en estas rutas.

### Swagger

- UI interactiva: `http://localhost:3000/api-docs`
- Spec JSON: `http://localhost:3000/api-docs.json`

## Arquitectura - Diagramas

### Capas de la Aplicación

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION                             │
│                                                                  │
│  OnboardingScreen │ AuthScreen │ RegisterScreen                  │
│  DashboardScreen  │ ChapterListScreen │ EditorScreen             │
│                                                                  │
│  (ConsumerWidget / ConsumerStatefulWidget, ref.watch)            │
└────────────────────────────┬────────────────────────────────────┘
                             │ consume providers
┌────────────────────────────▼────────────────────────────────────┐
│                      APPLICATION (Riverpod)                      │
│                                                                  │
│  AuthNotifier        → login(), register(), logout()             │
│  DashboardNotifier   → estado del dashboard                      │
│  ChaptersNotifier    → estado de lista de capítulos              │
│  EditorNotifier      → estado del editor                         │
│                                                                  │
│  (AsyncNotifier / Notifier con riverpod_generator)               │
└────────────────────────────┬────────────────────────────────────┘
                             │ usa repositorios
┌────────────────────────────▼────────────────────────────────────┐
│                         DATA LAYER                               │
│                                                                  │
│  ProjectRepository  │ ChapterRepository │ SessionStore           │
│                                                                  │
│  Estrategia: write-local-first, sync-afterward                   │
│  - Guardar en Drift primero (siempre funciona offline)           │
│  - Intentar sync remoto inmediato                                │
│  - Si falla: encolar en SyncQueue para reintento                 │
└──────────┬───────────────────────────┬──────────────────────────┘
           │                           │
┌──────────▼──────────┐     ┌──────────▼──────────────────────────┐
│   LOCAL (Drift)     │     │      REMOTE (Dio + Backend)         │
│                     │     │                                     │
│  Projects Table     │     │  POST /api/auth/login               │
│  Chapters Table     │     │  POST /api/auth/register            │
│  SyncQueue Table    │     │  GET/POST/PUT/DELETE /api/proyectos │
│                     │     │  GET/POST/PUT/DELETE /api/escritos  │
│  DAOs:              │     │  POST /api/upload (multipart)       │
│  - ProjectDao       │     │                                     │
│  - ChapterDao       │     │  AuthInterceptor: Bearer token      │
│  - SyncQueueDao     │     │  Timeout: 15s connect/receive       │
└─────────────────────┘     └─────────────────────────────────────┘
```

### Flujo de Sincronización Offline-First

```
┌──────────────────────────────────────────────────────────────┐
│                    ESCRITURA DE DATOS                         │
│                                                              │
│  Usuario crea/edita/elimina proyecto o capítulo              │
│                          │                                   │
│                          ▼                                   │
│              ┌───────────────────────┐                       │
│              │  1. Guardado local    │ ← Siempre funciona    │
│              │  (Drift SQLite)       │   offline             │
│              │  isSynced = false     │                       │
│              └───────────┬───────────┘                       │
│                          │                                   │
│                          ▼                                   │
│              ┌───────────────────────┐                       │
│              │  2. Intento sync      │                       │
│              │  directo (Dio)        │                       │
│              └───────────┬───────────┘                       │
│                          │                                   │
│                  ┌───────┴───────┐                           │
│                  │               │                           │
│                  ▼               ▼                           │
│         ┌──────────────┐  ┌──────────────┐                  │
│         │   ÉXITO      │  │ DioException │                  │
│         │              │  │ (sin red)    │                  │
│         │ isSynced=true│  │              │                  │
│         │ remoteId set │  │ enqueueFor   │                  │
│         │              │  │ Retry()      │                  │
│         └──────────────┘  └──────┬───────┘                  │
│                                  │                          │
│                                  ▼                          │
│                        ┌───────────────────┐                │
│                        │ SyncQueue.insert  │                │
│                        │ payloadSnapshot   │                │
│                        │ attemptCount = 0  │                │
│                        └───────────────────┘                │
└──────────────────────────────────────────────────────────────┘
```

### Procesamiento de Cola de Sincronización

```
┌──────────────────────────────────────────────────────────────┐
│              bootstrap() → syncEngine.processQueue()          │
│              (se ejecuta al iniciar la app)                   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
                 ┌─────────────────────┐
                 │ getAllPending()     │
                 │ (ordenado por       │
                 │  createdAt ASC)     │
                 └──────────┬──────────┘
                            │
                     ┌──────▼──────┐
                     │ Por cada    │
                     │ SyncQueue   │
                     │ item        │
                     └──────┬──────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │ attemptCount >= 3?  │
                 └──────────┬──────────┘
                            │
                    ┌───────┴───────┐
                    │               │
                   SÍ              NO
                    │               │
                    ▼               ▼
           ┌─────────────┐  ┌──────────────────────┐
           │ DESCARTAR   │  │ _checkDependencies() │
           │ (sin re-    │  │                      │
           │  intento)   │  │ - chapter create/    │
           └─────────────┘  │   update: necesita   │
                            │   remoteProjectId    │
                            │                      │
                            │ - update/delete:     │
                            │   necesita remoteId  │
                            └──────────┬───────────┘
                                       │
                                ┌──────┴──────┐
                                │             │
                               NO            SÍ
                                │             │
                                ▼             ▼
                       ┌────────────┐  ┌──────────────────────┐
                       │ DIFERIR    │  │ _executeOperation()  │
                       │ (esperar   │  │                      │
                       │  depend.)  │  │ switch entityType:   │
                       └────────────┘  │   project → CRUD     │
                                       │   chapter → CRUD     │
                                       └──────────┬───────────┘
                                                  │
                                           ┌──────┴──────┐
                                           │             │
                                          SÍ            NO
                                           │             │
                                           ▼             ▼
                                  ┌─────────────┐  ┌──────────────┐
                                  │ removeById  │  │ updateAttempt│
                                  │ (éxito)     │  │ attemptCount++│
                                  │ update local│  │ lastError    │
                                  │ isSynced=true│ │              │
                                  └─────────────┘  └──────────────┘
```

### Orden de Sincronización

1. **Proyectos primero** - Los capítulos dependen del `remoteId` del proyecto padre
2. **Capítulos después** - Se diferir si el proyecto padre aún no tiene `remoteId`
3. **Reintentos** - Máximo 3 intentos por operación; si se agotan, se descarta silenciosamente

### Dependencias entre Componentes

```
┌────────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH                         │
│                                                             │
│  App (bootstrap.dart)                                       │
│  ├── ProviderScope                                          │
│  │   ├── sessionStoreProvider                               │
│  │   ├── syncEngineProvider                                 │
│  │   │   ├── syncQueueDaoProvider                           │
│  │   │   ├── projectDaoProvider                             │
│  │   │   ├── chapterDaoProvider                             │
│  │   │   └── dioClientProvider                              │
│  │   │       └── authInterceptorProvider                    │
│  │   │           └── sessionStoreProvider                   │
│  │   ├── appRouterProvider                                  │
│  │   │   └── authNotifierProvider                           │
│  │   │       ├── sessionStoreProvider                       │
│  │   │       └── dioClientProvider                          │
│  │   ├── projectRepositoryProvider                          │
│  │   │   ├── projectDaoProvider                             │
│  │   │   ├── chapterDaoProvider                             │
│  │   │   ├── dioClientProvider                              │
│  │   │   ├── sessionStoreProvider                           │
│  │   │   └── syncEngineProvider                             │
│  │   └── chapterRepositoryProvider                          │
│  │       ├── chapterDaoProvider                             │
│  │       ├── projectDaoProvider                             │
│  │       ├── dioClientProvider                              │
│  │       └── syncEngineProvider                             │
│  └── MaterialApp.router                                     │
│      └── routerConfig (GoRouter)                            │
└────────────────────────────────────────────────────────────┘
```

## Tema de la Aplicación (StitchTheme)

La app utiliza un tema personalizado basado en Material 3 con las siguientes características:

- **Tipografía**: Google Fonts - Lora (serif) para cuerpo y títulos, Manrope (sans-serif) para labels
- **Color primario**: `#1B263B` (azul oscuro)
- **Color de acento**: `#FF9800` (naranja, estilo Jotterpad)
- **Fondo**: `#F5F5F3` (crema claro)
- **Cards**: blancas con bordes redondeados de 20px
- **Inputs**: bordes redondeados de 999px (pill shape)
- **AppBar**: transparente, sin elevación

## Configuración y Ejecución

### Requisitos

- Flutter SDK 3.11+
- Dart SDK 3.11+
- Backend corriendo (ver [ARQUITECTURA-backend.md](./ARQUITECTURA-backend.md))

### Instalación

```bash
flutter pub get
```

### Generar código (Drift, Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Watch mode (regeneración automática en cada cambio)

```bash
dart run build_runner watch
```

### Ejecutar en desarrollo

```bash
flutter run
```

### Configurar URL del backend

```bash
flutter run --dart-define=API_BASE_URL=http://tu-servidor:3000/api
```

### Build release

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS
```

### Testing y análisis

```bash
flutter analyze                      # Análisis estático de código
flutter test                         # Unit y widget tests
flutter test --coverage              # Tests con reporte de cobertura
```

## Code Generation

Este proyecto usa code generation extensivo:

| Herramienta | Genera | Archivos |
|-------------|--------|----------|
| `riverpod_generator` | Providers a partir de `@riverpod` / `@Riverpod` | `*.g.dart` |
| `drift_dev` | Código SQL/DAO a partir de tablas y `@DriftAccessor` | `*.g.dart` |
| `json_serializable` | Serialización JSON a partir de `@JsonSerializable` | `*.g.dart` |

Archivos generados actualmente:

- `lib/app/router/app_router.g.dart`
- `lib/core/network/dio_client.g.dart`
- `lib/core/network/auth_interceptor.g.dart`
- `lib/core/network/upload_service.g.dart`
- `lib/data/local/drift/app_database.g.dart`
- `lib/data/local/drift/database_provider.g.dart`
- `lib/data/local/drift/daos/project_dao.g.dart`
- `lib/data/local/drift/daos/chapter_dao.g.dart`
- `lib/data/local/drift/daos/sync_queue_dao.g.dart`
- `lib/features/auth/application/auth_notifier.g.dart`
- `lib/features/auth/data/session_store.g.dart`
- `lib/features/dashboard/application/dashboard_notifier.g.dart`
- `lib/features/projects/data/project_repository.g.dart`
- `lib/features/projects/domain/project_model.g.dart`
- `lib/features/chapters/application/chapters_notifier.g.dart`
- `lib/features/chapters/data/chapter_repository.g.dart`
- `lib/features/editor/application/editor_notifier.g.dart`
- `lib/sync/engine/sync_engine.g.dart`

## Documentos Relacionados

| Documento | Descripción |
|-----------|-------------|
| [ARQUITECTURA-backend.md](./ARQUITECTURA-backend.md) | Documentación completa del backend Express.js + PostgreSQL |
| [PLAN_MAESTRO_FLUTTER.md](./PLAN_MAESTRO_FLUTTER.md) | Plan de migración de 12 semanas con fases y epicas |
