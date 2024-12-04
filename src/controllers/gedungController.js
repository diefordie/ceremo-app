import { request, response } from 'express';
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';

const item_per_page = 10

export const gedungController = {
    getGedung: (request, response) => {
        
        const page = parseInt(request.params.page)
        const offset = item_per_page * (page - 1)
        const name = request.query.name

        if (!name) {
            db.query('CALL GetAllGedung(?, ?)', [offset, item_per_page],(error, result) => {
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
                    .json({ 
                        success: true, 
                        message: 'Data gedung berhasil didapatkan',
                        data: hasilQuery,
                        totalGedung: hasilQuery.length,
                        page: page,
                    });
            })
        }
        db.query('CALL SearchGedungByName(?)', [name],(error, result) => {
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
                .json({ 
                    success: true, 
                    message: 'Data gedung berhasil didapatkan',
                    data: hasilQuery,
                    totalGedung: hasilQuery.length,
                });
        })
        
    },

    addGedung: (request, response) => {
        const body = request.body
        const data = [
            body.namaGedung,
            body.hargaSewa,
            body.kapasitas,
            body.lokasi
        ]
        db.query('CALL AddGedung(?, ?, ?, ?)', data, (error, result) => {
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
                .json({ success: true, message: 'Gedung berhasil ditambahkan', data: result[0][0] });
            })
            
        },

    editGedung: (request, response) => {
        const idGedung = request.params.id
        const body = request.body
        const data = [
            idGedung,
            body.namaGedung,
            body.hargaSewa,
            body.kapasitas,
            body.lokasi
        ]
        db.query('CALL EditGedung(?, ?, ?, ?, ?)', data, (error, result) => {
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
                .json({ success: true, message: 'Gedung berhasil diupdate', data: result[0][0] });
        })
    },

    deleteGedung: (request, response) => {
        const idGedung = request.params.id

        db.query('CALL DeleteGedung(?)', [idGedung], (error, result) => {
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
                .json({ success: true, message: 'Gedung berhasil dihapus' });
        })
    }
}