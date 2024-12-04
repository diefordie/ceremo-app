import express from 'express';
import { profileController } from '../controllers/profileController.js';
import { authenticateToken, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.put('/profile/update', authenticateToken, profileController.editProfile);
router.get('/profile', authenticateToken, isAdmin, profileController.getProfile);

export default router;

