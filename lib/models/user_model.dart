import 'dart:convert';

class UserModel {
  final String nik;
  final String email;
  final String name;
  final int points;
  final String level;

  UserModel({
    required this.nik,
    required this.email,
    required this.name,
    this.points = 0,
    this.level = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'nik': nik,
      'email': email,
      'name': name,
      'points': points,
      'level': level,
    };
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      nik: map['nik']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      level: map['level']?.toString() ?? 'user',
    );
  }

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(nik: $nik, email: $email, name: $name, points: $points, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.nik == nik &&
        other.email == email &&
        other.name == name &&
        other.points == points &&
        other.level == level;
  }

  @override
  int get hashCode =>
      nik.hashCode ^
      email.hashCode ^
      name.hashCode ^
      points.hashCode ^
      level.hashCode;

  UserModel copyWith({
    String? nik,
    String? email,
    String? name,
    int? points,
    String? level,
  }) {
    return UserModel(
      nik: nik ?? this.nik,
      email: email ?? this.email,
      name: name ?? this.name,
      points: points ?? this.points,
      level: level ?? this.level,
    );
  }
}
