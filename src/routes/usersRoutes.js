import express from 'express';
import { usersController } from '../controllers/usersController.js';
import { authenticateToken, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/users/:page', authenticateToken, isAdmin, usersController.getAllUsers);

export default router;


