import 'package:flutter/material.dart';
import 'package:sis_project/screens/welcome/desktop_screen/welcome_screen.dart';
import 'package:sis_project/screens/welcome/mobile_screen/mobile_welcome_screen.dart';

class ResponsiveWelcomeWrapper extends StatelessWidget {
  const ResponsiveWelcomeWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 768;
        const double tabletBreakpoint = 1024;

        if (constraints.maxWidth < mobileBreakpoint) {
          return const MobileWelcomeScreen();
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return const MobileWelcomeScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(16),
    EdgeInsets tablet = const EdgeInsets.all(24),
    EdgeInsets desktop = const EdgeInsets.all(32),
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
}
