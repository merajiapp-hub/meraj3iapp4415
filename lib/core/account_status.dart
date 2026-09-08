class AccountStatusSnapshot {
  final bool isSuspended;
  final String accountStatus;
  final String reason;
  final DateTime? suspensionStartAt;
  final DateTime? suspensionEndAt;
  final DateTime? suspendedAt;
  final String? suspendedBy;

  const AccountStatusSnapshot({
    required this.isSuspended,
    required this.accountStatus,
    required this.reason,
    this.suspensionStartAt,
    this.suspensionEndAt,
    this.suspendedAt,
    this.suspendedBy,
  });

  bool get hasActiveSuspension => isSuspended;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is Map && value.containsKey('_seconds')) {
    final seconds = value['_seconds'];
    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    }
  }
  return null;
}

AccountStatusSnapshot normalizeAccountStatus(
  Map<String, dynamic>? data, {
  DateTime? now,
}) {
  final referenceNow = now ?? DateTime.now();
  final rawStatus = (data?['accountStatus'] ?? data?['status'] ?? 'active')
      .toString()
      .trim()
      .toLowerCase();
  final instructedSuspended = data?['isSuspended'] == true;
  final legacySuspended = rawStatus == 'suspended';
  final suspensionEndAt = _readDateTime(data?['suspensionEndAt']);

  bool isSuspended = instructedSuspended || legacySuspended;

  if (suspensionEndAt != null && isSuspended && suspensionEndAt.isBefore(referenceNow)) {
    isSuspended = false;
  }

  final reason = (data?['suspensionReason'] ?? data?['reason'] ?? '').toString();
  final accountStatus = isSuspended ? 'suspended' : 'active';

  return AccountStatusSnapshot(
    isSuspended: isSuspended,
    accountStatus: accountStatus,
    reason: reason,
    suspensionStartAt: _readDateTime(data?['suspensionStartAt']),
    suspensionEndAt: suspensionEndAt,
    suspendedAt: _readDateTime(data?['suspendedAt']),
    suspendedBy: data?['suspendedBy']?.toString(),
  );
}
