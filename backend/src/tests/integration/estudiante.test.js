// gestionar-citas-estudiante.test.js
import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../../server.js';
import Docente from '../../models/docente.js';
import Estudiante from '../../models/estudiante.js';
import Tutoria from '../../models/tutorias.js';
import disponibilidadDocente from '../../models/disponibilidadDocente.js';
import moment from 'moment';

let mongoServer;
let estudianteToken;
let estudianteId;
let docenteId;

describe('HU-004: Gestionar Citas como Estudiante', () => {
  
  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    await Docente.deleteMany({});
    await Estudiante.deleteMany({});
    await Tutoria.deleteMany({});
    await disponibilidadDocente.deleteMany({});

    // Crear docente
    const docente = new Docente({
      nombreDocente: 'Docente Test',
      emailDocente: 'docente@test.com',
      passwordDocente: await new Docente().encrypPassword('Password123'),
      confirmEmail: true,
      cedulaDocente: '1234567890',
      celularDocente: '0987654321',
      oficinaDocente: 'Oficina 101',
      emailAlternativoDocente: 'docente.alt@test.com',
      fechaNacimientoDocente: new Date('1990-01-01'),
      fechaIngresoDocente: new Date(),
      semestreAsignado: 'Primer Semestre',
      asignaturas: ['Matemáticas']
    });
    await docente.save();
    docenteId = docente._id;

    // Crear disponibilidad
    const disponibilidad = new disponibilidadDocente({
      docente: docenteId,
      diaSemana: 'lunes',
      materia: 'Matemáticas',
      bloques: [
        { horaInicio: '08:00', horaFin: '10:00' },
        { horaInicio: '14:00', horaFin: '16:00' }
      ]
    });
    await disponibilidad.save();

    // Crear estudiante y obtener token
    const estudiante = new Estudiante({
      nombreEstudiante: 'Estudiante Test',
      emailEstudiante: 'estudiante@test.com',
      password: await new Estudiante().encrypPassword('Password123'),
      confirmEmail: true
    });
    await estudiante.save();
    estudianteId = estudiante._id;

    // Login estudiante
    const loginResponse = await request(app)
      .post('/api/estudiante/login')
      .send({
        emailEstudiante: 'estudiante@test.com',
        password: 'Password123'
      });
    estudianteToken = loginResponse.body.token;
  });

  describe('Ver Disponibilidad', () => {
    
    test('4.1 - Debe ver disponibilidad de docente por materia', async () => {
      const response = await request(app)
        .get(`/api/ver-disponibilidad-materia/${docenteId}/Matemáticas`)
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.disponibilidad).toHaveLength(1);
      expect(response.body.disponibilidad[0].materia).toBe('Matemáticas');
    });

    test('4.2 - Debe ver disponibilidad completa del docente', async () => {
      const response = await request(app)
        .get(`/api/ver-disponibilidad-completa/${docenteId}`)
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.materias).toHaveProperty('Matemáticas');
    });

    test('4.3 - Debe obtener turnos disponibles de un bloque', async () => {
      const fechaLunes = moment().day(1).add(1, 'week').format('YYYY-MM-DD');

      const response = await request(app)
        .get('/api/turnos-disponibles')
        .query({
          docenteId: docenteId,
          fecha: fechaLunes,
          horaInicio: '08:00',
          horaFin: '10:00'
        })
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.turnos.lista.length).toBeGreaterThan(0);
    });
  });

  describe('Agendar Tutorías', () => {
    
    test('4.4 - Debe agendar tutoría exitosamente', async () => {
      const fechaLunes = moment().day(1).add(1, 'week').format('YYYY-MM-DD');

      const response = await request(app)
        .post('/api/tutoria/registrar-turno')
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          docente: docenteId,
          fecha: fechaLunes,
          horaInicio: '08:00',
          horaFin: '08:20'
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.tutoria.estado).toBe('pendiente');
    });

    test('4.5 - No debe agendar turno ya ocupado', async () => {
      const fechaLunes = moment().day(1).add(1, 'week').format('YYYY-MM-DD');

      // Crear tutoría existente
      const tutoriaExistente = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaLunes,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoriaExistente.save();

      const response = await request(app)
        .post('/api/tutoria/registrar-turno')
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          docente: docenteId,
          fecha: fechaLunes,
          horaInicio: '08:00',
          horaFin: '08:20'
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('ocupado');
    });

    test('4.6 - No debe agendar turno de más de 20 minutos', async () => {
      const fechaLunes = moment().day(1).add(1, 'week').format('YYYY-MM-DD');

      const response = await request(app)
        .post('/api/tutoria/registrar-turno')
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          docente: docenteId,
          fecha: fechaLunes,
          horaInicio: '08:00',
          horaFin: '08:30'
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('20 minutos');
    });

    test('4.7 - No debe agendar en el pasado', async () => {
      const fechaPasada = moment().subtract(1, 'day').format('YYYY-MM-DD');

      const response = await request(app)
        .post('/api/tutoria/registrar-turno')
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          docente: docenteId,
          fecha: fechaPasada,
          horaInicio: '08:00',
          horaFin: '08:20'
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('pasadas');
    });
  });

  describe('Ver Tutorías Agendadas', () => {
    
    test('4.8 - Debe listar tutorías del estudiante', async () => {
      const fechaFutura = moment().add(1, 'day').format('YYYY-MM-DD');

      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaFutura,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .get('/api/tutorias')
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.tutorias).toHaveLength(1);
    });

    test('4.9 - Debe filtrar tutorías por fecha', async () => {
      const fecha = moment().add(1, 'day').format('YYYY-MM-DD');

      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fecha,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .get('/api/tutorias')
        .query({ fecha: fecha })
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.tutorias).toHaveLength(1);
    });

    test('4.10 - Debe filtrar tutorías por estado', async () => {
      const fechaFutura = moment().add(1, 'day').format('YYYY-MM-DD');

      const tutoria1 = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaFutura,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'pendiente'
      });
      await tutoria1.save();

      const tutoria2 = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaFutura,
        horaInicio: '09:00',
        horaFin: '09:20',
        estado: 'confirmada'
      });
      await tutoria2.save();

      const response = await request(app)
        .get('/api/tutorias')
        .query({ estado: 'confirmada' })
        .set('Authorization', `Bearer ${estudianteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.tutorias).toHaveLength(1);
      expect(response.body.tutorias[0].estado).toBe('confirmada');
    });
  });

  describe('Cancelar Tutorías', () => {
    
    test('4.11 - Debe cancelar tutoría con anticipación', async () => {
      const fechaFutura = moment().add(1, 'day').format('YYYY-MM-DD');

      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaFutura,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .delete(`/api/tutoria/cancelar/${tutoria._id}`)
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          motivo: 'No podré asistir',
          canceladaPor: 'Estudiante'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.tutoria.estado).toBe('cancelada_por_estudiante');
    });

    test('4.12 - No debe cancelar sin anticipación', async () => {
      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: moment().format('YYYY-MM-DD'),
        horaInicio: moment().add(1, 'hour').format('HH:mm'),
        horaFin: moment().add(1.5, 'hours').format('HH:mm'),
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .delete(`/api/tutoria/cancelar/${tutoria._id}`)
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          motivo: 'Test',
          canceladaPor: 'Estudiante'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Reagendar Tutorías', () => {
    
    test('4.13 - Debe reagendar tutoría exitosamente', async () => {
      const fechaOriginal = moment().add(2, 'days').format('YYYY-MM-DD');
      const fechaNueva = moment().add(3, 'days').format('YYYY-MM-DD');

      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaOriginal,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .put(`/api/tutoria/reagendar/${tutoria._id}`)
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          nuevaFecha: fechaNueva,
          nuevaHoraInicio: '09:00',
          nuevaHoraFin: '09:20',
          motivo: 'Cambio de horario personal'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('4.14 - Debe cambiar estado a pendiente al reagendar', async () => {
      const fechaOriginal = moment().add(2, 'days').format('YYYY-MM-DD');
      const fechaNueva = moment().add(3, 'days').format('YYYY-MM-DD');

      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: fechaOriginal,
        horaInicio: '08:00',
        horaFin: '08:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .put(`/api/tutoria/reagendar/${tutoria._id}`)
        .set('Authorization', `Bearer ${estudianteToken}`)
        .send({
          nuevaFecha: fechaNueva,
          nuevaHoraInicio: '09:00',
          nuevaHoraFin: '09:20'
        });

      // Verificar en BD
      const tutoriaActualizada = await Tutoria.findById(tutoria._id);
      expect(tutoriaActualizada.estado).toBe('pendiente');
    });
  });
});