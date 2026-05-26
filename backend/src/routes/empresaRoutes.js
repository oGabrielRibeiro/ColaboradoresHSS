const express = require("express");
const {
  getEmpresas,
  createEmpresa,
  updateEmpresa,
  deleteEmpresa,
  getEmpresaById,
} = require("../controllers/empresaController");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// PROTEGE TODAS AS ROTAS DE EMPRESA
router.use(authMiddleware);

router.route("/").get(getEmpresas).post(createEmpresa);
router
  .route("/:id")
  .get(getEmpresaById)
  .put(updateEmpresa)
  .delete(deleteEmpresa);

module.exports = router;
