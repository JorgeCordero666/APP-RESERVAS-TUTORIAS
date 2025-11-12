// backend/src/controllers/tutorias_controller.js - VERSIÓN COMPLETA
import Tutoria from '../models/tutorias.js';
import disponibilidadDocente from '../models/disponibilidadDocente.js';
import Docente from '../models/docente.js';
import moment from 'moment';

// =====================================================
// ✅ REGISTRAR TUTORIA
// =====================================================
// backend/src/controllers/tutorias_controller.js

const registrarTutoria = async (req, res) => {
  try {
    const { docente, fecha, horaInicio, horaFin } = req.body;
    const estudiante = req.estudianteBDD?._id;

    if (!estudiante) {
      return res.status(401).json({ msg: "Estudiante no autenticado" });
    }

    // ✅ VALIDACIÓN 1: Verificar que no exista tutoría en ese horario
    const tutoriaExistente = await Tutoria.findOne({
      docente,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lte: horaInicio } },
            { horaFin: { $gt: horaInicio } }
          ]
        },
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gte: horaFin } }
          ]
        },
        {
          $and: [
            { horaInicio: { $gte: horaInicio } },
            { horaFin: { $lte: horaFin } }
          ]
        }
      ]
    });

    if (tutoriaExistente) {
      return res.status(400).json({ 
        msg: "Este horario ya está ocupado. Por favor, elige otro." 
      });
    }

    // ✅ VALIDACIÓN 2: Verificar que el bloque esté en la disponibilidad del docente
    const fechaUTC = new Date(fecha + 'T05:00:00Z');
    const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

    const disponibilidad = await disponibilidadDocente.findOne({ 
      docente, 
      diaSemana 
    });

    if (!disponibilidad) {
      return res.status(400).json({ 
        msg: "El docente no tiene disponibilidad registrada para ese día." 
      });
    }

    const bloqueValido = disponibilidad.bloques.some(
      b => b.horaInicio === horaInicio && b.horaFin === horaFin
    );

    if (!bloqueValido) {
      return res.status(400).json({ 
        msg: "Ese bloque no está en el horario disponible del docente." 
      });
    }

    // ✅ VALIDACIÓN 3: No permitir agendar en el pasado
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
      return res.status(400).json({ 
        msg: "No puedes agendar tutorías en fechas pasadas." 
      });
    }

    // ✅ VALIDACIÓN 4: Verificar que el estudiante no tenga otra tutoría a la misma hora
    const tutoriaEstudianteExistente = await Tutoria.findOne({
      estudiante,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lte: horaInicio } },
            { horaFin: { $gt: horaInicio } }
          ]
        },
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gte: horaFin } }
          ]
        }
      ]
    });

    if (tutoriaEstudianteExistente) {
      return res.status(400).json({ 
        msg: "Ya tienes una tutoría agendada en ese horario." 
      });
    }

    // ✅ REGISTRAR TUTORÍA
    const nuevaTutoria = new Tutoria({
      estudiante,
      docente,
      fecha,
      horaInicio,
      horaFin,
      estado: 'pendiente'
    });

    await nuevaTutoria.save();

    // Poblar datos para respuesta
    await nuevaTutoria.populate('docente', 'nombreDocente emailDocente avatarDocente');
    await nuevaTutoria.populate('estudiante', 'nombreEstudiante emailEstudiante fotoPerfil');

    console.log(`✅ Tutoría registrada: ${nuevaTutoria._id}`);

    res.status(201).json({ 
      success: true,
      msg: "Solicitud de tutoría enviada correctamente. El docente la revisará pronto.",
      tutoria: nuevaTutoria
    });

  } catch (error) {
    console.error("❌ Error registrando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al agendar tutoría.', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ LISTAR TUTORIAS
// =====================================================
// backend/src/controllers/tutorias_controller.js

const listarTutorias = async (req, res) => {
  try {
    let filtro = {};

    // Filtrar por rol (docente o estudiante autenticado)
    if (req.docenteBDD) {
      filtro.docente = req.docenteBDD._id;
    } else if (req.estudianteBDD) {
      filtro.estudiante = req.estudianteBDD._id;
    }

    // Extraer parámetros de consulta
    const { fecha, estado, incluirCanceladas, soloSemanaActual } = req.query;

    console.log('📋 [listarTutorias] Parámetros:', { 
      fecha, 
      estado, 
      incluirCanceladas, 
      soloSemanaActual,
      usuario: req.estudianteBDD?._id || req.docenteBDD?._id
    });

    // ✅ CORRECCIÓN: Solo filtrar por semana si se solicita explícitamente
    if (soloSemanaActual === 'true') {
      const inicioSemana = moment().startOf('isoWeek').format("YYYY-MM-DD");
      const finSemana = moment().endOf('isoWeek').format("YYYY-MM-DD");
      filtro.fecha = { $gte: inicioSemana, $lte: finSemana };
      console.log('📅 Filtrando por semana actual:', { inicioSemana, finSemana });
    } else if (fecha) {
      // Filtrar por fecha específica
      filtro.fecha = fecha;
      console.log('📅 Filtrando por fecha específica:', fecha);
    }
    // ✅ Si no se especifica, traer TODAS las fechas

    // Filtrar por estado específico
    if (estado) {
      filtro.estado = estado;
      console.log('🏷️ Filtrando por estado:', estado);
    } else {
      // ✅ Excluir canceladas por defecto (a menos que se pidan explícitamente)
      if (incluirCanceladas !== 'true') {
        filtro.estado = { 
          $nin: ['cancelada_por_estudiante', 'cancelada_por_docente'] 
        };
        console.log('🚫 Excluyendo canceladas');
      } else {
        console.log('✅ Incluyendo todas (incluso canceladas)');
      }
    }

    console.log('🔍 Filtro final:', JSON.stringify(filtro, null, 2));

    // Buscar tutorías con populate
    const tutorias = await Tutoria.find(filtro)
      .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
      .populate("docente", "nombreDocente emailDocente avatarDocente oficinaDocente")
      .sort({ fecha: -1, horaInicio: 1 }); // ✅ Ordenar por fecha DESC, hora ASC

    console.log(`✅ Tutorías encontradas: ${tutorias.length}`);

    // Log detallado para debugging
    if (tutorias.length > 0) {
      console.log('📊 Estados encontrados:', 
        tutorias.reduce((acc, t) => {
          acc[t.estado] = (acc[t.estado] || 0) + 1;
          return acc;
        }, {})
      );
    }

    res.status(200).json({
      success: true,
      total: tutorias.length,
      tutorias
    });
  } catch (error) {
    console.error("❌ Error al listar tutorías:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al listar tutorías.", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ ACTUALIZAR TUTORIA
// =====================================================
const actualizarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { fecha, horaInicio, horaFin } = req.body;
    
    const tutoria = await Tutoria.findById(id);

    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'No se puede modificar una tutoría cancelada.' });
    }

    if (!req.estudianteBDD || tutoria.estudiante.toString() !== req.estudianteBDD._id.toString()) {
      return res.status(403).json({ msg: 'No autorizado para modificar esta tutoría.' });
    }

    // ✅ Validar que la fecha no sea pasada
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(fecha || tutoria.fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
      return res.status(400).json({ msg: 'No puedes modificar una tutoría pasada.' });
    }

    // ✅ Solo actualizar campos permitidos
    if (fecha) tutoria.fecha = fecha;
    if (horaInicio) tutoria.horaInicio = horaInicio;
    if (horaFin) tutoria.horaFin = horaFin;

    await tutoria.save();

    res.json({ success: true, tutoria });
  } catch (error) {
    console.error("❌ Error actualizando tutoría:", error);
    res.status(500).json({ mensaje: 'Error al actualizar tutoría.', error: error.message });
  }
};

