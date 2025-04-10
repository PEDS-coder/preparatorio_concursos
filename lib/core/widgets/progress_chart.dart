import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressChart extends StatelessWidget {
  final double progress; // 0.0 a 1.0
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final Widget? child;
  final double strokeWidth;
  final bool showGradient;

  const ProgressChart({
    Key? key,
    required this.progress,
    this.size = 120,
    this.color,
    this.backgroundColor,
    this.child,
    this.strokeWidth = 10,
    this.showGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Fundo do gráfico
          CustomPaint(
            size: Size(size, size),
            painter: CircleChartPainter(
              progress: progress,
              progressColor: color ?? AppTheme.primaryColor,
              backgroundColor: backgroundColor ?? Colors.grey.withOpacity(0.2),
              strokeWidth: strokeWidth,
              useGradient: showGradient,
            ),
          ),
          
          // Conteúdo central
          if (child != null)
            Center(child: child),
        ],
      ),
    );
  }
}

class CircleChartPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final bool useGradient;

  CircleChartPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.useGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;
    
    // Desenhar círculo de fundo
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Desenhar arco de progresso
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    if (useGradient) {
      // Usar gradiente se solicitado
      final rect = Rect.fromCircle(center: center, radius: radius);
      progressPaint.shader = AppTheme.chartGradient.createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }
    
    final progressAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Começar do topo
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircleChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useGradient != useGradient;
  }
}
