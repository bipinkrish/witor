import 'package:flutter/material.dart';

class WitorIcon extends StatelessWidget {
  const WitorIcon({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/witor.png',
    width: size,
    height: size,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}

class WitorWordmark extends StatelessWidget {
  const WitorWordmark({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      WitorIcon(size: 32),
      SizedBox(width: 9),
      Text(
        'witor',
        style: TextStyle(
          fontSize: 23,
          letterSpacing: -1,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class WitorHeroMark extends StatelessWidget {
  const WitorHeroMark({super.key, required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: .62,
    heightFactor: .7,
    child: Image.asset(
      'assets/brand/witor-mark.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      color: dark ? null : const Color(0xff12615e),
    ),
  );
}
