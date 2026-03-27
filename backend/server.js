const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const multer = require("multer");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const rateLimit = require("express-rate-limit");
const path = require("path");
const fs = require("fs");
const cron = require("node-cron");

// Import database and helper functions
const pool = require("./src/config/db");
const {
  sanitizeText,
  parseOptionalInt,
  isValidFutureOrTodayDate,
  handleApiError,
  badRequest,
  unauthorized,
} = require("./src/utils/helpers");
const {
  waitForDatabase,
  ensureAuthBootstrap,
  ensureSchemaUpdates,
} = require("./src/config/bootstrap");
const authMiddleware = require("./src/middleware/auth");
const { apiLimiter, authLimiter } = require("./src/middleware/rateLimit"); // <--- ADD THIS LINE
const { iniciarJobNotificacoesVencimento } = require("./src/controllers/cronController");
const { generateFileAccessToken } = require("./src/controllers/uploadController"); // Assuming this helper is moved there

// Import routes
const authRoutes = require("./src/routes/authRoutes");
const dashboardRoutes = require("./src/routes/dashboardRoutes");
const colaboradorRoutes = require("./src/routes/colaboradorRoutes");
const empresaRoutes = require("./src/routes/empresaRoutes");
const tipoDocumentoRoutes = require("./src/routes/tipoDocumentoRoutes");
const documentoRoutes = require("./src/routes/documentoRoutes");
const vinculoRoutes = require("./src/routes/vinculoRoutes");
const uploadRoutes = require("./src/routes/uploadRoutes");

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 3000);
const uploadsDir = path.join(__dirname, "uploads");
const fileLinkExpiresIn = process.env.FILE_LINK_EXPIRES_IN || "5m";
const isProduction = process.env.NODE_ENV === "production";
const corsOrigins = (process.env.CORS_ORIGIN || "")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

app.use(express.json());
app.use(
  cors({
    exposedHeaders: ["X-Total-Count"],
    origin: (origin, callback) => {
      if (corsOrigins.length === 0) {
        return callback(null, true);
      }

      if (!origin || corsOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error("Origem nao permitida pelo CORS"));
    },
  }),
);

app.use(apiLimiter);

app.get("/", (req, res) => {
  res.send("API do RH Documentos esta rodando!");
});

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/uploads/:filename", (req, res) => {
  const filename = path.basename(req.params.filename || "");
  const token = req.query.token; // Token is already sanitized by jwt.verify

  if (!filename || !token) {
    return handleApiError(res, unauthorized("Link de arquivo invalido"));
  }

  try {
    const payload = jwt.verify(
      token,
      process.env.JWT_SECRET || "trocar-em-producao",
    );
    if (payload.type !== "file_access" || payload.filename !== filename) {
      return handleApiError(res, unauthorized("Link de arquivo invalido"));
    }
  } catch (err) {
    return handleApiError(res, unauthorized("Link expirado ou invalido"));
  }

  const filePath = path.join(uploadsDir, filename);
  if (!filePath.startsWith(uploadsDir) || !fs.existsSync(filePath)) {
    return res.status(404).json({ error: "Arquivo nao encontrado" });
  }

  return res.sendFile(filePath);
});

app.use("/auth", authLimiter, authRoutes); // Apply authLimiter only to auth routes
app.use(authMiddleware); // Apply authMiddleware to all subsequent routes

app.get("/arquivos/link", async (req, res) => {
  const requestedPath = sanitizeText(req.query.path);
  if (!requestedPath) {
    return handleApiError(res, badRequest("Caminho do arquivo obrigatorio"));
  }
  const filename = path.basename(requestedPath);
  const absolutePath = path.join(uploadsDir, filename);

  if (!absolutePath.startsWith(uploadsDir) || !fs.existsSync(absolutePath)) {
    return res.status(404).json({ error: "Arquivo nao encontrado" });
  }
  const fileToken = generateFileAccessToken(filename);
  const encodedFilename = encodeURIComponent(filename);
  const signedUrl = `${req.protocol}://${req.get("host")}/uploads/${encodedFilename}?token=${fileToken}`;

  return res.json({ url: signedUrl });
});

app.use("/dashboard", dashboardRoutes);
app.use("/colaboradores", colaboradorRoutes);
app.use("/empresas", empresaRoutes);
app.use("/tipos-documento", tipoDocumentoRoutes);
app.use("/documentos", documentoRoutes);
app.use("/vinculos", vinculoRoutes);
app.use("/upload", uploadRoutes);

async function startServer() {
  await waitForDatabase();
  await ensureAuthBootstrap();
  await ensureSchemaUpdates();
  iniciarJobNotificacoesVencimento();

  app.listen(port, () => {
    console.log(`Servidor rodando na porta ${port}`);
  });
}

startServer();
