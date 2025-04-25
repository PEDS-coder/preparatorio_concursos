import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MindMapAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const MindMapAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.yellow,
    this.secondaryColor = Colors.amber,
    this.message = 'Estruturando Mapa Mental',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _MindMapAnimationState createState() => _MindMapAnimationState();
}

class _MindMapAnimationState extends State<MindMapAnimation> with TickerProviderStateMixin {
  late List<MindMapNode> nodes;
  late List<MindMapConnection> connections;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  
  // Controladores de animação
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Nó central
  late MindMapNode centralNode;

  @override
  void initState() {
    super.initState();
    random = Random();
    nodes = [];
    connections = [];

    // Configurar animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Inicializar mapa mental
    initMindMap();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateMindMap();
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

  void initMindMap() {
    // Criar nó central
    centralNode = MindMapNode(
      id: 0,
      x: widget.width / 2,
      y: widget.height / 2,
      targetX: widget.width / 2,
      targetY: widget.height / 2,
      radius: 20,
      color: widget.secondaryColor,
      active: true,
      growing: false,
      growProgress: 1.0,
      level: 0,
    );
    
    nodes.add(centralNode);
    
    // Adicionar alguns nós iniciais
    for (int i = 0; i < 5; i++) {
      _addNewNode(parentId: 0, level: 1);
    }
  }

  int _nextNodeId = 1;
  
  void _addNewNode({required int parentId, required int level}) {
    // Encontrar o nó pai
    final parent = nodes.firstWhere((node) => node.id == parentId);
    
    // Calcular posição baseada no nível
    double angle = random.nextDouble() * 2 * pi;
    double distance = 60 + level * 40 + random.nextDouble() * 20;
    
    // Posição alvo
    double targetX = parent.x + cos(angle) * distance;
    double targetY = parent.y + sin(angle) * distance;
    
    // Posição inicial (mesma do pai)
    double startX = parent.x;
    double startY = parent.y;
    
    // Cor baseada no nível
    Color nodeColor;
    if (level == 1) {
      // Primeiro nível - variações da cor secundária
      nodeColor = HSLColor.fromColor(widget.secondaryColor)
        .withLightness(0.4 + random.nextDouble() * 0.3)
        .withSaturation(0.7 + random.nextDouble() * 0.3)
        .toColor();
    } else {
      // Níveis subsequentes - variações da cor primária
      nodeColor = HSLColor.fromColor(widget.primaryColor)
        .withLightness(0.3 + random.nextDouble() * 0.4)
        .withSaturation(0.6 + random.nextDouble() * 0.4)
        .toColor();
    }
    
    // Tamanho baseado no nível
    double radius = max(5, 15 - level * 3);
    
    // Criar novo nó
    final newNode = MindMapNode(
      id: _nextNodeId++,
      x: startX,
      y: startY,
      targetX: targetX,
      targetY: targetY,
      radius: radius,
      color: nodeColor,
      active: true,
      growing: true,
      growProgress: 0.0,
      level: level,
    );
    
    nodes.add(newNode);
    
    // Criar conexão com o pai
    connections.add(MindMapConnection(
      sourceId: parentId,
      targetId: newNode.id,
      progress: 0.0,
      color: nodeColor.withOpacity(0.7),
      width: max(1, 3 - level * 0.5),
    ));
  }

  void updateMindMap() {
    // Atualizar nós
    for (var node in nodes) {
      if (!node.active) continue;
      
      // Atualizar animação de crescimento
      if (node.growing) {
        node.growProgress += 0.05;
        if (node.growProgress >= 1.0) {
          node.growing = false;
          node.growProgress = 1.0;
          
          // Adicionar nós filhos aleatoriamente
          if (node.level < 3 && random.nextDouble() < 0.1) {
            _addNewNode(parentId: node.id, level: node.level + 1);
          }
        }
      }
      
      // Mover em direção à posição alvo
      double dx = node.targetX - node.x;
      double dy = node.targetY - node.y;
      
      node.x += dx * 0.1;
      node.y += dy * 0.1;
    }
    
    // Atualizar conexões
    for (var connection in connections) {
      connection.progress += 0.05;
      if (connection.progress > 1.0) {
        connection.progress = 1.0;
      }
    }
    
    // Adicionar novos nós aleatoriamente
    if (nodes.length < 30 && random.nextDouble() < 0.05) {
      // Escolher um nó existente como pai
      final potentialParents = nodes.where((node) => node.level < 3).toList();
      if (potentialParents.isNotEmpty) {
        final parent = potentialParents[random.nextInt(potentialParents.length)];
        _addNewNode(parentId: parent.id, level: parent.level + 1);
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
          // Camada de fundo para o mapa mental
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: MindMapPainter(nodes, connections),
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

class MindMapNode {
  final int id;
  double x;
  double y;
  final double targetX;
  final double targetY;
  final double radius;
  final Color color;
  final bool active;
  bool growing;
  double growProgress;
  final int level;

  MindMapNode({
    required this.id,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.radius,
    required this.color,
    required this.active,
    required this.growing,
    required this.growProgress,
    required this.level,
  });
}

class MindMapConnection {
  final int sourceId;
  final int targetId;
  double progress;
  final Color color;
  final double width;

  MindMapConnection({
    required this.sourceId,
    required this.targetId,
    required this.progress,
    required this.color,
    required this.width,
  });
}

class MindMapPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final List<MindMapConnection> connections;

  MindMapPainter(this.nodes, this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar conexões primeiro
    for (var connection in connections) {
      // Encontrar nós de origem e destino
      final source = nodes.firstWhere((node) => node.id == connection.sourceId);
      final target = nodes.firstWhere((node) => node.id == connection.targetId);
      
      // Calcular pontos de início e fim
      final start = Offset(source.x, source.y);
      final end = Offset(target.x, target.y);
      
      // Calcular ponto intermediário para a linha
      final progress = connection.progress;
      final currentEnd = Offset(
        start.dx + (end.dx - start.dx) * progress,
        start.dy + (end.dy - start.dy) * progress,
      );
      
      // Desenhar a linha
      final paint = Paint()
        ..color = connection.color
        ..strokeWidth = connection.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(start, currentEnd, paint);
    }
    
    // Desenhar nós
    for (var node in nodes) {
      if (!node.active) continue;
      
      // Calcular raio atual baseado na animação de crescimento
      final currentRadius = node.radius * node.growProgress;
      
      // Desenhar círculo do nó
      final paint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(node.x, node.y),
        currentRadius,
        paint,
      );
      
      // Desenhar borda
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawCircle(
        Offset(node.x, node.y),
        currentRadius,
        borderPaint,
      );
      
      // Adicionar brilho para o nó central
      if (node.level == 0) {
        final glowPaint = Paint()
          ..color = node.color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        
        canvas.drawCircle(
          Offset(node.x, node.y),
          currentRadius * 1.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
