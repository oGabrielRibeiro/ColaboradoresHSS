const express = require("express");
const router = express.Router();
const {
  getVinculos,
  createVinculo,
  deleteVinculo,
} = require("../controllers/vinculoController");
const protect = require("../middleware/auth");

// GET /api/vinculos?colaborador_id=X ou ?empresa_id=Y
router.get("/", protect, getVinculos);

// POST /api/vinculos
router.post("/", protect, createVinculo);

// DELETE /api/vinculos/:id
router.delete("/:id", protect, deleteVinculo);

module.exports = router;
