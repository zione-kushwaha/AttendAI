import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/features/home/home_screen.dart';
import 'package:hajiri/providers/settings_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;
  int _attempts = 0;
  final int _maxAttempts = 5;
  bool _isLocked = false;
  int _lockTimeRemaining = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    final settings = ref.read(settingsProvider);
    final correctPin = settings['pin'] as String? ?? '';

    if (_pinController.text == correctPin) {
      // Pin is correct, navigate to home using MaterialPageRoute
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _isError = true;
        _attempts++;
        _pinController.clear();

        // Lock the app after max attempts
        if (_attempts >= _maxAttempts) {
          _isLocked = true;
          _lockTimeRemaining = 30; // 30 seconds lock time
          _startLockdownTimer();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _attempts >= _maxAttempts
                ? 'Too many incorrect attempts. App locked for $_lockTimeRemaining seconds.'
                : 'Incorrect PIN. Please try again. (${_maxAttempts - _attempts} attempts remaining)',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLockdownTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _lockTimeRemaining--;
      });

      if (_lockTimeRemaining > 0) {
        _startLockdownTimer();
      } else {
        _isLocked = false;
        _attempts = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.secondary.withValues(alpha: .8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _isLocked ? 'App Locked' : 'Enter PIN',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLocked
                          ? 'Too many incorrect attempts.\nPlease wait $_lockTimeRemaining seconds.'
                          : 'Please enter your 4-digit PIN to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!_isLocked) ...[
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        autofocus: true,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: .6),
                            fontSize: 24,
                          ),
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _isError
                                      ? Colors.red
                                      : Colors.white.withValues(alpha: .5),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .1),
                        ),
                        onSubmitted: (_) => _verifyPin(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _verifyPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Unlock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (_isLocked)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
