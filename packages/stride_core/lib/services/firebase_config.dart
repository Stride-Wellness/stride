import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_core/firebase_options.dart';

/// Firebase configuration and initialization helper
class FirebaseConfig {
  static bool _initialized = false;

  /// Initialize Firebase if not already initialized
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Configure Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _initialized = true;
      print('Firebase initialized successfully');
    } catch (error) {
      print('Error initializing Firebase: $error');
      rethrow;
    }
  }

  /// Get Firestore instance
  static FirebaseFirestore get firestore {
    if (!_initialized) {
      throw Exception('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return FirebaseFirestore.instance;
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Initialize Firebase for testing (with emulator)
  static Future<void> initializeForTesting({
    String host = 'localhost',
    int port = 8080,
  }) async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, port);
      
      _initialized = true;
      print('Firebase initialized for testing (emulator: $host:$port)');
    } catch (error) {
      print('Error initializing Firebase for testing: $error');
      rethrow;
    }
  }
}