import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class QuizAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const QuizAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlueAccent,
    this.message = 'Elaborando Questões',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _QuizAnimationState createState() => _QuizAnimationState();
}

class _QuizAnimationState extends State<QuizAnimation> with TickerProviderStateMixin {
  late List<QuizElement> quizElements;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  
  // Controladores de animação
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Opções de múltipla escolha
  final List<String> _options = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    random = Random();
    quizElements = [];

    // Configurar animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Inicializar elementos do quiz
    initQuizElements();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateQuizElements();
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

  void initQuizElements() {
    // Adicionar alguns elementos iniciais
    for (int i = 0; i < 15; i++) {
      _addNewQuizElement();
    }
  }

  void _addNewQuizElement() {
    // Determinar tipo de elemento (interrogação ou opção)
    bool isQuestion = random.nextDouble() < 0.3;
    
    // Posição inicial fora da tela
    double startX, startY;
    if (random.nextBool()) {
      // Entrar pelos lados
      startX = random.nextBool() ? -50 : widget.width + 50;
      startY = random.nextDouble() * widget.height;
    } else {
      // Entrar por cima ou por baixo
      startX = random.nextDouble() * widget.width;
      startY = random.nextBool() ? -50 : widget.height + 50;
    }
    
    // Posição alvo dentro da tela
    double targetX = 50 + random.nextDouble() * (widget.width - 100);
    double targetY = 50 + random.nextDouble() * (widget.height - 100);
    
    // Velocidade
    double speed = 1 + random.nextDouble() * 3;
    
    // Tamanho
    double size = isQuestion ? (20 + random.nextDouble() * 20) : (15 + random.nextDouble() * 15);
    
    // Cor
    Color color;
    if (isQuestion) {
      // Interrogações - variações da cor secundária
      color = HSLColor.fromColor(widget.secondaryColor)
        .withLightness(0.5 + random.nextDouble() * 0.3)
        .toColor();
    } else {
      // Opções - variações da cor primária
      color = HSLColor.fromColor(widget.primaryColor)
        .withLightness(0.4 + random.nextDouble() * 0.4)
        .withSaturation(0.7 + random.nextDouble() * 0.3)
        .toColor();
    }
    
    // Texto (? ou opção)
    String text = isQuestion ? '?' : _options[random.nextInt(_options.length)];
    
    // Criar elemento
    quizElements.add(QuizElement(
      x: startX,
      y: startY,
      targetX: targetX,
      targetY: targetY,
      size: size,
      color: color,
      text: text,
      isQuestion: isQuestion,
      speed: speed,
      rotation: random.nextDouble() * 2 * pi,
      rotationSpeed: (random.nextDouble() - 0.5) * 0.05,
      active: true,
      lifetime: 100 + random.nextInt(200), // Tempo de vida em frames
    ));
  }

  void updateQuizElements() {
    for (var element in quizElements) {
      if (!element.active) continue;
      
      // Atualizar posição
      double dx = element.targetX - element.x;
      double dy = element.targetY - element.y;
      double distance = sqrt(dx * dx + dy * dy);
      
      if (distance > 1) {
        element.x += (dx / distance) * element.speed;
        element.y += (dy / distance) * element.speed;
      }
      
      // Atualizar rotação
      element.rotation += element.rotationSpeed;
      
      // Atualizar tempo de vida
      element.lifetime--;
      if (element.lifetime <= 0) {
        element.active = false;
      }
    }
    
    // Remover elementos inativos
    quizElements.removeWhere((element) => !element.active);
    
    // Adicionar novos elementos aleatoriamente
    if (random.nextDouble() < 0.05) {
      _addNewQuizElement();
    }
    
    // Manter um número máximo de elementos
    while (quizElements.length > 50) {
      quizElements.removeAt(0);
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
          // Camada de fundo para os elementos do quiz
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: QuizPainter(quizElements),
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

class QuizElement {
  double x;
  double y;
  final double targetX;
  final double targetY;
  final double size;
  final Color color;
  final String text;
  final bool isQuestion;
  final double speed;
  double rotation;
  final double rotationSpeed;
  bool active;
  int lifetime;

  QuizElement({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.size,
    required this.color,
    required this.text,
    required this.isQuestion,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.active,
    required this.lifetime,
  });
}

class QuizPainter extends CustomPainter {
  final List<QuizElement> elements;

  QuizPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) {
    for (var element in elements) {
      if (!element.active) continue;
      
      // Salvar o estado atual do canvas
      canvas.save();
      
      // Transladar para a posição do elemento
      canvas.translate(element.x, element.y);
      
      // Aplicar rotação
      canvas.rotate(element.rotation);
      
      if (element.isQuestion) {
        // Desenhar símbolo de interrogação
        _drawQuestionMark(canvas, element);
      } else {
        // Desenhar opção de múltipla escolha
        _drawOption(canvas, element);
      }
      
      // Restaurar o estado do canvas
      canvas.restore();
    }
  }
  
  void _drawQuestionMark(Canvas canvas, QuizElement element) {
    // Desenhar círculo de fundo com brilho
    final bgPaint = Paint()
      ..color = element.color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(
      Offset.zero,
      element.size * 1.2,
      bgPaint,
    );
    
    // Desenhar o símbolo de interrogação
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: element.color,
          fontSize: element.size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
  
  void _drawOption(Canvas canvas, QuizElement element) {
    // Desenhar círculo de fundo
    final bgPaint = Paint()
      ..color = element.color;
    
    canvas.drawCircle(
      Offset.zero,
      element.size * 0.8,
      bgPaint,
    );
    
    // Desenhar borda
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(
      Offset.zero,
      element.size * 0.8,
      borderPaint,
    );
    
    // Desenhar a letra da opção
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: element.size * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