// =====================================================
// ✅ CANCELAR TUTORIA
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

    // ✅ Validar fecha correctamente (comparar sin hora)
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(tutoria.fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
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

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría cancelada correctamente.', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        motivoCancelacion: tutoria.motivoCancelacion
      }
    });

  } catch (error) {
    console.error("❌ Error al cancelar tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al cancelar la tutoría.', 
      error: error.message 
    });
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
/**
 * ✅ VALIDAR CRUCES DE HORARIOS
 * Verifica que no haya solapamiento entre bloques del mismo día
 */
const validarCrucesHorarios = (bloques) => {
  // Convertir hora a minutos
  const convertirAMinutos = (hora) => {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  };

  // Ordenar por hora de inicio
  const bloquesOrdenados = bloques
    .map(b => ({
      inicio: convertirAMinutos(b.horaInicio),
      fin: convertirAMinutos(b.horaFin),
      horaInicio: b.horaInicio,
      horaFin: b.horaFin
    }))
    .sort((a, b) => a.inicio - b.inicio);

  // Verificar solapamientos consecutivos
  for (let i = 0; i < bloquesOrdenados.length - 1; i++) {
    const bloqueActual = bloquesOrdenados[i];
    const bloqueSiguiente = bloquesOrdenados[i + 1];

    if (bloqueActual.fin > bloqueSiguiente.inicio) {
      return {
        valido: false,
        mensaje: `Cruce detectado: ${bloqueActual.horaInicio}-${bloqueActual.horaFin} se solapa con ${bloqueSiguiente.horaInicio}-${bloqueSiguiente.horaFin}`
      };
    }
  }

  return { valido: true };
};
/**
 * ✅ VALIDACIÓN 2: Cruces locales POR DÍA
 * CAMBIO CRÍTICO: Agrupa por día ANTES de validar
 */
