const express = require("express");
const { getDashboardResumo } = require("../controllers/dashboardController");

const router = express.Router();

router.route("/resumo").get(getDashboardResumo);

module.exports = router;
