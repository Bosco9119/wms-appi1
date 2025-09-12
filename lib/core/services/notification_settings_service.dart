import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/notification_preferences_model.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  static const String _preferencesKey = 'notification_preferences';
  NotificationPreferences? _cachedPreferences;

  /// Get current notification preferences
  Future<NotificationPreferences> getPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_preferencesKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _cachedPreferences = NotificationPreferences.fromJson(json);
      } else {
        _cachedPreferences = NotificationPreferences.defaultSettings();
        await savePreferences(_cachedPreferences!);
      }

      return _cachedPreferences!;
    } catch (e) {
      print('❌ Error loading notification preferences: $e');
      _cachedPreferences = NotificationPreferences.defaultSettings();
      return _cachedPreferences!;
    }
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(_preferencesKey, jsonString);
      _cachedPreferences = preferences;
      print('✅ Notification preferences saved');
    } catch (e) {
      print('❌ Error saving notification preferences: $e');
    }
  }

  /// Toggle notification on/off
  Future<void> toggleNotifications(bool enabled) async {
    final preferences = await getPreferences();
    final updatedPreferences = preferences.copyWith(
      isEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    await savePreferences(updatedPreferences);
    print('🔔 Notification toggle: ${enabled ? "ENABLED" : "DISABLED"}');
  }

  /// Add a reminder interval
  Future<bool> addReminderInterval(ReminderInterval interval) async {
    final preferences = await getPreferences();

    // Check if already exists
    if (preferences.reminderIntervals.any((r) => r.id == interval.id)) {
      return false; // Already exists
    }

    // Check maximum limit (6 total)
    if (preferences.reminderIntervals.length >= 6) {
      return false; // Maximum reached
    }

    final updatedIntervals = List<ReminderInterval>.from(
      preferences.reminderIntervals,
    )..add(interval);

    final updatedPreferences = preferences.copyWith(
      reminderIntervals: updatedIntervals,
      lastUpdated: DateTime.now(),
    );

    await savePreferences(updatedPreferences);
    return true;
  }

  /// Remove a reminder interval
  Future<bool> removeReminderInterval(String intervalId) async {
    final preferences = await getPreferences();

    // Don't allow removing if it's the only one left
    if (preferences.reminderIntervals.length <= 1) {
      return false;
    }

    final updatedIntervals = preferences.reminderIntervals
        .where((r) => r.id != intervalId)
        .toList();

    final updatedPreferences = preferences.copyWith(
      reminderIntervals: updatedIntervals,
      lastUpdated: DateTime.now(),
    );

    await savePreferences(updatedPreferences);
    return true;
  }

  /// Toggle a specific reminder interval on/off
  Future<void> toggleReminderInterval(String intervalId, bool enabled) async {
    final preferences = await getPreferences();

    final updatedIntervals = preferences.reminderIntervals.map((interval) {
      if (interval.id == intervalId) {
        return interval.copyWith(isEnabled: enabled);
      }
      return interval;
    }).toList();

    final updatedPreferences = preferences.copyWith(
      reminderIntervals: updatedIntervals,
      lastUpdated: DateTime.now(),
    );

    await savePreferences(updatedPreferences);
    print(
      '⏰ Reminder interval ${intervalId}: ${enabled ? "ENABLED" : "DISABLED"}',
    );
  }

  /// Get available intervals that can be added
  Future<List<ReminderInterval>> getAvailableIntervals() async {
    final preferences = await getPreferences();
    final currentIds = preferences.reminderIntervals.map((r) => r.id).toSet();

    return ReminderInterval.allIntervals
        .where((interval) => !currentIds.contains(interval.id))
        .toList();
  }

  /// Clear all preferences and reset to default
  Future<void> resetToDefault() async {
    _cachedPreferences = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferencesKey);
    await getPreferences(); // This will create default preferences
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final preferences = await getPreferences();
    return preferences.isEnabled;
  }

  /// Get enabled reminder intervals
  Future<List<ReminderInterval>> getEnabledReminderIntervals() async {
    final preferences = await getPreferences();
    return preferences.reminderIntervals
        .where((interval) => interval.isEnabled)
        .toList();
  }
}
