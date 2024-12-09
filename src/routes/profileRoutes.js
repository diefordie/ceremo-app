import express from 'express';
import { profileController } from '../controllers/profileController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.put('/profile/update', authenticateToken, profileController.editProfile);
router.get('/profile', authenticateToken, profileController.getProfile);

export default router;

