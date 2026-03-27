import 'package:flutter/material.dart';

/// Joueur persistant dans le carnet de joueurs.
class Player {
  final String id;
  final String name;
  final int colorValue; // Couleur stockée en int pour la sérialisation

  Player({
    String? id,
    required this.name,
    int? colorValue,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        colorValue = colorValue ?? Colors.blue.value;

  Color get color => Color(colorValue);

  /// Initiales pour l'avatar.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length.clamp(0, 2)).toUpperCase();
  }

  Player copyWith({String? name, int? colorValue}) {
    return Player(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Player && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

/// Couleurs prédéfinies pour les joueurs.
class PlayerColors {
  static const List<Color> palette = [
    Color(0xFF1565C0), // Bleu
    Color(0xFFC62828), // Rouge
    Color(0xFF2E7D32), // Vert
    Color(0xFFF9A825), // Jaune
    Color(0xFF6A1B9A), // Violet
    Color(0xFFE65100), // Orange
    Color(0xFF00838F), // Cyan
    Color(0xFF4E342E), // Marron
  ];
}
