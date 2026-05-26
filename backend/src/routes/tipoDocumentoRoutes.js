const express = require("express");
const {
  getTiposDocumento,
  createTipoDocumento,
  updateTipoDocumento,
  deleteTipoDocumento,
} = require("../controllers/tipoDocumentoController");

const router = express.Router();

router.route("/").get(getTiposDocumento).post(createTipoDocumento);
router.route("/:id").put(updateTipoDocumento).delete(deleteTipoDocumento);

module.exports = router;
