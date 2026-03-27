const pool = require("../config/db");
const { handleApiError } = require("../utils/helpers");

const getTiposDocumento = async (req, res) => {
    try {
        const result = await pool.query(
          "SELECT * FROM tipos_documento ORDER BY tipo, nome",
        );
        res.json(result.rows);
      } catch (err) {
        handleApiError(res, err, "Erro ao buscar tipos de documento");
      }
};

module.exports = {
    getTiposDocumento,
};