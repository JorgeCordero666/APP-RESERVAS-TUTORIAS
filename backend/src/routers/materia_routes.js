// backend/src/routers/materia_routes.js
import { Router } from 'express';
import {
  listarMaterias,
  crearMateria,
  actualizarMateria,
  eliminarMateria,
  detalleMateria,
  buscarMaterias
} from '../controllers/materia_controller.js';
import { verificarTokenJWT } from '../middlewares/JWT.js';
import verificarRol from '../middlewares/rol.js';

const routerMateria = Router();

// ========== RUTAS PÚBLICAS (con autenticación básica) ==========

// Listar materias activas (todos los roles autenticados)
routerMateria.get(
  '/materias',
  verificarTokenJWT,
  listarMaterias
);

// Buscar materias (todos los roles autenticados)
routerMateria.get(
  '/materias/buscar',
  verificarTokenJWT,
  buscarMaterias
);

// Detalle de materia (todos los roles autenticados)
routerMateria.get(
  '/materias/:id',
  verificarTokenJWT,
  detalleMateria
);

// ========== RUTAS PRIVADAS - SOLO ADMINISTRADOR ==========

// Crear materia
routerMateria.post(
  '/materias',
  verificarTokenJWT,
  verificarRol(['Administrador']),
  crearMateria
);

// Actualizar materia
routerMateria.put(
  '/materias/:id',
  verificarTokenJWT,
  verificarRol(['Administrador']),
  actualizarMateria
);

// Eliminar (desactivar) materia
routerMateria.delete(
  '/materias/:id',
  verificarTokenJWT,
  verificarRol(['Administrador']),
  eliminarMateria
);

export default routerMateria;