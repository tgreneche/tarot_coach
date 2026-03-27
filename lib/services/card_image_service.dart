import 'package:flutter/material.dart';

/// Service qui gère les images de cartes de Tarot.
///
/// Quand des assets d'images seront disponibles, il suffira de :
/// 1. Placer les images dans assets/cards/ (ex: atout_1.png, coeur_14.png)
/// 2. Les déclarer dans pubspec.yaml sous flutter > assets
/// 3. Activer [useCustomImages] en passant à true
///
/// Convention de nommage des fichiers :
///   {suit}_{rank}.png
///   Exemples : atout_0.png (Excuse), atout_1.png (Petit),
///              coeur_14.png (Roi de Cœur), pique_7.png (7 de Pique)
class CardImageService {
  CardImageService._();

  static final CardImageService instance = CardImageService._();

  /// Passer à true quand les images custom sont disponibles dans assets/cards/
  bool useCustomImages = false;

  /// Chemin de base des assets d'images.
  static const String _basePath = 'assets/cards';

  /// Retourne le chemin de l'asset pour une carte donnée.
  /// [suitName] : nom du suit (coeur, carreau, trefle, pique, atout)
  /// [rank] : rang de la carte
  String getAssetPath(String suitName, int rank) {
    return '$_basePath/${suitName}_$rank.png';
  }

  /// Vérifie si une image custom est disponible pour cette carte.
  /// Utilise un try/catch car AssetImage peut échouer si l'asset n'existe pas.
  bool get isAvailable => useCustomImages;

  /// Retourne un widget Image si l'image custom est disponible,
  /// sinon retourne null (le widget appelant affichera le design par défaut).
  Widget? getCardImage(String suitName, int rank, {double? width, double? height}) {
    if (!useCustomImages) return null;

    return Image.asset(
      getAssetPath(suitName, rank),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Si l'image n'est pas trouvée, retourne un widget vide
        // pour que le fallback par défaut s'affiche
        return const SizedBox.shrink();
      },
    );
  }
}
