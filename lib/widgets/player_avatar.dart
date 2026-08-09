import 'dart:io';

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/player_photo_service.dart';

/// Avatar d'un joueur : photo si présente (et fichier valide), sinon bulle
/// couleur + initiales — comme avant l'ajout des photos.
///
/// On lit le chemin absolu de façon asynchrone (le sandbox iOS/Android peut
/// le déplacer entre deux versions), avec fallback bulle couleur tant que
/// le fichier n'a pas été résolu / s'il a disparu.
class PlayerAvatar extends StatelessWidget {
  final Player player;
  final double radius;
  final double? fontSize;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.radius = 20,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = player.photoFileName;
    if (fileName == null) {
      return _initialsAvatar();
    }

    return FutureBuilder<File?>(
      future: PlayerPhotoService.instance.resolveFile(fileName),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          // En attente de résolution OU fichier disparu : fallback initiales.
          return _initialsAvatar();
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: player.color,
          backgroundImage: FileImage(file),
        );
      },
    );
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: player.color,
      child: Text(
        player.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
