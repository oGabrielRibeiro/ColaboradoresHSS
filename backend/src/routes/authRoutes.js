const express = require("express");
const { login, getMe } = require("../controllers/authController");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

router.route("/login").post(login);
router.route("/me").get(authMiddleware, getMe);

module.exports = router;
