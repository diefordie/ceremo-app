import express from 'express';
import { bookingController } from '../controllers/bookingController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/booking/create', authenticateToken, bookingController.createBooking);
router.get('/booking/details/:page', authenticateToken, bookingController.getBookingDetails);
router.delete('/booking/cancel/:id', authenticateToken, bookingController.cancelBooking);

export default router;