const validarCrucesLocales = ({ bloques }) => {
  console.log('🔍 Validación local de cruces');
  
  // ✅ PASO 1: Agrupar bloques POR DÍA
  const bloquesPorDia = {};
  
  for (const bloque of bloques) {
    const dia = bloque.dia.toString().toLowerCase();
    
    if (!bloquesPorDia[dia]) {
      bloquesPorDia[dia] = [];
    }
    
    bloquesPorDia[dia].push(bloque);
  }
  
  console.log(`   Días a validar: ${Object.keys(bloquesPorDia).join(', ')}`);
  
  // ✅ PASO 2: Validar cruces DENTRO de cada día
  for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
    console.log(`   Validando ${dia}: ${bloquesDelDia.length} bloques`);
    
    // Ordenar por hora de inicio
    bloquesDelDia.sort((a, b) => {
      const aInicio = _convertirAMinutos(a.horaInicio);
      const bInicio = _convertirAMinutos(b.horaInicio);
      return aInicio - bInicio;
    });
    
    // Verificar solapamientos entre bloques consecutivos
    for (let i = 0; i < bloquesDelDia.length - 1; i++) {
      const bloqueActual = bloquesDelDia[i];
      const bloqueSiguiente = bloquesDelDia[i + 1];
      
      const finActual = _convertirAMinutos(bloqueActual.horaFin);
      const inicioSiguiente = _convertirAMinutos(bloqueSiguiente.horaInicio);
      
      if (finActual > inicioSiguiente) {
        return {
          valido: false,
          mensaje: `Cruce en ${dia}: ${bloqueActual.horaInicio}-${bloqueActual.horaFin} se solapa con ${bloqueSiguiente.horaInicio}-${bloqueSiguiente.horaFin}`
        };
      }
    }
  }
  
  console.log('   ✅ Sin cruces locales');
  return { valido: true };
};

/**
 * ✅ VALIDAR CRUCES ENTRE MATERIAS (CORREGIDO - SOLO MISMO DÍA)
 * Verifica que no haya cruces entre diferentes materias DEL MISMO DÍA
 */
