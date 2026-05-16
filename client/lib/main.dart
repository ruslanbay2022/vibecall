import 'package:flutter/material.dart';
import 'package:vibecall/app/env.dart';

void main() {
  Env.assertAll();
  runApp(const _VibeCallBootstrap());
}

class _VibeCallBootstrap extends StatelessWidget {
  const _VibeCallBootstrap();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeCall',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('VibeCall'),
              const SizedBox(height: 8),
              Text(
                'env: ${Env.env}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
