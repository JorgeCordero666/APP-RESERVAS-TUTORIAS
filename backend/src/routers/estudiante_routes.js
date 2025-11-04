// backend/src/routers/estudiante_routes.js - VERSIÓN ACTUALIZADA
import { Router } from 'express'
import { loginOAuthEstudiante } from "../controllers/sesion_google_correo_controller.js";
import {
  confirmarMailEstudiante,
  recuperarPasswordEstudiante,
  registroEstudiante,
  comprobarTokenPasswordEstudiante,
  crearNuevoPasswordEstudiante,
  loginEstudiante,
  perfilEstudiante,
  actualizarPerfilEstudiante,
  actualizarPasswordEstudiante,
  
  // ⭐ NUEVAS IMPORTACIONES
  listarEstudiantes,
  detalleEstudiante,
  actualizarEstudianteAdmin,
  eliminarEstudiante
} from '../controllers/estudiante_controller.js'
import { verificarTokenJWT } from '../middlewares/JWT.js'
import verificarRol from '../middlewares/rol.js'

const routerEstudiante = Router()

// ========== RUTAS PÚBLICAS ==========

// Registro
routerEstudiante.post('/estudiante/registro', registroEstudiante)

// Confirmación de email
routerEstudiante.get('/confirmar/:token', confirmarMailEstudiante)

// Recuperar contraseña
routerEstudiante.post('/estudiante/recuperarpassword', recuperarPasswordEstudiante)
routerEstudiante.get('/estudiante/recuperarpassword/:token', comprobarTokenPasswordEstudiante)
routerEstudiante.post('/estudiante/nuevopassword/:token', crearNuevoPasswordEstudiante)

// Login
routerEstudiante.post('/estudiante/login', loginEstudiante)

// Login con OAuth (Google, Microsoft)
routerEstudiante.post('/estudiante/login-oauth', loginOAuthEstudiante)

// ========== RUTAS PRIVADAS - ESTUDIANTE ==========

// Perfil
routerEstudiante.get('/estudiante/perfil', verificarTokenJWT, perfilEstudiante)

// Actualizar perfil (propio)
routerEstudiante.put('/estudiante/:id', verificarTokenJWT, actualizarPerfilEstudiante)

// Actualizar contraseña (propia)
routerEstudiante.put('/estudiante/actualizarpassword/:id', verificarTokenJWT, actualizarPasswordEstudiante)

// ========== RUTAS PRIVADAS - ADMINISTRADOR ==========

// Listar todos los estudiantes (solo admin)
routerEstudiante.get('/estudiantes', verificarTokenJWT, verificarRol(["Administrador"]), listarEstudiantes)

// Detalle de estudiante (admin)
routerEstudiante.get('/estudiante/detalle/:id', verificarTokenJWT, verificarRol(["Administrador"]), detalleEstudiante)

// Actualizar estudiante (admin)
routerEstudiante.put('/estudiante/actualizar/:id', verificarTokenJWT, verificarRol(["Administrador"]), actualizarEstudianteAdmin)

// Eliminar (deshabilitar) estudiante (admin)
routerEstudiante.delete('/estudiante/eliminar/:id', verificarTokenJWT, verificarRol(["Administrador"]), eliminarEstudiante)

export default routerEstudiante