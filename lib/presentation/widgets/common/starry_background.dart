import 'dart:math';
import 'package:flutter/material.dart';

class StarryBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const StarryBackground({
    Key? key,
    required this.child,
    required this.isDarkMode,
  }) : super(key: key);

  // Generar estrellas estáticas
  List<Star> _generateStars() {
    final random = Random(42); // Seed fijo para consistencia
    return List.generate(150, (index) {
      return Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 0.4 + random.nextDouble() * 1.6,
        // Opacidad más baja para oscurecer el cielo nocturno
        opacity: 0.2 + random.nextDouble() * 0.35,
        // Menos estrellas brillantes para un look más sobrio
        brightness: random.nextDouble() > 0.88
            ? 1.0
            : 0.0, // ~12% estrellas con brillo cruzado
      );
    });
  }

  // Generar nubes estáticas
  List<Cloud> _generateClouds() {
    final random = Random(123); // Seed fijo para consistencia
    return List.generate(5, (index) {
      return Cloud(
        x: random.nextDouble(),
        y: 0.05 + random.nextDouble() * 0.30, // Más hacia la parte superior
        width: 0.10 + random.nextDouble() * 0.18,
        height: 0.06 + random.nextDouble() * 0.10,
        opacity: 0.06 + random.nextDouble() * 0.08, // Mucho más sutiles
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = _generateStars();
    final clouds = _generateClouds();

    return Stack(
      children: [
        // Fondo base
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Más stops para transiciones más suaves y sin banding
                    colors: [
                      Color(0xFF02060D),
                      Color(0xFF050A14),
                      Color(0xFF0A1324),
                      Color(0xFF060A12),
                      Color(0xFF000000),
                    ],
                    stops: [0.0, 0.35, 0.7, 0.85, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Cielo más suave para mejor legibilidad en modo claro
                    colors: [
                      Color(0xFF78B7D8),
                      Color(0xFFAED4E2),
                      Color(0xFFF7F7F7),
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
          ),
        ),

        // Vignette sutil para ocultar artefactos en bordes (solo nocturno)
        if (isDarkMode)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Color(0xAA000000),
                ],
                stops: [0.6, 1.0],
              ),
            ),
          ),

        // Elementos decorativos estáticos
        if (isDarkMode)
          // Estrellas estáticas para modo nocturno
          CustomPaint(
            painter: StaticStarsPainter(stars: stars),
            size: Size.infinite,
          )
        else
          // Nubes estáticas para modo diurno
          CustomPaint(
            painter: StaticCloudsPainter(clouds: clouds),
            size: Size.infinite,
          ),

        // Scrim sutil en modo claro para aumentar contraste del contenido
        if (!isDarkMode)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x0A000000), // ~4% negro en el centro
                  Colors.transparent,
                ],
                stops: const [0.15, 0.55, 0.95],
              ),
            ),
          ),

        // Contenido principal
        child,
      ],
    );
  }
}

// Clases de datos para elementos estáticos
class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double brightness; // 0.0 normal, 1.0 brillante

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.brightness,
  });
}

class Cloud {
  final double x;
  final double y;
  final double width;
  final double height;
  final double opacity;

  Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.opacity,
  });
}

// Painters para elementos estáticos
class StaticStarsPainter extends CustomPainter {
  final List<Star> stars;

  StaticStarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Color dorado para las estrellas
      paint.color = Color(0xFFFFD700).withOpacity(star.opacity);

      // Dibujar estrella como círculo
      canvas.drawCircle(
        Offset(x, y),
        star.size,
        paint,
      );

      // Agregar brillo cruzado para estrellas brillantes (más sutil)
      if (star.brightness > 0.5) {
        paint.strokeWidth = 0.5;
        paint.color = const Color(0xFFFFD700).withOpacity(star.opacity * 0.5);

        // Línea vertical
        canvas.drawLine(
          Offset(x, y - star.size * 1.8),
          Offset(x, y + star.size * 1.8),
          paint,
        );

        // Línea horizontal
        canvas.drawLine(
          Offset(x - star.size * 1.8, y),
          Offset(x + star.size * 1.8, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Estático
}

class StaticCloudsPainter extends CustomPainter {
  final List<Cloud> clouds;

  StaticCloudsPainter({required this.clouds});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final cloud in clouds) {
      final x = cloud.x * size.width;
      final y = cloud.y * size.height;
      final width = cloud.width * size.width;
      final height = cloud.height * size.height;

      paint.color = Colors.white.withOpacity(cloud.opacity);

      // Dibujar nube como conjunto de círculos superpuestos
      _drawCloud(canvas, paint, x, y, width, height);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, double x, double y, double width,
      double height) {
    // Círculo principal
    canvas.drawCircle(Offset(x, y), height * 0.6, paint);

    // Círculos laterales
    canvas.drawCircle(
        Offset(x - width * 0.3, y + height * 0.1), height * 0.5, paint);
    canvas.drawCircle(
        Offset(x + width * 0.3, y + height * 0.1), height * 0.5, paint);

    // Círculos superiores para dar forma de nube
    canvas.drawCircle(
        Offset(x - width * 0.15, y - height * 0.2), height * 0.4, paint);
    canvas.drawCircle(
        Offset(x + width * 0.15, y - height * 0.2), height * 0.4, paint);

    // Círculo central superior
    canvas.drawCircle(Offset(x, y - height * 0.3), height * 0.35, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Estático
}
