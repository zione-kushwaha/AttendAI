import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';
import 'package:hajiri/common/widgets/stylish_container.dart';

class AnimatedEmptyState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? animationAsset;
  final double? animationSize;
  final IconData? icon;
  final Color? iconColor;
  final bool showGradient;

  const AnimatedEmptyState({
    Key? key,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.animationAsset,
    this.animationSize,
    this.icon,
    this.iconColor,
    this.showGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (animationAsset != null)
              Lottie.asset(
                animationAsset!,
                width: animationSize ?? 200,
                height: animationSize ?? 200,
                repeat: true,
              ),
            if (animationAsset == null && icon != null)
              StylishContainer.circle(
                    size: animationSize ?? 140,
                    padding: EdgeInsets.zero,
                    color:
                        showGradient
                            ? AppColors.primary.withOpacity(0.7)
                            : iconColor?.withOpacity(0.1) ??
                                theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      icon,
                      size: (animationSize ?? 140) * 0.5,
                      color: iconColor ?? theme.colorScheme.primary,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                  ),
            const SizedBox(height: 32),
            Text(
              message,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                    onPressed: onButtonPressed,
                    icon: const Icon(Icons.add),
                    label: Text(buttonText!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      foregroundColor: Colors.white,
                      backgroundColor:
                          isDarkMode ? AppColors.primary : AppColors.primary,
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                  )
                  .moveY(
                    begin: 20,
                    end: 0,
                    curve: Curves.easeOutQuad,
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
