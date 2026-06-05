import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../theme/app_theme.dart';

/// Écran d'achat du pack "Sans publicité".
///
/// Affiche les avantages, le prix localisé, et propose les boutons
/// "Acheter" + "Restaurer mes achats" (obligatoire côté Google).
class PremiumScreen extends StatefulWidget {
  final PremiumService premium;

  const PremiumScreen({super.key, required this.premium});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.premium.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.premium.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.premium.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Merci ! Les publicités sont désactivées.')),
      );
    }
    if (widget.premium.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.premium.lastError!)),
      );
    }
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    await widget.premium.buyPremium();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    await widget.premium.restorePurchases();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isPremium = widget.premium.isPremium;
    final available = widget.premium.available;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Tarot Premium')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // === Header ===
              Icon(Icons.workspace_premium, size: 72, color: t.gold),
              const SizedBox(height: 12),
              Text(
                isPremium
                    ? 'Vous êtes Premium ✨'
                    : 'Soutenez Coach Tarot',
                textAlign: TextAlign.center,
                style: t.titleFont(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPremium
                    ? 'Les publicités sont définitivement désactivées. Merci !'
                    : 'Un achat unique pour supprimer toutes les publicités '
                        'et soutenir le développement.',
                textAlign: TextAlign.center,
                style: t.bodyFont(fontSize: 14, color: t.textSecondary),
              ),
              const SizedBox(height: 28),

              // === Avantages ===
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      _Benefit(
                        icon: Icons.block,
                        title: 'Aucune publicité',
                        subtitle: 'Bannières masquées pour toujours',
                      ),
                      Divider(height: 20),
                      _Benefit(
                        icon: Icons.flash_on,
                        title: 'Expérience fluide',
                        subtitle: 'Plus de chargements pub, plus de tracking',
                      ),
                      Divider(height: 20),
                      _Benefit(
                        icon: Icons.favorite,
                        title: 'Soutien au développeur',
                        subtitle: 'Aide à maintenir l\'app et ajouter des fonctionnalités',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // === CTA ===
              if (isPremium) ...[
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Premium activé'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: (_busy || !available) ? null : _buy,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: t.gold,
                    foregroundColor: Colors.white,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Acheter pour ${widget.premium.displayPrice}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restaurer mes achats'),
                ),
                if (!available) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: t.error.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: t.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'La facturation Play Store n\'est pas '
                              'disponible sur cet appareil. Connectez-vous à '
                              'votre compte Google Play et réessayez.',
                              style: t.bodyFont(
                                fontSize: 12,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              Text(
                'Achat unique, sans abonnement. Géré par Google Play.',
                textAlign: TextAlign.center,
                style: t.bodyFont(fontSize: 11, color: t.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: t.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: t.gold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleFont(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodyFont(fontSize: 12, color: t.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
