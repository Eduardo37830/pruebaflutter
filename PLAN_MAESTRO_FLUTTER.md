# Plan Maestro para Replicar `proyectoFinal` en Flutter

> Objetivo: reconstruir la app Android actual en Flutter con **paridad funcional real** (auth, proyectos, capitulos, editor rico con imagenes, offline-first y sincronizacion), minimizando riesgo y permitiendo entregas incrementales.

## 1) Alcance confirmado del sistema actual

Base detectada en Android:

- Arquitectura actual por capas simples: UI (Compose) -> ViewModel -> Repository -> Room/Retrofit.
- Inicializacion manual de dependencias en `app/src/main/java/com/example/proyectofinal/EscritorApp.kt`.
- Navegacion centralizada en `app/src/main/java/com/example/proyectofinal/MainActivity.kt` con rutas:
  - `auth`
  - `dashboard`
  - `chapters/{projectLocalId}/{projectTitle}`
  - `editor/{projectLocalId}/{chapterLocalId}`
- Dominio principal:
  - Auth (`AuthApiService`, `AuthRepository`, `SessionManager`)
  - Proyectos (`ProjectEntity`, `ProjectDao`, `ProjectRepository`)
  - Capitulos (`ChapterEntity`, `ChapterDao`, `ChapterRepository`)
  - Editor enriquecido + upload de imagen (`EditorScreen.kt`, `ChapterApiService.uploadImage`)
- Offline-first ya presente con soft delete y marca de sync:
  - Campos clave: `localId`, `remoteId`, `isSynced`, `isDeleted`, `lastModified`
  - Worker de sincronizacion: `app/src/main/java/com/example/proyectofinal/worker/SyncWorker.kt`

## 2) Arquitectura objetivo en Flutter (decision recomendada)

### 2.1 Patron general

- **Feature-first + Clean Architecture ligera**
- Flujo: `Presentation -> Application(State) -> Domain(UseCases) -> Data(Repo) -> Local/Remote`
- Sincronizacion desacoplada en modulo propio: `sync/`

### 2.2 Stack tecnico sugerido

- UI: Flutter Material 3
- Estado: Riverpod (`Notifier` / `AsyncNotifier`)
- Routing: `go_router`
- HTTP: `dio` + interceptor de auth
- Serializacion: `json_serializable` + `freezed` (opcional)
- DB local: `drift` (SQLite)
- Sesion segura: `flutter_secure_storage` + `shared_preferences`
- Background tasks: `workmanager`
- Conectividad: `connectivity_plus`
- Editor rico (spike temprano): `flutter_quill` o `super_editor`
- Imagenes: `image_picker` (opcional `file_picker`) + multipart con `dio`

### 2.3 Estructura de carpetas

```text
lib/
  core/
    config/
    errors/
    network/
    logging/
    utils/
  app/
    router/
    theme/
    bootstrap/
  data/
    local/
      drift/
    remote/
    mappers/
  sync/
    engine/
    scheduler/
    queue/
  features/
    auth/
      presentation/
      application/
      domain/
      data/
    dashboard/
      ...
    chapters/
      ...
    editor/
      ...
test/
integration_test/
```

## 3) Mapeo directo Android -> Flutter (archivo a archivo)

- `MainActivity.kt` -> `lib/app/router/app_router.dart` + `lib/main.dart`
- `EscritorApp.kt` -> `lib/app/bootstrap/bootstrap.dart` + providers globales
- `MainViewModel.kt` -> provider `isLoggedInProvider`
- `AuthViewModel.kt` -> `auth_notifier.dart`
- `DashboardViewModel.kt` -> `dashboard_notifier.dart`
- `ChapterViewModel.kt` -> `chapters_notifier.dart` + `editor_notifier.dart`
- `NetworkModule.kt` -> `core/network/dio_client.dart` + `auth_interceptor.dart`
- `SessionManager.kt` -> `features/auth/data/session_store.dart`
- `AppDatabase.kt` + DAOs -> `data/local/drift/app_database.dart` + daos
- `SyncWorker.kt` -> `sync/engine/sync_engine.dart` + `sync/scheduler/sync_scheduler.dart`
- `AuthScreen.kt` -> `features/auth/presentation/auth_screen.dart`
- `DashboardScreen.kt` -> `features/dashboard/presentation/dashboard_screen.dart`
- `ChapterListScreen.kt` -> `features/chapters/presentation/chapter_list_screen.dart`
- `EditorScreen.kt` -> `features/editor/presentation/editor_screen.dart`

