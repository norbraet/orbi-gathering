import 'package:flutter/material.dart';

import '../design/theme/app_theme.dart';
import 'router.dart';

class OrbiGatheringApp extends StatelessWidget {
  const OrbiGatheringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OrbiGathering',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
