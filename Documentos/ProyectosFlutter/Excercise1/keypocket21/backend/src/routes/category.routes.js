const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

// Middleware to verify Firebase token
const verifyToken = async (req, res, next) => {
  console.log('🔒 Verificando token de autenticación en categorías...');
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      console.log('❌ No se proporcionó token');
      return res.status(401).json({ 
        endpoint: 'Categories Middleware',
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
      endpoint: 'Categories Middleware',
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
    endpoint: 'GET /api/categories/test',
    status: 'success',
    message: 'Category routes are working correctly!'
  });
});

// Get all categories for a user
router.get('/', verifyToken, async (req, res) => {
  console.log('📂 Getting categories for user:', req.user.uid);
  try {
    const snapshot = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('categories')
      .orderBy('createdAt', 'desc')
      .get();

    const categories = [];
    snapshot.forEach(doc => {
      categories.push({ id: doc.id, ...doc.data() });
    });

    console.log('✅ Categories retrieved successfully. Count:', categories.length);
    res.json({
      endpoint: 'GET /api/categories',
      status: 'success',
      data: categories
    });
  } catch (error) {
    console.log('❌ Error getting categories:', error.message);
    res.status(500).json({ 
      endpoint: 'GET /api/categories',
      status: 'error',
      message: error.message 
    });
  }
});

// Create a new category
router.post('/', verifyToken, async (req, res) => {
  try {
    const { name } = req.body;
    const categoryData = {
      name,
      userId: req.user.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('categories')
      .add(categoryData);

    res.status(201).json({ id: docRef.id, ...categoryData });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete a category
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('categories')
      .doc(req.params.id)
      .delete();

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;