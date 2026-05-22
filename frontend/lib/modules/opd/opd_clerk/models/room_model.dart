/// Room Model representing an OPD Room/Station
/// Implements OOP principles with encapsulation and immutability
class Room {
  final String id;
  final String code;
  final String name;
  final String floor;
  final String service;
  final String queuePrefix;
  final String doctor;
  final String status;

  const Room({
    required this.id,
    required this.code,
    required this.name,
    required this.floor,
    required this.service,
    required this.queuePrefix,
    required this.doctor,
    required this.status,
  });

  /// Factory constructor for creating Room from JSON/Map
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toString() ?? '',
      code: map['code'] as String,
      name: map['name'] as String,
      floor: map['floor'] as String,
      service: map['service'] as String,
      queuePrefix: map['queuePrefix'] as String,
      doctor: map['doctor'] as String,
      status: map['status'] as String,
    );
  }

  /// Factory constructor for creating Room from JSON (API response)
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      queuePrefix: json['queuePrefix']?.toString() ?? '',
      doctor: json['doctor']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Open',
    );
  }

  /// Convert Room to Map for API calls
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'floor': floor,
      'service': service,
      'queuePrefix': queuePrefix,
      'doctor': doctor,
      'status': status,
    };
  }

  /// Convert Room to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'floor': floor,
      'service': service,
      'queuePrefix': queuePrefix,
      'doctor': doctor,
      'status': status,
    };
  }

  /// CopyWith method for immutable updates (Fluent Interface pattern)
  Room copyWith({
    String? id,
    String? code,
    String? name,
    String? floor,
    String? service,
    String? queuePrefix,
    String? doctor,
    String? status,
  }) {
    return Room(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      service: service ?? this.service,
      queuePrefix: queuePrefix ?? this.queuePrefix,
      doctor: doctor ?? this.doctor,
      status: status ?? this.status,
    );
  }

  bool get isOpen => status == 'Open';
  bool get isClosed => status == 'Closed';

  @override
  String toString() => 'Room($code - $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Room Statistics Model
class RoomStats {
  final int totalRooms;
  final int openRooms;
  final int closedRooms;
  final int totalServices;

  const RoomStats({
    required this.totalRooms,
    required this.openRooms,
    required this.closedRooms,
    required this.totalServices,
  });

  /// Calculate stats from list of rooms
  factory RoomStats.fromRooms(List<Room> rooms, {int totalServices = 5}) {
    final openCount = rooms.where((r) => r.isOpen).length;
    return RoomStats(
      totalRooms: rooms.length,
      openRooms: openCount,
      closedRooms: rooms.length - openCount,
      totalServices: totalServices,
    );
  }
}
