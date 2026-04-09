module.exports = {
  query: jest.fn((sql, params) => {
    // Retorna resultado vazio ou específico baseado na query
    if (sql.includes('tipos_documento')) {
      return Promise.resolve({
        rows: [
          { id: 1, nome: 'RG', tipo: 'pessoal' },
          { id: 2, nome: 'CNPJ', tipo: 'empresa' }
        ]
      });
    }
    return Promise.resolve({ rows: [] });
  }),
  connect: jest.fn(() => Promise.resolve({
    query: jest.fn(() => Promise.resolve({ rows: [] })),
    release: jest.fn()
  }))
};
