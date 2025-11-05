// backend/src/controllers/tutorias_controller.js - VERSIÓN COMPLETA
import Tutoria from '../models/tutorias.js';
import disponibilidadDocente from '../models/disponibilidadDocente.js';
import Docente from '../models/docente.js';
import moment from 'moment';

// =====================================================
// ✅ REGISTRAR TUTORIA
// =====================================================
const registrarTutoria = async (req, res) => {
  try {
    const { docente, fecha, horaInicio, horaFin } = req.body;

    // Obtener el ID del estudiante 
    const estudiante = req.estudianteBDD?._id;
    if (!estudiante) {
      return res.status(401).json({ msg: "Estudiante no autenticado" });
    }

    // 1. Verificar si ya existe una tutoría ocupando ese espacio
    const existe = await Tutoria.findOne({
      docente,
      fecha,
      horaInicio,
      horaFin,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          horaInicio: { $lt: horaFin },
          horaFin: { $gt: horaInicio }
        }
      ]
    });

    if (existe) {
      return res.status(400).json({ msg: "Este horario no se encuentra disponible. Elija otro." });
    }

    // 2. Validar que el bloque esté en la disponibilidad del docente
    const fechaUTC = new Date(fecha + 'T05:00:00Z'); // Ecuador
    const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

    const disponibilidad = await disponibilidadDocente.findOne({ docente, diaSemana });
    if (!disponibilidad) {
      return res.status(400).json({ msg: "El docente no tiene disponibilidad registrada para ese día." });
    }

    const bloqueValido = disponibilidad.bloques.some(
      b => b.horaInicio === horaInicio && b.horaFin === horaFin
    );

    if (!bloqueValido) {
      return res.status(400).json({ msg: "Ese bloque no está dentro del horario disponible del docente." });
    }

    // 3. Registrar la tutoría
    const nuevaTutoria = new Tutoria({
      estudiante,
      docente,
      fecha,
      horaInicio,
      horaFin,
      estado: 'pendiente'
    });

    await nuevaTutoria.save();

    const { motivoCancelacion, observacionesDocente, __v, ...tutoria } = nuevaTutoria.toObject();

    res.status(201).json({ msg: "Tutoria registrada con éxito!", nuevaTutoria: tutoria });

  } catch (error) {
    res.status(500).json({ mensaje: 'Error al agendar tutoría.', error });
  }
};

// =====================================================
// ✅ LISTAR TUTORIAS
// =====================================================
const listarTutorias = async (req, res) => {
  try {
    let filtro = {};

    if (req.docenteBDD) {
      filtro.docente = req.docenteBDD._id;
    } else if (req.estudianteBDD) {
      filtro.estudiante = req.estudianteBDD._id;
    }

    const { fecha, estado } = req.query;

    if (fecha) {
      filtro.fecha = fecha;
    } else {
      const inicioSemana = moment().startOf('isoWeek').format("YYYY-MM-DD");
      const finSemana = moment().endOf('isoWeek').format("YYYY-MM-DD");

      filtro.fecha = { $gte: inicioSemana, $lte: finSemana };
    }

    if (estado) filtro.estado = estado;

    const tutorias = await Tutoria.find(filtro)
      .populate("estudiante", "nombreEstudiante")
      .populate("docente", "nombreDocente");

    res.json(tutorias);
  } catch (error) {
    res.status(500).json({ mensaje: "Error al listar tutorías.", error });
  }
};

// =====================================================
// ✅ ACTUALIZAR TUTORIA
// =====================================================
const actualizarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const tutoria = await Tutoria.findById(id);

    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'No se puede modificar una tutoría cancelada.' });
    }

    if (!req.estudianteBDD || tutoria.estudiante.toString() !== req.estudianteBDD._id.toString()) {
      return res.status(403).json({ msg: 'No autorizado para modificar esta tutoría.' });
    }

    Object.assign(tutoria, req.body);
    await tutoria.save();

    res.json(tutoria);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar tutoría.', error });
  }
};

