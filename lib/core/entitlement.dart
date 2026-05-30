import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class EntitlementService {
  static final EntitlementService _instance = EntitlementService._();
  factory EntitlementService() => _instance;
  EntitlementService._();

  Future<bool> hasPremium() async {
    if (kDebugMode) return true;

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    if (AppConstants.adminDeviceIds.contains(deviceId)) return true;

    // TODO: Check RevenueCat entitlement
    return false;
  }
}
