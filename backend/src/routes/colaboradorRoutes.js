const express = require("express");
const {
  getColaboradores,
  getColaboradorById,
  getColaboradorVinculos,
  createColaborador,
  updateColaborador,
  deleteColaborador,
} = require("../controllers/colaboradorController");

const router = express.Router();

router.route("/").get(getColaboradores).post(createColaborador);
router
  .route("/:id")
  .get(getColaboradorById)
  .put(updateColaborador)
  .delete(deleteColaborador);
router.route("/:id/vinculos").get(getColaboradorVinculos);

module.exports = router;
