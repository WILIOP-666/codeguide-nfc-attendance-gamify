import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/data/models/nfc_card.dart';
import 'package:nfc_attendance_gamify/data/services/nfc_service.dart';
import 'package:nfc_attendance_gamify/features/attendance/providers/attendance_provider.dart';

class NfcCheckinScreen extends ConsumerStatefulWidget {
  const NfcCheckinScreen({super.key});

  @override
  ConsumerState<NfcCheckinScreen> createState() => _NfcCheckinScreenState();
}

class _NfcCheckinScreenState extends ConsumerState<NfcCheckinScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  bool _isScanning = false;
  NfcScanResult? _lastScanResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    NfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Check-In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to attendance history
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Status Section
              _buildStatusSection(attendanceState),

              const SizedBox(height: 32),

              // NFC Scanner Visual
              Expanded(
                child: _buildNfcScanner(),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 16),

              // Last Scan Result
              if (_lastScanResult != null)
                _buildLastScanResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(attendanceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isScanning ? Icons.nfc : Icons.nfc_outlined,
                  color: _isScanning ? Colors.green : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isScanning ? 'Ready to Scan' : 'NFC Check-In',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isScanning
                            ? 'Hold NFC card near device'
                            : 'Tap the button below to start scanning',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            // Today's Stats
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today',
                    value: attendanceState.todayCheckIns.toString(),
                    icon: Icons.how_to_reg,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'This Week',
                    value: attendanceState.weeklyCheckIns.toString(),
                    icon: Icons.date_range,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcScanner() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NFC Visual
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
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
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                );
              },
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              _isScanning
                  ? 'Scanning for NFC Card...'
                  : 'Ready to Check-In',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              _isScanning
                  ? 'Hold the NFC card within 4cm of the device'
                  : 'Press "Start Scanning" to begin NFC check-in',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // NFC Status
            FutureBuilder<bool>(
              future: NfcService.isNfcAvailable(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final isAvailable = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvailable ? 'NFC Available' : 'NFC Not Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Main Scan Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isScanning ? _stopScanning : _startScanning,
            icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
            label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _isScanning ? Colors.red : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Manual Check-In Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showManualCheckIn,
            icon: const Icon(Icons.edit),
            label: const Text('Manual Check-In'),
          ),
        ),
      ],
    );
  }

  Widget _buildLastScanResult() {
    if (_lastScanResult == null) return const SizedBox.shrink();

    return Card(
      color: _lastScanResult!.isValid
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _lastScanResult!.isValid ? Icons.check_circle : Icons.error,
                  color: _lastScanResult!.isValid ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _lastScanResult!.isValid ? 'Card Detected' : 'Scan Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _lastScanResult!.isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastScanResult!.isValid) ...[
              _buildInfoRow('UID', _lastScanResult!.uid),
              _buildInfoRow('Type', _lastScanResult!.type),
              if (_lastScanResult!.technology != null)
                _buildInfoRow('Technology', _lastScanResult!.technology!),
              _buildInfoRow('Scanned At',
                  '${_lastScanResult!.scannedAt.hour.toString().padLeft(2, '0')}:'
                  '${_lastScanResult!.scannedAt.minute.toString().padLeft(2, '0')}:'
                  '${_lastScanResult!.scannedAt.second.toString().padLeft(2, '0')}'),
            ] else if (_lastScanResult!.errorMessage != null) ...[
              Text(
                _lastScanResult!.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _StatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _lastScanResult = null;
    });

    _scanController.repeat();

    try {
      final scanResult = await NfcService.scanNfcCard(
        timeout: const Duration(seconds: AppConstants.nfcTimeoutSeconds),
      );

      setState(() {
        _lastScanResult = scanResult;
      });

      if (scanResult.isValid) {
        // Process the scan result
        await _processNfcScan(scanResult);
      } else {
        setState(() {
          _errorMessage = scanResult.errorMessage ?? 'Failed to read NFC card';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _lastScanResult = NfcScanResult(
          uid: '',
          type: 'error',
          scannedAt: DateTime.now(),
          isValid: false,
          errorMessage: e.toString(),
        );
      });
    } finally {
      _scanController.stop();
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScanning() async {
    _scanController.stop();
    NfcService.stopScanning();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _processNfcScan(NfcScanResult scanResult) async {
    try {
      final attendanceNotifier = ref.read(attendanceProvider.notifier);
      await attendanceNotifier.recordNfcCheckIn(
        nfcUid: scanResult.uid,
        cardType: scanResult.type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showManualCheckIn() {
    // TODO: Show manual check-in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Check-In'),
        content: const Text('Manual check-in feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}