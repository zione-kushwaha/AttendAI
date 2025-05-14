import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';

class AnimationHelpers {
  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    double from = 0.0,
    Curve curve = Curves.easeIn,
  }) {
    return FadeIn(duration: duration, child: child);
  }

  // Fade in down animation
  static Widget fadeInDown({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double from = 20.0,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return FadeInDown(duration: duration, from: from, child: child);
  }

  // Fade in up animation
  static Widget fadeInUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double from = 20.0,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return FadeInUp(duration: duration, from: from, child: child);
  }

  // Sliding animation
  static Widget slideIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 500),
    Offset offset = const Offset(0.0, 50.0),
    Curve curve = Curves.easeOutQuart,
  }) {
    return child
        .animate(delay: delay)
        .slide(begin: offset, duration: duration, curve: curve)
        .fade(begin: 0.0, end: 1.0, duration: duration, curve: curve);
  }

  // Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double beginScale = 0.8,
    Curve curve = Curves.easeOutBack,
  }) {
    return child
        .animate(delay: delay)
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: curve,
        )
        .fade(begin: 0.0, end: 1.0, duration: duration, curve: curve);
  }

  // Staggered list animation
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration initialDelay = Duration.zero,
    Duration staggerDuration = const Duration(milliseconds: 50),
    Duration animationDuration = const Duration(milliseconds: 400),
    Offset offset = const Offset(0.0, 30.0),
    Curve curve = Curves.easeOutQuart,
  }) {
    return List.generate(
      children.length,
      (index) => slideIn(
        child: children[index],
        delay: initialDelay + (staggerDuration * index),
        duration: animationDuration,
        offset: offset,
        curve: curve,
      ),
    );
  }

  // Pulse animation for button press
  static Widget pulse({required Widget child}) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
  }

  // Loading spinner
  static Widget loadingSpinner({Color? color, double size = 50.0}) {
    return SpinKitCubeGrid(color: color ?? AppColors.primary, size: size);
  }

  // Shimmer loading effect
  static Widget shimmerLoading({required Widget child}) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: Colors.white.withOpacity(0.3),
        );
  }

  // Shake animation for error
  static Widget shakeError({required Widget child}) {
    return child.animate().shake(
      hz: 4,
      rotation: 0.05,
      curve: Curves.elasticOut,
    );
  }
}
