module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/', '<rootDir>/__tests__'],
  testMatch: ['**/__tests__/**/*.test.js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/config/**/*.js',
    '!src/middleware/**/*.js',
    '!src/routes/**/*.js', // Rotas são testadas em testes de integração
  ],
  coverageDirectory: 'coverage',
  verbose: true,
};
