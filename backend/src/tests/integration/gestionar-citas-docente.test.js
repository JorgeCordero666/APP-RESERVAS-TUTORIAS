import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../../server.js';
import Docente from '../../models/docente.js';
import Estudiante from '../../models/estudiante.js';
import Tutoria from '../../models/tutorias.js';
import moment from 'moment';

let mongoServer;
let docenteToken;
let docenteId;
let estudianteId;

describe('HU-003: Gestionar Citas como Docente', () => {
  
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

    // Crear docente y obtener token
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

    // Login docente
    const loginResponse = await request(app)
      .post('/api/docente/login')
      .send({
        email: 'docente@test.com',
        password: 'Password123'
      });
    docenteToken = loginResponse.body.token;

    // Crear estudiante
    const estudiante = new Estudiante({
      nombreEstudiante: 'Estudiante Test',
      emailEstudiante: 'estudiante@test.com',
      password: await new Estudiante().encrypPassword('Password123'),
      confirmEmail: true
    });
    await estudiante.save();
    estudianteId = estudiante._id;
  });

  describe('Ver Tutorías Pendientes', () => {
    
    test('3.1 - Debe listar tutorías pendientes del docente', async () => {
      // Crear tutoría pendiente
      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: moment().add(1, 'day').format('YYYY-MM-DD'),
        horaInicio: '10:00',
        horaFin: '10:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .put(`/api/tutoria/finalizar/${tutoria._id}`)
        .set('Authorization', `Bearer ${docenteToken}`)
        .send({
          asistio: true
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('aún no ha ocurrido');
    });
  });

  describe('Cancelar Tutorías', () => {
    
    test('3.11 - Debe cancelar tutoría con anticipación', async () => {
      const tutoria = new Tutoria({
        estudiante: estudianteId,
        docente: docenteId,
        fecha: moment().add(1, 'day').format('YYYY-MM-DD'),
        horaInicio: '10:00',
        horaFin: '10:20',
        estado: 'confirmada'
      });
      await tutoria.save();

      const response = await request(app)
        .delete(`/api/tutoria/cancelar/${tutoria._id}`)
        .set('Authorization', `Bearer ${docenteToken}`)
        .send({
          motivo: 'Imprevisto laboral',
          canceladaPor: 'Docente'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.tutoria.estado).toBe('cancelada_por_docente');
    });

    test('3.12 - No debe cancelar sin anticipación mínima', async () => {
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
        .set('Authorization', `Bearer ${docenteToken}`)
        .send({
          motivo: 'Test',
          canceladaPor: 'Docente'
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('2 horas');
    });
  });
});