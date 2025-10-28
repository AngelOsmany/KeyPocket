const admin = require('firebase-admin');
const express = require('express');
const router = express.Router();

// Middleware to verify Firebase token
const verifyToken = async (req, res, next) => {
  console.log('🔒 Verificando token de autenticación...');
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      console.log('❌ No se proporcionó token');
      return res.status(401).json({ 
        endpoint: 'Auth Middleware',
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
      endpoint: 'Auth Middleware',
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
    endpoint: 'GET /api/auth/test',
    status: 'success',
    message: 'Auth routes are working correctly!'
  });
});

// Get current user
router.get('/me', verifyToken, async (req, res) => {
  console.log('👤 Getting user information for:', req.user.uid);
  try {
    const user = await admin.auth().getUser(req.user.uid);
    console.log('✅ User information retrieved successfully');
    res.json({
      endpoint: 'GET /api/auth/me',
      status: 'success',
      data: {
        id: user.uid,
        email: user.email,
        displayName: user.displayName
      }
    });
  } catch (error) {
    console.log('❌ Error getting user information:', error.message);
    res.status(500).json({ 
      endpoint: 'GET /api/auth/me',
      status: 'error',
      message: error.message 
    });
  }
});

module.exports = router;