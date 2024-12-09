import express from 'express';
import { usersController } from '../controllers/usersController.js';
import { authenticateToken, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/users/:page', authenticateToken, isAdmin, usersController.getAllUsers);
router.get('/users/booking/:page', authenticateToken, isAdmin, usersController.getBookingAllUsers);

export default router;


