const express = require("express");
const { getTiposDocumento } = require("../controllers/tipoDocumentoController");

const router = express.Router();

router.route("/").get(getTiposDocumento);

module.exports = router;
