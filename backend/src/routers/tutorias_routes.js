// backend/src/routers/tutorias_routes.js - OPTIMIZADO PARA FLUTTER
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
  eliminarDisponibilidadMateria,
  actualizarHorarios
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

// Listar tutorías activas (sin canceladas por defecto)
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

// Historial completo para administrador
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

      const Tutoria = (await import('../models/tutorias.js')).default;

      const tutorias = await Tutoria.find(filtro)
        .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
        .populate("docente", "nombreDocente emailDocente avatarDocente")
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

// Registrar disponibilidad semanal (método antiguo)
routerTutorias.post(
  "/tutorias/registrar-disponibilidad",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarDisponibilidadDocente
);

// Ver disponibilidad general del docente (método antiguo)
routerTutorias.get(
  "/ver-disponibilidad-docente/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente", "Administrador"]),
  verDisponibilidadDocente
);

// Bloques ocupados
routerTutorias.get(
  "/tutorias-ocupadas/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente"]),
  bloquesOcupadosDocente
);

// =====================================================
// ✅ DISPONIBILIDAD POR MATERIA (USADO POR FLUTTER)
// =====================================================

// 🎯 MÉTODO 1: Ver disponibilidad de UNA materia específica
// Usado por: HorarioService.obtenerHorariosPorMateria()
// URL Flutter: /ver-disponibilidad-materia/$docenteId/${Uri.encodeComponent(materia)}
routerTutorias.get(
  "/ver-disponibilidad-materia/:docenteId/:materia",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente", "Administrador"]),
  verDisponibilidadPorMateria
);

// 🎯 MÉTODO 2: Actualizar horarios completos de una materia
// Usado por: HorarioService.actualizarHorarios()
// URL Flutter: /tutorias/actualizar-horarios-materia
// Body: { materia, bloques: [{ dia, horaInicio, horaFin }] }
routerTutorias.put(
  "/tutorias/actualizar-horarios-materia",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  actualizarHorarios
);

// 🎯 MÉTODO 3: Ver disponibilidad completa (TODAS las materias)
// Usado por: HorarioService.obtenerDisponibilidadCompleta()
// URL Flutter: /ver-disponibilidad-completa/$docenteId
routerTutorias.get(
  "/ver-disponibilidad-completa/:docenteId",
  verificarTokenJWT,
  verificarRol(["Estudiante", "Docente", "Administrador"]),
  verDisponibilidadCompletaDocente
);

// =====================================================
// ✅ OTRAS OPERACIONES DE DISPONIBILIDAD
// =====================================================

// Registrar/actualizar disponibilidad por materia y día (un día a la vez)
routerTutorias.post(
  "/tutorias/registrar-disponibilidad-materia",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  registrarDisponibilidadPorMateria
);

// Eliminar disponibilidad de materia + día específico
routerTutorias.delete(
  "/eliminar-disponibilidad-materia/:docenteId/:materia/:dia",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  eliminarDisponibilidadMateria
);

// =====================================================
// ✅ VALIDACIONES (OPCIONAL - para validación previa)
// =====================================================

// Validar cruces internos de horarios
routerTutorias.post(
  "/validar-cruces-horarios",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  async (req, res) => {
    try {
      const { bloques } = req.body;

      if (!bloques || !Array.isArray(bloques) || bloques.length === 0) {
        return res.status(400).json({
          success: false,
          msg: "Debes proporcionar un array de bloques"
        });
      }

      const { validarCrucesHorarios } = await import('../controllers/tutorias_controller.js');
      const resultado = validarCrucesHorarios(bloques);

      res.json({
        success: true,
        valido: resultado.valido,
        msg: resultado.valido ? "No hay cruces de horarios" : resultado.mensaje
      });

    } catch (error) {
      console.error("❌ Error validando cruces:", error);
      res.status(500).json({
        success: false,
        msg: "Error al validar horarios",
        error: error.message
      });
    }
  }
);

// Validar cruces entre diferentes materias
routerTutorias.post(
  "/validar-cruces-materias",
  verificarTokenJWT,
  verificarRol(["Docente"]),
  async (req, res) => {
    try {
      const { materia, diaSemana, bloques } = req.body;
      const docente = req.docenteBDD?._id;

      if (!docente) {
        return res.status(401).json({
          success: false,
          msg: "Docente no autenticado"
        });
      }

      if (!materia || !diaSemana || !bloques || !Array.isArray(bloques)) {
        return res.status(400).json({
          success: false,
          msg: "Materia, diaSemana y bloques son obligatorios"
        });
      }

      const { validarCrucesEntreMaterias } = await import('../controllers/tutorias_controller.js');
      const resultado = await validarCrucesEntreMaterias(docente, materia, diaSemana, bloques);

      res.json({
        success: true,
        valido: resultado.valido,
        msg: resultado.valido ? "No hay cruces con otras materias" : resultado.mensaje
      });

    } catch (error) {
      console.error("❌ Error validando cruces entre materias:", error);
      res.status(500).json({
        success: false,
        msg: "Error al validar cruces",
        error: error.message
      });
    }
  }
);

// =====================================================
// ✅ DEBUGGING (OPCIONAL - comentar en producción)
// =====================================================

// Ver todas las disponibilidades del sistema
routerTutorias.get(
  "/admin/todas-disponibilidades",
  verificarTokenJWT,
  verificarRol(["Administrador"]),
  async (req, res) => {
    try {
      const disponibilidadDocente = (await import('../models/disponibilidadDocente.js')).default;
      
      const disponibilidades = await disponibilidadDocente.find({})
        .populate("docente", "nombreDocente emailDocente")
        .sort({ materia: 1, diaSemana: 1 });

      res.json({
        success: true,
        total: disponibilidades.length,
        disponibilidades
      });
    } catch (error) {
      console.error("❌ Error obteniendo disponibilidades:", error);
      res.status(500).json({ 
        success: false,
        msg: "Error al obtener disponibilidades", 
        error: error.message 
      });
    }
  }
);

export default routerTutorias;