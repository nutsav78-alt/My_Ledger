import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../main.dart';

class AppLockScreen extends StatefulWidget {
  final Widget onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _lockType = 'pin';
  String _savedValue = '';
  bool _biometricEnabled = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLockData();
  }

  Future<void> _loadLockData() async {
    final type = await StorageService.getLockType();
    final value = await StorageService.getLockValue();
    final bio = await StorageService.isBiometricEnabled();
    setState(() {
      _lockType = type;
      _savedValue = value;
      _biometricEnabled = bio;
    });
    if (bio) {
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock My Ledger',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        _unlock();
      }
    } catch (e) {
      // Handle error
    }
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => widget.onUnlocked),
    );
  }

  void _verifyPin(String pin) {
    if (pin == _savedValue) {
      _unlock();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.translate('wrong_value', languageNotifier.value))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.teal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  TranslationService.translate(_lockType == 'pin' ? 'enter_pin' : 'enter_password', lang),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_lockType == 'pin')
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: Colors.white,
                    showFieldAsBox: true,
                    fieldWidth: 50,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                    onSubmit: _verifyPin,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
                      ),
                      onSubmitted: (val) {
                        if (val == _savedValue) {
                          _unlock();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(TranslationService.translate('wrong_value', lang))),
                          );
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 40),
                if (_biometricEnabled)
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 50, color: Colors.white),
                    onPressed: _authenticateBiometric,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
