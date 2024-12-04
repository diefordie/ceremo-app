import { jwt } from '../services/jwt.js';

export const authenticateToken = (request, response, next) => {
  const token = request.cookies.token;

  if (!token) {
    return response
      .status(401)
      .json({ message: 'Akses ditolak. Harap Login.' });
  }

  try {
    const decoded = jwt.verify(token);
    request.user = decoded;
    next();

  } catch (error) {
    console.error('Token verification error:', error);
    return response
      .status(403)
      .json({ message: 'Token tidak valid atau sudah kadaluarsa.' });
  }
  
};


export const isAdmin = (request, response, next) => {
  const user = request.user;

  if (user.role !== 'admin') {
    return response
      .status(403)
      .json({ message: 'Akses ditolak. Anda bukan admin.' });
  }

  next();
}

