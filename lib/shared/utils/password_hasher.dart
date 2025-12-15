import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for password hashing
/// Uses SHA-256 for hashing (for production, consider using bcrypt or argon2)
class PasswordHasher {
  /// Hash a password using SHA-256
  /// Note: For production, use a more secure hashing algorithm like bcrypt
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a password against a hash
  static bool verifyPassword(String password, String hash) {
    final hashedPassword = hashPassword(password);
    return hashedPassword == hash;
  }
}

