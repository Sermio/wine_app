// Ejemplo: widgets/rating_bar.dart

import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final void Function(int) onRatingSelected;

  const RatingBar({super.key, required this.onRatingSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(10, (index) {
        return IconButton(
          icon: Icon(Icons.star_border),
          onPressed: () => onRatingSelected(index + 1),
        );
      }),
    );
  }
}
