// ============================================
// SCRIPT DE SIMULACIÓN - LOGS DE NOTIFICACIONES
// Figura 3.48: Logs del sistema – Envío exitoso de notificaciones
// ============================================

import 'dart:async';

void main() async {
  print('\n' + '=' * 80);
  print('🔔 SISTEMA DE NOTIFICACIONES AUTOMÁTICAS - SERVICIO DE RECORDATORIOS');
  print('=' * 80 + '\n');
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  print('⏰ [${_obtenerTimestamp()}] Iniciando verificación de tutorías próximas...');
  print('📅 Rango: Próximas 24 horas');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 800));
  
  print('🔍 [${_obtenerTimestamp()}] Consultando base de datos...');
  print('   Query: Tutorías confirmadas en las próximas 24 horas sin recordatorio');
  
  await Future.delayed(const Duration(milliseconds: 1000));
  
  print('✅ [${_obtenerTimestamp()}] Encontradas 5 tutorías que requieren recordatorio');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Simulación de envío de recordatorios
  final tutorias = [
    {
      'id': 'TUT-2025-001',
      'estudiante': 'Juan Pérez García',
      'emailEstudiante': 'juan.perez@epn.edu.ec',
      'docente': 'Dr. María López',
      'emailDocente': 'maria.lopez@epn.edu.ec',
      'materia': 'Cálculo Diferencial',
      'fecha': '2025-12-18',
      'dia': 'Jueves',
      'horaInicio': '08:00',
      'horaFin': '08:20',
    },
    {
      'id': 'TUT-2025-002',
      'estudiante': 'Ana Martínez',
      'emailEstudiante': 'ana.martinez@epn.edu.ec',
      'docente': 'Ing. Carlos Ruiz',
      'emailDocente': 'carlos.ruiz@epn.edu.ec',
      'materia': 'Programación Orientada a Objetos',
      'fecha': '2025-12-18',
      'dia': 'Jueves',
      'horaInicio': '10:00',
      'horaFin': '10:20',
    },
    {
      'id': 'TUT-2025-003',
      'estudiante': 'Pedro Sánchez',
      'emailEstudiante': 'pedro.sanchez@epn.edu.ec',
      'docente': 'Dra. Laura Gómez',
      'emailDocente': 'laura.gomez@epn.edu.ec',
      'materia': 'Estructuras de Datos',
      'fecha': '2025-12-18',
      'dia': 'Jueves',
      'horaInicio': '14:00',
      'horaFin': '14:20',
    },
    {
      'id': 'TUT-2025-004',
      'estudiante': 'María González',
      'emailEstudiante': 'maria.gonzalez@epn.edu.ec',
      'docente': 'Dr. Roberto Torres',
      'emailDocente': 'roberto.torres@epn.edu.ec',
      'materia': 'Base de Datos',
      'fecha': '2025-12-18',
      'dia': 'Jueves',
      'horaInicio': '16:00',
      'horaFin': '16:20',
    },
    {
      'id': 'TUT-2025-005',
      'estudiante': 'Luis Ramírez',
      'emailEstudiante': 'luis.ramirez@epn.edu.ec',
      'docente': 'Ing. Patricia Vera',
      'emailDocente': 'patricia.vera@epn.edu.ec',
      'materia': 'Redes de Computadoras',
      'fecha': '2025-12-19',
      'dia': 'Viernes',
      'horaInicio': '08:00',
      'horaFin': '08:20',
    },
  ];
  
  print('━' * 80);
  print('📧 PROCESANDO ENVÍO DE RECORDATORIOS');
  print('━' * 80 + '\n');
  
  for (var i = 0; i < tutorias.length; i++) {
    final tutoria = tutorias[i];
    
    await _procesarRecordatorio(tutoria, i + 1, tutorias.length);
    
    if (i < tutorias.length - 1) {
      await Future.delayed(const Duration(milliseconds: 800));
      print('');
    }
  }
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  print('\n' + '━' * 80);
  print('📊 RESUMEN DE ENVÍO');
  print('━' * 80);
  print('');
  print('✅ Total enviados:           5 recordatorios');
  print('📤 Emails al estudiante:     5');
  print('📤 Emails al docente:        5');
  print('📧 Total de emails:          10');
  print('⏱️  Tiempo total:             ${(tutorias.length * 1.2).toStringAsFixed(1)}s');
  print('🔄 Estado:                   COMPLETADO');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  print('━' * 80);
  print('💾 ACTUALIZACIÓN DE BASE DE DATOS');
  print('━' * 80);
  print('');
  print('[${_obtenerTimestamp()}] Marcando tutorías con recordatorio enviado...');
  
  await Future.delayed(const Duration(milliseconds: 600));
  
  print('✅ [${_obtenerTimestamp()}] Actualizados 5 registros en la base de datos');
  print('   Campo actualizado: recordatorioEnviado = true');
  print('   Campo actualizado: fechaRecordatorio = ${_obtenerTimestamp()}');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  print('━' * 80);
  print('🎯 PRÓXIMA EJECUCIÓN');
  print('━' * 80);
  print('');
  final proximaEjecucion = DateTime.now().add(const Duration(hours: 1));
  print('⏰ Programada para: ${_formatearFechaHora(proximaEjecucion)}');
  print('🔄 Frecuencia: Cada hora');
  print('');
  
  print('=' * 80);
  print('✅ PROCESO FINALIZADO EXITOSAMENTE');
  print('=' * 80 + '\n');
}

