const express = require("express");
const {
  getDocumentosVencidosPorEmpresa,
  getDocumentosAVencerPorPeriodo,
  getIntegridadeDocumentos,
} = require("../controllers/relatorioController");

const router = express.Router();

router.get("/documentos-vencidos-por-empresa", getDocumentosVencidosPorEmpresa);
router.get("/documentos-a-vencer-periodo", getDocumentosAVencerPorPeriodo);
router.get("/integridade-documentos", getIntegridadeDocumentos);

module.exports = router;
