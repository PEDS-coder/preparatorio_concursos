import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const FlashcardAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.pink,
    this.secondaryColor = Colors.pinkAccent,
    this.message = 'Criando Flashcards',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _FlashcardAnimationState createState() => _FlashcardAnimationState();
}

class _FlashcardAnimationState extends State<FlashcardAnimation> with TickerProviderStateMixin {
  late List<Flashcard> flashcards;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  
  // Controladores de animação
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    random = Random();
    flashcards = [];

    // Configurar animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Inicializar flashcards
    initFlashcards();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateFlashcards();
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

  void initFlashcards() {
    // Criar flashcards iniciais
    for (int i = 0; i < 10; i++) {
      _addNewFlashcard();
    }
  }

  void _addNewFlashcard() {
    // Posição inicial fora da tela
    double startX = widget.width / 2 + (random.nextBool() ? 1 : -1) * (widget.width / 2 + 50);
    double startY = widget.height / 2 + (random.nextBool() ? 1 : -1) * (widget.height / 2 + 50);
    
    // Posição final no centro
    double endX = widget.width / 2 + (random.nextDouble() - 0.5) * 20;
    double endY = widget.height / 2 + (random.nextDouble() - 0.5) * 20;
    
    // Cor aleatória baseada na cor primária
    Color cardColor = HSLColor.fromColor(widget.primaryColor)
      .withLightness(0.3 + random.nextDouble() * 0.5)
      .withSaturation(0.7 + random.nextDouble() * 0.3)
      .toColor();
    
    flashcards.add(Flashcard(
      x: startX,
      y: startY,
      targetX: endX,
      targetY: endY,
      width: 60 + random.nextDouble() * 40,
      height: 40 + random.nextDouble() * 30,
      rotation: random.nextDouble() * 2 * pi,
      targetRotation: (random.nextDouble() - 0.5) * 0.5,
      speed: 1 + random.nextDouble() * 3,
      rotationSpeed: 0.05 + random.nextDouble() * 0.1,
      color: cardColor,
      active: true,
      delay: random.nextInt(100),
      zIndex: random.nextDouble(),
    ));
  }

  void updateFlashcards() {
    // Atualizar posição e rotação dos flashcards
    for (var card in flashcards) {
      if (card.delay > 0) {
        card.delay--;
        continue;
      }
      
      if (!card.active) continue;
      
      // Calcular distância até o alvo
      double dx = card.targetX - card.x;
      double dy = card.targetY - card.y;
      double distance = sqrt(dx * dx + dy * dy);
      
      // Calcular diferença de rotação
      double rotationDiff = card.targetRotation - card.rotation;
      while (rotationDiff > pi) {
        rotationDiff -= 2 * pi;
      }
      while (rotationDiff < -pi) {
        rotationDiff += 2 * pi;
      }
      
      if (distance < 5 && rotationDiff.abs() < 0.1) {
        // Quando chegar perto do alvo, desativar e criar novo flashcard
        card.active = false;
        
        // Adicionar novo flashcard
        _addNewFlashcard();
      } else {
        // Mover em direção ao alvo
        if (distance > 0) {
          card.x += (dx / distance) * card.speed;
          card.y += (dy / distance) * card.speed;
        }
        
        // Girar em direção à rotação alvo
        if (rotationDiff.abs() > 0.01) {
          card.rotation += rotationDiff * card.rotationSpeed;
        }
      }
    }
    
    // Remover flashcards inativos (manter no máximo 30 flashcards)
    flashcards.removeWhere((card) => !card.active);
    while (flashcards.length > 30) {
      flashcards.removeAt(0);
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
          // Camada de fundo para os flashcards
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: FlashcardPainter(flashcards),
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

class Flashcard {
  double x;
  double y;
  final double targetX;
  final double targetY;
  final double width;
  final double height;
  double rotation;
  final double targetRotation;
  final double speed;
  final double rotationSpeed;
  final Color color;
  bool active;
  int delay;
  final double zIndex;

  Flashcard({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.width,
    required this.height,
    required this.rotation,
    required this.targetRotation,
    required this.speed,
    required this.rotationSpeed,
    required this.color,
    required this.active,
    required this.delay,
    required this.zIndex,
  });
}

class FlashcardPainter extends CustomPainter {
  final List<Flashcard> flashcards;

  FlashcardPainter(this.flashcards);

  @override
  void paint(Canvas canvas, Size size) {
    // Ordenar flashcards por zIndex para simular profundidade
    final sortedCards = List<Flashcard>.from(flashcards)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    
    for (var card in sortedCards) {
      if (!card.active || card.delay > 0) continue;
      
      // Salvar o estado atual do canvas
      canvas.save();
      
      // Transladar para a posição do flashcard
      canvas.translate(card.x, card.y);
      
      // Aplicar rotação
      canvas.rotate(card.rotation);
      
      // Desenhar o flashcard
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: card.width,
        height: card.height,
      );
      
      // Sombra
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(2, 2),
          const Radius.circular(8),
        ),
        shadowPaint,
      );
      
      // Frente do cartão
      final cardPaint = Paint()
        ..color = card.color;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(8),
        ),
        cardPaint,
      );
      
      // Borda
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(8),
        ),
        borderPaint,
      );
      
      // Linhas decorativas simulando texto
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1;
      
      // Linha superior (título)
      canvas.drawLine(
        Offset(-card.width * 0.35, -card.height * 0.25),
        Offset(card.width * 0.35, -card.height * 0.25),
        linePaint,
      );
      
      // Linhas inferiores (conteúdo)
      for (int i = 0; i < 3; i++) {
        double y = -card.height * 0.1 + i * card.height * 0.2;
        canvas.drawLine(
          Offset(-card.width * 0.35, y),
          Offset(card.width * 0.35, y),
          linePaint,
        );
      }
      
      // Restaurar o estado do canvas
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
