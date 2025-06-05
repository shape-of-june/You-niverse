import 'package:flutter/material.dart';
import 'dart:math' as math;

class Planet {
  final String name;
  final double importance; // 0.0 to 1.0, affects size
  final double friendliness; // 0.0 to 1.0, affects distance from sun
  final Color color;
  final double speed; // Random orbital speed between 0.3 and 2.0

  Planet({
    required this.name,
    required this.importance,
    required this.friendliness,
    required this.color,
    double? speed,
  }) : speed = speed ??
            (0.3 +
                math.Random().nextDouble() *
                    1.7); // Random speed between 0.3 and 2.0

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      name: json['name'],
      importance: json['importance'],
      friendliness: json['friendliness'],
      color: Color(json['color']),
      speed: json['speed'] ?? (0.3 + math.Random().nextDouble() * 1.7),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'importance': importance,
      'friendliness': friendliness,
      'color': color.value,
      'speed': speed,
    };
  }

  // Add these overrides:
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // If they are the same instance

    return other is Planet && // If the other object is also a Planet
        other.name == name &&
        other.importance == importance &&
        other.friendliness == friendliness &&
        other.color == color &&
        other.speed == speed; // Compare all relevant fields
  }

  @override
  int get hashCode {
    // Combine the hash codes of all relevant fields
    return name.hashCode ^
        importance.hashCode ^
        friendliness.hashCode ^
        color.hashCode ^
        speed.hashCode;
  }
}
