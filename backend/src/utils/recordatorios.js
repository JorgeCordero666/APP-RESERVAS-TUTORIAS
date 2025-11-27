// backend/src/utils/recordatorios.js
import moment from 'moment';
import Tutoria from '../models/tutorias.js';
import { sendMailRecordatorioTutoria } from '../config/nodemailer.js';

/**
 * Enviar recordatorios de tutorías próximas
 * @param {number} horasAntes - Horas de anticipación (24 o 3)
 */
export const enviarRecordatoriosTutorias = async (horasAntes = 24) => {
  try {
    console.log(`\n⏰ Iniciando envío de recordatorios (${horasAntes}h antes)...`);
    
    const ahora = moment();
    const tiempoInicio = moment(ahora).add(horasAntes - 0.5, 'hours');
    const tiempoFin = moment(ahora).add(horasAntes + 0.5, 'hours');

    console.log(`   Buscando tutorías entre:`);
    console.log(`   ${tiempoInicio.format('YYYY-MM-DD HH:mm')} y ${tiempoFin.format('YYYY-MM-DD HH:mm')}`);

    // Buscar tutorías confirmadas
    const tutorias = await Tutoria.find({
      estado: 'confirmada',
      [`recordatorio${horasAntes}hEnviado`]: { $ne: true }
    })
    .populate('estudiante', 'nombreEstudiante emailEstudiante')
    .populate('docente', 'nombreDocente emailDocente oficinaDocente');

    console.log(`   Total tutorías confirmadas: ${tutorias.length}`);

    let enviados = 0;
    let omitidos = 0;

    for (const tutoria of tutorias) {
      try {
        const fechaHoraTutoria = moment(`${tutoria.fecha} ${tutoria.horaInicio}`, 'YYYY-MM-DD HH:mm');
        const horasRestantes = fechaHoraTutoria.diff(ahora, 'hours', true);

        // Verificar si está en el rango correcto
        if (horasRestantes >= (horasAntes - 0.5) && horasRestantes <= (horasAntes + 0.5)) {
          
          const formatearFecha = (fecha) => {
            const date = moment(fecha, 'YYYY-MM-DD');
            const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
            const dia = dias[date.day()];
            return `${dia} ${date.format('DD/MM/YYYY')}`;
          };

          const tiempoRestante = horasAntes === 24 ? 'mañana' : 'en 3 horas';

          const datosTutoria = {
            fecha: formatearFecha(tutoria.fecha),
            horaInicio: tutoria.horaInicio,
            horaFin: tutoria.horaFin,
            nombreEstudiante: tutoria.estudiante.nombreEstudiante,
            nombreDocente: tutoria.docente.nombreDocente,
            oficinaDocente: tutoria.docente.oficinaDocente,
            tiempoRestante
          };

          // Enviar recordatorio al estudiante
          await sendMailRecordatorioTutoria(
            tutoria.estudiante.emailEstudiante,
            tutoria.estudiante.nombreEstudiante,
            false,
            datosTutoria
          );

          // Enviar recordatorio al docente
          await sendMailRecordatorioTutoria(
            tutoria.docente.emailDocente,
            tutoria.docente.nombreDocente,
            true,
            datosTutoria
          );

          // Marcar como enviado
          if (horasAntes === 24) {
            tutoria.recordatorio24hEnviado = true;
          } else if (horasAntes === 3) {
            tutoria.recordatorio3hEnviado = true;
          }
          
          await tutoria.save();

          console.log(`   ✅ Recordatorio enviado: ${tutoria._id}`);
          console.log(`      Estudiante: ${tutoria.estudiante.nombreEstudiante}`);
          console.log(`      Docente: ${tutoria.docente.nombreDocente}`);
          console.log(`      Fecha/Hora: ${tutoria.fecha} ${tutoria.horaInicio}`);
          
          enviados++;
        } else {
          omitidos++;
        }
      } catch (errorTutoria) {
        console.error(`   ❌ Error procesando tutoría ${tutoria._id}:`, errorTutoria.message);
      }
    }

    console.log(`\n📊 Resumen de recordatorios (${horasAntes}h antes):`);
    console.log(`   ✅ Enviados: ${enviados}`);
    console.log(`   ⏭️  Omitidos: ${omitidos}`);
    console.log(`   ⏰ Próxima ejecución en 1 hora\n`);

    return { enviados, omitidos };

  } catch (error) {
    console.error('❌ Error enviando recordatorios:', error);
    return { enviados: 0, omitidos: 0, error: error.message };
  }
};

/**
 * Limpiar flags de recordatorios de tutorías pasadas
 */
export const limpiarFlagsRecordatorios = async () => {
  try {
    const ayer = moment().subtract(1, 'day').format('YYYY-MM-DD');
    
    const resultado = await Tutoria.updateMany(
      { fecha: { $lt: ayer } },
      { 
        $unset: { 
          recordatorio24hEnviado: "",
          recordatorio3hEnviado: "" 
        } 
      }
    );

    console.log(`🧹 Limpieza de flags: ${resultado.modifiedCount} tutorías actualizadas`);
  } catch (error) {
    console.error('❌ Error limpiando flags:', error);
  }
};