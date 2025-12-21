import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../../server.js';
import Administrador from '../../models/administrador.js';
import Docente from '../../models/docente.js';
import Estudiante from '../../models/estudiante.js';

let mongoServer;

describe('HU-002: Recuperar Contraseña', () => {
  
  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  describe('Recuperación - Administrador', () => {
    
    beforeEach(async () => {
      await Administrador.deleteMany({});
    });

    test('2.1 - Debe generar token de recuperación para admin existente', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('OldPassword123'),
        confirmEmail: true
      });
      await admin.save();

      const response = await request(app)
        .post('/api/administrador/recuperarpassword')
        .send({
          email: 'admin@test.com'
        });

      expect(response.status).toBe(200);
      expect(response.body.msg).toContain('correo');

      // Verificar que se generó el token
      const adminActualizado = await Administrador.findOne({ email: 'admin@test.com' });
      expect(adminActualizado.token).toBeTruthy();
    });

    test('2.2 - Debe rechazar email no registrado', async () => {
      const response = await request(app)
        .post('/api/administrador/recuperarpassword')
        .send({
          email: 'noexiste@test.com'
        });

      expect(response.status).toBe(404);
      expect(response.body.msg).toContain('no existe');
    });

    test('2.3 - Debe validar formato de email', async () => {
      const response = await request(app)
        .post('/api/administrador/recuperarpassword')
        .send({
          email: 'email_invalido'
        });

      expect(response.status).toBe(404);
    });
  });

  describe('Comprobar Token', () => {
    
    test('2.4 - Debe validar token correcto', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('OldPassword123'),
        confirmEmail: true
      });
      const token = admin.crearToken();
      await admin.save();

      const response = await request(app)
        .get(`/api/administrador/recuperarpassword/${token}`);

      expect(response.status).toBe(200);
      expect(response.body.msg).toContain('confirmado');
    });

    test('2.5 - Debe rechazar token inválido', async () => {
      const response = await request(app)
        .get('/api/administrador/recuperarpassword/token_falso_123');

      expect(response.status).toBe(404);
      expect(response.body.msg).toContain('no se puede validar');
    });
  });

  describe('Crear Nueva Contraseña', () => {
    
    test('2.6 - Debe permitir crear nueva contraseña con token válido', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('OldPassword123'),
        confirmEmail: true
      });
      const token = admin.crearToken();
      await admin.save();

      const response = await request(app)
        .post(`/api/administrador/nuevopassword/${token}`)
        .send({
          password: 'NewPassword123',
          confirmpassword: 'NewPassword123'
        });

      expect(response.status).toBe(200);
      expect(response.body.msg).toContain('iniciar sesión');

      // Verificar que el token se eliminó
      const adminActualizado = await Administrador.findOne({ email: 'admin@test.com' });
      expect(adminActualizado.token).toBeNull();
    });

    test('2.7 - Debe rechazar contraseñas que no coinciden', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('OldPassword123'),
        confirmEmail: true
      });
      const token = admin.crearToken();
      await admin.save();

      const response = await request(app)
        .post(`/api/administrador/nuevopassword/${token}`)
        .send({
          password: 'NewPassword123',
          confirmpassword: 'DifferentPassword123'
        });

      expect(response.status).toBe(404);
      expect(response.body.msg).toContain('no coinciden');
    });

    test('2.8 - Debe validar longitud mínima de contraseña', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('OldPassword123'),
        confirmEmail: true
      });
      const token = admin.crearToken();
      await admin.save();

      const response = await request(app)
        .post(`/api/administrador/nuevopassword/${token}`)
        .send({
          password: '123',
          confirmpassword: '123'
        });

      expect(response.status).toBe(404);
    });
  });

  describe('Recuperación - Docente', () => {
    
    beforeEach(async () => {
      await Docente.deleteMany({});
    });

    test('2.9 - Debe generar token de recuperación para docente', async () => {
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

      const response = await request(app)
        .post('/api/docente/recuperarpassword')
        .send({
          emailDocente: 'docente@test.com'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('Recuperación - Estudiante', () => {
    
    beforeEach(async () => {
      await Estudiante.deleteMany({});
    });

    test('2.10 - Debe generar token de recuperación para estudiante', async () => {
      const estudiante = new Estudiante({
        nombreEstudiante: 'Estudiante Test',
        emailEstudiante: 'estudiante@test.com',
        password: await new Estudiante().encrypPassword('Password123'),
        confirmEmail: true
      });
      await estudiante.save();

      const response = await request(app)
        .post('/api/estudiante/recuperarpassword')
        .send({
          emailEstudiante: 'estudiante@test.com'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});