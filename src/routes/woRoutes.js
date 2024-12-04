import express from 'express';
import { woController } from '../controllers/woController.js';
import { authenticateToken, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/wedding-organizer/page/:page', authenticateToken, woController.getWo);
router.get('/wedding-organizer/', authenticateToken, woController.getWo); //by name

//admin-only
router.put('/wedding-organizer/edit/:id', authenticateToken, isAdmin, woController.editWo);
router.post('/wedding-organizer/add', authenticateToken, isAdmin, woController.addWo);
//router.delete('/wedding-organizer/delete/:id', authenticateToken, woController.deleteWo);

export default router;