// lib/config/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints estándar
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Obtener tipo de dispositivo
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Verificaciones rápidas
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Padding responsivo
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  // Spacing responsivo
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // Tamaño de fuente responsivo
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return baseSize;
    if (width < tabletBreakpoint) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  // Ancho máximo del contenido
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 700;
    return 900;
  }

  // Número de columnas para grids
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  // Altura de botones
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 56.0;
    if (isTablet(context)) return 60.0;
    return 64.0;
  }

  // Radio de bordes
  static double getBorderRadius(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  // Tamaño de íconos
  static double getIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  // Altura del AppBar
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return kToolbarHeight;
    return kToolbarHeight * 1.2;
  }

  // Padding horizontal del contenido
  static EdgeInsets getContentPadding(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  // Widget con ancho máximo centrado
  static Widget centerConstrainedBox({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  // SizedBox responsivo
  static SizedBox verticalSpace(BuildContext context, {double multiplier = 1.0}) {
    return SizedBox(height: getResponsiveSpacing(context) * multiplier);
  }

  static SizedBox horizontalSpace(BuildContext context, {double multiplier = 1.0}) {
    return SizedBox(width: getResponsiveSpacing(context) * multiplier);
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

// Extension para facilitar el uso
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  double get responsivePadding => ResponsiveHelper.getResponsivePadding(this);
  double get responsiveSpacing => ResponsiveHelper.getResponsiveSpacing(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  
  double responsiveFontSize(double baseSize) =>
      ResponsiveHelper.getResponsiveFontSize(this, baseSize);
  
  double responsiveIconSize(double baseSize) =>
      ResponsiveHelper.getIconSize(this, baseSize);
}