import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/chile_regions.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../feed/presentation/providers/feed_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _detecting = false;
  // true mientras se evalúa si corresponde el salto automático (E): la
  // pantalla no se dibuja hasta saber si hay que mostrarla.
  bool _checkingAutoSkip = true;

  @override
  void initState() {
    super.initState();
    _maybeAutoSkip();
  }

  /// E: si el permiso de ubicación ya está concedido (usuario que vuelve a
  /// pasar por acá, o reinstaló con permisos ya otorgados a nivel de SO) y
  /// además hay región cacheada o la detección resuelve, se salta esta
  /// pantalla y se entra directo a /feed sin requerir el tap de "Permitir
  /// ubicación". Si el permiso no está concedido, o está pero no hay caché
  /// ni la detección resuelve, se muestra la pantalla normal.
  Future<void> _maybeAutoSkip() async {
    try {
      final hasPermission = await ref
          .read(geoDatasourceProvider)
          .hasLocationPermission();
      if (!hasPermission) return;

      final cachedRegion = await const LocalStorageService().read(
        StorageKeys.region,
      );
      if (cachedRegion != null && cachedRegion.isNotEmpty) {
        if (mounted) context.go('/feed');
        return;
      }

      // Sin caché pero con permiso ya concedido: la detección debería
      // resolver sin mostrar ningún diálogo nativo (ya está autorizado).
      final loc = await ref.read(geoDatasourceProvider).getCurrentLocation();
      const LocalStorageService()
          .write(StorageKeys.region, loc.region)
          .ignore();
      final city = loc.city;
      if (city != null && city.isNotEmpty) {
        const LocalStorageService().write(StorageKeys.city, city).ignore();
      }
      if (mounted) context.go('/feed');
    } catch (_) {
      // No se pudo resolver en automático: se cae a la pantalla normal,
      // el usuario decide (permitir de nuevo o elegir manualmente).
    } finally {
      if (mounted) setState(() => _checkingAutoSkip = false);
    }
  }

  /// Pide la ubicación real (dispara el permiso nativo vía Geolocator), cachea
  /// la región y entra al feed. Si falla (denegado / sin soporte), avisa y entra
  /// igual - el feed hace fallback.
  Future<void> _onPermitir() async {
    setState(() => _detecting = true);
    try {
      final loc = await ref.read(geoDatasourceProvider).getCurrentLocation();
      // Cacheo best-effort: no bloquea la navegación. La ciudad se guarda
      // junto a la región para pre-llenar formularios después.
      const LocalStorageService()
          .write(StorageKeys.region, loc.region)
          .ignore();
      final city = loc.city;
      if (city != null && city.isNotEmpty) {
        const LocalStorageService().write(StorageKeys.city, city).ignore();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos obtener tu ubicación; mostrando el feed general.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
    if (mounted) context.go('/feed');
  }

  /// Selector manual de región: cachea la elegida y entra al feed.
  Future<void> _onManual() async {
    final region = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Selecciona tu región',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            for (final r in chileRegions)
              ListTile(title: Text(r), onTap: () => Navigator.of(ctx).pop(r)),
          ],
        ),
      ),
    );
    if (region == null) return;
    // Cacheo best-effort: no bloquea la navegación.
    const LocalStorageService().write(StorageKeys.region, region).ignore();
    if (mounted) context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAutoSkip) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E70CD),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

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
              child: Image.asset('assets/images/Logo_SIRE.png', width: 250),
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
                Image.asset('assets/images/Logo_SIRE.png', width: 180),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
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
            _buildDot(isActive: false),
            _buildDot(isActive: true),
            _buildDot(isActive: false),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          '¿Dónde estás?',
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
          'Necesitamos tu ubicación para mostrarte\npublicaciones en tu región.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 40),
        CustomButton(
          text: _detecting ? 'Detectando…' : 'Permitir ubicación',
          onPressed: _detecting ? null : _onPermitir,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _detecting ? null : _onManual,
          child: const Text(
            'Seleccionar ubicación manualmente',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Tu ubicación solo se usa para filtrar el feed.\nNunca se comparte con terceros ni publicadores.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Color(0xFF64748B),
          ),
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
