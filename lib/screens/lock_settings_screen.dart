import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../main.dart';

class LockSettingsScreen extends StatefulWidget {
  const LockSettingsScreen({super.key});

  @override
  State<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends State<LockSettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isLockEnabled = false;
  String _lockType = 'pin';
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await StorageService.isLockEnabled();
    final type = await StorageService.getLockType();
    final bio = await StorageService.isBiometricEnabled();
    final canBio = await auth.canCheckBiometrics;
    setState(() {
      _isLockEnabled = enabled;
      _lockType = type;
      _biometricEnabled = bio;
      _canCheckBiometrics = canBio;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value) {
      // Enable lock - need to set a value
      final success = await _showSetupDialog();
      if (success) {
        await StorageService.setLockEnabled(true);
        setState(() => _isLockEnabled = true);
      }
    } else {
      await StorageService.setLockEnabled(false);
      setState(() => _isLockEnabled = false);
    }
  }

  Future<bool> _showSetupDialog() async {
    final lang = languageNotifier.value;
    String setupValue = '';
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate(_lockType == 'pin' ? 'set_pin' : 'set_password', lang)),
        content: _lockType == 'pin' 
            ? OtpTextField(
                numberOfFields: 4,
                borderColor: Colors.teal,
                showFieldAsBox: true,
                onSubmit: (val) => setupValue = val,
              )
            : TextField(
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (val) => setupValue = val,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(TranslationService.translate('cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              if (setupValue.isNotEmpty) {
                await StorageService.setLockValue(setupValue);
                Navigator.pop(context, true);
              }
            },
            child: Text(TranslationService.translate('save', lang)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('app_lock', lang)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: Text(TranslationService.translate('enable_lock', lang)),
                value: _isLockEnabled,
                onChanged: _toggleLock,
                activeColor: Colors.teal,
              ),
              if (_isLockEnabled) ...[
                const Divider(),
                ListTile(
                  title: Text(TranslationService.translate('lock_type', lang)),
                  trailing: DropdownButton<String>(
                    value: _lockType,
                    items: ['pin', 'password'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(TranslationService.translate(value, lang)),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _lockType = val);
                        await StorageService.setLockType(val);
                        await _showSetupDialog();
                      }
                    },
                  ),
                ),
                if (_canCheckBiometrics)
                  SwitchListTile(
                    title: Text(TranslationService.translate('biometrics', lang)),
                    value: _biometricEnabled,
                    onChanged: (val) async {
                      await StorageService.setBiometricEnabled(val);
                      setState(() => _biometricEnabled = val);
                    },
                    activeColor: Colors.teal,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
