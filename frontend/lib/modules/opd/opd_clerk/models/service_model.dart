/// Service Model
/// Represents an OPD service from the backend
class Service {
  final int id;
  final String code;
  final String name;

  const Service({
    required this.id,
    required this.code,
    required this.name,
  });

  /// Factory constructor for creating Service from JSON (API response)
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  /// Convert Service to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
    };
  }

  @override
  String toString() => '$code - $name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
