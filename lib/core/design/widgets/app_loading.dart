import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

class AppLoading extends StatelessWidget {
  final String? label;
  const AppLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.dentalTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.indicatorColor),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(label!, style: theme.textTheme.labelMedium),
          ],
        ],
      ),
    );
  }
}
