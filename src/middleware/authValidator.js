import { body, validationResult } from 'express-validator';

export const validateRegister = [
  body('nama')
    .notEmpty().withMessage('Harus isi nama, jangan dikosongkan')
    .isString().withMessage('Nama harus berupa string')
    .matches(/^[A-Za-z\s]+$/).withMessage('Nama tidak boleh mengandung angka atau karakter khusus')
    .isLength({ min: 2, max: 100 }).withMessage('Nama harus memiliki panjang antara 2 dan 100 karakter'),
  body('alamat')
    .notEmpty().withMessage('Harus isi alamat, jangan dikosongkan'),
  body('email')
    .isEmail().withMessage('Tolong masukkan email yang valid'),
  body('password')
    .isLength({ min: 6 }).withMessage('Password harus minimal 6 karakter'),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        message: 'Validation error',
        errors: errors.array() 
      });
    }
    next();
  }
];

export const validateLogin = [
  body('email').isEmail().withMessage('Please include a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];