const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

// Carga la JSON de cuenta de servicio que subiste al backend
const serviceAccount = require('./keypocket-61ec3-firebase-adminsdk-fbsvc-5f2e62382d.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

const app = express();
const PORT = process.env.PORT || 3000;
app.use(cors()); // en pruebas permite todo; en producción restringe orígenes
app.use(express.json());

// Middleware: verifica Firebase ID Token (Bearer <token>)
async function verifyToken(req, res, next) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) return res.status(401).json({ error: 'No token' });
  const idToken = auth.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

// Endpoints ejemplos
app.get('/api/saludo', (req, res) => res.json({ mensaje: '¡Hola desde tu API Node.js!' }));

app.get('/api/categories', verifyToken, async (req, res) => {
  try {
    const snap = await db.collection('users').doc(req.uid).collection('categories').orderBy('name').get();
    const categories = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json(categories);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/categories', verifyToken, async (req, res) => {
  try {
    const { name } = req.body;
    const ref = await db.collection('users').doc(req.uid).collection('categories').add({ name, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    const doc = await ref.get();
    res.status(201).json({ id: doc.id, ...doc.data() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/categories/:categoryId/credentials', verifyToken, async (req, res) => {
  try {
    const { categoryId } = req.params;
    const snap = await db.collection('users').doc(req.uid).collection('categories').doc(categoryId).collection('credentials').get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/categories/:categoryId/credentials', verifyToken, async (req, res) => {
  try {
    const { categoryId } = req.params;
    const { username, password } = req.body;
    const ref = await db.collection('users').doc(req.uid).collection('categories').doc(categoryId).collection('credentials').add({
      username,
      password,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    const doc = await ref.get();
    res.status(201).json({ id: doc.id, ...doc.data() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.listen(PORT, () => console.log(`API escuchando en http://localhost:${PORT}`));