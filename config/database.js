import mysql from "mysql2";

export const pool = mysql.createConnection({
  host: 'localhost',
  user: 'dieefordii',
  password: 'dieforyou',
  database: 'ceremo2',
});
