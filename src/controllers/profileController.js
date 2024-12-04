import { request, response } from 'express';
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';

export const profileController = {
    editProfile: (request, response) => {
        const userId = request.user.id;
        const body = request.body;

        const data = [
            userId,
            body.nama,
            body.alamat,
            body.email,
        ]

        db.query('CALL EditProfile(?, ?, ?, ?)', data, (error, result) => {
            if (error) {
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
                .json({ success: true, message: 'Profile berhasil diupdate', data: result[0][0] });

        })
    },

    getProfile: (request, response) => {
        const userId = request.user.id;
        
        db.query('CALL GetPenggunaDetails(?)', [userId], (error, result) => {
            if (error) {
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
                .json({ success: true, data: result[0][0] });

        })
    
    }
}