// =====================================================
// ✅ CANCELAR TUTORIA
// =====================================================
const cancelarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { motivo, canceladaPor } = req.body;

    const tutoria = await Tutoria.findById(id);
    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    const hoy = new Date();
    const fechaTutoria = new Date(tutoria.fecha);

    if (fechaTutoria < hoy) {
      return res.status(400).json({ msg: 'No puedes cancelar una tutoría anterior.' });
    }

    tutoria.estado = canceladaPor === 'Estudiante'
      ? 'cancelada_por_estudiante'
      : 'cancelada_por_docente';

    tutoria.motivoCancelacion = motivo;
    tutoria.asistenciaEstudiante = null;
    tutoria.observacionesDocente = null;

    await tutoria.save();

    res.json({ msg: 'Tutoría cancelada correctamente.', tutoria });

  } catch (error) {
    res.status(500).json({ msg: 'Error al cancelar la tutoría.', error });
  }
};

// =====================================================
// ✅ REGISTRAR ASISTENCIA
// =====================================================
const registrarAsistencia = async (req, res) => {
  try {
    const { id } = req.params;
    const { asistio, observaciones } = req.body;

    const tutoria = await Tutoria.findById(id);
    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'No se puede registrar asistencia en una tutoría cancelada.' });
    }

    if (tutoria.asistenciaEstudiante !== null) {
      return res.status(400).json({ msg: 'La asistencia ya fue registrada.' });
    }

    tutoria.asistenciaEstudiante = asistio;
    tutoria.observacionesDocente = observaciones || null;
    tutoria.estado = 'finalizada';

    await tutoria.save();

    res.json({ msg: 'Asistencia registrada exitosamente.', tutoria });
  } catch (error) {
    res.status(500).json({ msg: 'Error al registrar asistencia.', error });
  }
};

// =====================================================
// ✅ REGISTRAR DISPONIBILIDAD GENERAL (LEGACY)
// =====================================================
const registrarDisponibilidadDocente = async (req, res) => {
  try {
    const { diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;
    if (!docente) return res.status(401).json({ msg: "Docente no autenticado" });

    let disponibilidad = await disponibilidadDocente.findOne({ docente, diaSemana });

    if (disponibilidad) {
      disponibilidad.bloques = bloques;
    } else {
      disponibilidad = new disponibilidadDocente({ docente, diaSemana, bloques });
    }

    await disponibilidad.save();
    res.status(200).json({ msg: "Su horario se actualizó con éxito.", disponibilidad });
  } catch (error) {
    res.status(500).json({ msg: "Error al actualizar disponibilidad", error });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD GENERAL (LEGACY)
// =====================================================
const verDisponibilidadDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    const disponibilidad = await disponibilidadDocente.find({ docente: docenteId });

    if (!disponibilidad || disponibilidad.length === 0) {
      return res.status(404).json({ msg: "El docente no tiene disponibilidad registrada." });
    }

    res.status(200).json({ disponibilidad });
  } catch (error) {
    res.status(500).json({ msg: "Error al obtener la disponibilidad.", error });
  }
};

// =====================================================
// ✅ BLOQUES OCUPADOS DOCENTE
// =====================================================
const bloquesOcupadosDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    const inicioSemana = moment().startOf('isoWeek').format("YYYY-MM-DD");
    const finSemana = moment().endOf('isoWeek').format("YYYY-MM-DD");

    const ocupados = await Tutoria.find({
      docente: docenteId,
      fecha: { $gte: inicioSemana, $lte: finSemana },
      estado: { $in: ['pendiente', 'confirmada'] }
    }).select("fecha horaInicio horaFin");

    const resultado = ocupados.map(o => {
      const fechaUTC = new Date(o.fecha + 'T05:00:00Z');
      const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

      return {
        diaSemana,
        fecha: o.fecha,
        horaInicio: o.horaInicio,
        horaFin: o.horaFin
      };
    });

    res.json(resultado);
  } catch (error) {
    res.status(500).json({ msg: "Error al obtener bloques ocupados.", error });
  }
};

