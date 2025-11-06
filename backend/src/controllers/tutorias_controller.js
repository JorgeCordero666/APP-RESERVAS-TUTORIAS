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
// ✅ LISTAR TUTORIAS - CORREGIDO (línea ~50)
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

    // ✅ NUEVO: Excluir tutorías canceladas por defecto
    if (estado) {
      filtro.estado = estado;
    } else {
      // Si no se especifica estado, mostrar solo activas
      filtro.estado = { $nin: ['cancelada_por_estudiante', 'cancelada_por_docente'] };
    }

    const tutorias = await Tutoria.find(filtro)
      .populate("estudiante", "nombreEstudiante")
      .populate("docente", "nombreDocente")
      .sort({ fecha: 1, horaInicio: 1 }); // Ordenar por fecha y hora

    console.log(`📋 Tutorías encontradas: ${tutorias.length}`);

    res.json({
      total: tutorias.length,
      tutorias
    });
  } catch (error) {
    console.error("Error al listar tutorías:", error);
    res.status(500).json({ mensaje: "Error al listar tutorías.", error: error.message });
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
// ✅ CANCELAR TUTORIA - CORREGIDO (línea ~110)
// =====================================================
const cancelarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { motivo, canceladaPor } = req.body;

    console.log(`🗑️ Intentando cancelar tutoría: ${id}`);
    console.log(`   Cancelada por: ${canceladaPor}`);

    const tutoria = await Tutoria.findById(id);
    if (!tutoria) {
      return res.status(404).json({ msg: 'Tutoría no encontrada.' });
    }

    // Validar que no esté ya cancelada
    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'Esta tutoría ya fue cancelada.' });
    }

    const hoy = new Date();
    const fechaTutoria = new Date(tutoria.fecha);

    if (fechaTutoria < hoy) {
      return res.status(400).json({ msg: 'No puedes cancelar una tutoría pasada.' });
    }

    // Determinar el estado correcto
    if (canceladaPor === 'Estudiante') {
      tutoria.estado = 'cancelada_por_estudiante';
    } else if (canceladaPor === 'Docente') {
      tutoria.estado = 'cancelada_por_docente';
    } else {
      return res.status(400).json({ msg: 'Valor de canceladaPor inválido.' });
    }

    tutoria.motivoCancelacion = motivo || 'Sin motivo especificado';
    tutoria.asistenciaEstudiante = null;
    tutoria.observacionesDocente = null;

    await tutoria.save();

    console.log(`✅ Tutoría cancelada: ${tutoria._id}`);
    console.log(`   Nuevo estado: ${tutoria.estado}`);

    res.json({ 
      msg: 'Tutoría cancelada correctamente.', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        motivoCancelacion: tutoria.motivoCancelacion
      }
    });

  } catch (error) {
    console.error("Error al cancelar tutoría:", error);
    res.status(500).json({ msg: 'Error al cancelar la tutoría.', error: error.message });
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
// ✅ REGISTRAR/ACTUALIZAR DISPONIBILIDAD POR MATERIA  ✅ MODIFICADA
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

    // ✅ VALIDACIÓN SIMPLIFICADA — YA NO SE VERIFICA SI LA MATERIA PERTENECE AL DOCENTE

    // ❌ COMENTADO EL BLOQUE ANTERIOR
    /*
    // ✅ Verificar que la materia pertenece al docente
    const docenteBDD = await Docente.findById(docente);
    
    if (!docenteBDD) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

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
    */

    // ✅ Nueva validación simple
    const docenteBDD = await Docente.findById(docente);

    if (!docenteBDD) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

    // Permitir registrar disponibilidad para cualquier materia
    console.log(`📚 Registrando disponibilidad de ${docenteBDD.nombreDocente} para ${materia}`);


    // ✅ Validar formato de bloques
    for (const bloque of bloques) {
      if (!bloque.horaInicio || !bloque.horaFin) {
        return res.status(400).json({
          msg: "Cada bloque debe tener horaInicio y horaFin"
        });
      }

      const formatoHora = /^([01]\d|2[0-3]):([0-5]\d)$/;
      if (!formatoHora.test(bloque.horaInicio) || !formatoHora.test(bloque.horaFin)) {
        return res.status(400).json({
          msg: "Formato de hora inválido. Usa HH:MM (ej: 14:00)"
        });
      }

      const [hIni, mIni] = bloque.horaInicio.split(':').map(Number);
      const [hFin, mFin] = bloque.horaFin.split(':').map(Number);
      const inicioMin = hIni * 60 + mIni;
      const finMin = hFin * 60 + mFin;

      if (finMin <= inicioMin) {
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
// ✅ VER DISPONIBILIDAD POR MATERIA - CORREGIDA
// =====================================================
const verDisponibilidadPorMateria = async (req, res) => {
  try {
    const { docenteId, materia } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 [Backend] Buscando disponibilidad:`);
    console.log(`   Docente ID: ${docenteId}`);
    console.log(`   Materia: ${materia}`);

    const disponibilidad = await disponibilidadDocente.find({ 
      docente: docenteId,
      materia 
    }).sort({ diaSemana: 1 });

    console.log(`📊 [Backend] Resultados encontrados: ${disponibilidad.length}`);
    
    if (disponibilidad.length > 0) {
      console.log(`📋 [Backend] Disponibilidad por día:`);
      disponibilidad.forEach(d => {
        console.log(`   - ${d.diaSemana}: ${d.bloques.length} bloques`);
        d.bloques.forEach(b => {
          console.log(`     ${b.horaInicio}-${b.horaFin}`);
        });
      });
    }

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ [Backend] No hay disponibilidad para ${materia}`);
      return res.status(200).json({
        success: true,
        msg: "El docente no tiene disponibilidad registrada para esta materia.",
        disponibilidad: []
      });
    }

    // ✅ CLAVE: Devolver en formato consistente
    const resultado = disponibilidad.map(d => ({
      diaSemana: d.diaSemana,
      bloques: d.bloques.map(b => ({
        horaInicio: b.horaInicio,
        horaFin: b.horaFin
      })),
      _id: d._id
    }));

    console.log(`✅ [Backend] Enviando respuesta con ${resultado.length} días`);

    res.status(200).json({ 
      success: true,
      disponibilidad: resultado
    });
  } catch (error) {
    console.error("❌ [Backend] Error en verDisponibilidadPorMateria:", error);
    res.status(500).json({ 
      msg: "Error al obtener la disponibilidad.", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD COMPLETA (TODAS LAS MATERIAS) - CORREGIDA
// =====================================================
const verDisponibilidadCompletaDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 [Backend] Buscando disponibilidad completa del docente: ${docenteId}`);

    const disponibilidad = await disponibilidadDocente.find({
      docente: docenteId
    }).sort({ materia: 1, diaSemana: 1 });

    console.log(`📊 [Backend] Registros encontrados: ${disponibilidad.length}`);

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ [Backend] No hay disponibilidad registrada`);
      return res.status(200).json({
        success: true,
        msg: "El docente no tiene disponibilidad registrada.",
        docenteId,
        materias: {}
      });
    }

    // ✅ ESTRUCTURA CORREGIDA: Agrupar por materia
    const porMateria = {};
    
    disponibilidad.forEach(disp => {
      const mat = disp.materia;
      
      if (!porMateria[mat]) {
        porMateria[mat] = [];
      }

      // ✅ CLAVE: Agregar cada DÍA como un objeto separado
      porMateria[mat].push({
        diaSemana: disp.diaSemana,
        bloques: disp.bloques.map(b => ({
          horaInicio: b.horaInicio,
          horaFin: b.horaFin
        }))
      });
    });

    console.log(`✅ [Backend] Disponibilidad agrupada:`);
    Object.keys(porMateria).forEach(mat => {
      console.log(`   📚 ${mat}: ${porMateria[mat].length} días`);
      porMateria[mat].forEach(dia => {
        console.log(`      - ${dia.diaSemana}: ${dia.bloques.length} bloques`);
        dia.bloques.forEach(b => {
          console.log(`        ${b.horaInicio}-${b.horaFin}`);
        });
      });
    });

    res.status(200).json({
      success: true,
      docenteId,
      materias: porMateria
    });

  } catch (error) {
    console.error("❌ [Backend] Error en verDisponibilidadCompletaDocente:", error);
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

    console.log('🗑️ Solicitud de eliminación:');
    console.log('   Docente:', docenteId);
    console.log('   Materia:', materia);
    console.log('   Día:', dia);

    // Validar que el docente autenticado es el mismo
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
      console.log('ℹ️ No se encontró disponibilidad para eliminar');
      // ✅ NO ES ERROR - puede no existir
      return res.status(200).json({
        success: true,
        msg: "No había disponibilidad para eliminar"
      });
    }

    console.log(`✅ Eliminado: ${materia} - ${diaNormalizado}`);

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