Future<void> _procesarRecordatorio(
  Map<String, dynamic> tutoria,
  int actual,
  int total,
) async {
  print('[$actual/$total] 📋 Procesando: ${tutoria['id']}');
  print('        📚 Materia: ${tutoria['materia']}');
  print('        📅 Fecha: ${tutoria['dia']} ${tutoria['fecha']}');
  print('        ⏰ Horario: ${tutoria['horaInicio']} - ${tutoria['horaFin']}');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 300));
  
  // Email al estudiante
  print('        📤 Enviando recordatorio al estudiante...');
  await Future.delayed(const Duration(milliseconds: 400));
  
  print('        ✅ [${_obtenerTimestamp()}] Email enviado exitosamente');
  print('           Destinatario: ${tutoria['estudiante']}');
  print('           Email: ${tutoria['emailEstudiante']}');
  print('           Asunto: Recordatorio de Tutoría - ${tutoria['materia']}');
  print('           Contenido:');
  print('           ┌─────────────────────────────────────────────┐');
  print('           │ Hola ${_obtenerPrimerNombre(tutoria['estudiante'])},                            │');
  print('           │                                             │');
  print('           │ Te recordamos tu tutoría programada:        │');
  print('           │                                             │');
  print('           │ 👨‍🏫 Docente: ${_ajustarTexto(tutoria['docente'], 29)} │');
  print('           │ 📚 Materia: ${_ajustarTexto(tutoria['materia'], 30)} │');
  print('           │ 📅 Fecha: ${tutoria['dia']} ${tutoria['fecha']}            │');
  print('           │ ⏰ Hora: ${tutoria['horaInicio']} - ${tutoria['horaFin']}                   │');
  print('           │ 🔢 Nº Tutoría: ${tutoria['id']}              │');
  print('           │                                             │');
  print('           │ ¡No olvides asistir puntualmente!           │');
  print('           └─────────────────────────────────────────────┘');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 300));
  
  // Email al docente
  print('        📤 Enviando recordatorio al docente...');
  await Future.delayed(const Duration(milliseconds: 400));
  
  print('        ✅ [${_obtenerTimestamp()}] Email enviado exitosamente');
  print('           Destinatario: ${tutoria['docente']}');
  print('           Email: ${tutoria['emailDocente']}');
  print('           Asunto: Recordatorio de Tutoría - ${tutoria['estudiante']}');
  print('           Contenido:');
  print('           ┌─────────────────────────────────────────────┐');
  print('           │ Estimado/a ${_obtenerPrimerNombre(tutoria['docente'])},                        │');
  print('           │                                             │');
  print('           │ Recordatorio de tutoría agendada:           │');
  print('           │                                             │');
  print('           │ 👨‍🎓 Estudiante: ${_ajustarTexto(tutoria['estudiante'], 26)} │');
  print('           │ 📚 Materia: ${_ajustarTexto(tutoria['materia'], 30)} │');
  print('           │ 📅 Fecha: ${tutoria['dia']} ${tutoria['fecha']}            │');
  print('           │ ⏰ Hora: ${tutoria['horaInicio']} - ${tutoria['horaFin']}                   │');
  print('           │ 🔢 Nº Tutoría: ${tutoria['id']}              │');
  print('           │                                             │');
  print('           │ El estudiante espera su asesoría.           │');
  print('           └─────────────────────────────────────────────┘');
  print('');
  
  await Future.delayed(const Duration(milliseconds: 200));
  
  print('        💾 Actualizando registro en base de datos...');
  await Future.delayed(const Duration(milliseconds: 300));
  
  print('        ✅ Registro actualizado: recordatorioEnviado = true');
  print('');
}

String _obtenerTimestamp() {
  final ahora = DateTime.now();
  return '${ahora.hour.toString().padLeft(2, '0')}:'
         '${ahora.minute.toString().padLeft(2, '0')}:'
         '${ahora.second.toString().padLeft(2, '0')}';
}

String _formatearFechaHora(DateTime fecha) {
  return '${fecha.day}/${fecha.month}/${fecha.year} '
         '${fecha.hour.toString().padLeft(2, '0')}:'
         '${fecha.minute.toString().padLeft(2, '0')}';
}

String _obtenerPrimerNombre(String nombreCompleto) {
  return nombreCompleto.split(' ').first;
}

String _ajustarTexto(String texto, int longitudMaxima) {
  if (texto.length <= longitudMaxima) {
    return texto.padRight(longitudMaxima);
  }
  return texto.substring(0, longitudMaxima - 3) + '...';
}