import express from 'express';
import { paymentController } from '../controllers/paymentController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/payment/create/:id', authenticateToken, paymentController.createPayment);

export default router;