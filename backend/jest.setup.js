// Mocka dependências externas para testes
jest.mock('./src/config/db');
jest.mock('./src/middleware/auth');

// Configurações globais de teste
global.console = {
  ...console,
  error: jest.fn(),
  warn: jest.fn(),
};
