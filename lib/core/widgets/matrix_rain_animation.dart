import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MatrixRainAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const MatrixRainAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = const Color(0xFF00FF41),
    this.secondaryColor = const Color(0x000ff0f0),
    this.message = 'Analisando edital...',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _MatrixRainAnimationState createState() => _MatrixRainAnimationState();
}

class _MatrixRainAnimationState extends State<MatrixRainAnimation> {
  late List<MatrixColumn> columns;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';

  @override
  void initState() {
    super.initState();
    random = Random();
    columns = [];

    // Inicializar colunas
    initColumns();

    // Atualizar a animação a cada 100ms
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          updateColumns();
        });
      }
    });

    // Atualizar mensagens de status a cada 15 segundos para que cada mensagem seja exibida por mais tempo
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
    if (widget.statusMessages.isNotEmpty) {
      messageTimer.cancel();
    }
    super.dispose();
  }

  void initColumns() {
    int numColumns = (widget.width / 15).floor(); // Espaçamento entre colunas

    for (int i = 0; i < numColumns; i++) {
      columns.add(MatrixColumn(
        x: i * 15.0,
        speed: 2 + random.nextDouble() * 5,
        length: 5 + random.nextInt(15),
        startY: random.nextDouble() * widget.height * 2 - widget.height,
        primaryColor: widget.primaryColor,
        secondaryColor: widget.secondaryColor,
      ));
    }
  }

  void updateColumns() {
    for (var column in columns) {
      column.update(widget.height);
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
          // Camada de fundo para o efeito de brilho
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: MatrixRainPainter(columns),
          ),

          // Mensagem principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
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

class MatrixColumn {
  final double x;
  double y;
  final double speed;
  final int length;
  final List<String> characters = [];
  final Color primaryColor;
  final Color secondaryColor;

  static final List<String> possibleChars = [
    '0', '1', '{', '}', '[', ']', '(', ')', '<', '>', '=', '+', '-', '*', '/', '\\', '|', ':', ';', '.', ',', '?', '!', '@', '#', '\$', '%', '^', '&', '_', '~'
  ];

  static final Random random = Random();

  MatrixColumn({
    required this.x,
    required this.speed,
    required this.length,
    required double startY,
    required this.primaryColor,
    required this.secondaryColor,
  }) : y = startY {
    // Inicializar caracteres aleatórios
    for (int i = 0; i < length; i++) {
      characters.add(getRandomChar());
    }
  }

  String getRandomChar() {
    return possibleChars[random.nextInt(possibleChars.length)];
  }

  void update(double maxHeight) {
    y += speed;

    // Resetar a posição quando sair da tela
    if (y > maxHeight + length * 20) {
      y = -length * 20.0;

      // Atualizar caracteres aleatoriamente
      for (int i = 0; i < length; i++) {
        if (random.nextDouble() < 0.2) {
          characters[i] = getRandomChar();
        }
      }
    }

    // Atualizar alguns caracteres aleatoriamente durante a queda
    if (random.nextDouble() < 0.05) {
      int index = random.nextInt(length);
      characters[index] = getRandomChar();
    }
  }
}

class MatrixRainPainter extends CustomPainter {
  final List<MatrixColumn> columns;

  MatrixRainPainter(this.columns);

  @override
  void paint(Canvas canvas, Size size) {
    for (var column in columns) {
      // Desenhar cada caractere da coluna
      for (int i = 0; i < column.length; i++) {
        double charY = column.y + i * 20;

        // Só desenhar caracteres visíveis
        if (charY >= -20 && charY <= size.height + 20) {
          // Calcular opacidade baseada na posição (primeiro caractere mais brilhante)
          double opacity = i == 0 ? 1.0 : 1.0 - (i / column.length);

          // Cor baseada na posição
          Color color = i == 0
              ? column.secondaryColor.withOpacity(opacity)
              : column.primaryColor.withOpacity(opacity * 0.8);

          // Desenhar o caractere
          TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: column.characters[i],
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(canvas, Offset(column.x, charY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
