import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Lock screen with PIN input and biometric option
class LockScreen extends StatefulWidget {
  final bool isSetup;

  const LockScreen({super.key, this.isSetup = false});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = AuthService.instance;
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSetup) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (!_auth.isBiometricEnabled) return;

    setState(() => _loading = true);
    final success = await _auth.authenticateWithBiometric();
    setState(() => _loading = false);

    if (success && mounted) {
      _navigateToHome();
    }
  }

  void _onNumberTap(String num) {
    HapticFeedback.lightImpact();

    if (widget.isSetup) {
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          setState(() {
            _confirmPin += num;
            _error = null;
          });
          if (_confirmPin.length == 4) {
            _verifySetup();
          }
        }
      } else {
        if (_pin.length < 4) {
          setState(() {
            _pin += num;
            _error = null;
          });
          if (_pin.length == 4) {
            setState(() => _isConfirming = true);
          }
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += num;
          _error = null;
        });
        if (_pin.length == 4) {
          _verifyPin();
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (widget.isSetup && _isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(
          () => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1),
        );
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    }
  }

  Future<void> _verifyPin() async {
    final success = _auth.verifyPin(_pin);
    if (success) {
      _navigateToHome();
    } else {
      setState(() {
        _error = 'Mã PIN không đúng';
        _pin = '';
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _verifySetup() async {
    if (_pin == _confirmPin) {
      setState(() => _loading = true);
      await _auth.setPin(_pin);
      setState(() => _loading = false);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _error = 'Mã PIN không khớp';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = widget.isSetup && _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.success],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('💰', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.isSetup
                    ? (_isConfirming ? 'Xác nhận mã PIN' : 'Tạo mã PIN mới')
                    : 'Nhập mã PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetup
                    ? (_isConfirming
                          ? 'Nhập lại 4 số'
                          : 'Nhập 4 số để bảo vệ app')
                    : 'Mở khóa để tiếp tục',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < currentPin.length;
                  return Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: filled ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? AppTheme.danger
                            : AppTheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppTheme.danger)),
              ],

              const Spacer(),

              // Number pad
              if (_loading)
                const CircularProgressIndicator()
              else
                _buildNumberPad(),

              const SizedBox(height: 24),

              // Biometric button (only for unlock, not setup)
              if (!widget.isSetup && _auth.isBiometricEnabled)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text('Dùng vân tay'),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (row < 3)
                  for (var col = 0; col < 3; col++)
                    _buildNumberButton('${row * 3 + col + 1}')
                else ...[
                  _buildNumberButton('', isEmpty: true),
                  _buildNumberButton('0'),
                  _buildBackspaceButton(),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNumberButton(String num, {bool isEmpty = false}) {
    if (isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }

    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: () => _onNumberTap(num),
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onBackspace,
          borderRadius: BorderRadius.circular(40),
          child: const Center(child: Icon(Icons.backspace_outlined, size: 28)),
        ),
      ),
    );
  }
}
