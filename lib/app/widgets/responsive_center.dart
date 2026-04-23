import 'package:flutter/material.dart';

/// Centra el contenido y limita su ancho máximo cuando la pantalla es ancha
/// (desktop, web, tablet landscape). En mobile (< 600px) pasa el child tal cual.
///
/// Usar envolviendo el `body` de un Scaffold:
/// ```dart
/// Scaffold(
///   appBar: AppBar(...),
///   body: ResponsiveCenter(child: myContent),
/// )
/// ```
class ResponsiveCenter extends StatelessWidget {
  final Widget child;

  /// Ancho máximo del contenido en pantallas anchas.
  /// - `formWidth` (440): formularios y flujos lineales
  /// - `listWidth` (560): listas, dashboards
  /// - `wideWidth` (760): tablas, detalles con muchos datos
  final double maxWidth;

  /// Padding horizontal cuando el ancho de pantalla es menor que `maxWidth`
  final double mobilePadding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = formWidth,
    this.mobilePadding = 0,
  });

  static const double formWidth = 440;
  static const double listWidth = 560;
  static const double wideWidth = 760;

  /// Breakpoint a partir del cual centramos y restringimos.
  static const double breakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < breakpoint) {
      // Mobile: pasar el child tal cual (fullwidth)
      return mobilePadding > 0
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: mobilePadding),
              child: child,
            )
          : child;
    }

    // Desktop/tablet: centrar con max-width
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
