const express = require("express");
const {
  getDocumentos,
  createDocumento,
  getDocumentoById,
  getDocumentoHistorico,
  substituirDocumento,
  updateDocumento,
  deleteDocumento,
} = require("../controllers/documentoController");
const upload = require("../middleware/upload");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// PROTEGE TODAS AS ROTAS DE DOCUMENTO
router.use(authMiddleware);

router.route("/").get(getDocumentos).post(createDocumento);
router
  .route("/:id")
  .get(getDocumentoById)
  .put(updateDocumento)
  .delete(deleteDocumento);
router.route("/:id/historico").get(getDocumentoHistorico);
router
  .route("/:id/substituir")
  .post(upload.single("arquivo"), substituirDocumento);

module.exports = router;
