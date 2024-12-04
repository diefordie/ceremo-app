USE ceremo2;

CREATE USER 'dieefirdii'@'localhost' IDENTIFIED BY 'dieforyou';
GRANT EXECUTE ON ceremo2.* TO 'dieefordii'@'localhost';

flush privileges;

--    CREATE TABLE

    CREATE TABLE Pengguna (
        id_pengguna INT AUTO_INCREMENT PRIMARY KEY,
        nama VARCHAR(100) NOT NULL,
        alamat TEXT NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL
    );


INSERT INTO Pengguna (nama, alamat, email, password, role) VALUES ('Admin', 'Jl. Jend. Sudirman No. 1', 'adminku@ceremo.com', SHA2('adminlalala', 256), 'admin');

SHOW CREATE TABLE Pengguna;


    CREATE TABLE Gedung (
        id_gedung INT AUTO_INCREMENT PRIMARY KEY,
        harga_sewa DECIMAL(10, 2) NOT NULL,
        kapasitas INT NOT NULL,
        lokasi VARCHAR(100) NOT NULL,
        status ENUM('available', 'booked') NOT NULL,
        nama_gedung VARCHAR(100) NOT NULL
    );

    CREATE TABLE Wedding_Organizer (
        id_wo INT AUTO_INCREMENT PRIMARY KEY,
        nama_wo VARCHAR(100) NOT NULL,
        harga_paket DECIMAL(10, 2) NOT NULL,
        deskripsi TEXT
    );

    CREATE TABLE Booking (
        id_booking INT AUTO_INCREMENT PRIMARY KEY,
        id_pengguna INT,
        id_gedung INT,
        id_wo INT,
        tgl_acara DATE NOT NULL,
        tgl_booking DATE NOT NULL,
        status_pesanan ENUM('pending', 'confirmed', 'cancelled') NOT NULL,
        deskripsi TEXT,
        FOREIGN KEY (id_pengguna) REFERENCES Pengguna(id_pengguna),
        FOREIGN KEY (id_gedung) REFERENCES Gedung(id_gedung),
        FOREIGN KEY (id_wo) REFERENCES Wedding_Organizer(id_wo)
    );

    ALTER TABLE Booking
ADD COLUMN deskripsi TEXT DEFAULT 'Tidak ada deskripsi';

    CREATE TABLE Payment (
        id_pembayaran INT AUTO_INCREMENT PRIMARY KEY,
        id_booking INT,
        harga_paket DECIMAL(10, 2) NOT NULL,
        deskripsi TEXT,
        FOREIGN KEY (id_booking) REFERENCES Booking(id_booking)
    );


--    TRIGGER

DELIMITER //

CREATE TRIGGER update_booking_description
BEFORE UPDATE ON Booking
FOR EACH ROW
BEGIN
    IF NEW.status_pesanan != OLD.status_pesanan THEN
        CASE NEW.status_pesanan
            WHEN 'confirmed' THEN
                SET NEW.deskripsi = 'Pesanan telah dikonfirmasi. Silakan lanjut ke tahap pembayaran.';
            WHEN 'pending' THEN
                SET NEW.deskripsi = 'Pesanan sedang diproses. Mohon tunggu konfirmasi dari kami.';
            WHEN 'cancelled' THEN
                SET NEW.deskripsi = 'Pesanan telah dibatalkan.';
            ELSE
                SET NEW.deskripsi = CONCAT('Status pesanan telah diubah menjadi ', NEW.status_pesanan);
        END CASE;
    END IF;
END//

DELIMITER ;

-- trigger ketika booking cancelled maka pembayaran dihapus
DELIMITER //

CREATE or replace TRIGGER AfterUpdateBookingStatus
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
    IF NEW.status_pesanan = 'cancelled' THEN
        UPDATE Payment
        SET is_deleted = TRUE, deleted_at = NOW()
        WHERE id_booking = NEW.id_booking;
    END IF;
END //

DELIMITER ;


DELIMITER //

