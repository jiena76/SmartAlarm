enum AlarmType { locationGated, regular }

enum SnoozeMode { fixed, progressive }

enum VolumeMode { fixed, escalating }

class AlarmModel {
  final String id;
  final DateTime triggerTime;
  final AlarmType type;
  final String? eventTitle;
  final String? eventLocation;
  final SnoozeMode snoozeMode;
  final VolumeMode volumeMode;
  final int snoozeDurationMinutes;
  final bool isActive;

  AlarmModel({
    required this.id,
    required this.triggerTime,
    required this.type,
    this.eventTitle,
    this.eventLocation,
    this.snoozeMode = SnoozeMode.fixed,
    this.volumeMode = VolumeMode.fixed,
    this.snoozeDurationMinutes = 10,
    this.isActive = true,
  });

  AlarmModel copyWith({
    String? id,
    DateTime? triggerTime,
    AlarmType? type,
    String? eventTitle,
    String? eventLocation,
    SnoozeMode? snoozeMode,
    VolumeMode? volumeMode,
    int? snoozeDurationMinutes,
    bool? isActive,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      triggerTime: triggerTime ?? this.triggerTime,
      type: type ?? this.type,
      eventTitle: eventTitle ?? this.eventTitle,
      eventLocation: eventLocation ?? this.eventLocation,
      snoozeMode: snoozeMode ?? this.snoozeMode,
      volumeMode: volumeMode ?? this.volumeMode,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }
}