const validarCrucesEntreMaterias = async (docenteId, materia, diaSemana, bloquesNuevos) => {
  try {
    console.log('🔍 Validando cruces entre materias:');
    console.log('   Docente:', docenteId);
    console.log('   Materia actual:', materia);
    console.log('   Día:', diaSemana);
    console.log('   Bloques nuevos:', bloquesNuevos.length);

    // Normalizar día
    let diaNormalizado = diaSemana
      .toLowerCase()
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');

    const mapaValidos = {
      'lunes': 'lunes',
      'martes': 'martes',
      'miercoles': 'miércoles',
      'miércoles': 'miércoles',
      'jueves': 'jueves',
      'viernes': 'viernes'
    };
    
    diaNormalizado = mapaValidos[diaNormalizado] || diaNormalizado;
    console.log(`   Día normalizado: "${diaNormalizado}"`);

    // ✅ BUSCAR SOLO BLOQUES DEL MISMO DÍA Y OTRAS MATERIAS
    const disponibilidadesExistentes = await disponibilidadDocente.find({
      docente: docenteId,
      diaSemana: diaNormalizado,
      materia: { $ne: materia }
    });

    console.log(`   Disponibilidades en "${diaNormalizado}":`, disponibilidadesExistentes.length);

    if (disponibilidadesExistentes.length === 0) {
      console.log('   ✅ No hay otras materias en este día');
      return { valido: true };
    }

    // Recopilar bloques existentes
    const bloquesExistentes = [];
    disponibilidadesExistentes.forEach(disp => {
      console.log(`   📚 Materia existente: ${disp.materia} (${disp.bloques.length} bloques)`);
      disp.bloques.forEach(b => {
        bloquesExistentes.push({
          materia: disp.materia,
          horaInicio: b.horaInicio,
          horaFin: b.horaFin
        });
      });
    });

    // Verificar solapamientos
    for (const bloqueNuevo of bloquesNuevos) {
      const nuevoInicio = _convertirAMinutos(bloqueNuevo.horaInicio);
      const nuevoFin = _convertirAMinutos(bloqueNuevo.horaFin);

      for (const bloqueExistente of bloquesExistentes) {
        const existenteInicio = _convertirAMinutos(bloqueExistente.horaInicio);
        const existenteFin = _convertirAMinutos(bloqueExistente.horaFin);

        const haySolapamiento = 
          (nuevoInicio < existenteFin && nuevoFin > existenteInicio);

        if (haySolapamiento) {
          const mensaje = `El bloque ${bloqueNuevo.horaInicio}-${bloqueNuevo.horaFin} de "${materia}" ` +
                         `se cruza con ${bloqueExistente.horaInicio}-${bloqueExistente.horaFin} de "${bloqueExistente.materia}" ` +
                         `el día ${diaSemana}`;
          
          console.log(`   ❌ CRUCE DETECTADO: ${mensaje}`);
          return { valido: false, mensaje };
        }
      }
    }

    console.log('   ✅ No se detectaron cruces');
    return { valido: true };
    
  } catch (error) {
    console.error('❌ Error validando cruces entre materias:', error);
    return { 
      valido: false, 
      mensaje: 'Error al validar cruces de horarios' 
    };
  }
};

/**
 * ✅ FUNCIÓN AUXILIAR: Convertir hora a minutos
 */
const _convertirAMinutos = (hora) => {
  try {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  } catch (e) {
    console.log('⚠️ Error convirtiendo hora:', hora);
    return 0;
  }
};

/**
 * ✅ FUNCIÓN AUXILIAR: Agrupar bloques por día
 */
