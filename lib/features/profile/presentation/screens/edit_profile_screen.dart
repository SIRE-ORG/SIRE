import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/data/datasources/avatar_storage_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  Uint8List? _avatarBytes;
  String? _avatarExtension;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _avatarBytes = bytes;
      _avatarExtension = ext.isEmpty ? 'jpg' : ext;
    });
  }

  Future<void> _handleSave(String userId) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile(
            userId: userId,
            name: name.isNotEmpty ? name : null,
            phone: phone.isNotEmpty ? phone : null,
            avatarBytes: _avatarBytes,
            avatarExtension: _avatarExtension,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// El interceptor de Dio envuelve la [AppException] tipada dentro de
  /// `DioException.error`; acá se desenvuelve para poder mapear el mensaje
  /// visible sin depender del transporte (mismo patrón que
  /// ReservationConfirmScreen).
  Object _unwrap(Object e) => e is DioException ? (e.error ?? e) : e;

  String _errorMessage(Object error) {
    final err = _unwrap(error);
    switch (err) {
      case AvatarUploadException():
        // El upload del avatar ocurre ANTES del PUT /users/me
        // (UpdateProfileUseCase) y hoy falla por configuración pendiente de
        // los buckets en Supabase: distinguirlo evita el mensaje genérico
        // "No se pudo guardar el perfil", que apuntaba al lado equivocado.
        return 'No pudimos subir la foto (almacenamiento en configuración). '
            'Puedes guardar los demás cambios quitando la imagen.';
      case NotFoundException():
      case ServerException(code: 'ENDPOINT_NOT_AVAILABLE'):
        // Cubre tanto "el backend viejo de Render todavía no tiene el
        // endpoint" (404 sin match de shape -> NotFoundException con code
        // UNKNOWN) como "el perfil no existe" una vez desplegado.
        return 'La edición de perfil estará disponible tras la próxima '
            'actualización del servidor';
      case NetworkException():
        return 'Sin conexión. Revisa tu internet e intenta nuevamente.';
      default:
        final code = switch (err) {
          ServerException(:final code) => code,
          ConflictException(:final code) => code,
          NotFoundException(:final code) => code,
          _ => null,
        };
        return code != null
            ? 'No se pudo guardar el perfil (error $code)'
            : 'No se pudo guardar el perfil';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    profileAsync.whenData((profile) {
      if (profile != null) {
        if (_nameController.text.isEmpty) {
          _nameController.text = profile.name;
        }
        if (_phoneController.text.isEmpty && profile.phone != null) {
          _phoneController.text = profile.phone!;
        }
      }
    });

    final userId = profileAsync.value?.id ?? '';
    final existingAvatarUrl = profileAsync.value?.avatarUrl;

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
                        child: _buildFormCard(
                          context,
                          userId: userId,
                          isWeb: true,
                          existingAvatarUrl: existingAvatarUrl,
                        ),
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Editar Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildFormMobile(
                context,
                userId: userId,
                existingAvatarUrl: existingAvatarUrl,
              ),
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
          const Text(
            'SIRE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(
            context,
            Icons.home_outlined,
            'Inicio',
            () => context.go('/feed'),
          ),
          if (!isPublisher)
            _buildSidebarItem(
              context,
              Icons.calendar_today_outlined,
              'Mis Reservas',
              () => context.go('/my-reservations'),
            )
          else
            _buildSidebarItem(
              context,
              Icons.bar_chart_outlined,
              'Dashboard',
              () => context.go('/dashboard'),
            ),
          _buildSidebarItem(
            context,
            Icons.person,
            'Perfil',
            () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildFormCard(
    BuildContext context, {
    required String userId,
    required bool isWeb,
    String? existingAvatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Editar Perfil',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancelar'),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildPhotoEditor(existingAvatarUrl: existingAvatarUrl),
          const SizedBox(height: 40),
          CustomTextField(
            label: 'Nombre completo',
            hintText: 'Tu nombre',
            keyboardType: TextInputType.name,
            controller: _nameController,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Teléfono',
            hintText: '+56 9 1234 5678',
            keyboardType: TextInputType.phone,
            controller: _phoneController,
          ),
          const SizedBox(height: 40),
          const Text(
            'Cambiar contraseña',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'El cambio de contraseña estará disponible próximamente.',
              style: TextStyle(color: Color(0xFFF57C00), fontSize: 13),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              text: _saving ? 'Guardando...' : 'Guardar cambios',
              onPressed: _saving || userId.isEmpty
                  ? null
                  : () => _handleSave(userId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormMobile(
    BuildContext context, {
    required String userId,
    String? existingAvatarUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoEditor(existingAvatarUrl: existingAvatarUrl),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Nombre completo',
          hintText: 'Tu nombre',
          keyboardType: TextInputType.name,
          controller: _nameController,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Teléfono',
          hintText: '+56 9 1234 5678',
          keyboardType: TextInputType.phone,
          controller: _phoneController,
        ),
        const SizedBox(height: 40),
        const Text(
          'Cambiar contraseña',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'El cambio de contraseña estará disponible próximamente.',
            style: TextStyle(color: Color(0xFFF57C00), fontSize: 13),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: _saving ? 'Guardando...' : 'Guardar cambios',
            onPressed: _saving || userId.isEmpty
                ? null
                : () => _handleSave(userId),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoEditor({String? existingAvatarUrl}) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 4),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildAvatarContent(existingAvatarUrl),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E70CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String? existingAvatarUrl) {
    if (_avatarBytes != null) {
      return Image.memory(_avatarBytes!, fit: BoxFit.cover);
    }
    if (existingAvatarUrl != null && existingAvatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: existingAvatarUrl,
        fit: BoxFit.cover,
        placeholder: (_, a) =>
            const Icon(Icons.person, size: 70, color: Color(0xFF94A3B8)),
        errorWidget: (_, a, b) =>
            const Icon(Icons.person, size: 70, color: Color(0xFF94A3B8)),
      );
    }
    return const Icon(Icons.person, size: 70, color: Color(0xFF94A3B8));
  }
}
