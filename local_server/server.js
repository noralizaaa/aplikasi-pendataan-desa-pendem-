const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const mysql = require('mysql2');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE"]
    }
});
const port = 3000;

// ==========================================
// PENGATURAN MODE PENYIMPANAN
// ==========================================
const STORAGE_MODE = 'mysql'; // Ganti ke 'json' jika tidak pakai XAMPP
// ==========================================

const DB_FILE = 'database.json';

// --- KONEKSI MYSQL ---
let db;
if (STORAGE_MODE === 'mysql') {
    db = mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'desa_db'
    });

    db.connect(err => {
        if (err) {
            console.error('--- GAGAL KONEKSI MYSQL ---');
        } else {
            console.log('Mode: MYSQL Aktif');
        }
    });
}

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));
app.use(express.static('public'));

const getCurrentPeriod = () => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
};

// --- SOCKET CONNECTION ---
io.on('connection', (socket) => {
    console.log('User Terhubung ke Dashboard Realtime');
    socket.on('disconnect', () => {
        console.log('User Terputus');
    });
});

// --- ENDPOINT GET (AMBIL DATA) ---
app.get('/api/submissions', (req, res) => {
    const { formId, userId } = req.query;

    if (STORAGE_MODE === 'mysql') {
        let query = 'SELECT id, content FROM submissions';
        let params = [];

        if (formId && userId) {
            query += ' WHERE formId = ? AND userId = ?';
            params = [formId, userId];
        } else if (formId) {
            query += ' WHERE formId = ?';
            params = [formId];
        } else if (userId) {
            query += ' WHERE userId = ?';
            params = [userId];
        }

        db.query(query, params, (err, results) => {
            if (err) return res.status(500).send(err);
            let submissions = results.map(r => {
                let data = typeof r.content === 'string' ? JSON.parse(r.content) : r.content;
                data.id = r.id;
                return data;
            });
            res.status(200).json(submissions);
        });
    } else {
        if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, '[]');
        let allData = JSON.parse(fs.readFileSync(DB_FILE));
        let filtered = allData;
        if (formId) filtered = filtered.filter(s => s.formId === formId);
        if (userId) filtered = filtered.filter(s => s.userId === userId);
        res.status(200).json(filtered);
    }
});

// --- ENDPOINT POST (SIMPAN) ---
app.post('/api/submissions', (req, res) => {
    const data = req.body;
    const id = data.id || `LOCAL_${Date.now()}`;
    const period = data.period || getCurrentPeriod();

    if (STORAGE_MODE === 'mysql') {
        db.query('INSERT INTO submissions (id, formId, userId, period, content) VALUES (?, ?, ?, ?, ?)',
        [id, data.formId, data.userId, period, JSON.stringify(data)], (err) => {
            if (err) return res.status(500).send(err);
            io.emit('data-updated', { type: 'create', data: data }); // NOTIFIKASI REALTIME
            res.status(201).send({ message: "Tersimpan!", id: id });
        });
    } else {
        let allData = JSON.parse(fs.readFileSync(DB_FILE));
        allData.push({ ...data, id: id });
        fs.writeFileSync(DB_FILE, JSON.stringify(allData, null, 2));
        io.emit('data-updated', { type: 'create', data: data }); // NOTIFIKASI REALTIME
        res.status(201).send({ message: "Tersimpan!", id: id });
    }
});

app.put('/api/submissions/:id', (req, res) => {
    if (STORAGE_MODE === 'mysql') {
        db.query('UPDATE submissions SET content = ? WHERE id = ?', [JSON.stringify(req.body), req.params.id], (err) => {
            if (err) return res.status(500).send(err);
            io.emit('data-updated', { type: 'update', id: req.params.id }); // NOTIFIKASI REALTIME
            res.status(200).send({ message: "Updated!" });
        });
    } else {
        let allData = JSON.parse(fs.readFileSync(DB_FILE));
        const index = allData.findIndex(s => s.id === req.params.id);
        if (index !== -1) {
            allData[index] = { ...allData[index], ...req.body };
            fs.writeFileSync(DB_FILE, JSON.stringify(allData, null, 2));
            io.emit('data-updated', { type: 'update', id: req.params.id }); // NOTIFIKASI REALTIME
            res.status(200).send({ message: "Updated!" });
        } else {
            res.status(404).send("Not Found");
        }
    }
});

app.delete('/api/submissions/:id', (req, res) => {
    if (STORAGE_MODE === 'mysql') {
        db.query('DELETE FROM submissions WHERE id = ?', [req.params.id], (err) => {
            if (err) return res.status(500).send(err);
            io.emit('data-updated', { type: 'delete', id: req.params.id }); // NOTIFIKASI REALTIME
            res.status(200).send({ message: "Deleted!" });
        });
    } else {
        let allData = JSON.parse(fs.readFileSync(DB_FILE));
        const filtered = allData.filter(s => s.id !== req.params.id);
        fs.writeFileSync(DB_FILE, JSON.stringify(filtered, null, 2));
        io.emit('data-updated', { type: 'delete', id: req.params.id }); // NOTIFIKASI REALTIME
        res.status(200).send({ message: "Deleted!" });
    }
});

const upload = multer({ storage: multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
})});
app.post('/api/upload', upload.single('image'), (req, res) => {
    res.status(200).send({ imageUrl: `http://${req.hostname}:3000/uploads/${req.file.filename}` });
});

server.listen(port, '0.0.0.0', () => {
    console.log(`Server Realtime Jalan di Port ${port}`);
});
