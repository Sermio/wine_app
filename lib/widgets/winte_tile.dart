// Ejemplo: widgets/wine_tile.dart

import 'package:flutter/material.dart';
import '../models/wine_model.dart';

class WineTile extends StatelessWidget {
  final Wine wine;
  final VoidCallback onTap;

  const WineTile({super.key, required this.wine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(wine.imageUrl, width: 50, height: 50),
      title: Text(wine.name),
      onTap: onTap,
    );
  }
}
