# KeyPocket

Una aplicación segura de gestión de contraseñas construida con Flutter y Firebase, con soporte para autenticación biométrica y sincronización offline/online.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración de Firebase](#configuración-de-firebase)
- [Configuración de Autenticación Biométrica](#configuración-de-autenticación-biométrica)
- [Ejecución de la Aplicación](#ejecución-de-la-aplicación)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Solución de Problemas](#solución-de-problemas)

## ✨ Características

- 🔐 **Autenticación segura** con Firebase Authentication
- 🔑 **Gestión de contraseñas** organizada por categorías
- 👆 **Autenticación biométrica** (huella digital/Face ID) para ver contraseñas
- 💾 **Almacenamiento local** con Hive para acceso offline
- 🔄 **Sincronización automática** entre dispositivos
- 📱 **Multiplataforma**: Android, iOS, Web, Windows
- 🌐 **Modo offline/online**: Funciona sin conexión y sincroniza cuando hay internet

## 📦 Requisitos Previos

### Software Requerido

- **Flutter SDK**: ^3.9.2
- **Dart SDK**: ^3.9.2
- **Android Studio** (para desarrollo Android):
  - Android SDK
  - Android Emulator
- **Xcode** (para desarrollo iOS, solo macOS)
- **Visual Studio Code** (recomendado) con extensiones:
  - Flutter
  - Dart

### Cuenta de Firebase

Necesitarás crear un proyecto en [Firebase Console](https://console.firebase.google.com/)

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd keypocket21
```

### 2. Instalar Dependencias de Flutter

```bash
flutter pub get
```

### 3. Verificar Instalación de Flutter

```bash
flutter doctor
```

Asegúrate de que todos los componentes necesarios estén instalados correctamente.

## 🔥 Configuración de Firebase

### Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Anota el **Project ID** (necesario más adelante)

### Paso 2: Configurar Firebase Authentication

1. En Firebase Console, ve a **Authentication**
2. Habilita **Email/Password** como método de autenticación

### Paso 3: Configurar Firestore Database

1. En Firebase Console, ve a **Firestore Database**
2. Crea una base de datos en modo **producción** o **prueba**
3. Configura las siguientes reglas de seguridad:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/categories/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId}/credentials/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Paso 4: Configurar Android

1. En Firebase Console, añade una **app de Android**
2. **Package name**: `com.example.keypocket1`
3. Descarga el archivo `google-services.json`
4. Coloca el archivo en: `android/app/google-services.json`

### Paso 5: Configurar iOS (opcional)

1. En Firebase Console, añade una **app de iOS**
2. **Bundle ID**: `com.example.keypocket1`
3. Descarga el archivo `GoogleService-Info.plist`
4. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

### Paso 6: Actualizar Configuración en el Código

Edita `lib/main.dart` y actualiza las credenciales de Firebase:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "TU_API_KEY",
    authDomain: "TU_PROJECT_ID.firebaseapp.com",
    projectId: "TU_PROJECT_ID",
    storageBucket: "TU_PROJECT_ID.firebasestorage.app",
    messagingSenderId: "TU_MESSAGING_SENDER_ID",
    appId: "TU_APP_ID",
  ),
);
```

Puedes encontrar estos valores en:
- Firebase Console → Project Settings → General
- O en el archivo `google-services.json` que descargaste

## 👆 Configuración de Autenticación Biométrica

### Android

La autenticación biométrica ya está configurada en el código. Solo necesitas:

1. **Permisos**: Ya incluido en `AndroidManifest.xml`
2. **Dispositivo físico**: Asegúrate de tener huella digital configurada en tu dispositivo
3. **Emulador**: 
   - Abre Settings → Security → Fingerprint
   - Configura un PIN/patrón
   - Añade una huella digital
   - Usa los controles extendidos del emulador (`...`) → Fingerprint → "Touch the sensor"

### iOS

Para iOS, el permiso de Face ID ya está incluido en `Info.plist`. Funciona automáticamente en dispositivos con Face ID o Touch ID.

## 🎯 Ejecución de la Aplicación

### Modo Debug (Desarrollo)

1. **Conectar un dispositivo o iniciar emulador**

2. **Verificar dispositivos disponibles**:
   ```bash
   flutter devices
   ```

3. **Ejecutar la app**:
   ```bash
   flutter run
   ```
   
   O desde VS Code:
   - Presiona `F5`
   - Selecciona el dispositivo de la lista

### Compilar APK (Android Release)

```bash
flutter build apk --release
```

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### Compilar para iOS (macOS)

```bash
flutter build ios --release
```

## 📁 Estructura del Proyecto

```
keypocket21/
├── lib/
│   ├── config/
│   │   └── api_config.dart          # Configuración de API
│   ├── models/
│   │   ├── category.dart            # Modelo de categoría
│   │   ├── credential.dart          # Modelo de credencial
│   │   └── user.dart                # Modelo de usuario
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart    # Pantalla de login
│   │   │   └── register_screen.dart # Pantalla de registro
│   │   └── home/
│   │       ├── home_screen.dart     # Pantalla principal
│   │       ├── categories_screen.dart   # Gestión de categorías
│   │       └── credentials_screen.dart  # Gestión de credenciales
│   ├── services/
│   │   ├── auth_service.dart        # Servicio de autenticación
│   │   ├── biometric_service.dart   # Servicio de biometría
│   │   ├── firestore_service.dart   # Servicio de Firestore
│   │   ├── local_storage.dart       # Almacenamiento local (Hive)
│   │   └── sync_service.dart        # Sincronización offline/online
│   └── main.dart                    # Punto de entrada
├── android/
│   └── app/
│       ├── build.gradle.kts         # Configuración de Gradle
│       ├── google-services.json     # Config de Firebase (no incluido)
│       └── src/main/
│           ├── AndroidManifest.xml  # Manifiesto Android
│           └── kotlin/.../MainActivity.kt
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist # Config de Firebase iOS (no incluido)
│       └── Info.plist
└── pubspec.yaml                     # Dependencias del proyecto
```

## 🔧 Solución de Problemas

### Error: "A Firebase App named '[DEFAULT]' already exists"

**Solución**: Este es un warning normal durante hot reload. Puedes ignorarlo o reiniciar la app completamente.

### Error: "Biométricos no disponibles"

**Causas posibles**:
1. No hay huella digital configurada en el dispositivo
2. El emulador no tiene sensor biométrico configurado
3. Los permisos no están otorgados

**Solución**:
- **Dispositivo físico**: Ve a Settings → Security → Fingerprint y configura una huella
- **Emulador**: Sigue los pasos en [Configuración de Autenticación Biométrica](#configuración-de-autenticación-biométrica)

### Error: "local_auth plugin requires activity to be a FragmentActivity"

**Solución**: Ya está resuelto. `MainActivity.kt` extiende `FlutterFragmentActivity`.

### La app no sincroniza con Firebase

**Verificar**:
1. Archivo `google-services.json` está en `android/app/`
2. Package name en `build.gradle.kts` coincide con Firebase (`com.example.keypocket1`)
3. Firebase Authentication y Firestore están habilitados
4. Las reglas de seguridad de Firestore permiten lectura/escritura

### Error de compilación en Android

**Solución**:
```bash
flutter clean
flutter pub get
flutter run
```

### Problemas de sincronización offline

**Verificar**:
1. El usuario ha iniciado sesión correctamente
2. Hay conexión a internet para la sincronización inicial
3. Los datos locales se guardan en Hive (verifica logs con emoji 💾)

## 📱 Uso de la Aplicación

### Primer Uso

1. **Registrarse**: Crea una cuenta con email y contraseña
2. **Crear categoría**: Añade categorías para organizar tus contraseñas (ej: "Redes Sociales", "Bancos")
3. **Añadir credenciales**: Dentro de cada categoría, guarda tus contraseñas
4. **Ver contraseñas**: Presiona el ícono del ojo 👁️ y autentica con tu huella digital

### Modo Offline

- La app funciona completamente sin conexión
- Los datos se guardan localmente en Hive
- Al reconectar, sincroniza automáticamente con Firebase

## 🔒 Seguridad

- ✅ Autenticación de dos factores con biometría
- ✅ Datos encriptados en Firebase
- ✅ Almacenamiento local seguro con Hive
- ✅ Reglas de seguridad de Firestore por usuario
- ⚠️ **IMPORTANTE**: Nunca compartas tu archivo `google-services.json`

## 📚 Recursos Adicionales

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Firebase para Flutter](https://firebase.flutter.dev/)
- [Hive Database](https://docs.hivedb.dev/)
- [Local Auth Plugin](https://pub.dev/packages/local_auth)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir los cambios que te gustaría realizar.

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.


## Project Structure

```
keypocket21/
├── lib/               # Flutter app source code
│   ├── models/       # Data models
│   ├── screens/      # UI screens
│   └── services/     # Business logic and services
├── backend/          # Node.js backend
│   ├── src/         # Backend source code
│   ├── config/      # Configuration files
│   └── .env         # Environment variables
└── ...              # Other Flutter project files
```

## Prerequisites

- Flutter SDK (^3.9.2)
- Dart SDK (^3.9.2)
- Node.js (>=14.x)
- npm (>=6.x)
- Firebase project

## Flutter App Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Update Firebase configuration:
   - For Android: Place `google-services.json` in `android/app/`
   - For iOS: Place `GoogleService-Info.plist` in `ios/Runner/`

## Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install Node.js dependencies:
   ```bash
   npm install
   ```

3. Firebase Admin Setup:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Navigate to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the downloaded file as `serviceAccountKey.json` in `backend/config/`

4. Environment Configuration:
   - Create `.env` file in `backend/` directory:
   ```env
   PORT=3000
   FIREBASE_PROJECT_ID=keypocket-61ec3
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@keypocket-61ec3.iam.gserviceaccount.com
   ```

## Running the Application

1. Start the backend server:
   ```bash
   cd backend
   npm run dev
   ```
   The server will start on `http://localhost:3000`

2. Run the Flutter app:
   ```bash
   # In a new terminal
   flutter run
   ```

### API Base URLs

- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator: `http://localhost:3000`
- Physical Device: `http://<your-computer-ip>:3000`

## Features

- 🔐 User authentication with Firebase
- 📱 Secure password storage
- 📂 Category management
- 🔄 Offline data synchronization
- 📱 Cross-platform support (iOS, Android)

## Development Notes

1. Always keep the Node.js server running while developing
2. Use `npm run dev` for backend development (auto-reload enabled)
3. The backend server must be running for the app to work properly

## Security Notes

- Never commit `serviceAccountKey.json` to version control
- Keep your `.env` file secure and never commit it
- Regularly update dependencies for security patches

## Troubleshooting

### Backend Issues
- Ensure Node.js and npm are installed correctly
- Check if the server is running on the correct port
- Verify Firebase Admin SDK credentials

### Flutter App Issues
- Verify Firebase configuration files are in place
- Check API base URL configuration
- Ensure backend server is running

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Node.js Documentation](https://nodejs.org/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Express.js Documentation](https://expressjs.com/)
