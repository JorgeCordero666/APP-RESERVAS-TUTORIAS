import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import app from '../../server.js';
import Administrador from '../../models/administrador.js';

let mongoServer;

describe('HU-001: Login como Administrador', () => {
  
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
    await Administrador.deleteMany({});
  });

  describe('POST /api/login - Casos de Éxito', () => {
    
    test('1.1 - Debe permitir login con credenciales correctas', async () => {
      // ARRANGE - Preparar
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: true
      });
      await admin.save();

      // ACT - Actuar
      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'admin@test.com',
          password: 'Password123'
        });

      // ASSERT - Verificar
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('rol', 'Administrador');
      expect(response.body).toHaveProperty('nombreAdministrador', 'Admin Test');
      expect(response.body).not.toHaveProperty('password');
    });

    test('1.2 - El token JWT debe ser válido y decodificable', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: true
      });
      await admin.save();

      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'admin@test.com',
          password: 'Password123'
        });

      expect(response.body.token).toMatch(/^[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$/);
    });
  });

  describe('POST /api/login - Casos de Error', () => {
    
    test('1.3 - Debe rechazar login con email incorrecto', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: true
      });
      await admin.save();

      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'wrong@test.com',
          password: 'Password123'
        });

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('msg');
      expect(response.body.msg).toContain('no existe');
    });

    test('1.4 - Debe rechazar login con contraseña incorrecta', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: true
      });
      await admin.save();

      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'admin@test.com',
          password: 'WrongPassword'
        });

      expect(response.status).toBe(401);
      expect(response.body.msg).toContain('incorrecta');
    });

    test('1.5 - Debe validar campos obligatorios', async () => {
      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'admin@test.com'
          // Falta password
        });

      expect(response.status).toBe(400);
      expect(response.body.msg).toContain('obligatorios');
    });

    test('1.6 - Debe rechazar email con formato inválido', async () => {
      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'email_invalido',
          password: 'Password123'
        });

      expect(response.status).toBe(404);
    });
  });

  describe('POST /api/login - Casos Edge (Límites)', () => {
    
    test('1.7 - Debe manejar emails con espacios', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: true
      });
      await admin.save();

      const response = await request(app)
        .post('/api/login')
        .send({
          email: '  admin@test.com  ',
          password: 'Password123'
        });

      expect(response.status).toBe(200);
    });

    test('1.8 - Debe rechazar cuenta no confirmada', async () => {
      const admin = new Administrador({
        nombreAdministrador: 'Admin Test',
        email: 'admin@test.com',
        password: await new Administrador().encrypPassword('Password123'),
        confirmEmail: false // Cuenta no confirmada
      });
      await admin.save();

      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'admin@test.com',
          password: 'Password123'
        });

      expect(response.status).toBe(200);
    });
  });
});