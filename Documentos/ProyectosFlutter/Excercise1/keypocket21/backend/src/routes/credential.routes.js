const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

// Middleware to verify Firebase token
const verifyToken = async (req, res, next) => {
  console.log('🔒 Verificando token de autenticación en credenciales...');
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      console.log('❌ No se proporcionó token');
      return res.status(401).json({ 
        endpoint: 'Credentials Middleware',
        status: 'error',
        message: 'No token provided' 
      });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    console.log('✅ Token verificado correctamente para el usuario:', decodedToken.uid);
    next();
  } catch (error) {
    console.log('❌ Token inválido:', error.message);
    res.status(401).json({ 
      endpoint: 'Credentials Middleware',
      status: 'error',
      message: 'Invalid token',
      error: error.message 
    });
  }
};

// Test endpoint - No authentication required
router.get('/test', (req, res) => {
  console.log('📡 Test endpoint called');
  res.json({
    endpoint: 'GET /api/credentials/test',
    status: 'success',
    message: 'Credential routes are working correctly!'
  });
});

// Get all credentials for a category
router.get('/category/:categoryId', verifyToken, async (req, res) => {
  console.log('🔑 Getting credentials for category:', req.params.categoryId);
  try {
    const snapshot = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('credentials')
      .where('categoryId', '==', req.params.categoryId)
      .orderBy('createdAt', 'desc')
      .get();

    const credentials = [];
    snapshot.forEach(doc => {
      credentials.push({ id: doc.id, ...doc.data() });
    });

    res.json(credentials);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create a new credential
router.post('/', verifyToken, async (req, res) => {
  try {
    const { title, username, email, password, website, notes, categoryId } = req.body;
    const credentialData = {
      title,
      username,
      email,
      password,
      website,
      notes,
      categoryId,
      userId: req.user.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('credentials')
      .add(credentialData);

    res.status(201).json({ id: docRef.id, ...credentialData });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete a credential
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('credentials')
      .doc(req.params.id)
      .delete();

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;