const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");
const {
  sanitizeText,
  handleApiError,
  badRequest,
  unauthorized,
} = require("../utils/helpers");

const jwtSecret = process.env.JWT_SECRET || "trocar-em-producao";
const jwtExpiresIn = process.env.JWT_EXPIRES_IN || "12h";

function generateToken(user) {
    return jwt.sign(
      {
        sub: user.id,
        email: user.email,
        nome: user.nome,
      },
      jwtSecret,
      { expiresIn: jwtExpiresIn },
    );
  }

const login = async (req, res) => {
    const email = sanitizeText(req.body.email)?.toLowerCase();
    const senha = sanitizeText(req.body.senha);
  
    if (!email || !senha) {
      return handleApiError(res, badRequest("E-mail e senha sao obrigatorios"));
    }
  
    try {
      const result = await pool.query(
        `SELECT id, nome, email, senha_hash, ativo
         FROM usuarios_rh
         WHERE email = $1`,
        [email],
      );
  
      if (result.rows.length === 0) {
        return handleApiError(res, unauthorized("Credenciais invalidas"));
      }
  
      const usuario = result.rows[0];
      if (!usuario.ativo) {
        return handleApiError(
          res,
          unauthorized("Usuario desativado. Procure o administrador."),
        );
      }
  
      const senhaOk = await bcrypt.compare(senha, usuario.senha_hash);
      if (!senhaOk) {
        return handleApiError(res, unauthorized("Credenciais invalidas"));
      }
  
      const token = generateToken(usuario);
  
      return res.json({
        token,
        usuario: {
          id: usuario.id,
          nome: usuario.nome,
          email: usuario.email,
        },
      });
    } catch (err) {
      return handleApiError(res, err, "Erro ao autenticar usuario");
    }
};

const getMe = async (req, res) => {
    try {
        const id = Number.parseInt(req.authUser.sub, 10);
        const result = await pool.query(
          "SELECT id, nome, email, ativo FROM usuarios_rh WHERE id = $1",
          [id],
        );
    
        if (result.rows.length === 0 || !result.rows[0].ativo) {
          return handleApiError(res, unauthorized("Sessao invalida"));
        }
    
        return res.json({ usuario: result.rows[0] });
      } catch (err) {
        return handleApiError(res, err, "Erro ao validar sessao");
      }
};

module.exports = {
    login,
    getMe,
};