import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';

const item_per_page = 10

export const usersController = {
    getAllUsers: (request, response) => {

        const page = parseInt(request.params.page)
        const offset = item_per_page * (page - 1)
        const name = request.query.name

        if (!name) {
            db.query('CALL GetAllUsers(?, ?)',[offset, item_per_page], (error, result) => {
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
                const hasilQuery = result[0]
    
                return response
                    .status(200)
                    .json({ success: true,message: 'Data pengguna berhasil didapatkan', data: hasilQuery, totalUsers: hasilQuery.length, page: page });
            })
        }
        else {
            db.query('CALL GetAllUsers(?, ?)',[offset, item_per_page], (error, result) => {
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
                const hasilQuery = result[0]
    
                return response
                    .status(200)
                    .json({ success: true,message: 'Data pengguna berhasil didapatkan', data: hasilQuery, totalUsers: hasilQuery.length, page: page });
            })

        }


        
    },

    getBookingAllUsers: (request, response) => {

        const page = parseInt(request.params.page)
        const offset = item_per_page * (page - 1)
        const status = request.query.status


        if (!status) {
            db.query('CALL GetAllDetailBooking(?, ?)',[page, item_per_page], (error, result) => {
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
                const hasilQuery = result[0]
    
                return response
                    .status(200)    
                    .json({ success: true, message: 'Data booking pengguna berhasil didapatkan', data: hasilQuery, totalBooking: hasilQuery.length, page: page });
            })

        }
        else {
            db.query('CALL GetDetailBookingByStatus(?, ?, ?)',[page, item_per_page, status], (error, result) => {
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
                const hasilQuery = result[0]
    
                return response
                    .status(200)    
                    .json({ success: true, message: 'Data booking pengguna berhasil didapatkan', data: hasilQuery, totalBooking: hasilQuery.length, page: page });
            })

        }
        
    },
}