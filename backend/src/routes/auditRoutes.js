const express = require("express");
const { getAuditLogs } = require("../controllers/auditController");

const router = express.Router();

router.route("/").get(getAuditLogs);

module.exports = router;
