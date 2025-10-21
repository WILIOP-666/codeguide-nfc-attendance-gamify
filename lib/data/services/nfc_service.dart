import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:nfc_attendance_gamify/core/constants/app_constants.dart';
import 'package:nfc_attendance_gamify/data/models/nfc_card.dart';

class NfcService {
  static bool _isScanning = false;
  static StreamSubscription<NFCTag>? _pollingSubscription;

  static bool get isScanning => _isScanning;

  static Future<bool> isNfcAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability != NFCAvailability.not_supported;
    } catch (e) {
      debugPrint('Error checking NFC availability: $e');
      return false;
    }
  }

  static Future<NfcScanResult> scanNfcCard({
    Duration timeout = const Duration(seconds: 30),
    bool showAlertDialog = true,
  }) async {
    if (_isScanning) {
      throw Exception('NFC scanning is already in progress');
    }

    try {
      _isScanning = true;

      // Check NFC availability
      final availability = await FlutterNfcKit.nfcAvailability;
      switch (availability) {
        case NFCAvailability.not_supported:
          throw Exception('NFC is not supported on this device');
        case NFCAvailability.disabled:
          throw Exception('NFC is disabled. Please enable it in settings');
        case NFCAvailability.not_supported:
          throw Exception('NFC is not supported on this device');
        default:
          break;
      }

      // Start polling for NFC tags
      NFCTag? tag;
      try {
        tag = await FlutterNfcKit.poll(
          timeout: timeout.inSeconds,
          readIso15693: true,
          readIso14443A: true,
          readIso14443B: true,
          readFeliCa: true,
        ).timeout(timeout);
      } catch (e) {
        if (e is TimeoutException) {
          throw Exception('No NFC card detected. Please try again.');
        }
        rethrow;
      }

      if (tag == null) {
        throw Exception('No NFC card detected');
      }

      // Extract card information
      final uid = _extractUid(tag);
      final type = _getCardType(tag);
      final technology = tag.technology?.join(', ');

      // Create scan result
      final scanResult = NfcScanResult(
        uid: uid,
        type: type,
        technology: technology,
        additionalData: {
          'id': tag.id,
          'standard': tag.standard,
          'manufacturer': tag.manufacturer,
          'historicalBytes': tag.historicalBytes,
          'systemCode': tag.systemCode,
          'manufacturerCode': tag.manufacturerCode,
          'applicationData': tag.applicationData,
        },
        scannedAt: DateTime.now(),
        isValid: uid.isNotEmpty,
      );

      debugPrint('NFC Card Scanned: UID=$uid, Type=$type, Technology=$technology');

      return scanResult;

    } catch (e) {
      debugPrint('NFC Scan Error: $e');
      return NfcScanResult(
        uid: '',
        type: 'error',
        scannedAt: DateTime.now(),
        isValid: false,
        errorMessage: e.toString(),
      );
    } finally {
      _isScanning = false;
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        debugPrint('Error finishing NFC session: $e');
      }
    }
  }

  static String _extractUid(NFCTag tag) {
    try {
      if (tag.id != null) {
        return tag.id!.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
      }
      return '';
    } catch (e) {
      debugPrint('Error extracting UID: $e');
      return '';
    }
  }

  static String _getCardType(NFCTag tag) {
    try {
      if (tag.standard == NFCStandard.iso14443A) {
        return 'MIFARE Classic/NTAG';
      } else if (tag.standard == NFCStandard.iso14443B) {
        return 'ISO14443B';
      } else if (tag.standard == NFCStandard.iso15693) {
        return 'ISO15693';
      } else if (tag.standard == NFCStandard.feliCa) {
        return 'FeliCa';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('Error determining card type: $e');
      return 'Unknown';
    }
  }

  static void stopScanning() {
    if (_isScanning) {
      _isScanning = false;
      _pollingSubscription?.cancel();
      _pollingSubscription = null;
      FlutterNfcKit.finish().catchError((e) {
        debugPrint('Error stopping NFC session: $e');
      });
    }
  }

  static Future<String> getDeviceInfo() async {
    try {
      final deviceInfo = await FlutterNfcKit.getIosAvailability();
      return 'iOS NFC Support: $deviceInfo';
    } catch (e) {
      try {
        return 'Android Device: Platform supports NFC';
      } catch (e) {
        return 'Unknown Platform';
      }
    }
  }

  // Validate MIFARE Classic card format
  static bool isValidMifareCard(String uid) {
    try {
      // Basic validation - should be 4, 7, or 8 bytes
      final parts = uid.split(':');
      return parts.length >= 4 && parts.length <= 8;
    } catch (e) {
      return false;
    }
  }

  // Format UID for consistent storage
  static String formatUid(String rawUid) {
    try {
      // Remove any formatting and return clean uppercase format
      final cleaned = rawUid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      final formatted = cleaned
          .toUpperCase()
          .replaceAllMapped(RegExp(r'.{2}'), (match) => '${match.group(0)}:')
          .replaceAll(RegExp(r':$'), '');
      return formatted;
    } catch (e) {
      return rawUid.toUpperCase();
    }
  }
}