CREATE or replace TRIGGER after_booking_confirmed
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
    DECLARE v_harga_paket DECIMAL(10,2);
    DECLARE v_deskripsi TEXT;

    IF NEW.status_pesanan = 'confirmed' THEN
        -- Hitung harga paket menggunakan function
        SET v_harga_paket = CalculatePackagePrice(NEW.id_wo, NEW.id_gedung);

        -- Buat deskripsi
        SELECT CONCAT('Transaksi oleh ', p.nama, ' kepada ', wo.nama_wo, ' dan ', g.nama_gedung)
        INTO v_deskripsi
        FROM Pengguna p
        JOIN Wedding_Organizer wo ON wo.id_wo = NEW.id_wo
        JOIN Gedung g ON g.id_gedung = NEW.id_gedung
        WHERE p.id_pengguna = NEW.id_pengguna;

        -- Insert ke Payment
        INSERT INTO Payment (id_booking, harga_paket, deskripsi)
        VALUES (NEW.id_booking, v_harga_paket, v_deskripsi);
    END IF;
END //

DELIMITER ;

CREATE TRIGGER delete_payment_on_cancel
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
  IF NEW.status_pesanan = 'cancelled' THEN
    DELETE FROM Payment WHERE id_booking = NEW.id_booking;
  END IF;
END




-- PROCEDURE

DELIMITER //

CREATE OR REPLACE PROCEDURE RegisterUser(
    IN p_nama VARCHAR(100),
    IN p_alamat TEXT,
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE email_exists BOOLEAN;

    START TRANSACTION;

    -- Cek apakah email sudah ada di dalam tabel
    SELECT EXISTS (
        SELECT 1 FROM Pengguna 
        WHERE email = p_email
        LIMIT 1
    ) INTO email_exists;

    IF email_exists THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email sudah terdaftar';
    ELSE
        -- Jika email belum terdaftar, lakukan insert dengan password yang di-hash
        INSERT INTO Pengguna (nama, alamat, email, password)
        VALUES (p_nama, p_alamat, p_email, SHA2(p_password, 256));

        -- Mengembalikan ID pengguna yang baru didaftarkan
        SELECT LAST_INSERT_ID() AS userId;
    END IF;

    COMMIT;
END

CREATE OR REPLACE PROCEDURE LoginUser(
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255)
)
BEGIN
    -- Deklarasi variabel
    DECLARE db_password VARCHAR(255); -- Variabel untuk menyimpan password dari tabel
    DECLARE user_id INT;
    DECLARE user_name VARCHAR(100);
    DECLARE _role VARCHAR(100);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validasi email
    IF INSTR(p_email, '@') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tolong Masukkan Email yang valid';
    END IF;

    -- Validasi password
    IF LENGTH(p_password) < 6 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password harus memiliki minimal 6 karakter';
    END IF;

    -- Cek apakah email ada di dalam tabel
    SELECT id_pengguna, nama, password, role
    INTO user_id, user_name, db_password, _role
    FROM Pengguna
    WHERE email = p_email
    LIMIT 1;

    IF db_password IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email tidak terdaftar';
    END IF;

    -- Verifikasi password
    IF db_password != SHA2(p_password, 256) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email atau password tidak valid';
    END IF;

    -- Jika login berhasil, kembalikan data pengguna
    SELECT user_id AS 'id', user_name AS 'nama', p_email AS 'email', _role AS 'role';

    COMMIT;
END;




