import { request, response } from 'express';
import {pool as db} from '../../config/database.js';
import { sqlClientErrors } from '../../utilts/sqlClientError.js';

const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    }).split('/').join('-');
};

export const bookingController = {
    createBooking: (request, response) => {
        const userId = request.user.id;
        const body = request.body

        const data = [
            userId,
            body.namaGedung,
            body.namaWo,
            body.tglAcara
        ]

        db.query('CALL CreateBooking(?, ?, ?, ?)', data, (error, result) => {
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
            console.log(result)

            return response 
                .status(201)        
                .json({ success: true, 
                        message: 'Pesanan berhasil dibuat, mohon melakukan pembayaran sebelum 24 jam', 
                        data: {
                            id_booking: hasilQuery.id_booking,
                            nama_gedung: hasilQuery.nama_gedung,
                            nama_wo: hasilQuery.nama_wo,
                            tgl_acara: formatDate(hasilQuery.tgl_acara),
                            deskripsi: hasilQuery.deskripsi,
                    }
                
                        })
                });
                },

    getBookingDetails: (request, response) => {
        const userId = request.user.id;
        const page = parseInt(request.query.page) || 1;
        const limit = 5;

        db.query('CALL GetBookingDetailsByUserId(?, ?, ?)', [userId, page, limit], (error, result) => {
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
            const hasilQuery = result[0];

            return response
                .status(200)
                .json({ success: true,
                        message: 'Berikut adalah detail pesanan anda', 
                        totalPesanan: hasilQuery.length,
                        data: hasilQuery.map((booking) => {
                            return {                                  
                                id_booking: booking.id_booking,
                                namaGedung: booking.nama_gedung,
                                namaWo: booking.nama_wo,
                                tglAcara: formatDate(booking.tgl_acara),
                                tglBooking: formatDate(booking.tgl_booking),
                                status: booking.status_pesanan,
                                deskripsi: booking.deskripsi,
                            }
                            
                        }),
                            page: page,
                            totalPage: Math.ceil(hasilQuery.length / limit),
                    });
        })


    },

    cancelBooking: (request, response) => {
        const idBooking = request.params.id;
        const userId = request.user.id;

        db.query('CALL CancelBooking(?, ?)', [idBooking, userId], (error, result) => {
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
                .json({ success: true,
                        message: 'Berhasil membatalkan pesanan', 
                    });
        })


    },


}