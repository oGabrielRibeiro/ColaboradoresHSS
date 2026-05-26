const express = require("express");
const {
  getColaboradores,
  getColaboradorById,
  getColaboradorVinculos,
  createColaborador,
  updateColaborador,
  deleteColaborador,
} = require("../controllers/colaboradorController");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// PROTEGE TODAS AS ROTAS DE COLABORADOR
router.use(authMiddleware);

router.route("/").get(getColaboradores).post(createColaborador);
router
  .route("/:id")
  .get(getColaboradorById)
  .put(updateColaborador)
  .delete(deleteColaborador);
router.route("/:id/vinculos").get(getColaboradorVinculos);

module.exports = router;
