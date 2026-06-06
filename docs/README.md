# 📦 Assets de publication Play Store

Ce dossier contient tous les livrables nécessaires pour la fiche Play Store de Coach Tarot.

## 📁 Contenu

| Fichier | Usage |
|---|---|
| `index.html` | Page d'accueil GitHub Pages (`https://tgreneche.github.io/tarot_coach/`) |
| `privacy.html` | Politique de confidentialité (URL obligatoire dans Play Console) |
| `store-listing.md` | Textes prêts à coller (titre, descriptions, catégorie, etc.) |
| `feature-graphic.svg` | Visuel 1024×500 pour la "Feature graphic" Play Store |
| `screenshot-mockups.html` | Cadres téléphone pour habiller tes captures d'app |
| `screenshots/` | (À créer) Tes captures `.png` de l'app, nommées `01-home.png`, etc. |

## 🚀 Activer GitHub Pages

Pour que la privacy policy soit accessible publiquement :

1. Aller sur [github.com/tgreneche/tarot_coach/settings/pages](https://github.com/tgreneche/tarot_coach/settings/pages)
2. **Source** → `Deploy from a branch`
3. **Branch** → `master` (ou `main`), dossier `/docs`
4. **Save**
5. Attendre ~1 minute → l'URL `https://tgreneche.github.io/tarot_coach/` devient active
6. La privacy policy est à `https://tgreneche.github.io/tarot_coach/privacy.html`

## 🖼️ Exporter le feature graphic en PNG

1. Ouvrir `feature-graphic.svg` dans un navigateur (double-clic depuis l'explorateur)
2. Le navigateur affiche le visuel à la taille exacte 1024×500
3. Clic droit → "Enregistrer l'image sous..." → `feature-graphic.png`
4. Uploader dans Play Console

Alternative : convertir via [svgtopng.com](https://svgtopng.com) (drag & drop le SVG).

## 📸 Préparer les screenshots

1. Lancer l'app sur un émulateur Pixel 7 (Android Studio → Device Manager)
2. Capturer chaque écran clé en `1080 × 1920` (portrait standard)
3. Placer les PNG dans `docs/screenshots/` avec les noms attendus
4. Ouvrir `screenshot-mockups.html` pour visualiser le rendu final