// =====================================================
// ✅ REGISTRAR/ACTUALIZAR DISPONIBILIDAD POR MATERIA
// =====================================================
const registrarDisponibilidadPorMateria = async (req, res) => {
  try {
    const { materia, diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    // Validaciones básicas
    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !diaSemana || !bloques || !Array.isArray(bloques)) {
      return res.status(400).json({ 
        msg: "Materia, día de la semana y bloques (array) son obligatorios" 
      });
    }

    // Validar que bloques no esté vacío
    if (bloques.length === 0) {
      return res.status(400).json({
        msg: "Debes agregar al menos un bloque de horario"
      });
    }

    // Normalizar día de la semana
    const diaNormalizado = diaSemana.toLowerCase().trim();
    const diasValidos = ["lunes", "martes", "miércoles", "jueves", "viernes"];
    
    if (!diasValidos.includes(diaNormalizado)) {
      return res.status(400).json({
        msg: "Día de la semana inválido. Debe ser lunes, martes, miércoles, jueves o viernes"
      });
    }

    // ✅ Verificar que la materia pertenece al docente
    const docenteBDD = await Docente.findById(docente);
    
    if (!docenteBDD) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

    // Parsear asignaturas si es string
    let asignaturasDocente = docenteBDD.asignaturas;
    if (typeof asignaturasDocente === 'string') {
      try {
        asignaturasDocente = JSON.parse(asignaturasDocente);
      } catch {
        asignaturasDocente = [];
      }
    }

    if (!asignaturasDocente || !asignaturasDocente.includes(materia)) {
      return res.status(400).json({
        msg: `La materia "${materia}" no está asignada a tu perfil. Primero agrega la materia en "Mis Materias".`
      });
    }

    // ✅ Validar formato de bloques
    for (const bloque of bloques) {
      if (!bloque.horaInicio || !bloque.horaFin) {
        return res.status(400).json({
          msg: "Cada bloque debe tener horaInicio y horaFin"
        });
      }

      // Validar formato HH:MM
      const formatoHora = /^([01]\d|2[0-3]):([0-5]\d)$/;
      if (!formatoHora.test(bloque.horaInicio) || !formatoHora.test(bloque.horaFin)) {
        return res.status(400).json({
          msg: "Formato de hora inválido. Usa HH:MM (ej: 14:00)"
        });
      }

      // Validar que hora fin > hora inicio
      const [hIni, mIni] = bloque.horaInicio.split(':').map(Number);
      const [hFin, mFin] = bloque.horaFin.split(':').map(Number);
      const inicioMinutos = hIni * 60 + mIni;
      const finMinutos = hFin * 60 + mFin;

      if (finMinutos <= inicioMinutos) {
        return res.status(400).json({
          msg: `El bloque ${bloque.horaInicio}-${bloque.horaFin} es inválido: la hora de fin debe ser mayor que la de inicio`
        });
      }
    }

    // ✅ Buscar o crear disponibilidad
    let disponibilidad = await disponibilidadDocente.findOne({ 
      docente, 
      diaSemana: diaNormalizado, 
      materia 
    });

    if (disponibilidad) {
      // Actualizar bloques existentes
      disponibilidad.bloques = bloques.map(b => ({
        horaInicio: b.horaInicio,
        horaFin: b.horaFin
      }));
      
      console.log(`📝 Actualizando disponibilidad: ${materia} - ${diaNormalizado}`);
    } else {
      // Crear nueva disponibilidad
      disponibilidad = new disponibilidadDocente({ 
        docente, 
        diaSemana: diaNormalizado, 
        materia,
        bloques: bloques.map(b => ({
          horaInicio: b.horaInicio,
          horaFin: b.horaFin
        }))
      });
      
      console.log(`✨ Creando nueva disponibilidad: ${materia} - ${diaNormalizado}`);
    }

    await disponibilidad.save();

    console.log(`✅ Disponibilidad guardada exitosamente`);

    res.status(200).json({ 
      success: true,
      msg: "Disponibilidad actualizada con éxito.", 
      disponibilidad: {
        materia: disponibilidad.materia,
        diaSemana: disponibilidad.diaSemana,
        bloques: disponibilidad.bloques,
        id: disponibilidad._id
      }
    });
  } catch (error) {
    console.error("❌ Error en registrarDisponibilidadPorMateria:", error);
    
    // Manejo de error de clave duplicada
    if (error.code === 11000) {
      return res.status(409).json({
        msg: "Ya existe un registro para esta materia y día. Intenta actualizar en lugar de crear uno nuevo."
      });
    }
    
    res.status(500).json({ 
      msg: "Error al actualizar disponibilidad", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD POR MATERIA
// =====================================================
const verDisponibilidadPorMateria = async (req, res) => {
  try {
    const { docenteId, materia } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 Buscando disponibilidad: Docente=${docenteId}, Materia=${materia}`);

    const disponibilidad = await disponibilidadDocente.find({ 
      docente: docenteId,
      materia 
    }).sort({ diaSemana: 1 });

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ No hay disponibilidad para ${materia}`);
      return res.status(200).json({
        msg: "El docente no tiene disponibilidad registrada para esta materia.",
        disponibilidad: []
      });
    }

    console.log(`✅ Disponibilidad encontrada: ${disponibilidad.length} días`);

    res.status(200).json({ 
      success: true,
      disponibilidad: disponibilidad.map(d => ({
        diaSemana: d.diaSemana,
        bloques: d.bloques,
        id: d._id
      }))
    });
  } catch (error) {
    console.error("❌ Error en verDisponibilidadPorMateria:", error);
    res.status(500).json({ 
      msg: "Error al obtener la disponibilidad.", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD COMPLETA (TODAS LAS MATERIAS)
// =====================================================
const verDisponibilidadCompletaDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 Buscando disponibilidad completa del docente: ${docenteId}`);

    const disponibilidad = await disponibilidadDocente.find({
      docente: docenteId
    }).sort({ materia: 1, diaSemana: 1 });

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ No hay disponibilidad registrada`);
      return res.status(200).json({
        success: true,
        msg: "El docente no tiene disponibilidad registrada.",
        docenteId,
        materias: {}
      });
    }

    // Agrupar por materia
    const porMateria = {};
    disponibilidad.forEach(disp => {
      const mat = disp.materia;
      if (!porMateria[mat]) {
        porMateria[mat] = [];
      }

      porMateria[mat].push({
        diaSemana: disp.diaSemana,
        bloques: disp.bloques
      });
    });

    console.log(`✅ Disponibilidad completa: ${Object.keys(porMateria).length} materias`);

    res.status(200).json({
      success: true,
      docenteId,
      materias: porMateria
    });

  } catch (error) {
    console.error("❌ Error en verDisponibilidadCompletaDocente:", error);
    res.status(500).json({
      msg: "Error al obtener disponibilidad.",
      error: error.message
    });
  }
};

// =====================================================
// ✅ ELIMINAR DISPONIBILIDAD POR MATERIA Y DÍA
// =====================================================
const eliminarDisponibilidadMateria = async (req, res) => {
  try {
    const { docenteId, materia, dia } = req.params;

    // Solo el docente puede eliminar su propia disponibilidad
    if (req.docenteBDD._id.toString() !== docenteId) {
      return res.status(403).json({
        msg: 'No tienes permiso para eliminar esta disponibilidad'
      });
    }

    const diaNormalizado = dia.toLowerCase().trim();

    const resultado = await disponibilidadDocente.findOneAndDelete({
      docente: docenteId,
      materia,
      diaSemana: diaNormalizado
    });

    if (!resultado) {
      return res.status(404).json({
        msg: "No se encontró disponibilidad para eliminar"
      });
    }

    console.log(`🗑️ Disponibilidad eliminada: ${materia} - ${diaNormalizado}`);

    res.status(200).json({
      success: true,
      msg: "Disponibilidad eliminada correctamente"
    });

  } catch (error) {
    console.error("❌ Error en eliminarDisponibilidadMateria:", error);
    res.status(500).json({
      msg: "Error al eliminar disponibilidad",
      error: error.message
    });
  }
};

// =====================================================
// ✅ EXPORTAR TODAS LAS FUNCIONES
// =====================================================
export {
  // Tutorías
  registrarTutoria,
  listarTutorias,
  actualizarTutoria,
  cancelarTutoria,
  registrarAsistencia,
  
  // Disponibilidad general (legacy)
  registrarDisponibilidadDocente,
  verDisponibilidadDocente,
  bloquesOcupadosDocente,

  // Disponibilidad por materia (nuevo)
  registrarDisponibilidadPorMateria,
  verDisponibilidadPorMateria,
  verDisponibilidadCompletaDocente,
  eliminarDisponibilidadMateria
};