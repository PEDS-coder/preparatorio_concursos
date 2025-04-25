import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TextSummarizationAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const TextSummarizationAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.teal,
    this.secondaryColor = Colors.tealAccent,
    this.message = 'Sintetizando Conteúdo',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _TextSummarizationAnimationState createState() => _TextSummarizationAnimationState();
}

class _TextSummarizationAnimationState extends State<TextSummarizationAnimation> with TickerProviderStateMixin {
  late List<TextParticle> textParticles;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  
  // Controladores de animação
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Lista de palavras para a animação
  final List<String> _words = [
    'Texto', 'Conteúdo', 'Palavras', 'Frases', 'Parágrafos', 
    'Análise', 'Síntese', 'Resumo', 'Conceitos', 'Ideias',
    'Tópicos', 'Pontos', 'Chaves', 'Principais', 'Essenciais',
    'Informações', 'Dados', 'Conhecimento', 'Aprendizado', 'Estudo'
  ];

  @override
  void initState() {
    super.initState();
    random = Random();
    textParticles = [];

    // Configurar animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Inicializar partículas de texto
    initTextParticles();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateTextParticles();
        });
      }
    });

    // Atualizar mensagens de status a cada 15 segundos
    if (widget.statusMessages.isNotEmpty) {
      currentStatusMessage = widget.statusMessages[0];
      messageTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
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
    _pulseController.dispose();
    if (widget.statusMessages.isNotEmpty) {
      messageTimer.cancel();
    }
    super.dispose();
  }

  void initTextParticles() {
    // Criar partículas de texto espalhadas pela tela
    for (int i = 0; i < 30; i++) {
      textParticles.add(TextParticle(
        text: _words[random.nextInt(_words.length)],
        x: random.nextDouble() * widget.width,
        y: random.nextDouble() * widget.height,
        targetX: widget.width / 2,
        targetY: widget.height / 2,
        speed: 0.5 + random.nextDouble() * 2,
        size: 10 + random.nextDouble() * 10,
        color: HSLColor.fromColor(widget.primaryColor)
          .withLightness(0.3 + random.nextDouble() * 0.5)
          .toColor(),
        active: true,
        delay: random.nextInt(100),
      ));
    }
  }

  void updateTextParticles() {
    for (var particle in textParticles) {
      if (particle.delay > 0) {
        particle.delay--;
        continue;
      }
      
      if (!particle.active) continue;
      
      // Mover em direção ao centro
      double dx = particle.targetX - particle.x;
      double dy = particle.targetY - particle.y;
      double distance = sqrt(dx * dx + dy * dy);
      
      if (distance < 5) {
        // Quando chegar perto do centro, desativar e criar nova partícula
        particle.active = false;
        
        // Criar nova partícula na borda
        double angle = random.nextDouble() * 2 * pi;
        double radius = max(widget.width, widget.height) * 0.6;
        double newX = widget.width / 2 + cos(angle) * radius;
        double newY = widget.height / 2 + sin(angle) * radius;
        
        textParticles.add(TextParticle(
          text: _words[random.nextInt(_words.length)],
          x: newX,
          y: newY,
          targetX: widget.width / 2,
          targetY: widget.height / 2,
          speed: 0.5 + random.nextDouble() * 2,
          size: 10 + random.nextDouble() * 10,
          color: HSLColor.fromColor(widget.primaryColor)
            .withLightness(0.3 + random.nextDouble() * 0.5)
            .toColor(),
          active: true,
          delay: random.nextInt(50),
        ));
      } else {
        // Mover em direção ao centro
        particle.x += (dx / distance) * particle.speed;
        particle.y += (dy / distance) * particle.speed;
        
        // Diminuir o tamanho à medida que se aproxima do centro
        double progress = 1.0 - (distance / (max(widget.width, widget.height) * 0.6));
        particle.currentSize = particle.size * (1.0 - progress * 0.7);
      }
    }
    
    // Remover partículas inativas (manter no máximo 50 partículas)
    textParticles.removeWhere((p) => !p.active);
    while (textParticles.length > 50) {
      textParticles.removeAt(0);
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
          // Camada de fundo para as partículas de texto
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: TextSummarizationPainter(textParticles),
          ),
          
          // Círculo central pulsante
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 80 * _pulseAnimation.value,
                  height: 80 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: widget.secondaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.secondaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Mensagem principal com efeito de pulso
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Text(
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
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (widget.statusMessages.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
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
                const SizedBox(height: 16),
                const Text(
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

class TextParticle {
  final String text;
  double x;
  double y;
  final double targetX;
  final double targetY;
  final double speed;
  final double size;
  double currentSize;
  final Color color;
  bool active;
  int delay;

  TextParticle({
    required this.text,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.speed,
    required this.size,
    required this.color,
    required this.active,
    required this.delay,
  }) : currentSize = size;
}

class TextSummarizationPainter extends CustomPainter {
  final List<TextParticle> particles;

  TextSummarizationPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (!particle.active || particle.delay > 0) continue;
      
      // Desenhar o texto
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: particle.text,
          style: TextStyle(
            color: particle.color,
            fontSize: particle.currentSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      
      // Centralizar o texto na posição da partícula
      final offset = Offset(
        particle.x - textPainter.width / 2,
        particle.y - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
