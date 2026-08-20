import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String note;
  const PlaceholderScreen({super.key, required this.title, required this.note});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
            const SizedBox(height: 8),
            Text(note,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: C.text3, height: 1.5)),
          ]),
        ),
      );
}
