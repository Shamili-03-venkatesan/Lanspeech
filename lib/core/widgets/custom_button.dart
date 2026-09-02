import 'package:flutter/material.dart';
import 'package:lanspeech/core/constants/colors.dart';

enum ButtonType { primary, secondary, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget childWidget;
    if (isLoading) {
      childWidget = SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.primary
                ? AppColors.white
                : (isDark ? AppColors.yellow : AppColors.teal),
          ),
        ),
      );
    } else {
      childWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      );
    }

    Widget button;
    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.teal.withOpacity(0.6),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: SizedBox(
            width: width ?? double.infinity,
            height: 24,
            child: Center(child: childWidget),
          ),
        );
        break;

      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? AppColors.yellow : AppColors.teal,
              width: 2.0,
            ),
            foregroundColor: isDark ? AppColors.yellow : AppColors.teal,
          ),
          child: SizedBox(
            width: width ?? double.infinity,
            height: 24,
            child: Center(child: childWidget),
          ),
        );
        break;

      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.yellow : AppColors.teal,
          ),
          child: childWidget,
        );
        break;
    }

    // Add physical feedback with a Duolingo-style bottom border for primary button
    if (type == ButtonType.primary && !isLoading && onPressed != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.darkTeal,
              offset: Offset(0, 4),
              blurRadius: 0,
            )
          ],
        ),
        margin: const EdgeInsets.only(bottom: 4),
        child: button,
      );
    }

    return button;
  }
}
