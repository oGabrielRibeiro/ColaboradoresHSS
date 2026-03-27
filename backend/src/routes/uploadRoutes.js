const express = require("express");
const { uploadFile } = require("../controllers/uploadController");
const upload = require("../middleware/upload");

const router = express.Router();

router.route("/").post(upload.single("arquivo"), uploadFile);

module.exports = router;
