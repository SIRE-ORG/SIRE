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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        if (isWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Row(
              children: [
                _buildSidebar(context, isPublisher),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildFormCard(context, isWeb: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E70CD),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              title: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildFormMobile(context),
            ),
          );
        }
      },
    );
  }

  Widget _buildSidebar(BuildContext context, bool isPublisher) {
    return Container(
      width: 250,
      color: const Color(0xFF1E70CD),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('SIRE', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _buildSidebarItem(context, Icons.home_outlined, 'Inicio', () => context.go('/feed')),
          if (!isPublisher) _buildSidebarItem(context, Icons.calendar_today_outlined, 'Mis Reservas', () => context.go('/my-reservations'))
          else _buildSidebarItem(context, Icons.bar_chart_outlined, 'Dashboard', () => context.go('/dashboard')),
          _buildSidebarItem(context, Icons.person, 'Perfil', () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isWeb}) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editar Perfil', style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900)),
              TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.close, size: 18), label: const Text('Cancelar')),
            ],
          ),
          const SizedBox(height: 40),
          _buildPhotoEditor(),
          const SizedBox(height: 40),
          const CustomTextField(label: 'Nombre completo', hintText: 'María González', keyboardType: TextInputType.name),
          const SizedBox(height: 24),
          const CustomTextField(label: 'Teléfono', hintText: '+56 9 1234 5678', keyboardType: TextInputType.phone),
          const SizedBox(height: 40),
          const Text('Cambiar contraseña', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const CustomTextField(label: 'Contraseña actual', hintText: 'Tu contraseña actual', isPassword: true),
          const SizedBox(height: 24),
          const CustomTextField(label: 'Nueva contraseña', hintText: 'Mínimo 8 caracteres', isPassword: true),
          const SizedBox(height: 24),
          const CustomTextField(label: 'Confirmar contraseña nueva', hintText: 'Repite la contraseña nueva', isPassword: true),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(text: 'Guardar cambios', onPressed: () => context.pop()),
          ),
        ],
      ),
    );
  }

  Widget _buildFormMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoEditor(),
        const SizedBox(height: 32),
        const CustomTextField(label: 'Nombre completo', hintText: 'María González', keyboardType: TextInputType.name),
        const SizedBox(height: 20),
        const CustomTextField(label: 'Teléfono', hintText: '+56 9 1234 5678', keyboardType: TextInputType.phone),
        const SizedBox(height: 40),
        const Text('Cambiar contraseña', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const CustomTextField(label: 'Contraseña actual', hintText: 'Tu contraseña actual', isPassword: true),
        const SizedBox(height: 20),
        const CustomTextField(label: 'Nueva contraseña', hintText: 'Mínimo 8 caracteres', isPassword: true),
        const SizedBox(height: 20),
        const CustomTextField(label: 'Confirmar contraseña nueva', hintText: 'Repite la contraseña nueva', isPassword: true),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 50, child: CustomButton(text: 'Guardar cambios', onPressed: () => context.pop())),
      ],
    );
  }

  Widget _buildPhotoEditor() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0), width: 4)),
            child: const Icon(Icons.person, size: 70, color: Color(0xFF94A3B8)),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF1E70CD), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}