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
// ✅ REGISTRAR DISPONIBILIDAD GENERAL
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
// ✅ VER DISPONIBILIDAD GENERAL
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
// ✅ NUEVAS FUNCIONES — DISPONIBILIDAD POR MATERIA
// =====================================================

// ⭐ Registrar disponibilidad por materia
const registrarDisponibilidadPorMateria = async (req, res) => {
  try {
    const { materia, diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !diaSemana || !bloques) {
      return res.status(400).json({ 
        msg: "Materia, día de la semana y bloques son obligatorios" 
      });
    }

    const docenteBDD = await Docente.findById(docente);

    if (!docenteBDD.asignaturas || !docenteBDD.asignaturas.includes(materia)) {
      return res.status(400).json({
        msg: "Esta materia no está asignada a tu perfil"
      });
    }

    let disponibilidad = await disponibilidadDocente.findOne({ 
      docente, 
      diaSemana, 
      materia 
    });

    if (disponibilidad) {
      disponibilidad.bloques = bloques;
    } else {
      disponibilidad = new disponibilidadDocente({ 
        docente, 
        diaSemana, 
        materia,
        bloques 
      });
    }

    await disponibilidad.save();

    res.status(200).json({ 
      msg: "Disponibilidad actualizada con éxito.", 
      disponibilidad 
    });
  } catch (error) {
    console.error("Error en registrarDisponibilidadPorMateria:", error);
    res.status(500).json({ 
      msg: "Error al actualizar disponibilidad", 
      error: error.message 
    });
  }
};

// ⭐ Ver disponibilidad por materia
const verDisponibilidadPorMateria = async (req, res) => {
  try {
    const { docenteId, materia } = req.params;

    const disponibilidad = await disponibilidadDocente.find({ 
      docente: docenteId,
      materia 
    });

    if (!disponibilidad || disponibilidad.length === 0) {
      return res.status(200).json({
        msg: "El docente no tiene disponibilidad registrada para esta materia.",
        disponibilidad: []
      });
    }

    res.status(200).json({ disponibilidad });
  } catch (error) {
    console.error("Error en verDisponibilidadPorMateria:", error);
    res.status(500).json({ 
      msg: "Error al obtener la disponibilidad.", 
      error: error.message 
    });
  }
};

// ⭐ Ver toda la disponibilidad agrupada por materia
const verDisponibilidadCompletaDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    const disponibilidad = await disponibilidadDocente.find({
      docente: docenteId
    }).sort({ materia: 1, diaSemana: 1 });

    if (!disponibilidad || disponibilidad.length === 0) {
      return res.status(200).json({
        msg: "El docente no tiene disponibilidad registrada.",
        disponibilidad: {}
      });
    }

    const porMateria = {};
    disponibilidad.forEach(disp => {
      const mat = disp.materia || 'General';
      if (!porMateria[mat]) porMateria[mat] = [];

      porMateria[mat].push({
        diaSemana: disp.diaSemana,
        bloques: disp.bloques
      });
    });

    res.status(200).json({
      docenteId,
      materias: porMateria
    });

  } catch (error) {
    console.error("Error en verDisponibilidadCompletaDocente:", error);
    res.status(500).json({
      msg: "Error al obtener disponibilidad.",
      error: error.message
    });
  }
};

// ⭐ Eliminar disponibilidad por materia y día
const eliminarDisponibilidadMateria = async (req, res) => {
  try {
    const { docenteId, materia, dia } = req.params;

    if (req.docenteBDD._id.toString() !== docenteId) {
      return res.status(403).json({
        msg: 'No tienes permiso para eliminar esta disponibilidad'
      });
    }

    await disponibilidadDocente.findOneAndDelete({
      docente: docenteId,
      materia,
      diaSemana: dia
    });

    res.status(200).json({
      msg: "Disponibilidad eliminada correctamente"
    });

  } catch (error) {
    console.error("Error en eliminarDisponibilidadMateria:", error);
    res.status(500).json({
      msg: "Error al eliminar disponibilidad",
      error: error.message
    });
  }
};

// =====================================================
// ✅ EXPORTAR TODO
// =====================================================
export {
  registrarTutoria,
  listarTutorias,
  actualizarTutoria,
  cancelarTutoria,
  registrarAsistencia,
  registrarDisponibilidadDocente,
  verDisponibilidadDocente,
  bloquesOcupadosDocente,

  // ✅ Nuevas funciones
  registrarDisponibilidadPorMateria,
  verDisponibilidadPorMateria,
  verDisponibilidadCompletaDocente,
  eliminarDisponibilidadMateria
};
