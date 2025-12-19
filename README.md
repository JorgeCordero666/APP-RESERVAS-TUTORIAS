# 🎓 Sistema de Gestión de Tutorías Académicas - ESFOT

Sistema de gestión de tutorías académicas desarrollado para la Escuela de Formación de Tecnólogos (ESFOT) de la Escuela Politécnica Nacional. Permite a estudiantes reservar tutorías con docentes mediante un sistema de turnos de 20 minutos, con notificaciones automáticas por correo y gestión completa de horarios.

---

## 📱 Descargar la Aplicación

Descarga la APK de la aplicación para dispositivos Android desde el siguiente enlace:

### [🔗 Descargar APK](https://github.com/IGNN3LZ3R0/APP-RESERVAS-TUTORIAS/releases/latest)

### Instrucciones de Instalación

1. Descarga la APK `app-reservas-tutorias-v1.0.0.apk` en tu dispositivo móvil
2. Si es la primera vez que instalas una app fuera de Google Play, habilita **Orígenes desconocidos** en la configuración de seguridad de tu teléfono
3. Abre el archivo descargado e instala la aplicación
4. ¡Listo! Accede con tu cuenta institucional o regístrate como estudiante

**Requisitos:**
- Android 5.0 (Lollipop) o superior
- Conexión a internet
- ~60 MB de espacio disponible

---

## ✨ Características Principales

### Para Estudiantes
- ✅ Registro y autenticación segura con JWT
- 🔍 Búsqueda de materias y docentes disponibles
- 📅 Visualización de horarios disponibles en tiempo real
- ⏰ Sistema de turnos de 20 minutos para reservas precisas
- 🔔 Notificaciones por email (24h y 3h antes de la tutoría)
- 📚 Historial completo de tutorías
- 🔄 Cancelación y reagendamiento de tutorías
- 👤 Gestión de perfil con foto

### Para Docentes
- 📊 Gestión de horarios de disponibilidad por materia
- 📋 Aprobación/rechazo de solicitudes de tutoría
- ✍️ Finalización de tutorías con registro de asistencia
- 📈 Reportes de tutorías por materia
- 🔔 Notificaciones de nuevas solicitudes
- 🕐 Control de bloques horarios personalizados

### Para Administradores
- 👥 CRUD completo de docentes y estudiantes
- 📖 Gestión del catálogo de materias
- 📊 Reportes y estadísticas del sistema
- 📈 Métricas por docente, materia y período
- 🔍 Historial completo de todas las tutorías

---

## 🛠️ Tecnologías Utilizadas

### Frontend (App Móvil)
- **Flutter 3.9.2** - Framework multiplataforma
- **Dart 3.9.2** - Lenguaje de programación
- **http** - Comunicación con API REST
- **shared_preferences** - Almacenamiento local
- **image_picker** - Gestión de imágenes de perfil
- **app_links** - Deep linking para recuperación de contraseña

### Backend (API REST)
- **Node.js 18.x** - Runtime de JavaScript
- **Express 4.21.2** - Framework web
- **MongoDB 8.19** - Base de datos NoSQL
- **Mongoose** - ODM para MongoDB
- **JWT** - Autenticación y autorización
- **bcryptjs** - Encriptación de contraseñas
- **Nodemailer** - Sistema de notificaciones por email
- **Cloudinary** - Almacenamiento de imágenes

---

## 🚀 Instalación del Proyecto (Para Desarrolladores)

### 1. Clonar el repositorio

```bash
git clone https://github.com/IGNN3LZ3R0/APP-RESERVAS-TUTORIAS.git
cd APP-RESERVAS-TUTORIAS
```

### 2. Configurar el Backend

```bash
cd backend
npm install
```

Crear archivo `.env` en la carpeta `backend/`:

```env
# MongoDB
MONGODB_URL=mongodb://localhost:27017/tutorias_db

# JWT
JWT_SECRET=tu_clave_secreta_segura

# Nodemailer (Gmail)
EMAIL_USER=tu_correo@gmail.com
EMAIL_PASS=tu_contraseña_de_aplicacion

# Cloudinary (opcional)
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret

# Puerto
PORT=3000
```

Iniciar el servidor:

```bash
# Modo desarrollo
npm run dev

# Modo producción
npm start
```

### 3. Configurar el Frontend

```bash
cd app_tesis
flutter pub get
```

Configurar la URL del backend en `lib/config/api_config.dart`:

```dart
// Para emulador Android
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Para dispositivo físico (reemplaza con tu IP local)
// static const String baseUrl = 'http://192.168.1.X:3000/api';
```

Ejecutar la aplicación:

```bash
# En emulador o dispositivo conectado
flutter run

# Compilar APK de producción
flutter build apk --release
```

---

## 🗄️ Esquema de la Base de Datos (MongoDB)

### Colecciones Principales

#### 📋 Administradores
```javascript
{
  _id: ObjectId,
  nombreAdministrador: String,
  email: String,
  password: String (encrypted),
  fotoPerfilAdmin: String,
  rol: "Administrador",
  confirmEmail: Boolean,
  timestamps: { createdAt, updatedAt }
}
```