## 4) Modelo de datos y reglas de sincronizacion (critico)

### 4.1 Entidades locales en Flutter

Crear tablas Drift equivalentes:

- `projects`
  - `local_id` TEXT PK
  - `remote_id` INT NULL
  - `titulo` TEXT
  - `genero` TEXT
  - `usuario_id` INT
  - `is_synced` BOOL
  - `is_deleted` BOOL
  - `last_modified` INT
- `chapters`
  - `local_id` TEXT PK
  - `remote_id` INT NULL
  - `titulo_capitulo` TEXT
  - `contenido` TEXT
  - `orden` INT
  - `project_local_id` TEXT
  - `remote_project_id` INT NULL
  - `is_synced` BOOL
  - `is_deleted` BOOL
  - `last_modified` INT
- `sync_queue` (nueva, recomendada)
  - `id` INTEGER PK autoincrement
  - `entity_type` (`project`/`chapter`)
  - `entity_local_id` TEXT
  - `operation` (`create`/`update`/`delete`)
  - `payload_snapshot` TEXT(JSON)
  - `attempt_count` INT
  - `last_error` TEXT NULL
  - `created_at` INT

### 4.2 Orden de sincronizacion

Basado en `SyncWorker.kt`:

1. Sincronizar proyectos pendientes.
2. Sincronizar capitulos pendientes.
3. Si capitulo no tiene `remoteProjectId`, diferir hasta que proyecto tenga `remoteId`.

### 4.3 Politica de conflictos

- Primera version: **Last Write Wins** por `lastModified`.
- Si hay conflicto repetido (`attempt_count >= 3`): marcar `needs_manual_review` en cola.
- Nunca borrar fisicamente local sin confirmar respuesta remota (excepto registros sin `remoteId`).

## 5) Plan de ejecucion por fases (12 semanas)

## Fase 0 - Descubrimiento y decisiones irreversibles (Semana 1)

Entregables:

- Inventario completo de pantallas, endpoints y estados.
- Decision final editor (`flutter_quill` vs `super_editor`) con PoC.
- Contrato de API congelado (ideal OpenAPI).
- ADRs tecnicos (estado, DB, sync, router).

Criterio de salida:

- Documento aprobado por equipo (producto + backend + mobile).

## Fase 1 - Fundacion Flutter (Semanas 2 y 3)

Trabajo:

- Crear proyecto Flutter y estructura por features.
- Configurar `go_router`, tema M3 y bootstrap.
- Configurar `dio` + interceptor bearer token.
- Configurar session store y proveedor de sesion.

Criterio de salida:

- App abre, restaura sesion y enruta correctamente a auth/dashboard.

## Fase 2 - Persistencia y dominio (Semanas 4 y 5)

Trabajo:

- Implementar Drift DB, DAOs y repositorios locales.
- Implementar modelos DTO remotos y mappers.
- Implementar casos de uso principales (auth, CRUD proyecto/capitulo).

Criterio de salida:

- CRUD local de proyectos y capitulos funcionando sin red.

## Fase 3 - Auth y Dashboard (Semana 6)

Trabajo:

- Migrar `AuthScreen.kt` con estados `Idle/Loading/Success/Error`.
- Migrar `DashboardScreen.kt` con crear/eliminar y badge de `isSynced`.
- Manejo de snackbars equivalente.

Criterio de salida:

- Login/registro/logout funcionales + dashboard operativo offline.

## Fase 4 - Capitulo y Editor (Semanas 7 y 8)

Trabajo:

- Migrar lista de capitulos (`ChapterListScreen.kt`) con preview HTML a texto plano.
- Migrar editor rico (`EditorScreen.kt`) + toolbar + guardado.
- Upload imagen multipart y dialogo de metadata (caption).

Criterio de salida:

- Edicion y guardado confiables, insercion de imagen estable.

## Fase 5 - Sync robusto + observabilidad (Semanas 9 y 10)

Trabajo:

- Implementar `SyncEngine` y scheduler (`workmanager`).
- Cola de sync con reintentos, backoff, trazas y metricas.
- Manejo de errores de red y reconciliacion de IDs remotos.

Criterio de salida:

- Tasa de sync exitosa >= 98% en staging.

