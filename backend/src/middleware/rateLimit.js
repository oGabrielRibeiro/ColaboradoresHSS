const rateLimit = require("express-rate-limit");

const apiRateLimitWindowMs = Number.parseInt(
  process.env.API_RATE_LIMIT_WINDOW_MS || "60000",
  10,
);
const apiRateLimitMax = Number.parseInt(
  process.env.API_RATE_LIMIT_MAX || "120",
  10,
);
const authRateLimitMax = Number.parseInt(
  process.env.AUTH_RATE_LIMIT_MAX || "10",
  10,
);

const apiLimiter = rateLimit({
  windowMs: apiRateLimitWindowMs,
  max: apiRateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Muitas requisicoes. Tente novamente em instantes." },
});

const authLimiter = rateLimit({
  windowMs: apiRateLimitWindowMs,
  max: authRateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Muitas tentativas de login. Aguarde e tente novamente." },
});

module.exports = { apiLimiter, authLimiter };
