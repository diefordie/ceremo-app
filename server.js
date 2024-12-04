import express from 'express';
import cookieParser from 'cookie-parser';
import authRoutes from './src/routes/authRoutes.js';
import profileRoutes from './src/routes/profileRoutes.js';
import bookingRoutes from './src/routes/bookingRoutes.js';
import gedungRoutes from './src/routes/gedungRoutes.js';
import woRoutes from './src/routes/woRoutes.js';
import paymentRoutes from './src/routes/paymentRoutes.js';
// Import rute lain di sini

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Routes
app.use('/auth', authRoutes);
app.use('/api', profileRoutes);
app.use('/api', bookingRoutes);
app.use('/api', gedungRoutes);
app.use('/api', woRoutes);
app.use('/api', paymentRoutes);
// Gunakanprofile rute lain di sini

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Ooppsie!Terjadi kesalahan!');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});

export default app;