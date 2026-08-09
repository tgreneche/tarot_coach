import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service qui gère le stockage local des photos de profil des joueurs.
///
/// Les photos sont copiées dans `<documents>/player_photos/` avec un nom
/// dérivé de l'ID du joueur. On ne stocke dans le modèle [Player] que le
/// nom de fichier relatif (pas le chemin absolu) car le sandbox iOS/Android
/// peut le déplacer entre deux versions de l'app.
class PlayerPhotoService {
  PlayerPhotoService._();
  static final PlayerPhotoService instance = PlayerPhotoService._();

  static const _subDir = 'player_photos';
  static const _maxWidth = 512.0;
  static const _quality = 80;

  final ImagePicker _picker = ImagePicker();

  /// Résout le chemin absolu d'une photo à partir de son nom de fichier
  /// relatif. Retourne null si [fileName] est null ou si le fichier n'existe
  /// plus sur disque.
  Future<File?> resolveFile(String? fileName) async {
    if (fileName == null) return null;
    final dir = await _dir();
    final file = File('${dir.path}/$fileName');
    return await file.exists() ? file : null;
  }

  /// Variante synchrone qui retourne juste le chemin attendu (sans vérifier
  /// l'existence). Utile pour FileImage qui gère lui-même l'absence.
  String? absolutePathSync(String? fileName, String docsPath) {
    if (fileName == null) return null;
    return '$docsPath/$_subDir/$fileName';
  }

  /// Capture une photo via l'appareil. Retourne le nom de fichier relatif
  /// stocké, ou null si l'utilisateur a annulé.
  Future<String?> pickFromCamera(String playerId) async {
    final picked = await _safePick(ImageSource.camera);
    if (picked == null) return null;
    return _persist(picked, playerId);
  }

  /// Choisit une photo dans la galerie. Retourne le nom de fichier relatif
  /// stocké, ou null si l'utilisateur a annulé.
  Future<String?> pickFromGallery(String playerId) async {
    final picked = await _safePick(ImageSource.gallery);
    if (picked == null) return null;
    return _persist(picked, playerId);
  }

  /// Supprime le fichier photo associé. Sans effet si [fileName] est null
  /// ou si le fichier n'existe pas.
  Future<void> deletePhoto(String? fileName) async {
    if (fileName == null) return;
    try {
      final dir = await _dir();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PlayerPhotoService.deletePhoto failed : $e');
    }
  }

  Future<XFile?> _safePick(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: _maxWidth,
        imageQuality: _quality,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('PlayerPhotoService pick failed : $e');
      return null;
    }
  }

  Future<String> _persist(XFile picked, String playerId) async {
    final dir = await _dir();
    // Un nouveau timestamp évite que FileImage ne serve un cache obsolète
    // quand on remplace la photo d'un même joueur.
    final fileName = '${playerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final target = File('${dir.path}/$fileName');
    await picked.saveTo(target.path);
    return fileName;
  }

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
