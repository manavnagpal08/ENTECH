import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScaffold;
  final Widget webScaffold;

  const ResponsiveLayout({
    super.key,
    required this.mobileScaffold,
    required this.webScaffold,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return mobileScaffold;
        } else {
          return webScaffold;
        }
      },
    );
  }
}
