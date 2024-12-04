import { request, response } from 'express';
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';


export const paymentController = {
    createPayment: (request, response) => {
        const idBooking = request.params.id;
        const userId = request.user.id;

        db.query('CALL CreatePayment(?, ?)', [idBooking,userId], (error, result) => {
            if (error) {
                console.error('SQL Error:', error);
                const sqlErrorCode = error.sqlState;
                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    console.error('SQL Error:', error);
                    return response
                        .status(500)
                        .json({ success: false, message: 'Terjadi kesalahan pada server' });
                }
                return response
                    .status(400)
                    .json({ success: false, message: error.message });
            }

            return response
                .status(200)
                .json({ success: true, message: 'Pembayaran berhasil dibuat', data: result[0][0] });
        });
    },

}
