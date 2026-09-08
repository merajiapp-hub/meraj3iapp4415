class AppSettings {
  const AppSettings({
    this.maintenanceMode = false,
    this.maintenanceMessage =
        'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.',
    this.registrationOpen = true,
    this.allowGuestView = false,
  });

  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool registrationOpen;
  final bool allowGuestView;

  AppSettings copyWith({
    bool? maintenanceMode,
    String? maintenanceMessage,
    bool? registrationOpen,
    bool? allowGuestView,
  }) {
    return AppSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      allowGuestView: allowGuestView ?? this.allowGuestView,
    );
  }

  factory AppSettings.fromFirestore(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return AppSettings(
      maintenanceMode: map['isMaintenance'] == true,
      maintenanceMessage: (map['message'] as String?) ??
          'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.',
      registrationOpen: map['registrationOpen'] != false,
      allowGuestView: map['allowGuestView'] == true,
    );
  }
}
