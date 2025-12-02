import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBPvVfoRiHEXMQZ2YAGDzunDNgA_0no01w",
        authDomain: "keypocket-61ec3.firebaseapp.com",
        projectId: "keypocket-61ec3",
        storageBucket: "keypocket-61ec3.firebasestorage.app",
        messagingSenderId: "603483098467",
        appId: "1:603483098467:web:c7c0a65fcb84753c621756",
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  // Inicializa Hive
  await Hive.initFlutter();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => SyncService()),
      ],
      child: MaterialApp(
        title: 'KeyPocket',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Cargando...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return LoginScreen();
        }
        
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen();
        }
        
        return HomeScreen();
      },
    );
  }
}