# API Reference - Backend Escritor App

Base URL: `https://unrife-sinless-latesha.ngrok-free.dev/api`

> Documentación interactiva disponible en Swagger: `http://localhost:3000/api-docs`

## Tabla de Contenidos

1. [Autenticación](#autenticación)
2. [Proyectos](#proyectos)
3. [Escritos/Capítulos](#escritoscapítulos)
4. [Upload de Archivos](#upload-de-archivos)
5. [Modelos de Datos](#modelos-de-datos)
6. [Códigos de Error](#códigos-de-error)

---

## Autenticación

### POST `/api/auth/register`

Registra un nuevo usuario en el sistema.

**Request:**

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "usuario@example.com",
  "password": "contraseña123",
  "pseudonimo": "MiPseudónimo"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `email` | string | Sí | Correo electrónico (único) |
| `password` | string | Sí | Contraseña (se hashea con bcrypt) |
| `pseudonimo` | string | Sí | Nombre visible del usuario |

**Response 201 - Created:**

```json
{
  "message": "Registro exitoso",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "email": "usuario@example.com",
    "pseudonimo": "MiPseudónimo"
  }
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 400 | El correo ya está registrado |
| 500 | Error interno del servidor |

---

### POST `/api/auth/login`

Autentica un usuario y retorna un JWT.

**Request:**

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "usuario@example.com",
  "password": "contraseña123"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `email` | string | Sí | Correo electrónico |
| `password` | string | Sí | Contraseña |

**Response 200 - OK:**

```json
{
  "message": "Login exitoso",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "email": "usuario@example.com",
    "pseudonimo": "MiPseudónimo"
  }
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 401 | Correo o contraseña incorrectos |
| 500 | Error interno del servidor |

---

## Proyectos

### GET `/api/proyectos`

Obtiene todos los proyectos de un usuario.

**Request:**

```http
GET /api/proyectos?usuario_id=1
```

| Parámetro | Tipo | Ubicación | Requerido | Descripción |
|-----------|------|-----------|:---------:|-------------|
| `usuario_id` | int | query | Sí | ID del usuario propietario |

**Response 200 - OK:**

```json
[
  {
    "id": 1,
    "titulo": "Mi Primera Novela",
    "genero": "novela",
    "usuario_id": 1,
    "fecha_creacion": "2026-05-04T10:30:00Z"
  },
  {
    "id": 2,
    "titulo": "Cuentos Cortos",
    "genero": "cuento",
    "usuario_id": 1,
    "fecha_creacion": "2026-05-05T14:00:00Z"
  }
]
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 400 | `usuario_id` no proporcionado |
| 500 | Error interno del servidor |

---

### GET `/api/proyectos/:id`

Obtiene un proyecto específico por su ID.

**Request:**

```http
GET /api/proyectos/1
```

**Response 200 - OK:**

```json
{
  "id": 1,
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 404 | Proyecto no encontrado |
| 500 | Error interno del servidor |

---

### POST `/api/proyectos`

Crea un nuevo proyecto literario.

**Request:**

```http
POST /api/proyectos
Content-Type: application/json

{
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `titulo` | string | Sí | Título del proyecto |
| `genero` | string | Sí | Género literario |
| `usuario_id` | int | Sí | ID del usuario propietario |

**Response 201 - Created:**

```json
{
  "id": 1,
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

### PUT `/api/proyectos/:id`

Actualiza un proyecto existente.

**Request:**

```http
PUT /api/proyectos/1
Content-Type: application/json

{
  "titulo": "Mi Primera Novela Actualizada",
  "genero": "novela"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `titulo` | string | No | Nuevo título |
| `genero` | string | No | Nuevo género |

**Response 200 - OK:**

```json
{
  "id": 1,
  "titulo": "Mi Primera Novela Actualizada",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

### DELETE `/api/proyectos/:id`

Elimina un proyecto y todos sus escritos asociados (cascada).

**Request:**

```http
DELETE /api/proyectos/1
```

**Response 204 - No Content:**

```
(Sin cuerpo)
```

**Comportamiento:**
- Elimina automáticamente todos los escritos asociados (cascada en base de datos)
- Elimina el registro del proyecto

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

## Escritos/Capítulos

### GET `/api/escritos/proyecto/:id`

Obtiene todos los capítulos de un proyecto, ordenados por el campo `orden`.

**Request:**

```http
GET /api/escritos/proyecto/1
```

**Response 200 - OK:**

```json
[
  {
    "id": 1,
    "titulo_capitulo": "Capítulo 1: El Inicio",
    "contenido": "Hace mucho tiempo en una galaxia lejana...",
    "orden": 1,
    "proyecto_id": 1,
    "fecha_actualizacion": "2026-05-04T10:30:00Z"
  },
  {
    "id": 2,
    "titulo_capitulo": "Capítulo 2: La Aventura",
    "contenido": "Nuestro héroe continuó su viaje...",
    "orden": 2,
    "proyecto_id": 1,
    "fecha_actualizacion": "2026-05-04T11:00:00Z"
  }
]
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

### GET `/api/escritos/:id`

Obtiene un capítulo específico por su ID.

**Request:**

```http
GET /api/escritos/1
```

**Response 200 - OK:**

```json
{
  "id": 1,
  "titulo_capitulo": "Capítulo 1: El Inicio",
  "contenido": "Hace mucho tiempo en una galaxia lejana...",
  "orden": 1,
  "proyecto_id": 1,
  "fecha_actualizacion": "2026-05-04T10:30:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 404 | Escrito no encontrado |
| 500 | Error interno del servidor |

---

### POST `/api/escritos`

Crea un nuevo capítulo/escrito.

**Request:**

```http
POST /api/escritos
Content-Type: application/json

{
  "titulo_capitulo": "Capítulo 1: El Inicio",
  "contenido": "Hace mucho tiempo en una galaxia lejana...",
  "orden": 1,
  "proyecto_id": 1
}
```

| Campo | Tipo | Requerido | Default | Descripción |
|-------|------|:---------:|---------|-------------|
| `titulo_capitulo` | string | Sí | - | Título del capítulo |
| `contenido` | string | No | `""` | Cuerpo del texto |
| `orden` | int | No | `1` | Posición secuencial |
| `proyecto_id` | int | Sí | - | ID del proyecto padre |

**Response 201 - Created:**

```json
{
  "id": 1,
  "titulo_capitulo": "Capítulo 1: El Inicio",
  "contenido": "Hace mucho tiempo en una galaxia lejana...",
  "orden": 1,
  "proyecto_id": 1,
  "fecha_actualizacion": "2026-05-04T10:30:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

### PUT `/api/escritos/:id`

Actualiza un capítulo existente.

**Request:**

```http
PUT /api/escritos/1
Content-Type: application/json

{
  "titulo_capitulo": "Capítulo 1: El Inicio (Revisado)",
  "contenido": "Contenido actualizado...",
  "orden": 1
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `titulo_capitulo` | string | No | Nuevo título |
| `contenido` | string | No | Nuevo contenido |
| `orden` | int | No | Nueva posición |

**Response 200 - OK:**

```json
{
  "id": 1,
  "titulo_capitulo": "Capítulo 1: El Inicio (Revisado)",
  "contenido": "Contenido actualizado...",
  "orden": 1,
  "proyecto_id": 1,
  "fecha_actualizacion": "2026-05-04T12:00:00Z"
}
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

### DELETE `/api/escritos/:id`

Elimina un capítulo.

**Request:**

```http
DELETE /api/escritos/1
```

**Response 204 - No Content:**

```
(Sin cuerpo)
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 500 | Error interno del servidor |

---

## Upload de Archivos

### POST `/api/upload`

Sube un archivo de imagen al servidor.

**Request:**

```http
POST /api/upload
Content-Type: multipart/form-data

[archivo binario en el campo "imagen"]
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|:---------:|-------------|
| `imagen` | file | Sí | Archivo de imagen (multipart/form-data) |

**Response 200 - OK:**

```json
{
  "status": "success",
  "data": {
    "url": "http://localhost:3000/uploads/imagen_uuid.ext",
    "filename": "imagen_uuid.ext"
  }
}
```

**Acceso al archivo subido:**

```http
GET /uploads/imagen_uuid.ext
```

**Errores:**

| Status | Descripción |
|--------|-------------|
| 400 | No se ha subido ningún archivo |
| 500 | Error interno del servidor |

---

## Modelos de Datos

### Usuario

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | int | Identificador único (auto-incrementado) |
| `pseudonimo` | string | Nombre visible |
| `email` | string | Correo electrónico (único) |
| `password_hash` | string | Hash bcrypt (no se expone en responses) |
| `fecha_registro` | datetime | Timestamp de creación |

### Proyecto

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | int | Identificador único (auto-incrementado) |
| `titulo` | string | Título del proyecto |
| `genero` | string | Género literario |
| `usuario_id` | int | FK → Usuario.id |
| `fecha_creacion` | datetime | Timestamp de creación |

### Escrito

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | int | Identificador único (auto-incrementado) |
| `titulo_capitulo` | string | Título del capítulo |
| `contenido` | string | Cuerpo del texto |
| `orden` | int | Posición secuencial |
| `proyecto_id` | int | FK → Proyecto.id |
| `fecha_actualizacion` | datetime | Última actualización (auto-update) |

### Relaciones

```
Usuario (1) ──────── (N) Proyecto
                         │
                         └─── (1) ──────── (N) Escrito
```

---

## Códigos de Error

| Status | Significado | Cuándo ocurre |
|--------|-------------|---------------|
| 200 | OK | Operación exitosa con cuerpo de respuesta |
| 201 | Created | Recurso creado exitosamente |
| 204 | No Content | Operación exitosa sin cuerpo (DELETE) |
| 400 | Bad Request | Parámetros faltantes o inválidos |
| 401 | Unauthorized | Credenciales incorrectas (login) |
| 404 | Not Found | Recurso no encontrado |
| 500 | Internal Server Error | Error no manejado del servidor |

---

## Autenticación

El backend utiliza JWT (JSON Web Tokens) para autenticación:

- **Expiración del token:** 10 días
- **Header de autenticación:** `Authorization: Bearer <token>`
- **Hasheado de contraseñas:** bcryptjs (10 rounds)

> **Nota:** Actualmente los endpoints de proyectos y escritos no validan el token JWT. El interceptor del cliente Flutter adjunta el Bearer token en todas las peticiones de todas formas.

---

## Swagger

Documentación interactiva completa disponible en:

- **UI:** `http://localhost:3000/api-docs`
- **Spec JSON:** `http://localhost:3000/api-docs.json`

---

## Documentos Relacionados

| Documento | Descripción |
|-----------|-------------|
| [ARQUITECTURA-backend.md](../ARQUITECTURA-backend.md) | Arquitectura completa del backend Express.js |
| [README.md](../README.md) | Documentación general del proyecto Flutter |
| [ARQUITECTURA-Flutter.md](./ARQUITECTURA-Flutter.md) | Arquitectura de la app Flutter |
