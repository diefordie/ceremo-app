
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';
import { jwt } from '../services/jwt.js';

export const authController = {
    register: (request, response) => {
        const body = request.body

        const data = [
            body.nama,
            body.alamat,
            body.email,
            body.password,
        ]

        db.query(
            'CALL RegisterUser(?, ?, ?, ?)', data, (error, result) => {
                if (error) {
                    const sqlErrorCode = error.sqlState;
                    if (!sqlClientErrors.includes(sqlErrorCode)) {
                        return response
                            .status(500)
                            .json({ success: false, message: 'Terjadi kesalahan pada server' });
                    }
                    return response
                        .status(400)
                        .json({ success: false, message: error.message });
                }

                return response
                    .status(201)
                    .json({ success: true, message: 'Akun berhasil dibuat' , data: result[0][0] });
            })

    },

    login: (request, response) => {
        const body = request.body

        const data = [
            body.email,
            body.password,
        ]

        db.query('CALL LoginUser(?,?)', data, (error, result) => {
            if (error) {
                console.error('SQL Error:', error);
                const sqlErrorCode = error.sqlState;
                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response
                        .status(500)
                        .json({ success: false, message: 'Terjadi kesalahan pada server' });
                }
                return response
                    .status(400)
                    .json({ success: false, message: error.message });
            }

            const hasilQuery = result[0][0];

            response.cookie(
              'token', 
              jwt.sign(hasilQuery),{  
                maxAge: 3_600 * 1000
              })

            return response
                .status(200)
                .json({ success: true, message: `Login Berhasil! Selamat Datang ${result[0][0].nama}`, data: hasilQuery });
        })
    }
}