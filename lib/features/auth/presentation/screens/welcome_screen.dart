import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E70CD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(context);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1E70CD),
            child: Center(
              child: Image.asset(
                'assets/images/Logo_SIRE.png',
                width: 250,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1E70CD),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo_SIRE.png',
                  width: 180,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            color: const Color(0xFF1E70CD),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(isActive: true),
            _buildDot(isActive: false),
            _buildDot(isActive: false),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          'Sistema Integral de Reservas Estratégicas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Encuentra y reserva espacios cerca de ti.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 40),
        CustomButton(
          text: 'Comenzar',
          onPressed: () {
            context.push('/location');
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ya tengo cuenta. ',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            GestureDetector(
              onTap: () {
                context.push('/login');
              },
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: Color(0xFF1E70CD),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E70CD) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}