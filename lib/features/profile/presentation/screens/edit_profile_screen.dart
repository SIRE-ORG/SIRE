import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomTextField(label: 'Nombre', hintText: 'María González'),
                  const SizedBox(height: 16),
                  const CustomTextField(label: 'Teléfono', hintText: '+56 9 1234 5678', keyboardType: TextInputType.phone),
                  const SizedBox(height: 32),
                  const Text('Cambiar contraseña', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const CustomTextField(label: 'Contraseña actual', hintText: 'Tu contraseña actual', isPassword: true),
                  const SizedBox(height: 16),
                  const CustomTextField(label: 'Nueva contraseña', hintText: 'Mínimo 8 caracteres', isPassword: true),
                  const SizedBox(height: 16),
                  const CustomTextField(label: 'Confirmar contraseña nueva', hintText: 'Repite la contraseña nueva', isPassword: true),
                  const SizedBox(height: 40),
                  CustomButton(text: 'Guardar cambios', onPressed: () => context.pop()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, isPublisher),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: const BoxDecoration(color: Color(0xFF1E70CD)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Editar perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF1E70CD), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isPublisher) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 80, right: 80),
        height: 60,
        decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(onTap: () => context.go('/feed'), child: const Icon(Icons.home_outlined, color: Colors.white)),
            if (!isPublisher)
              InkWell(onTap: () => context.go('/my-reservations'), child: const Icon(Icons.calendar_today_outlined, color: Colors.white))
            else
              InkWell(onTap: () => context.go('/dashboard'), child: const Icon(Icons.bar_chart, color: Colors.white)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}