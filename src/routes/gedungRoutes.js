import express from 'express';
import { gedungController } from '../controllers/gedungController.js';
import { authenticateToken, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/gedung/page/:page', authenticateToken, gedungController.getGedung);
router.get('/gedung/', authenticateToken, gedungController.getGedung); //by name

//admin-only
router.put('/gedung/edit/:id', authenticateToken, isAdmin, gedungController.editGedung);
router.post('/gedung/add', authenticateToken, isAdmin, gedungController.addGedung);
router.delete('/gedung/delete/:id', authenticateToken, isAdmin, gedungController.deleteGedung);

export default router;