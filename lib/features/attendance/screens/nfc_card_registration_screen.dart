import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/data/models/nfc_card.dart';
import 'package:nfc_attendance_gamify/data/services/nfc_service.dart';
import 'package:nfc_attendance_gamify/features/auth/providers/auth_provider.dart';
import 'package:nfc_attendance_gamify/features/attendance/providers/attendance_provider.dart';
import 'package:nfc_attendance_gamify/widgets/forms/student_search_form.dart';

class NfcCardRegistrationScreen extends ConsumerStatefulWidget {
  const NfcCardRegistrationScreen({super.key});

  @override
  ConsumerState<NfcCardRegistrationScreen> createState() => _NfcCardRegistrationScreenState();
}

class _NfcCardRegistrationScreenState extends ConsumerState<NfcCardRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool _isScanning = false;
  bool _isRegistering = false;
  String? _selectedStudentId;
  String? _selectedStudentName;
  NfcScanResult? _scannedCard;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _scanController.dispose();
    NfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Card Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Registration Instructions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Select a student from the search below\n'
                      '2. Scan the NFC card to register\n'
                      '3. Confirm the registration',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Student Selection
            Text(
              'Step 1: Select Student',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StudentSearchForm(
              onStudentSelected: (studentId, studentName) {
                setState(() {
                  _selectedStudentId = studentId;
                  _selectedStudentName = studentName;
                });
              },
              enabled: !_isScanning && !_isRegistering,
            ),
            if (_selectedStudentName != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: $_selectedStudentName',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // NFC Scanning
            Text(
              'Step 2: Scan NFC Card',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildNfcScanner(),
            const SizedBox(height: 24),

            // Registration Button
            Text(
              'Step 3: Register Card',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canRegister() ? _registerNfcCard : null,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.register_app),
                label: Text(_isRegistering ? 'Registering...' : 'Register NFC Card'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNfcScanner() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // NFC Visual
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isScanning
                    ? Colors.green.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                  color: _isScanning
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.nfc,
                    size: 50,
                    color: _isScanning
                        ? Colors.green
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: CircularProgressIndicator(
                            value: _scanAnimation.value,
                            strokeWidth: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan Status
            Text(
              _isScanning ? 'Scanning...' : 'Ready to Scan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isScanning ? Colors.green : null,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isScanning
                  ? 'Hold NFC card near device'
                  : 'Select student first, then tap to scan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Scan Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_selectedStudentId == null || _isScanning)
                    ? null
                    : _scanNfcCard,
                icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              ),
            ),

            // Scan Result
            if (_scannedCard != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _scannedCard!.isValid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _scannedCard!.isValid ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: _scannedCard!.isValid ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Card Detected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _scannedCard!.isValid ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (_scannedCard!.isValid) ...[
                        const SizedBox(height: 4),
                        Text(
                          'UID: ${_scannedCard!.uid}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Type: ${_scannedCard!.type}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canRegister() {
    return _selectedStudentId != null &&
        _scannedCard != null &&
        _scannedCard!.isValid &&
        !_isScanning &&
        !_isRegistering;
  }

  Future<void> _scanNfcCard() async {
    if (_selectedStudentId == null) return;

    setState(() {
      _isScanning = true;
      _scannedCard = null;
      _errorMessage = null;
    });

    _scanController.repeat();

    try {
      final scanResult = await NfcService.scanNfcCard(
        timeout: const Duration(seconds: 30),
      );

      setState(() {
        _scannedCard = scanResult;
      });

      if (!scanResult.isValid) {
        setState(() {
          _errorMessage = scanResult.errorMessage ?? 'Failed to read NFC card';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      _scanController.stop();
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _registerNfcCard() async {
    if (!_canRegister()) return;

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call Supabase function to register NFC card
      final response = await SupabaseConfig.client.functions.invoke(
        'register-nfc-card',
        body: {
          'student_id': _selectedStudentId,
          'nfc_uid': _scannedCard!.uid,
          'card_type': _scannedCard!.type,
          'registered_by': currentUser.id,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to register NFC card');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC card registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedStudentId = null;
          _selectedStudentName = null;
          _scannedCard = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }
}