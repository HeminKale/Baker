/// The logged-in user's account info (06_profile_and_account.md's Profile
/// Card + Edit Profile screen). `phone` is read-only everywhere in the UI --
/// it's the OTP login identity (Key Rules).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.email,
    this.phone,
    this.fullName,
    this.businessName,
    this.gstin,
    this.avatarUrl,
  });

  final String id;
  final String role;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? businessName;
  final String? gstin;
  final String? avatarUrl;

  /// Fallback shown in the top bar / Profile Overlay avatar when there's no
  /// `avatarUrl` yet -- up to 2 uppercase letters, matching the initials-badge
  /// pattern in the Milestone 5 mockups.
  String get initials {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory UserProfile.fromUserJson(Map<String, dynamic> user, {required String role}) {
    return UserProfile(
      id: user['id'] as String,
      role: role,
      email: user['email'] as String?,
      phone: user['phone'] as String?,
      fullName: user['fullName'] as String?,
      businessName: user['businessName'] as String?,
      gstin: user['gstin'] as String?,
      avatarUrl: user['avatarUrl'] as String?,
    );
  }

  /// Shape of GET /v1/users/me -- `{ data: { user: {...}, role: '...' } }`.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile.fromUserJson(json['user'] as Map<String, dynamic>, role: json['role'] as String? ?? '');
  }

  UserProfile copyWith({
    String? fullName,
    String? businessName,
    String? gstin,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      role: role,
      email: email,
      phone: phone,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      gstin: gstin ?? this.gstin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
