import 'project.dart';
import 'project_item.dart';

class ProjectDetail {
  const ProjectDetail({
    required this.project,
    required this.items,
    required this.estimatedTotal,
    required this.originalTotal,
  });

  final Project project;
  final List<ProjectItem> items;
  final int estimatedTotal;
  final int originalTotal;

  /// Struck-through original total is only meaningful when it's actually
  /// higher than the estimate -- 07_projects.md §6.
  bool get hasDiscount => originalTotal > estimatedTotal;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      project: Project.fromJson(json),
      items: (json['items'] as List).map((e) => ProjectItem.fromJson(e as Map<String, dynamic>)).toList(),
      estimatedTotal: json['estimatedTotal'] as int,
      originalTotal: json['originalTotal'] as int,
    );
  }
}
