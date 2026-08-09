import 'package:flutter/material.dart';

/// Joueur persistant dans le carnet de joueurs.
class Player {
  final String id;
  final String name;
  final int colorValue; // Couleur stockée en int pour la sérialisation
  /// Nom du fichier de la photo de profil, relatif au dossier de l'app.
  /// null si le joueur n'a pas de photo (fallback bulle couleur + initiales).
  final String? photoFileName;

  Player({
    String? id,
    required this.name,
    int? colorValue,
    this.photoFileName,
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

  Player copyWith({
    String? name,
    int? colorValue,
    Object? photoFileName = _sentinel,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      photoFileName: identical(photoFileName, _sentinel)
          ? this.photoFileName
          : photoFileName as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        if (photoFileName != null) 'photoFileName': photoFileName,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int?,
        photoFileName: json['photoFileName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Player && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

/// Sentinelle pour distinguer "non fourni" de "null explicite" dans copyWith.
const Object _sentinel = Object();

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
