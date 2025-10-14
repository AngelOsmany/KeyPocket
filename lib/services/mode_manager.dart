import 'package:shared_preferences/shared_preferences.dart';

class ModeManager {
  static const String _modeKey = 'app_mode';
  static late SharedPreferences _prefs;
  
  static bool _isOnlineMode = true;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isOnlineMode = _prefs.getBool(_modeKey) ?? true;
  }

  static bool get isOnlineMode => _isOnlineMode;

  static Future<void> setOnlineMode(bool online) async {
    _isOnlineMode = online;
    await _prefs.setBool(_modeKey, online);
  }

  static void toggleMode() {
    setOnlineMode(!_isOnlineMode);
  }
}