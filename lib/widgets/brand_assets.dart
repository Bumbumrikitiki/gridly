import 'package:flutter/material.dart';

class BrandAssets {
  static const String logoMark = 'assets/images/logo_mark.png';
  static const String splashIllustration = 'assets/images/splash_hero.png';
  static const String dashboardHero = 'assets/images/dashboard_hero.png';
  static const String topologyEmpty = 'assets/images/topology_empty.png';
  static const String auditHint = 'assets/images/audit_hint.png';
}

class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        BrandAssets.logoMark,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Icon(
              Icons.bolt,
              size: size * 0.62,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class BrandSubtleIllustration extends StatelessWidget {
  const BrandSubtleIllustration({
    super.key,
    required this.assetPath,
    this.height = 92,
    this.padding = const EdgeInsets.all(10),
  });

  final String assetPath;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: padding,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