CREATE or replace PROCEDURE EditProfile(
    IN p_id_pengguna INT,
    IN p_nama VARCHAR(100),
    IN p_alamat TEXT,
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validasi email
    IF INSTR(p_email, '@') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tolong Masukkan Email yang valid';
    END IF;
    
    UPDATE Pengguna
    SET
        nama = p_nama,
        alamat = p_alamat,
        email = p_email
    WHERE id_pengguna = p_id_pengguna;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengguna tidak ditemukan';
    ELSE

    SELECT nama, alamat, email
    FROM Pengguna
    WHERE id_pengguna = p_id_pengguna;
        COMMIT;
    END IF;
END//

DELIMITER //

CREATE or replace PROCEDURE EditGedung(
    IN p_id_gedung INT,
    IN p_nama_gedung VARCHAR(100),
    IN p_harga_sewa DECIMAL(10, 2),
    IN p_kapasitas INT,
    IN p_lokasi VARCHAR(100)
    
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE Gedung
    SET
        harga_sewa = p_harga_sewa,
        kapasitas = p_kapasitas,
        lokasi = p_lokasi,
        nama_gedung = p_nama_gedung
    WHERE id_gedung = p_id_gedung;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Gedung tidak ditemukan';
    ELSE
        SELECT nama_gedung, harga_sewa, kapasitas, lokasi
        FROM Gedung
        WHERE id_gedung = p_id_gedung;
        COMMIT;
    END IF;
END//

DELIMITER //

CREATE or replace PROCEDURE EditWeddingOrganizer(
    IN p_id_wo INT,
    IN p_nama_wo VARCHAR(100),
    IN p_harga_paket DECIMAL(10, 2),
    IN p_deskripsi TEXT
)
BEGIN
    START TRANSACTION;

    UPDATE Wedding_Organizer
    SET
        nama_wo = p_nama_wo,
        harga_paket = p_harga_paket,
        deskripsi = p_deskripsi
    WHERE id_wo = p_id_wo;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Wedding Organizer tidak ditemukan';
    ELSE
        SELECT id_wo, nama_wo, harga_paket, deskripsi
        FROM Wedding_Organizer
        WHERE id_wo = p_id_wo;
        COMMIT;
    END IF;
END



CREATE or replace PROCEDURE AddGedung(
    IN p_nama_gedung VARCHAR(100),
    IN p_harga_sewa DECIMAL(10, 2),
    IN p_kapasitas INT,
    IN p_lokasi VARCHAR(100)
    
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Gedung (harga_sewa, kapasitas, lokasi, nama_gedung)
    VALUES (p_harga_sewa, p_kapasitas, p_lokasi, p_nama_gedung);

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Gagal menambahkan gedung';
    ELSE
        SELECT nama_gedung, harga_sewa, kapasitas, lokasi
        FROM Gedung
        WHERE id_gedung = LAST_INSERT_ID();
        COMMIT;
    END IF;
END

DELIMITER //

CREATE OR REPLACE PROCEDURE DeleteGedung(
    IN p_id_gedung INT
)
BEGIN
    DECLARE gedung_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Periksa apakah gedung ada
    SELECT COUNT(id_gedung) INTO gedung_exists FROM Gedung WHERE id_gedung = p_id_gedung;

    IF gedung_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Gagal menghapus gedung, gedung tidak ditemukan';
    ELSE
        -- Periksa apakah ada booking yang terkait
        IF EXISTS (SELECT 1 FROM Booking WHERE id_gedung = p_id_gedung) THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gagal menghapus gedung, gedung sedang digunakan';
        ELSE
            DELETE FROM Gedung WHERE id_gedung = p_id_gedung;
            COMMIT;
        END IF;
    END IF;
END//


CREATE or replace PROCEDURE AddWeddingOrganizer(
    IN p_nama_wo VARCHAR(100),
    IN p_harga_paket DECIMAL(10, 2),
    IN p_deskripsi TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Wedding_Organizer (nama_wo, harga_paket, deskripsi)
    VALUES (p_nama_wo, p_harga_paket, p_deskripsi);

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Gagal menambahkan Wedding Organizer';
    ELSE
        SELECT id_wo, nama_wo, harga_paket, deskripsi
        FROM Wedding_Organizer
        WHERE id_wo = LAST_INSERT_ID();
        COMMIT;
    END IF;
END//

DELIMITER ;

DELIMITER //

CREATE PROCEDURE DeleteWeddingOrganizer(
    IN p_id_wo INT,
    OUT p_result VARCHAR(255)
)
BEGIN
    DECLARE wo_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = CONCAT('Error: ', SQLERRM);
    END;

    START TRANSACTION;

    -- Periksa apakah WO ada
    SELECT COUNT(*) INTO wo_exists FROM Wedding_Organizer WHERE id_wo = p_id_wo;

    IF wo_exists = 0 THEN
        SET p_result = 'Error: Wedding Organizer tidak ditemukan';
        ROLLBACK;
    ELSE
        -- Periksa apakah ada booking yang terkait
        IF EXISTS (SELECT 1 FROM Booking WHERE id_wo = p_id_wo) THEN
            SET p_result = 'Error: Tidak dapat menghapus Wedding Organizer karena masih ada booking terkait';
            ROLLBACK;
        ELSE
            DELETE FROM Wedding_Organizer WHERE id_wo = p_id_wo;
            SET p_result = 'Wedding Organizer berhasil dihapus';
            COMMIT;
        END IF;
    END IF;
END //

DELIMITER ;


CREATE or REPLACE PROCEDURE UpdateBookingStatus(
    IN p_id_booking INT,
    IN p_status ENUM('pending', 'confirmed', 'cancelled')
)
BEGIN
    START TRANSACTION;

    UPDATE Booking
    SET status_pesanan = p_status
    WHERE id_booking = p_id_booking;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking tidak ditemukan';
    ELSE
        COMMIT;
    END IF;
END

DELIMITER //

CREATE OR REPLACE PROCEDURE CreateBooking(
    IN p_id_pengguna INT,
    IN p_nama_gedung VARCHAR(100),
    IN p_nama_wo VARCHAR(100),
    IN p_tgl_acara DATE
)
BEGIN
    DECLARE p_id_gedung INT DEFAULT NULL;
    DECLARE p_id_wo INT DEFAULT NULL;
    DECLARE booking_exists INT;
    DECLARE p_tgl_booking DATE;
    DECLARE new_booking_id INT;
    DECLARE p_deskripsi TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Set tanggal booking ke waktu saat ini
    SET p_tgl_booking = CURDATE();
    SET p_deskripsi = 'Pesanan ini sedang diproses';

    START TRANSACTION;
    
    -- Mencari id_gedung berdasarkan nama_gedung
    SELECT id_gedung INTO p_id_gedung
    FROM Gedung
    WHERE nama_gedung = p_nama_gedung;
    
    -- Check if gedung was found
    IF p_id_gedung IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Nama gedung tidak ditemukan.';
    END IF;

    -- Mencari id_wo berdasarkan nama_wo
    SELECT id_wo INTO p_id_wo
    FROM Wedding_Organizer
    WHERE nama_wo = p_nama_wo;
    
    -- Check if wedding organizer was found
    IF p_id_wo IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Nama wedding organizer tidak ditemukan.';
    END IF;

    -- Memeriksa apakah gedung sudah dibooking pada tanggal yang sama
    SELECT COUNT(id_booking) INTO booking_exists
    FROM Booking
    WHERE id_gedung = p_id_gedung AND tgl_acara = p_tgl_acara;

    IF booking_exists > 0 THEN
        -- Jika gedung sudah dibooking, batalkan transaksi
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Gedung sudah dibooking pada tanggal ini';
    ELSE
        -- Jika gedung belum dibooking, masukkan ke tabel Booking
        INSERT INTO Booking (id_pengguna, id_gedung, id_wo, tgl_acara, tgl_booking, status_pesanan, deskripsi)
        VALUES (p_id_pengguna, p_id_gedung, p_id_wo, p_tgl_acara, p_tgl_booking, 'pending', p_deskripsi);

        -- Dapatkan ID booking yang baru dibuat
        SET new_booking_id = LAST_INSERT_ID();

        COMMIT;

        -- Return the new booking details
        SELECT 
            new_booking_id AS id_booking,
            p_nama_gedung AS nama_gedung,
            p_nama_wo AS nama_wo,
            p_tgl_acara AS tgl_acara,
            p_deskripsi AS deskripsi;
    END IF;
END;


CREATE or REPLACE PROCEDURE CreatePayment(
    IN p_id_booking INT,
    IN p_id_pengguna INT
)
BEGIN
    DECLARE booking_exists INT;
    DECLARE p_id_wo INT;
    DECLARE p_id_gedung INT;
    DECLARE p_harga_paket DECIMAL(10, 2);
    DECLARE p_deskripsi TEXT;
    DECLARE p_status_pesanan VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Cek apakah pesanan sudah ada, milik pengguna yang benar, dan statusnya
    SELECT COUNT(*), id_wo, id_gedung, status_pesanan 
    INTO booking_exists, p_id_wo, p_id_gedung, p_status_pesanan
    FROM Booking
    WHERE id_booking = p_id_booking AND id_pengguna = p_id_pengguna;

    IF booking_exists = 0 THEN
        -- Jika pesanan tidak ada atau bukan milik pengguna, batalkan transaksi
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pesanan tidak ditemukan atau bukan milik pengguna ini';
    ELSEIF p_status_pesanan != 'confirmed' THEN
        -- Jika pesanan belum dikonfirmasi, batalkan transaksi
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pesanan belum dikonfirmasi. Pembayaran tidak dapat diproses';
    ELSE
        -- Hitung harga paket menggunakan fungsi CalculatePackagePrice
        SET p_harga_paket = CalculatePackagePrice(p_id_wo, p_id_gedung);
        
        -- Buat deskripsi otomatis
        SET p_deskripsi = CONCAT('Pembayaran untuk booking ID ', p_id_booking, ' dengan total harga ', p_harga_paket);

        -- Jika pesanan valid dan confirmed, masukkan pembayaran
        INSERT INTO Payment (id_booking, harga_paket, deskripsi)
        VALUES (p_id_booking, p_harga_paket, p_deskripsi);

        -- Commit transaksi jika semua berhasil
        COMMIT;
        
        -- Return informasi pembayaran
        SELECT 
            p_id_booking AS id_booking,
            p_harga_paket AS harga_paket,
            p_deskripsi AS deskripsi;
    END IF;
END;

CREATE or REPLACE PROCEDURE CancelBooking(
    IN p_id_booking INT,
    IN p_id_pengguna INT
)
BEGIN
    DECLARE booking_status ENUM('pending', 'confirmed', 'cancelled');
    DECLARE booking_owner INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Cek apakah pesanan ada, dapatkan statusnya, dan verifikasi pemiliknya
    SELECT status_pesanan, id_pengguna 
    INTO booking_status, booking_owner
    FROM Booking
    WHERE id_booking = p_id_booking;

    IF booking_status IS NULL THEN
        -- Jika pesanan tidak ada, batalkan transaksi
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pesanan yang anda maksud tidak ada';
    ELSEIF booking_owner != p_id_pengguna THEN
        -- Jika id_pengguna tidak cocok, batalkan transaksi
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Maaf, harap masukkan id booking dengan benar';
    ELSEIF booking_status = 'confirmed' THEN
        -- Jika status pesanan sudah confirmed, batalkan transaksi
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pesanan yang sudah dikonfirmasi tidak dapat dibatalkan';
    ELSE
        -- Jika pesanan ada, milik pengguna yang benar, dan statusnya pending, hapus booking
        DELETE FROM Booking
        WHERE id_booking = p_id_booking AND id_pengguna = p_id_pengguna;

        -- Periksa apakah penghapusan berhasil
        IF ROW_COUNT() = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gagal membatalkan pesanan';
        ELSE
            -- Commit transaksi jika semua berhasil
            COMMIT;
        END IF;
    END IF;
END;



DELIMITER //

CREATE OR REPLACE PROCEDURE GetAllGedung(
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_gedung, nama_gedung, harga_sewa, kapasitas, lokasi
    FROM Gedung
    ORDER BY id_gedung
    LIMIT p_offset, p_limit;

    COMMIT;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE SearchGedungByName(
    IN p_nama_gedung VARCHAR(100)
)
BEGIN
    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT 
        id_gedung,
        nama_gedung,
        harga_sewa,
        kapasitas,
        lokasi
    FROM 
        Gedung
    WHERE 
        nama_gedung LIKE CONCAT('%', p_nama_gedung, '%');

    COMMIT;
END //

DELIMITER ;

CREATE PROCEDURE SearchWeddingOrganizerByName(
    IN p_nama_wo VARCHAR(100)
)
BEGIN
    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT 
        id_wo ,
        nama_wo ,
        harga_paket ,
        deskripsi
    FROM 
        Wedding_Organizer
    WHERE 
        nama_wo LIKE CONCAT('%', p_nama_wo, '%');

    COMMIT;
END //

DELIMITER ;


DELIMITER //

CREATE OR REPLACE PROCEDURE GetAllWeddingOrganizer(
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_wo, nama_wo, harga_paket 
    FROM Wedding_Organizer
    ORDER BY id_wo
    LIMIT p_offset, p_limit;

    COMMIT;
END //

DELIMITER ;

-- Procedure to retrieve nama, alamat, and email from the Pengguna table
DELIMITER //

CREATE OR REPLACE PROCEDURE GetPenggunaDetails(
    IN p_id_pengguna INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_pengguna, nama, email 
    FROM Pengguna
    WHERE id_pengguna = p_id_pengguna;

    COMMIT;
END

CREATE or replace PROCEDURE GetBookingDetailsByUserId(
    IN p_user_id INT,
    IN p_page INT,
    IN p_limit INT
)
BEGIN
    DECLARE offset_val INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET offset_val = (p_page - 1) * p_limit;

    START TRANSACTION;

    -- Get total count
    SELECT COUNT(id_booking) INTO @total_count
    FROM Booking
    WHERE id_pengguna = p_user_id;

    -- Get paginated results
    SELECT 
        b.id_booking,
        g.nama_gedung,
        wo.nama_wo,
        b.tgl_acara,
        b.tgl_booking,
        b.status_pesanan,
        b.deskripsi
    FROM 
        Booking b
    JOIN 
        Gedung g ON b.id_gedung = g.id_gedung
    JOIN 
        Wedding_Organizer wo ON b.id_wo = wo.id_wo
    WHERE 
        b.id_pengguna = p_user_id
    ORDER BY 
        b.tgl_booking DESC
    LIMIT p_limit OFFSET offset_val;

    -- Return total count
    SELECT @total_count AS total_count;

    COMMIT;
END

DELIMITER ;
CREATE OR REPLACE PROCEDURE GetEmailPengguna(
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_pengguna, email, password
    FROM Pengguna
    WHERE email = p_email;

    COMMIT;
END //


DELIMITER ;

-- FUNCTION 
CREATE FUNCTION IsGedungAvailable(p_id_gedung INT, p_tgl_acara DATE)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE availability_status VARCHAR(20);

    SELECT 
        CASE 
            WHEN COUNT(1) = 0 THEN 'Tersedia'
            ELSE 'Tidak Tersedia'
        END INTO availability_status
    FROM 
        Booking
    WHERE 
        id_gedung = p_id_gedung
        AND tgl_acara = p_tgl_acara
        AND status_pesanan = 'confirmed';
    
    RETURN availability_status;
END;


DELIMITER //

CREATE FUNCTION CalculatePackagePrice(p_id_wo INT, p_id_gedung INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_price DECIMAL(10,2);
    
    SELECT wo.harga_paket + g.harga_sewa INTO total_price
    FROM Wedding_Organizer wo
    JOIN Gedung g ON g.id_gedung = p_id_gedung
    WHERE wo.id_wo = p_id_wo;
    
    RETURN COALESCE(total_price, 0);
END //

DELIMITER ;


-- VIEW
CREATE VIEW View_Booking_Details AS
SELECT 
    b.id_booking,
    p.nama AS nama_pengguna,
    g.nama_gedung,
    wo.nama_wo,
    b.tgl_acara,
    b.tgl_booking,
    b.status_pesanan
FROM 
    Booking b
JOIN 
    Pengguna p ON b.id_pengguna = p.id_pengguna
JOIN 
    Gedung g ON b.id_gedung = g.id_gedung
JOIN 
    Wedding_Organizer wo ON b.id_wo = wo.id_wo;

CREATE VIEW View_Transaction_Details AS
SELECT 
    p.id_pembayaran,
    b.id_booking,
    pengguna.nama AS nama_pengguna,
    p.harga_paket,
    p.deskripsi
FROM 
    Payment p
JOIN 
    Booking b ON p.id_booking = b.id_booking
JOIN 
    Pengguna pengguna ON b.id_pengguna = pengguna.id_pengguna;



====== PER USECASE ======
-- 1. Register User
CALL RegisterUser("Desti Nur Irawati", "Jl. Gunung Bakaran", "desti@gmail.com", "123456");
CALL GetPenggunaDetails();


-- 2. Login User
SELECT LoginUser("dhiee@gmail.com", "123456") ;

-- 3. Edit Profile
call GetPenggunaDetails();
CALL EditPengguna(6, 'Frieza Sadira', 'Jl. Swadaya', 'eja5432@gmail.com');

-- 4. Lihat Detail Pesanan
SELECT * FROM View_Booking_Details;

-- 5. Cancel Pesanan
SELECT * FROM View_Booking_Details;
CALL UpdateBookingStatus(36, 'confirmed');

-- 6. Melakukan Pembayaran
CALL CreatePayment(1, 6000.00, 'Pembayaran untuk paket pernikahan');

-- 7. Menambahkan Gedung yang tersedia
CALL AddGedung (2000.00, 150, 'Jalan Kebangsaan No. 5', 'available', 'Gedung Indah');

-- 8. Mengubah detail gedung
CALL GetAllGedung();
CALL EditGedung(1, 150000, 100, 'Jalan Raya No. 1', 'available', 'Gedung Goku');

-- 9. Menambahkan Wedding Organizer
CALL AddWeddingOrganizer('Wedding Planner B', 6000.00, 'Paket eksklusif untuk pernikahan');

-- 10. Mengubah detail Wedding Organizer
CALL GetAllWeddingOrganizer();
CALL EditWeddingOrganizer(1, 'Wedding Organizer Sadira', 5000.00, 'Paket lengkap untuk pernikahan');

-- 11. Membuat Pesanan
CALL GetPenggunaDetails(1);
CALL GetAllGedung();
CALL CreateBooking("Ardhi Iwantara Saputra", "Gedung Sudirman Jaya", "Wedding Organizer Sadira", '2024-11-12', '2024-10-24');


ALTER TABLE Pengguna
ADD COLUMN role ENUM('user', 'admin') NOT NULL DEFAULT 'user';

