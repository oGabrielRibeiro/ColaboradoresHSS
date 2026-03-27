const { handleApiError } = require("../utils/helpers");

const uploadFile = async (req, res) => {
    try {
        if (!req.file) {
          return res.status(400).json({ error: "Nenhum arquivo enviado" });
        }
    
        res.json({
          message: "Upload realizado com sucesso",
          file: {
            originalname: req.file.originalname,
            filename: req.file.filename,
            path: `/uploads/${req.file.filename}`,
            size: req.file.size,
          },
        });
      } catch (err) {
        handleApiError(res, err, "Erro no upload");
      }
};

module.exports = {
    uploadFile,
};