const _agruparPorDia = (bloques) => {
  const resultado = {};
  
  for (const bloque of bloques) {
    const dia = bloque.dia.toString().toLowerCase();
    
    if (!resultado[dia]) {
      resultado[dia] = [];
    }
    
    resultado[dia].push({
      horaInicio: bloque.horaInicio,
      horaFin: bloque.horaFin
    });
  }
  
  return resultado;
};
// =====================================================
// ✅ REGISTRAR/ACTUALIZAR DISPONIBILIDAD POR MATERIA
// =====================================================
const registrarDisponibilidadPorMateria = async (req, res) => {
  try {
    const { materia, diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    // ✅ Validaciones básicas
    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !diaSemana || !bloques || !Array.isArray(bloques)) {
      return res.status(400).json({
        msg: "Materia, día de la semana y bloques (array) son obligatorios"
      });
    }

    if (bloques.length === 0) {
      return res.status(400).json({
        msg: "Debes agregar al menos un bloque de horario"
      });
    }

    // ✅ Normalizar día
    const diaNormalizado = diaSemana.toLowerCase().trim();
    const diasValidos = ["lunes", "martes", "miércoles", "jueves", "viernes"];
    if (!diasValidos.includes(diaNormalizado)) {
      return res.status(400).json({
        msg: "Día inválido. Usa lunes, martes, miércoles, jueves o viernes"
      });
    }

    // ✅ Verificar que la materia pertenece al docente
    const docenteBDD = await Docente.findById(docente);
    if (!docenteBDD) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

    let asignaturasDocente = docenteBDD.asignaturas;
    if (typeof asignaturasDocente === "string") {
      try {
        asignaturasDocente = JSON.parse(asignaturasDocente);
      } catch {
        asignaturasDocente = [];
      }
    }

    if (!asignaturasDocente.includes(materia)) {
      return res.status(400).json({
        msg: `La materia "${materia}" no está asignada a tu perfil. Primero agrega la materia en "Mis Materias".`
      });
    }

    // ✅ Validar formato y coherencia de bloques
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

      const [hIni, mIni] = bloque.horaInicio.split(":").map(Number);
      const [hFin, mFin] = bloque.horaFin.split(":").map(Number);
      const inicioMinutos = hIni * 60 + mIni;
      const finMinutos = hFin * 60 + mFin;

      if (finMinutos <= inicioMinutos) {
        return res.status(400).json({
          msg: `El bloque ${bloque.horaInicio}-${bloque.horaFin} es inválido: la hora de fin debe ser mayor que la de inicio`
        });
      }
    }

    // ✅ NUEVA VALIDACIÓN 1: Cruces dentro de la misma materia
    const validacionInterna = validarCrucesHorarios(bloques);
    if (!validacionInterna.valido) {
      return res.status(400).json({
        msg: validacionInterna.mensaje
      });
    }

    // ✅ NUEVA VALIDACIÓN 2: Cruces entre diferentes materias del mismo docente
    const validacionEntreMaterias = await validarCrucesEntreMaterias(
      docente,
      materia,
      diaNormalizado,
      bloques
    );

    if (!validacionEntreMaterias.valido) {
      return res.status(400).json({
        msg: validacionEntreMaterias.mensaje
      });
    }

    // ✅ Buscar o crear disponibilidad
    let disponibilidad = await disponibilidadDocente.findOne({
      docente,
      diaSemana: diaNormalizado,
      materia
    });

    if (disponibilidad) {
      disponibilidad.bloques = bloques.map(b => ({
        horaInicio: b.horaInicio,
        horaFin: b.horaFin
      }));

      console.log(`📝 Actualizando disponibilidad: ${materia} - ${diaNormalizado}`);
    } else {
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

/**
 * ✅ ACTUALIZAR HORARIOS CON VALIDACIÓN COMPLETA (CORREGIDO)
 * Permite horarios iguales en días diferentes, solo valida cruces en el mismo día
 */
const actualizarHorarios = async (req, res) => {
  try {
    const { materia, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    // Validaciones básicas
    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !bloques || !Array.isArray(bloques)) {
      return res.status(400).json({ 
        msg: "Materia y bloques (array) son obligatorios" 
      });
    }

    if (bloques.length === 0) {
      return res.status(400).json({
        msg: "Debes agregar al menos un bloque de horario"
      });
    }

    console.log(`🔄 Actualizando horarios completos de: ${materia}`);
    console.log(`   Bloques recibidos: ${bloques.length}`);

    // ✅ PASO 1: AGRUPAR BLOQUES POR DÍA
    const bloquesPorDia = {};
    
    for (const bloque of bloques) {
      const dia = bloque.dia.toLowerCase().trim();
      
      if (!bloquesPorDia[dia]) {
        bloquesPorDia[dia] = [];
      }
      
      bloquesPorDia[dia].push({
        horaInicio: bloque.horaInicio,
        horaFin: bloque.horaFin
      });
    }

    console.log(`📋 Días a guardar: ${Object.keys(bloquesPorDia).join(', ')}`);

    // ✅ PASO 2: VALIDAR CRUCES INTERNOS POR DÍA
    // (Esto valida cruces dentro de la misma materia en el mismo día)
    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      console.log(`   Validando cruces internos en ${dia}...`);
      const validacion = validarCrucesHorarios(bloquesDelDia);
      if (!validacion.valido) {
        return res.status(400).json({
          msg: `Error en ${dia}: ${validacion.mensaje}`
        });
      }
    }
    console.log('   ✅ Sin cruces internos');

    // ✅ PASO 3: VALIDAR CRUCES ENTRE MATERIAS (SOLO POR DÍA)
    // IMPORTANTE: Cada día se valida independientemente
    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      console.log(`   Validando cruces con otras materias en ${dia}...`);
      
      // ✅ CLAVE: Solo validamos los bloques de ESE día específico
      const validacion = await validarCrucesEntreMaterias(
        docente,
        materia,
        dia, // ✅ Solo valida contra bloques del mismo día
        bloquesDelDia
      );

      if (!validacion.valido) {
        return res.status(400).json({
          msg: validacion.mensaje
        });
      }
    }
    console.log('   ✅ Sin cruces con otras materias');

    // ✅ PASO 4: ELIMINAR FÍSICAMENTE TODOS LOS REGISTROS ANTERIORES DE ESTA MATERIA
    const eliminados = await disponibilidadDocente.deleteMany({
      docente: docente,
      materia: materia
    });

    console.log(`🗑️ Registros eliminados: ${eliminados.deletedCount}`);

    // ✅ PASO 5: CREAR NUEVOS REGISTROS (UN DOCUMENTO POR DÍA)
    const registrosCreados = [];

    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      const nuevoRegistro = new disponibilidadDocente({
        docente: docente,
        diaSemana: dia,
        materia: materia,
        bloques: bloquesDelDia
      });

      await nuevoRegistro.save();
      registrosCreados.push(nuevoRegistro);
      
      console.log(`✅ Creado: ${dia} con ${bloquesDelDia.length} bloques`);
    }

    console.log(`✅ Total registros creados: ${registrosCreados.length}`);

    res.status(200).json({
      success: true,
      msg: "Horarios actualizados correctamente",
      registrosEliminados: eliminados.deletedCount,
      registrosCreados: registrosCreados.length,
      disponibilidad: registrosCreados.map(r => ({
        dia: r.diaSemana,
        bloques: r.bloques
      }))
    });

  } catch (error) {
    console.error('❌ Error actualizando horarios:', error);
    res.status(500).json({
      msg: "Error al actualizar horarios",
      error: error.message
    });
  }
};

