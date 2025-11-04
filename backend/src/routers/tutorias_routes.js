import { Router } from "express";
import {
  registrarTutoria,
  actualizarTutoria,
  cancelarTutoria,
  listarTutorias,
  registrarAsistencia,
  registrarDisponibilidadDocente,        
  verDisponibilidadDocente,             
  bloquesOcupadosDocente,

  // ⭐ NUEVAS IMPORTACIONES
  registrarDisponibilidadPorMateria,
  verDisponibilidadPorMateria,
  verDisponibilidadCompletaDocente,
  eliminarDisponibilidadMateria
} from "../controllers/tutorias_controller.js";

import { verificarTokenJWT } from "../middlewares/JWT.js";
import verificarRol from "../middlewares/rol.js";

const routerTutorias = Router();

// =====================================================
// ✅ RUTAS EXISTENTES (NO MODIFICAR)
// =====================================================

// 📌 Registrar tutoría (solo estudiantes)
routerTutorias.post(
  "/tutoria/registro",
  verificarTokenJWT,
  verificarRol(["Estudiante"]),
  registrarTutoria
);

// 📌 Listar tutorías
routerTutorias.get(
  "/tutorias",
  verificarTokenJWT,
  verificarRol(["Docente", "Estudiante"]),
  listarTutorias
);

// 📌 Actualizar tutoría
routerTutorias.put(
  "/tutoria/actualizar/:id",
  verificarTokenJWT,
  verificarRol(["Estudiante"]),
  actualizarTutoria
);

// 📌 Cancelar tutoría
routerTutorias.delete(
  "/tutoria/cancelar/:id",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente"]),
  cancelarTutoria
);

// 📌 Registrar asistencia
routerTutorias.put(
  "/tutoria/registrar-asistencia/:id_tutoria",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarAsistencia
);

// 📌 Disponibilidad semanal (versión antigua — mantener)
routerTutorias.post(
  "/tutorias/registrar-disponibilidad",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarDisponibilidadDocente
);

// 📌 Ver disponibilidad general del docente
routerTutorias.get(
  "/ver-disponibilidad-docente/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente"]),
  verDisponibilidadDocente
);

// 📌 Bloques ocupados
routerTutorias.get("/tutorias-ocupadas/:docenteId", bloquesOcupadosDocente);

// =====================================================
// ✅ ⭐ NUEVAS RUTAS — DISPONIBILIDAD POR MATERIA
// =====================================================

// Registrar disponibilidad por materia
routerTutorias.post(
  "/tutorias/registrar-disponibilidad-materia",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarDisponibilidadPorMateria
);

// Ver disponibilidad de un docente por una materia específica
routerTutorias.get(
  "/ver-disponibilidad-materia/:docenteId/:materia",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente", "Administrador"]),
  verDisponibilidadPorMateria
);

// Ver disponibilidad completa (todas las materias)
routerTutorias.get(
  "/ver-disponibilidad-completa/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente", "Administrador"]),
  verDisponibilidadCompletaDocente
);

// Eliminar disponibilidad de materia + día
routerTutorias.delete(
  "/eliminar-disponibilidad-materia/:docenteId/:materia/:dia",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  eliminarDisponibilidadMateria
);

export default routerTutorias;
