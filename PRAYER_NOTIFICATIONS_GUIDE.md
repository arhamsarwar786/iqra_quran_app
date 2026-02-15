# Prayer Notification Service - Implementation Guide

## Overview
This implementation adds a comprehensive prayer notification system to the Iqra Quran App with support for both **Hanafi** and **Shafi** madhabs (schools of Islamic jurisprudence).

## Features Implemented

### 1. **Prayer Notification Service** (`lib/Services/prayer_notification_service.dart`)
A dedicated service that handles all prayer time notifications with the following capabilities:

- ✅ **Automatic Scheduling**: Schedules notifications for all 5 daily prayers (Fajr, Zuhr, Asr, Maghrib, Isha)
- ✅ **Madhab Support**: Properly calculates prayer times based on selected madhab (Hanafi or Shafi)
  - **Hanafi**: Uses later Asr time calculation
  - **Shafi**: Uses standard Asr time calculation
- ✅ **Timezone Aware**: Handles timezone conversions correctly
- ✅ **Exact Scheduling**: Uses `AndroidScheduleMode.exactAllowWhileIdle` for precise notifications
- ✅ **Auto-Rescheduling**: Can reschedule for tomorrow's prayers
- ✅ **Notification Management**: Cancel all or individual prayer notifications

### 2. **User Preferences** (Updated `lib/Helper/preference/saved_preferences.dart`)
Added methods to persist notification settings:

```dart
// Enable/disable notifications
await SavedPrefernces.setPrayerNotificationsEnabled(true);
bool enabled = await SavedPrefernces.getPrayerNotificationsEnabled();
```

### 3. **Prayer Time Screen Integration** (`lib/Screens/MainPage/Home/azan/PrayerTime.dart`)
Enhanced the Prayer Time screen with:

- **Notification Toggle**: Beautiful UI switch to enable/disable notifications
- **Real-time Updates**: Notifications are rescheduled when madhab changes
- **User Feedback**: Snackbar messages confirm notification status
- **Automatic Initialization**: Notifications are set up when the app starts

## How It Works

### Madhab-Specific Calculations

The key difference between Hanafi and Shafi madhabs is the **Asr prayer time**:

```dart
CalculationParameters params = CalculationMethod.muslimWorldLeague();
params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
```

- **Hanafi**: Asr begins when shadow length = 2x object height
- **Shafi**: Asr begins when shadow length = 1x object height (earlier)

### Notification Scheduling Flow

1. **User Location**: Gets current GPS coordinates
2. **Prayer Calculation**: Calculates prayer times using `adhan_dart` package
3. **Madhab Application**: Applies selected madhab for accurate times
4. **Notification Scheduling**: Schedules exact-time notifications
5. **Daily Refresh**: Auto-reschedules for next day

### Code Example

```dart
// Schedule all prayers
await PrayerNotificationService.scheduleAllPrayers(
  position: currentPosition,
  madhab: 'hanafi', // or 'shafi'
);

// Cancel all notifications
await PrayerNotificationService.cancelAllNotifications();
```

## User Interface

### Madhab Selection
Users can select their madhab with visual chips:
- **Hanafi** (default)
- **Shafi / Standard**

### Notification Toggle
A beautiful card with:
- Icon indicator
- Title: "Prayer Notifications"
- Subtitle: "Get notified at prayer times"
- Switch to enable/disable

## Setup Instructions

### 1. Install Dependencies

The following package has been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

Run:
```bash
flutter pub get
```

### 2. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- Add this for exact alarms (Android 12+) -->
        <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
        <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
        
        <!-- Notification permission (Android 13+) -->
        <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    </application>
</manifest>
```

### 3. iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Testing the Implementation

### 1. Enable Notifications
1. Open the app
2. Navigate to Prayer Times screen
3. Select your madhab (Hanafi or Shafi)
4. Toggle "Prayer Notifications" ON
5. You should see: "Prayer notifications enabled"

### 2. Verify Scheduling
The notifications are scheduled for:
- **Fajr**: Dawn prayer
- **Zuhr**: Midday prayer
- **Asr**: Afternoon prayer (time varies by madhab)
- **Maghrib**: Sunset prayer
- **Isha**: Night prayer

### 3. Test Madhab Switching
1. Switch from Hanafi to Shafi (or vice versa)
2. Notifications are automatically rescheduled
3. Asr time will change based on madhab

## Key Differences: Hanafi vs Shafi

| Prayer | Hanafi | Shafi | Difference |
|--------|--------|-------|------------|
| Fajr | Same | Same | No difference |
| Zuhr | Same | Same | No difference |
| **Asr** | **Later** | **Earlier** | **~15-30 minutes** |
| Maghrib | Same | Same | No difference |
| Isha | Same | Same | No difference |

## Notification Features

### Notification Content
- **Title**: "Prayer Time: [Prayer Name]"
- **Body**: "It's time for [Prayer Name] prayer. May Allah accept your prayers."
- **Sound**: Default notification sound
- **Vibration**: Enabled
- **Priority**: High (ensures delivery)

### Notification Behavior
- **Exact Timing**: Notifications fire at exact prayer time
- **While Idle**: Works even when device is idle
- **Persistent**: Survives app restarts
- **Daily**: Auto-reschedules for next day

## Troubleshooting

### Notifications Not Appearing?

1. **Check Permissions**:
   - Android: Settings → Apps → Iqra → Notifications (Enabled)
   - iOS: Settings → Iqra → Notifications (Allow)

2. **Check Location**:
   - Ensure location services are enabled
   - Grant location permission to the app

3. **Check Toggle**:
   - Verify notification toggle is ON in Prayer Times screen

4. **Check Madhab**:
   - Ensure correct madhab is selected
   - Try switching madhab to refresh

### Debugging

Check pending notifications:
```dart
final pending = await PrayerNotificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

## Future Enhancements

Potential improvements:
- [ ] Custom notification sounds (Adhan audio)
- [ ] Notification for optional prayers (Tahajjud, Ishraq, etc.)
- [ ] Reminder before prayer time (5/10/15 minutes)
- [ ] Notification customization per prayer
- [ ] Silent mode during specific hours
- [ ] Notification history/log

## Technical Details

### Dependencies
- `flutter_local_notifications`: ^17.0.0
- `adhan_dart`: Prayer time calculations
- `geolocator`: GPS location
- `timezone`: Timezone handling

### Architecture
```
PrayerTime Screen
    ↓
PrayerNotificationService
    ↓
flutter_local_notifications
    ↓
System Notifications
```

## Summary

This implementation provides a complete, production-ready prayer notification system with:
- ✅ Full Hanafi and Shafi madhab support
- ✅ Accurate prayer time calculations
- ✅ User-friendly toggle interface
- ✅ Persistent notification preferences
- ✅ Automatic rescheduling
- ✅ Proper timezone handling

The system is now ready to notify users at the correct prayer times based on their location and chosen madhab!
