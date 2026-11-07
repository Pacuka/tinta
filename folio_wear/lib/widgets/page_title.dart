import 'package:flutter/material.dart';
import 'edge_fade.dart';

class PageTitle extends StatelessWidget {
  final String text;
  const PageTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => EdgeFade(
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
