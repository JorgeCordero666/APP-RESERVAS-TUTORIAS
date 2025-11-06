// backend/src/routers/tutorias_routes.js
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
  registrarDisponibilidadPorMateria,
  verDisponibilidadPorMateria,
  verDisponibilidadCompletaDocente,
  eliminarDisponibilidadMateria
} from "../controllers/tutorias_controller.js";

import { verificarTokenJWT } from "../middlewares/JWT.js";
import verificarRol from "../middlewares/rol.js";

const routerTutorias = Router();

// =====================================================
// ✅ GESTIÓN DE TUTORÍAS
// =====================================================

// Registrar tutoría (solo estudiantes)
routerTutorias.post(
  "/tutoria/registro",
  verificarTokenJWT,
  verificarRol(["Estudiante"]),
  registrarTutoria
);

// Listar tutorías activas (sin canceladas)
routerTutorias.get(
  "/tutorias",
  verificarTokenJWT,
  verificarRol(["Docente", "Estudiante"]),
  listarTutorias
);

// Actualizar tutoría
routerTutorias.put(
  "/tutoria/actualizar/:id",
  verificarTokenJWT,
  verificarRol(["Estudiante"]),
  actualizarTutoria
);

// Cancelar tutoría
routerTutorias.delete(
  "/tutoria/cancelar/:id",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente"]),
  cancelarTutoria
);

// Registrar asistencia
routerTutorias.put(
  "/tutoria/registrar-asistencia/:id",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarAsistencia
);

// =====================================================
// ✅ HISTORIAL DE TUTORÍAS (incluye canceladas)
// =====================================================

// Historial completo del estudiante
routerTutorias.get(
  "/estudiante/historial-tutorias",
  verificarTokenJWT,
  verificarRol(["Estudiante"]),
  (req, res, next) => {
    req.query.incluirCanceladas = 'true';
    next();
  },
  listarTutorias
);

// Historial completo del docente
routerTutorias.get(
  "/docente/historial-tutorias",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  (req, res, next) => {
    req.query.incluirCanceladas = 'true';
    next();
  },
  listarTutorias
);

// Historial completo para administrador (todas las tutorías del sistema)
routerTutorias.get(
  "/admin/todas-tutorias",
  verificarTokenJWT,
  verificarRol(["Administrador"]),
  async (req, res) => {
    try {
      const { incluirCanceladas } = req.query;
      
      let filtro = {};
      
      if (incluirCanceladas !== 'true') {
        filtro.estado = { 
          $nin: ['cancelada_por_estudiante', 'cancelada_por_docente'] 
        };
      }

      // Importar Tutoria aquí para evitar dependencia circular
      const Tutoria = (await import('../models/tutorias.js')).default;

      const tutorias = await Tutoria.find(filtro)
        .populate("estudiante", "nombreEstudiante emailEstudiante")
        .populate("docente", "nombreDocente emailDocente")
        .sort({ fecha: -1, horaInicio: -1 });

      res.json({
        success: true,
        total: tutorias.length,
        tutorias
      });
    } catch (error) {
      console.error("❌ Error en admin/todas-tutorias:", error);
      res.status(500).json({ 
        success: false,
        msg: "Error al obtener tutorías", 
        error: error.message 
      });
    }
  }
);

// =====================================================
// ✅ DISPONIBILIDAD GENERAL (LEGACY)
// =====================================================

// Registrar disponibilidad semanal
routerTutorias.post(
  "/tutorias/registrar-disponibilidad",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarDisponibilidadDocente
);

// Ver disponibilidad general del docente
routerTutorias.get(
  "/ver-disponibilidad-docente/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente"]),
  verDisponibilidadDocente
);

// Bloques ocupados
routerTutorias.get(
  "/tutorias-ocupadas/:docenteId", 
  bloquesOcupadosDocente
);

// =====================================================
// ✅ DISPONIBILIDAD POR MATERIA
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