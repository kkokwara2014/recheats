import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

/// RechEats brand mark used on the splash screen.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          AppAssets.brandLogo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: 'RechEats',
        ),
      ),
    );
  }
}
