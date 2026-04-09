const request = require('supertest');
const express = require('express');

/**
 * @jest-environment node
 */

describe('Teste de Proteção de Rotas', () => {
  let app;

  beforeEach(() => {
    app = express();
    app.use(express.json());

    // Importa rotas
    const documentoRoutes = require('../src/routes/documentoRoutes');
    const empresaRoutes = require('../src/routes/empresaRoutes');
    const colaboradorRoutes = require('../src/routes/colaboradorRoutes');
    const authRoutes = require('../src/routes/authRoutes');

    app.use('/api/auth', authRoutes);
    app.use('/api/documentos', documentoRoutes);
    app.use('/api/empresas', empresaRoutes);
    app.use('/api/colaboradores', colaboradorRoutes);
  });

  describe('Rotas Públicas - devem funcionar sem token', () => {
    test('/api/auth/login deve ser pública', async () => {
      const res = await request(app).post('/api/auth/login').send({ email: 'test@test.com', password: '123456' });
      expect(res.status).not.toBe(401);
    });
  });

  describe('Rotas Privadas - devem retornar 401 sem token', () => {
    const testCases = [
      { method: 'get', path: '/api/documentos' },
      { method: 'post', path: '/api/documentos', body: {} },
      { method: 'get', path: '/api/empresas' },
      { method: 'post', path: '/api/empresas', body: {} },
      { method: 'get', path: '/api/colaboradores' },
      { method: 'post', path: '/api/colaboradores', body: {} },
    ];

    testCases.forEach(({ method, path, body }) => {
      test(`
        ${method.toUpperCase()} ${path} deve retornar 401
        sem token de autenticação
      `, async () => {
        const res = await request(app)[method](path).send(body || {});
        expect(res.status).toBe(401);
        expect(res.body.error).toMatch(/token|autoriza/i);
      });
    });
  });

  describe('Rotas Privadas - devem funcionar COM token válido', () => {
    let token;

    beforeEach(async () => {
      // Mock de login bem-sucedido
      const res = await request(app).post('/api/auth/login').send({
        email: 'rh@empresa.com',
        password: '123456'
      });

      token = res.body.token;
    });

    test('GET /api/documentos deve retornar 200 com token', async () => {
      const res = await request(app)
        .get('/api/documentos')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
    });
  });
});
