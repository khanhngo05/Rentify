import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

enum BiometricAuthResult { verified, unavailable, failed }

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<BiometricAuthResult> authenticateForLogin() async {
    if (kIsWeb) {
      return BiometricAuthResult.unavailable;
    }

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) {
        return BiometricAuthResult.unavailable;
      }

      final enrolled = await _localAuth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return BiometricAuthResult.unavailable;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xac thuc sinh trac hoc de vao Rentify',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate
          ? BiometricAuthResult.verified
          : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return BiometricAuthResult.unavailable;
      }
      return BiometricAuthResult.failed;
    }
  }
}