## Fase 6 - QA, release y hardening (Semanas 11 y 12)

Trabajo:

- Unit tests, widget tests, integration tests.
- CI/CD completo (analyze, test, build, firma, distribucion interna).
- Beta cerrada + checklist de paridad funcional.

Criterio de salida:

- Build release candidato a produccion aprobado por QA/Producto.

## 6) Migracion por modulo con Definition of Done (DoD)

### Auth

DoD:

- Requests `auth/login` y `auth/register` equivalentes.
- Token persistido seguro y restauracion tras relanzamiento.
- Manejo de errores de red y credenciales con feedback UX.

### Proyectos

DoD:

- Listado por `usuario_id` local.
- Crear y eliminar (soft delete) local.
- Indicador visual de no sincronizado equivalente (`CloudOff` actual).

### Capitulos

DoD:

- Listado por `project_local_id`, ordenado por `orden`.
- Crear/eliminar local y preview limpio de HTML.
- Navegacion estable hacia editor.

### Editor

DoD:

- Cargar contenido HTML inicial.
- Guardar cambios con timestamp y estado no sincronizado.
- Insertar imagen con caption y HTML escapado.

### Sync

DoD:

- Create/Update/Delete de proyectos y capitulos idempotente.
- Dependencia proyecto->capitulo respetada.
- Reintentos y manejo de errores persistidos en cola.

## 7) Estrategia de pruebas (por prioridad)

1. Unit tests (alta prioridad)
   - Mappers DTO<->Entity
   - Use cases
   - Motor de sync (orden + reintentos + conflictos)
2. Widget tests
   - Auth: validaciones y estados
   - Dashboard/ChapterList: render por estado
   - Editor: guardado y acciones de toolbar
3. Integration tests
   - Flujo completo: login -> proyecto -> capitulo -> edicion -> sync
4. Contract tests contra backend (si hay OpenAPI/mocks)

Objetivos de cobertura:

- Global >= 70%
- `sync/` y `repositories/` >= 85%

## 8) CI/CD recomendado

Pipeline minimo:

- PR: `flutter format --set-exit-if-changed`, `flutter analyze`, `flutter test`
- Main: build apk/aab release + artifacts
- Release: distribucion interna (Firebase App Distribution)

Comandos base:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## 9) Riesgos reales y mitigaciones

- Riesgo: paridad incompleta del editor rico.
  - Mitigacion: spike semana 1 + golden/widget tests tempranos.
- Riesgo: backend no retorna IDs al crear (comentario en `SyncWorker.kt`).
  - Mitigacion: acordar contrato obligatorio de create con ID remoto.
- Riesgo: tareas en background limitadas por SO.
  - Mitigacion: sync foreground al abrir app + background best effort.
- Riesgo: corrupcion o perdida en conflictos.
  - Mitigacion: cola transaccional + snapshots + flags de revision manual.

## 10) Plan de rollback y contingencia

Triggers de rollback:

- Crash-free rate < 99.5% en beta.
- Sync failures > 5% sostenido por 24h.
- Evidencia de perdida de contenido.

Acciones:

1. Pausar rollout.
2. Desactivar feature flags de sync avanzado/editor nuevo.
3. Volver a build estable anterior.
4. Ejecutar saneamiento de cola (`sync_queue`) y forzar resync controlado.

## 11) Backlog inicial (epicas)

- EPIC-01: Base app Flutter + arquitectura
- EPIC-02: Autenticacion y sesion
- EPIC-03: Persistencia local offline-first
- EPIC-04: Dashboard de proyectos
- EPIC-05: Capitulos y navegacion interna
- EPIC-06: Editor enriquecido + imagenes
- EPIC-07: Sincronizacion robusta y conflictos
- EPIC-08: Observabilidad, QA y CI/CD

## 12) Criterio final de paridad (Go/No-Go)

Go si se cumple todo:

- Todas las rutas funcionales: Auth, Dashboard, ChapterList, Editor.
- CRUD completo offline con sincronizacion estable.
- Sin regresiones UX graves frente a Android actual.
- Pruebas criticas en verde + metricas de estabilidad aceptables.

---

## Nota de implementacion inmediata

El siguiente paso recomendado es generar una **matriz de trazabilidad** (feature Android -> feature Flutter -> pruebas -> responsable -> fecha), y convertir este plan en tickets de sprint con dependencias explicitas.

