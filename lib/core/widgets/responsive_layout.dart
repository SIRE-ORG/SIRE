import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              if (MediaQuery.of(context).size.width > 450)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: SafeArea(child: child),
        ),
      ),
    );
  }
}
