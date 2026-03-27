function sanitizeText(value) {
  if (value === undefined || value === null) {
    return null;
  }

  const normalized = String(value).trim();
  return normalized.length > 0 ? normalized : null;
}

function parseOptionalInt(value) {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? null : parsed;
}

function isValidFutureOrTodayDate(value) {
  if (!value) {
    return false;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return false;
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  date.setHours(0, 0, 0, 0);
  return date >= today;
}

function handleApiError(res, err, defaultMessage) {
  console.error(err);
  const message = err.message || defaultMessage;
  const status = err.statusCode || 500;
  res.status(status).json({ error: message });
}

function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

function unauthorized(message = "Nao autorizado") {
  const error = new Error(message);
  error.statusCode = 401;
  return error;
}

module.exports = {
  sanitizeText,
  parseOptionalInt,
  isValidFutureOrTodayDate,
  handleApiError,
  badRequest,
  unauthorized,
};