// =====================================================
// ✅ ACEPTAR SOLICITUD DE TUTORÍA (DOCENTE)
// =====================================================
export const aceptarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutoria = await Tutoria.findById(id);

    if (!tutoria) {
      return res.status(404).json({ 
        success: false,
        msg: 'Tutoría no encontrada' 
      });
    }

    // Verificar que sea el docente correcto
    if (tutoria.docente.toString() !== docente.toString()) {
      return res.status(403).json({ 
        success: false,
        msg: 'No tienes permiso para gestionar esta tutoría' 
      });
    }

    // Validar estado actual
    if (tutoria.estado !== 'pendiente') {
      return res.status(400).json({ 
        success: false,
        msg: `Esta tutoría ya fue ${tutoria.estado}` 
      });
    }

    // Actualizar estado
    tutoria.estado = 'confirmada';
    await tutoria.save();

    console.log(`✅ Tutoría aceptada: ${tutoria._id}`);

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría aceptada exitosamente', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        estudiante: tutoria.estudiante,
        fecha: tutoria.fecha,
        horaInicio: tutoria.horaInicio,
        horaFin: tutoria.horaFin
      }
    });

  } catch (error) {
    console.error("❌ Error aceptando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al aceptar la tutoría', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ RECHAZAR SOLICITUD DE TUTORÍA (DOCENTE)
// =====================================================
export const rechazarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { motivoRechazo } = req.body;
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutoria = await Tutoria.findById(id);

    if (!tutoria) {
      return res.status(404).json({ 
        success: false,
        msg: 'Tutoría no encontrada' 
      });
    }

    // Verificar que sea el docente correcto
    if (tutoria.docente.toString() !== docente.toString()) {
      return res.status(403).json({ 
        success: false,
        msg: 'No tienes permiso para gestionar esta tutoría' 
      });
    }

    // Validar estado actual
    if (tutoria.estado !== 'pendiente') {
      return res.status(400).json({ 
        success: false,
        msg: `Esta tutoría ya fue ${tutoria.estado}` 
      });
    }

    // Actualizar estado
    tutoria.estado = 'rechazada';
    tutoria.motivoRechazo = motivoRechazo || 'Sin motivo especificado';
    await tutoria.save();

    console.log(`❌ Tutoría rechazada: ${tutoria._id}`);

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría rechazada', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        motivoRechazo: tutoria.motivoRechazo
      }
    });

  } catch (error) {
    console.error("❌ Error rechazando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al rechazar la tutoría', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ LISTAR TUTORÍAS PENDIENTES (SOLO DOCENTE)
// =====================================================
export const listarTutoriasPendientes = async (req, res) => {
  try {
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutorias = await Tutoria.find({
      docente: docente,
      estado: 'pendiente'
    })
    .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
    .sort({ fecha: 1, horaInicio: 1 });

    console.log(`📋 Tutorías pendientes: ${tutorias.length}`);

    res.status(200).json({
      success: true,
      total: tutorias.length,
      tutorias
    });

  } catch (error) {
    console.error("❌ Error listando tutorías pendientes:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al listar tutorías", 
      error: error.message 
    });
  }
};


// =====================================================
// ✅ EXPORTAR TODAS LAS FUNCIONES (BLOQUE ÚNICO)
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
  eliminarDisponibilidadMateria,
  actualizarHorarios,   
  // Validaciones de horarios
  validarCrucesHorarios,
  validarCrucesLocales,
  validarCrucesEntreMaterias,
  _convertirAMinutos,
  _agruparPorDia
};
