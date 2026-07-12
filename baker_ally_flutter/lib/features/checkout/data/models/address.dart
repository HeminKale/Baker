/// A saved delivery address (00_common_architecture.md §4). Milestone 3 uses
/// list + add only; edit/delete are Phase 5.
class Address {
  const Address({
    required this.id,
    required this.line1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
    this.label,
    this.line2,
  });

  final String id;
  final String? label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  /// One-line summary shown on the checkout CTA bar.
  String get shortLine => [line1, city].where((s) => s.isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String?,
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
    );
  }
}
