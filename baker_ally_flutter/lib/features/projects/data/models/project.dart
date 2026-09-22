class Project {
  const Project({
    required this.id,
    required this.name,
    required this.status,
    required this.itemCount,
    required this.estimatedTotal,
    this.eventDate,
    this.clientName,
    this.clientPhone,
    this.notes,
    this.coverImageUrl,
  });

  final String id;
  final String name;
  final String status; // 'active' | 'completed'
  final int itemCount;
  final int estimatedTotal;
  final DateTime? eventDate;
  final String? clientName;
  final String? clientPhone;
  final String? notes;
  final String? coverImageUrl;

  bool get isCompleted => status == 'completed';

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      itemCount: json['itemCount'] as int? ?? 0,
      estimatedTotal: json['estimatedTotal'] as int? ?? 0,
      eventDate: json['eventDate'] != null ? DateTime.parse(json['eventDate'] as String) : null,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      notes: json['notes'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
    );
  }
}
