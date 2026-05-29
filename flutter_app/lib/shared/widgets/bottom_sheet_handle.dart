import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)));
}
