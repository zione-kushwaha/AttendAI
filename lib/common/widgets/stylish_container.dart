import 'package:flutter/material.dart';
import 'package:hajiri/common/theme/enhanced_app_theme.dart';

class StylishContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final DecorationImage? backgroundImage;
  final BoxShape shape;
  final Alignment alignment;
  final Matrix4? transform;
  final double? elevation;

  const StylishContainer({
    Key? key,
    required this.child,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 0.0,
    this.boxShadow,
    this.gradient,
    this.backgroundImage,
    this.shape = BoxShape.rectangle,
    this.alignment = Alignment.center,
    this.transform,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.surface;
    final effectiveBorderRadius =
        shape == BoxShape.rectangle
            ? borderRadius ?? BorderRadius.circular(16.0)
            : null;

    final effectiveBoxShadow =
        boxShadow ??
        (elevation != null
            ? [
              BoxShadow(
                color: AppColors.gray700.withOpacity(0.15),
                blurRadius: elevation! * 3,
                spreadRadius: elevation! * 0.4,
                offset: Offset(0, elevation! * 0.7),
              ),
            ]
            : null);

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin,
      alignment: alignment,
      transform: transform,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveBorderRadius,
        shape: shape,
        border:
            borderWidth > 0
                ? Border.all(
                  color: borderColor ?? AppColors.gray300,
                  width: borderWidth,
                )
                : null,
        boxShadow: effectiveBoxShadow,
        gradient: gradient,
        image: backgroundImage,
      ),
      child: child,
    );
  }

  // Factory constructors for common styles

  // Primary colored container
  factory StylishContainer.primary({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return StylishContainer(
      child: child,
      color: AppColors.primary,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      elevation: elevation,
    );
  }

  // Container with gradient
  factory StylishContainer.gradient({
    required Widget child,
    required Gradient gradient,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return StylishContainer(
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      gradient: gradient,
      elevation: elevation,
    );
  }

  // Card-like container
  factory StylishContainer.card({
    required Widget child,
    Color? color,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return StylishContainer(
      child: child,
      color: color,
      width: width,
      height: height,
      padding: padding,
      margin:
          margin ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      borderRadius: borderRadius,
      elevation: elevation ?? 4.0,
    );
  }

  // Circle container
  factory StylishContainer.circle({
    required Widget child,
    Color? color,
    double? size,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
    double borderWidth = 0.0,
    double? elevation,
  }) {
    return StylishContainer(
      child: child,
      color: color,
      width: size,
      height: size,
      padding: padding,
      margin: margin,
      shape: BoxShape.circle,
      borderColor: borderColor,
      borderWidth: borderWidth,
      elevation: elevation,
    );
  }
}
