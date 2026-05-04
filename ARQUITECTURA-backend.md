# Backend Dispositivos - Documentación de Arquitectura

## 📋 Tabla de Contenidos
1. [Visión General](#visión-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Modelos de Base de Datos](#modelos-de-base-de-datos)
6. [Endpoints API](#endpoints-api)
7. [Configuración y Ejecución](#configuración-y-ejecución)

---

## 🎯 Visión General

Este es un backend literario desarrollado con **Express.js** y **TypeScript** que gestiona proyectos de escritura, capítulos (escritos) y la autenticación de usuarios. El sistema permite a los usuarios crear proyectos, escribir capítulos dentro de ellos y gestionar su contenido de manera organizada.

**Características principales:**
- Autenticación con JWT
- Gestión de proyectos literarios
- Gestión de capítulos/escritos
- Subida de imágenes/archivos
- API documentada con Swagger
- Base de datos PostgreSQL con Prisma ORM

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| **Runtime** | Node.js | - |
| **Framework** | Express.js | 5.2.1 |
| **Lenguaje** | TypeScript | 6.0.2 |
| **Base de Datos** | PostgreSQL | 8.20.0 |
| **ORM** | Prisma | 7.7.0 |
| **Autenticación** | JWT (jsonwebtoken) | 9.0.3 |
| **Encriptación** | bcryptjs | 3.0.3 |
| **Validación** | Zod | 4.3.6 |
| **Documentación** | Swagger/OpenAPI | - |
| **Upload de Archivos** | Multer | 2.1.1 |
| **CORS** | cors | 2.8.6 |

---

## 🏗️ Arquitectura del Sistema

### Arquitectura en Capas

```
┌─────────────────────────────────────┐
│        CLIENTE (Frontend)           │
└────────────┬────────────────────────┘
             │ HTTP/REST
┌────────────▼────────────────────────┐
│      CAPA DE RUTAS (Routes)         │
│  Definen endpoints y middlewares    │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   CAPA DE CONTROLADORES            │
│  Lógica de negocio principal       │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   CAPA DE PERSISTENCIA (Prisma)    │
│  ORM y acceso a datos              │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   BASE DE DATOS (PostgreSQL)       │
│  Almacenamiento de datos           │
└─────────────────────────────────────┘
```

### Flujo de una Solicitud

1. **Cliente** → Envía una solicitud HTTP a un endpoint
2. **Express App** → Middleware de CORS y JSON parsing
3. **Rutas (Routes)** → Enruta la solicitud al controlador correcto
4. **Controlador (Controller)** → Ejecuta la lógica de negocio
5. **Prisma Client** → Ejecuta queries a la BD
6. **PostgreSQL** → Ejecuta operaciones CRUD
7. **Respuesta** → JSON devuelto al cliente con status HTTP

---

## 📁 Estructura de Carpetas

```
backendDispositivos/
├── src/
│   ├── index.ts                 # Punto de entrada de la aplicación
│   ├── config/
│   │   └── prisma.ts           # Configuración de Prisma y conexión a BD
│   ├── controllers/             # Lógica de negocio
│   │   ├── auth.controller.ts
│   │   ├── proyecto.controller.ts
│   │   ├── escrito.controller.ts
│   │   └── upload.controller.ts
│   ├── dto/                     # Data Transfer Objects (Schemas)
│   │   ├── auth.dto.ts
│   │   ├── proyecto.dto.ts
│   │   └── escrito.dto.ts
│   ├── lib/                     # Librerías compartidas
│   │   ├── openapi-registry.ts # Registro de OpenAPI
│   │   ├── swagger.ts          # Configuración de Swagger
│   │   └── zod.ts              # Configuración de Zod
│   ├── middlewares/             # Middlewares personalizados
│   │   └── upload.ts           # Configuración de Multer
│   ├── routes/                  # Definición de rutas
│   │   ├── auth.routes.ts
│   │   ├── auth.docs.ts        # Documentación de auth
│   │   ├── proyecto.routes.ts
│   │   ├── proyecto.docs.ts
│   │   ├── escrito.routes.ts
│   │   ├── escrito.docs.ts
│   │   └── upload.routes.ts
│   └── types/                   # Tipos TypeScript personalizados
├── prisma/
│   ├── schema.prisma           # Definición del modelo de datos
│   └── migrations/             # Historial de migraciones
├── uploads/                     # Directorio para archivos subidos
├── .env                         # Variables de entorno
├── package.json
├── tsconfig.json
└── README.md
```

---

## 🗄️ Modelos de Base de Datos

### Relaciones

```
Usuario (1) ──────── (N) Proyecto
                         │
                         └─── (1) ──────── (N) Escrito
```

### Modelo: Usuario

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | Identificador único (auto-incrementado) |
| `pseudonimo` | String | Nombre de usuario para mostrar |
| `email` | String (UNIQUE) | Correo electrónico del usuario |
| `password_hash` | String | Hash bcrypt de la contraseña |
| `fecha_registro` | DateTime | Timestamp de creación (default: now) |
| `proyectos` | Relation | Relación con proyectos del usuario |

### Modelo: Proyecto

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | Identificador único (auto-incrementado) |
| `titulo` | String | Título del proyecto literario |
| `genero` | String | Género literario (ej: novela, cuento, poesía) |
| `usuario_id` | Int (FK) | Referencia al usuario propietario |
| `fecha_creacion` | DateTime | Timestamp de creación (default: now) |
| `usuario` | Relation | Relación con el usuario propietario |
| `escritos` | Relation | Relación con capítulos del proyecto |

### Modelo: Escrito

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | Identificador único (auto-incrementado) |
| `titulo_capitulo` | String | Título del capítulo |
| `contenido` | String | Cuerpo del texto del capítulo |
| `orden` | Int | Número secuencial del capítulo |
| `proyecto_id` | Int (FK) | Referencia al proyecto padre |
| `fecha_actualizacion` | DateTime | Última actualización (auto-actualizado) |
| `proyecto` | Relation | Relación con el proyecto padre |

---

## 🔌 Endpoints API

La base de la API es: `http://localhost:3000/api`

### 🔐 Autenticación (`/api/auth`)

#### 1. Registrar usuario
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "usuario@example.com",
  "password": "contraseña123",
  "pseudonimo": "MiPseudónimo"
}
```

**Respuesta (201 Created):**
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

**Posibles errores:**
- `400 Bad Request` - El correo ya está registrado
- `500 Internal Server Error` - Error del servidor

---

#### 2. Iniciar sesión
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "usuario@example.com",
  "password": "contraseña123"
}
```

**Respuesta (200 OK):**
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

**Posibles errores:**
- `401 Unauthorized` - Correo o contraseña incorrectos
- `500 Internal Server Error` - Error del servidor

---

### 📚 Proyectos (`/api/proyectos`)

#### 3. Obtener todos los proyectos del usuario
```http
GET /api/proyectos?usuario_id=1
```

**Respuesta (200 OK):**
```json
[
  {
    "id": 1,
    "titulo": "Mi Primera Novela",
    "genero": "novela",
    "usuario_id": 1,
    "fecha_creacion": "2026-05-04T10:30:00Z"
  }
]
```

**Parámetros:**
- `usuario_id` (query, requerido) - ID del usuario propietario de los proyectos

**Posibles errores:**
- `400 Bad Request` - usuario_id no proporcionado
- `500 Internal Server Error` - Error del servidor

---

#### 4. Obtener un proyecto específico
```http
GET /api/proyectos/:id
```

**Parámetros:**
- `id` (path, requerido) - ID del proyecto

**Respuesta (200 OK):**
```json
{
  "id": 1,
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Posibles errores:**
- `404 Not Found` - Proyecto no encontrado
- `500 Internal Server Error` - Error del servidor

---

#### 5. Crear un nuevo proyecto
```http
POST /api/proyectos
Content-Type: application/json

{
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1
}
```

**Parámetros del cuerpo:**
- `titulo` (string, requerido) - Título del proyecto
- `genero` (string, requerido) - Género literario
- `usuario_id` (integer, requerido) - ID del usuario propietario

**Respuesta (201 Created):**
```json
{
  "id": 1,
  "titulo": "Mi Primera Novela",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

#### 6. Actualizar un proyecto
```http
PUT /api/proyectos/:id
Content-Type: application/json

{
  "titulo": "Mi Primera Novela Actualizada",
  "genero": "novela"
}
```

**Parámetros:**
- `id` (path, requerido) - ID del proyecto
- `titulo` (string, opcional) - Nuevo título
- `genero` (string, opcional) - Nuevo género

**Respuesta (200 OK):**
```json
{
  "id": 1,
  "titulo": "Mi Primera Novela Actualizada",
  "genero": "novela",
  "usuario_id": 1,
  "fecha_creacion": "2026-05-04T10:30:00Z"
}
```

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

#### 7. Eliminar un proyecto
```http
DELETE /api/proyectos/:id
```

**Parámetros:**
- `id` (path, requerido) - ID del proyecto

**Respuesta (204 No Content):**
```
Sin cuerpo
```

**Comportamiento:**
- Elimina automáticamente todos los escritos asociados (cascada)
- Elimina el proyecto de la base de datos

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

### ✍️ Escritos/Capítulos (`/api/escritos`)

#### 8. Obtener escritos de un proyecto
```http
GET /api/escritos/proyecto/:id
```

**Parámetros:**
- `id` (path, requerido) - ID del proyecto

**Respuesta (200 OK):**
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

**Nota:** Los escritos se retornan ordenados por el campo `orden` (ascendente)

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

#### 9. Obtener un escrito específico
```http
GET /api/escritos/:id
```

**Parámetros:**
- `id` (path, requerido) - ID del escrito

**Respuesta (200 OK):**
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

**Posibles errores:**
- `404 Not Found` - Escrito no encontrado
- `500 Internal Server Error` - Error del servidor

---

#### 10. Crear un nuevo escrito
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

**Parámetros del cuerpo:**
- `titulo_capitulo` (string, requerido) - Título del capítulo
- `contenido` (string, opcional) - Cuerpo del capítulo (default: "")
- `orden` (integer, opcional) - Posición del capítulo (default: 1)
- `proyecto_id` (integer, requerido) - ID del proyecto padre

**Respuesta (201 Created):**
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

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

#### 11. Actualizar un escrito
```http
PUT /api/escritos/:id
Content-Type: application/json

{
  "titulo_capitulo": "Capítulo 1: El Inicio (Revisado)",
  "contenido": "Contenido actualizado...",
  "orden": 1
}
```

**Parámetros:**
- `id` (path, requerido) - ID del escrito
- `titulo_capitulo` (string, opcional) - Nuevo título
- `contenido` (string, opcional) - Nuevo contenido
- `orden` (integer, opcional) - Nueva posición

**Respuesta (200 OK):**
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

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

#### 12. Eliminar un escrito
```http
DELETE /api/escritos/:id
```

**Parámetros:**
- `id` (path, requerido) - ID del escrito

**Respuesta (204 No Content):**
```
Sin cuerpo
```

**Posibles errores:**
- `500 Internal Server Error` - Error del servidor

---

### 📤 Upload de Archivos (`/api/upload`)

#### 13. Subir un archivo
```http
POST /api/upload
Content-Type: multipart/form-data

[archivo binario en el campo "imagen"]
```

**Parámetros:**
- `imagen` (file, requerido) - Archivo a subir (multipart/form-data)

**Respuesta (200 OK):**
```json
{
  "status": "success",
  "data": {
    "url": "http://localhost:3000/uploads/imagen_uuid.ext",
    "filename": "imagen_uuid.ext"
  }
}
```

**Acceso al archivo:**
```
GET /uploads/imagen_uuid.ext
```

**Posibles errores:**
- `400 Bad Request` - No se ha subido ningún archivo
- `500 Internal Server Error` - Error del servidor

---

### 📖 Documentación Swagger

Accede a la documentación interactiva de la API en:
```
http://localhost:3000/api-docs
```

JSON raw de la especificación OpenAPI:
```
http://localhost:3000/api-docs.json
```

---

## ⚙️ Configuración y Ejecución

### Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
# Base de Datos
DATABASE_URL="postgresql://usuario:contraseña@localhost:5432/nombre_bd"

# Puerto
PORT=3000

# JWT
JWT_SECRET="tu_secret_key_aqui"

# Node Environment
NODE_ENV="development"
```

### Instalación de Dependencias

```bash
npm install
```

### Migraciones de Base de Datos

Sincronizar el schema con la base de datos:

```bash
npm run db:sync
```

### Desarrollo

Ejecutar en modo desarrollo con hot-reload:

```bash
npm run dev
```

El servidor se iniciará en `http://localhost:3000`

### Producción

Compilar TypeScript a JavaScript:

```bash
npx tsc
```

Ejecutar el código compilado:

```bash
node dist/index.js
```

---

## 🔒 Seguridad

**Implementado:**
- Hasheado de contraseñas con bcryptjs (10 rounds)
- Autenticación con JWT (10 días de expiración)
- CORS habilitado
- Variables de entorno para datos sensibles

**Recomendaciones futuras:**
- Implementar middleware de autenticación JWT en rutas protegidas
- Rate limiting
- Validación de entrada con Zod en todos los endpoints
- HTTPS en producción
- Sanitización de input

---

## 📊 Flujos de Trabajo Comunes

### Crear un proyecto y escribir capítulos

1. **Registrar/Login** → Obtener JWT
   ```
   POST /api/auth/register
   ```

2. **Crear proyecto** → Obtener ID del proyecto
   ```
   POST /api/proyectos
   {
     "titulo": "Mi Novela",
     "genero": "ficción",
     "usuario_id": 1
   }
   ```

3. **Crear capítulos** → Crear múltiples escritos
   ```
   POST /api/escritos
   {
     "titulo_capitulo": "Capítulo 1",
     "contenido": "...",
     "orden": 1,
     "proyecto_id": 1
   }
   ```

4. **Listar capítulos** → Obtener todos los capítulos del proyecto
   ```
   GET /api/escritos/proyecto/1
   ```

5. **Editar capítulo** → Actualizar contenido
   ```
   PUT /api/escritos/:id
   ```

---

## 🚀 Próximas Mejoras

- [ ] Implementar middleware de autenticación JWT
- [ ] Validación robusta con Zod en DTOs
- [ ] Tests unitarios y de integración
- [ ] Paginación en listados
- [ ] Búsqueda y filtros avanzados
- [ ] Soft delete para proyectos y escritos
- [ ] Control de acceso basado en roles (RBAC)
- [ ] Versionado de escritos
- [ ] Compartir proyectos entre usuarios
- [ ] Exportar proyectos (PDF, EPUB, Word)

---

## 📞 Soporte

Para más información o dudas sobre la arquitectura, consulta el código fuente en los archivos de `controllers/`, `routes/` y la configuración en `src/config/`.
