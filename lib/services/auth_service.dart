import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';

/// Authentication service for PIN and biometric lock
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final _localAuth = LocalAuthentication();
  final _db = DatabaseService.instance;

  /// Check if device supports biometric
  Future<bool> get canUseBiometric async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if app lock is enabled
  bool get isLockEnabled => _db.hasPinLock;

  /// Check if biometric is enabled
  bool get isBiometricEnabled => _db.biometricEnabled;

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set up PIN lock
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _db.setPin(hash);
  }

  /// Remove PIN lock
  Future<void> removePin() async {
    await _db.removePin();
    await _db.setBiometricEnabled(false);
  }

  /// Verify PIN
  bool verifyPin(String pin) {
    if (!isLockEnabled) return true;
    final hash = _hashPin(pin);
    return hash == _db.pinHash;
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;
    await setPin(newPin);
    return true;
  }

  /// Enable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _db.setBiometricEnabled(enabled);
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    if (!isBiometricEnabled) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Mở khóa FinTech App',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Authenticate with PIN or biometric
  Future<bool> authenticate({String? pin}) async {
    // Try biometric first if enabled
    if (isBiometricEnabled) {
      final biometricResult = await authenticateWithBiometric();
      if (biometricResult) return true;
    }

    // Fall back to PIN
    if (pin != null) {
      return verifyPin(pin);
    }

    return false;
  }
}
