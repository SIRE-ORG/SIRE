import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Las pantallas de tab (dashboard, mis reservas, recibidas, perfil, mis
/// publicaciones) se navegan entre sí con `context.go`, que REEMPLAZA el
/// stack de navegación en vez de apilar una ruta encima de otra. Eso deja
/// sin nada que hacer "pop": el back físico de Android, al no encontrar una
/// ruta previa, cierra la app directamente desde cualquier pantalla de tab.
///
/// Este widget intercepta ese back y lo redirige a `/feed` en su lugar, tal
/// como haría un tab bar real. Las pantallas con navegación interna
/// (detalles, formularios) llegan por `context.push` y sí tienen una ruta
/// previa que hacer pop, así que no necesitan (ni deben) envolverse con
/// esto: su back normal ya funciona.
class TabBackToFeed extends StatelessWidget {
  const TabBackToFeed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/feed');
      },
      child: child,
    );
  }
}

/// En /feed (la pantalla de tab raíz) un back no navega a ningún lado: el
/// primer toque avisa con un SnackBar y solo el segundo, dentro de la
/// ventana [window], cierra la app.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.window = const Duration(seconds: 2),
  });

  final Widget child;
  final Duration window;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        final withinWindow =
            _lastBackPress != null &&
            now.difference(_lastBackPress!) <= widget.window;

        if (withinWindow) {
          SystemNavigator.pop();
          return;
        }

        _lastBackPress = now;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Presiona atrás de nuevo para salir'),
            duration: widget.window,
          ),
        );
      },
      child: widget.child,
    );
  }
}
