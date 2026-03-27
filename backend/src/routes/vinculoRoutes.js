const express = require("express");
const {
  getVinculos,
  createVinculo,
  deleteVinculo,
  getVinculoById,
} = require("../controllers/vinculoController");

const router = express.Router();

router.route("/").get(getVinculos).post(createVinculo);
router.route("/:id").get(getVinculoById).delete(deleteVinculo);

module.exports = router;