#### 👨‍🏫 Docentes
```javascript
{
  _id: ObjectId,
  cedulaDocente: String,
  nombreDocente: String,
  fechaNacimientoDocente: Date,
  oficinaDocente: String,
  emailDocente: String,
  emailAlternativoDocente: String,
  passwordDocente: String (encrypted),
  celularDocente: String,
  avatarDocente: String,
  fechaIngresoDocente: Date,
  semestreAsignado: String,
  asignaturas: [String],
  confirmEmail: Boolean,
  estadoDocente: Boolean,
  requiresPasswordChange: Boolean,
  rol: "Docente",
  administrador: ObjectId (ref: Administrador),
  timestamps: { createdAt, updatedAt }
}
```

#### 👨‍🎓 Estudiantes
```javascript
{
  _id: ObjectId,
  nombreEstudiante: String,
  telefono: String,
  emailEstudiante: String,
  password: String (encrypted),
  fotoPerfil: String,
  status: Boolean,
  confirmEmail: Boolean,
  rol: "Estudiante",
  timestamps: { createdAt, updatedAt }
}
```

#### 📚 Materias
```javascript
{
  _id: ObjectId,
  nombre: String,
  codigo: String,
  semestre: String,
  creditos: Number,
  descripcion: String,
  activa: Boolean,
  creadoPor: ObjectId (ref: Administrador),
  timestamps: { createdAt, updatedAt }
}
```

#### 📅 DisponibilidadDocente
```javascript
{
  _id: ObjectId,
  docente: ObjectId (ref: Docente),
  diaSemana: String, // lunes, martes, miércoles, jueves, viernes
  materia: String,
  bloques: [
    {
      horaInicio: String, // "08:00"
      horaFin: String     // "10:00"
    }
  ],
  timestamps: { createdAt, updatedAt }
}
```

#### 📝 Tutorías
```javascript
{
  _id: ObjectId,
  estudiante: ObjectId (ref: Estudiante),
  docente: ObjectId (ref: Docente),
  fecha: String, // "2025-12-20"
  horaInicio: String, // "08:00"
  horaFin: String, // "08:20"
  bloqueDocenteId: ObjectId (ref: disponibilidadDocente),
  estado: String, // pendiente, confirmada, rechazada, cancelada_*, finalizada, no_asiste, expirada
  motivoRechazo: String,
  motivoCancelacion: String,
  motivoReagendamiento: String,
  reagendadaPor: String,
  fechaReagendamiento: Date,
  asistenciaEstudiante: Boolean,
  observacionesDocente: String,
  recordatorio24hEnviado: Boolean,
  recordatorio3hEnviado: Boolean,
  timestamps: { createdAt, updatedAt }
}
```

### Relaciones entre Colecciones

```
Administrador (1) -----> (N) Docentes
Administrador (1) -----> (N) Materias

Docente (1) -----> (N) DisponibilidadDocente
Docente (1) -----> (N) Tutorías

Estudiante (1) -----> (N) Tutorías

DisponibilidadDocente (1) -----> (N) Tutorías
```

---

## 🏗️ Arquitectura del Sistema

### Patrón MVC (Modelo-Vista-Controlador)

```
┌─────────────────────────────────────────┐
│         CAPA DE PRESENTACIÓN            │
│                (Flutter)                 │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │ Modelos │  │ Pantallas│  │Servicios│ │
│  └─────────┘  └──────────┘  └────────┘ │
└──────────────────┬──────────────────────┘
                   │ HTTP/REST (JWT)
┌──────────────────▼──────────────────────┐
│          CAPA DE NEGOCIO                 │
│            (Node.js + Express)           │
│  ┌───────────┐  ┌────────────┐          │
│  │Controllers│  │Middlewares │          │
│  └───────────┘  └────────────┘          │
└──────────────────┬──────────────────────┘
                   │ Mongoose ODM
┌──────────────────▼──────────────────────┐
│          CAPA DE DATOS                   │
│             (MongoDB)                    │
│  Colecciones: Usuarios, Tutorías, etc.  │
└──────────────────────────────────────────┘
```

---

## 🧪 Pruebas

### Ejecutar pruebas unitarias

```bash
cd app_tesis
flutter test

# Pruebas específicas por sprint
flutter test test/sprint1/
flutter test test/sprint2/
flutter test test/sprint3/
flutter test test/sprint4/
```

### Cobertura de Pruebas

- ✅ Autenticación y registro
- ✅ Recuperación de contraseña
- ✅ Gestión de perfiles
- ✅ CRUD de materias
- ✅ Agendamiento de tutorías
- ✅ Cancelación y reagendamiento
- ✅ Finalización y asistencia
- ✅ Reportes para administradores

## 👥 Equipo de Desarrollo

**Proyecto de Titulación - Escuela Politécnica Nacional**

| Nombre | Rol | Contacto |
|--------|-----|----------|
| **Lenin Gabriel Proaño Chamba** | Desarrollo Frontend (Flutter) | [GitHub](https://github.com/IGNN3LZ3R0) |
| **Pablo Emilio Erazo Ortega** | Desarrollo Backend (Node.js) | - |

**Institución:** Escuela de Formación de Tecnólogos (ESFOT) - EPN  
**Año:** 2024-2025  
**Ubicación:** Quito, Ecuador


## 🙏 Agradecimientos

- Escuela Politécnica Nacional por el apoyo institucional
- Escuela de Formación de Tecnólogos (ESFOT)
- Docentes tutores del proyecto
- Estudiantes y profesores que participaron en las pruebas

---

<div align="center">

[⬆ Volver arriba](#-sistema-de-gestión-de-tutorías-académicas---esfot)

</div>
