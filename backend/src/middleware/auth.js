const jwt = require("jsonwebtoken");
const { handleApiError, unauthorized } = require("../utils/helpers");

const jwtSecret = process.env.JWT_SECRET || "trocar-em-producao";

function authMiddleware(req, res, next) {
  if (req.method === "OPTIONS") {
    return next();
  }

  const publicPaths = new Set(["/", "/health", "/auth/login"]);
  if (publicPaths.has(req.path) || req.path.startsWith("/uploads")) {
    return next();
  }

  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (!token) {
    return handleApiError(res, unauthorized("Token de acesso ausente"));
  }

  try {
    const payload = jwt.verify(token, jwtSecret);
    req.authUser = payload;
    return next();
  } catch (err) {
    return handleApiError(res, unauthorized("Token invalido ou expirado"));
  }
}

module.exports = authMiddleware;
