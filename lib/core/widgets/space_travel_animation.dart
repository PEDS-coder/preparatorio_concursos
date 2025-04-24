import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SpaceTravelAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const SpaceTravelAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.cyanAccent,
    this.secondaryColor = Colors.blueAccent,
    this.message = 'Analisando documentos...',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _SpaceTravelAnimationState createState() => _SpaceTravelAnimationState();
}

class _SpaceTravelAnimationState extends State<SpaceTravelAnimation> with SingleTickerProviderStateMixin {
  late List<Star> stars;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    random = Random();
    stars = [];

    // Inicializar estrelas
    initStars();

    // Configurar animação de pulso
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );

    // Atualizar a animação a cada 16ms (aproximadamente 60fps)
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (mounted) {
        setState(() {
          updateStars();
        });
      }
    });

    // Atualizar mensagens de status a cada 15 segundos
    if (widget.statusMessages.isNotEmpty) {
      currentStatusMessage = widget.statusMessages[0];
      messageTimer = Timer.periodic(Duration(seconds: 15), (timer) {
        if (mounted) {
          setState(() {
            currentMessageIndex = (currentMessageIndex + 1) % widget.statusMessages.length;
            currentStatusMessage = widget.statusMessages[currentMessageIndex];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    _controller.dispose();
    if (widget.statusMessages.isNotEmpty) {
      messageTimer.cancel();
    }
    super.dispose();
  }

  void initStars() {
    // Criar estrelas com posições aleatórias
    for (int i = 0; i < 200; i++) {
      stars.add(Star(
        x: random.nextDouble() * widget.width,
        y: random.nextDouble() * widget.height,
        z: random.nextDouble() * 1000 + 1, // Profundidade
        size: random.nextDouble() * 2 + 0.5,
        color: i % 5 == 0 
            ? widget.primaryColor 
            : i % 10 == 0 
                ? widget.secondaryColor 
                : Colors.white,
      ));
    }
  }

  void updateStars() {
    for (var star in stars) {
      // Mover estrelas em direção ao observador (aumentar Z)
      star.z -= 5;
      
      // Resetar estrelas que saem do campo de visão
      if (star.z <= 0) {
        star.z = 1000;
        star.x = random.nextDouble() * widget.width;
        star.y = random.nextDouble() * widget.height;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: Stack(
        children: [
          // Camada de fundo para as estrelas
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: SpaceTravelPainter(stars, widget.width / 2, widget.height / 2),
          ),

          // Mensagem principal com efeito de pulso
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: widget.primaryColor.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                if (widget.statusMessages.isNotEmpty)
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      currentStatusMessage,
                      key: ValueKey<String>(currentStatusMessage),
                      style: TextStyle(
                        color: widget.secondaryColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Pode levar alguns minutos...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Star {
  double x;
  double y;
  double z;
  double size;
  Color color;

  Star({
    required this.x,
    required this.y,
    required this.z,
    this.size = 1.0,
    this.color = Colors.white,
  });
}

class SpaceTravelPainter extends CustomPainter {
  final List<Star> stars;
  final double centerX;
  final double centerY;

  SpaceTravelPainter(this.stars, this.centerX, this.centerY);

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Calcular posição projetada (efeito 3D)
      double factor = 200 / star.z;
      double x = (star.x - centerX) * factor + centerX;
      double y = (star.y - centerY) * factor + centerY;
      
      // Calcular tamanho baseado na profundidade
      double starSize = star.size * factor;
      
      // Calcular opacidade baseada na profundidade
      double opacity = 1.0 - (star.z / 1000);
      opacity = opacity.clamp(0.2, 1.0);
      
      // Desenhar a estrela como um círculo
      final paint = Paint()
        ..color = star.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Adicionar rastro (cauda) para estrelas mais próximas
      if (star.z < 400) {
        // Calcular posição anterior (para criar o efeito de rastro)
        double prevFactor = 200 / (star.z + 15);
        double prevX = (star.x - centerX) * prevFactor + centerX;
        double prevY = (star.y - centerY) * prevFactor + centerY;
        
        // Desenhar linha de rastro
        final trailPaint = Paint()
          ..color = star.color.withOpacity(opacity * 0.5)
          ..strokeWidth = starSize * 0.8
          ..style = PaintingStyle.stroke;
        
        canvas.drawLine(
          Offset(prevX, prevY),
          Offset(x, y),
          trailPaint,
        );
      }
      
      // Desenhar a estrela
      canvas.drawCircle(
        Offset(x, y),
        starSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
