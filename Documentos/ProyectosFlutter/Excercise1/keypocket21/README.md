# KeyPocket

A secure password manager application built with Flutter and Node.js.

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

## Contributing

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit:
   ```bash
   git commit -m "Description of changes"
   ```

3. Push to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Node.js Documentation](https://nodejs.org/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Express.js Documentation](https://expressjs.com/)
