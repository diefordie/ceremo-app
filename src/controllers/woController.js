import { request, response } from 'express';
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';
import { toEditorSettings } from 'typescript';

const item_per_page = 10

export const woController = {
    getWo: (request, response) => {

        const page = parseInt(request.params.page)
        const offset = item_per_page * (page - 1)
        const name = request.query.name

        if (!name) {
            
        db.query('CALL GetAllWeddingOrganizer(?, ?)', [offset, item_per_page], (error, result) => {
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
                    message: 'Data wo berhasil didapatkan', 
                    data: hasilQuery, 
                    totalWo: hasilQuery.length 
                }); 

        })
    }
    db.query('CALL SearchWeddingOrganizerByName(?)', [name], (error, result) => {
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
                message: 'Data wo berhasil didapatkan', 
                data: hasilQuery, 
            }); 

    })

    
},
    addWo: (request, response) => {
        const body = request.body

        const data = [
            body.namaWo,
            body.harga_sewa,
            body.deskripsi,
        ]

        db.query('CALL AddWeddingOrganizer(?, ?, ?)', data, (error, result) => {
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
                .json({ success: true, message: 'Wo berhasil ditambahkan', data: result[0][0] });
        })
    },

    editWo: (request, response) => {
        const idWo = request.params.id
        const body = request.body

        const data = [
            idWo,
            body.namaWo,
            body.harga_sewa,
            body.deskripsi,
        ]

        db.query('CALL EditWeddingOrganizer(?, ?, ?, ?)', data, (error, result) => {
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
                .json({ success: true, message: 'Wo berhasil diupdate', data: result[0][0] });
        })
    },


}