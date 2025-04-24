import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DataProcessingAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const DataProcessingAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.amber,
    this.secondaryColor = Colors.deepOrange,
    this.message = 'Processando dados...',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _DataProcessingAnimationState createState() => _DataProcessingAnimationState();
}

class _DataProcessingAnimationState extends State<DataProcessingAnimation> with TickerProviderStateMixin {
  late List<DataNode> nodes;
  late List<DataConnection> connections;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    random = Random();
    nodes = [];
    connections = [];

    // Configurar animações
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_rotationController);

    // Inicializar rede de processamento
    initDataProcessingNetwork();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateDataProcessingNetwork();
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
    _pulseController.dispose();
    _rotationController.dispose();
    if (widget.statusMessages.isNotEmpty) {
      messageTimer.cancel();
    }
    super.dispose();
  }

  void initDataProcessingNetwork() {
    // Criar nós de dados em um padrão circular
    final int nodeCount = 12;
    final double centerX = widget.width / 2;
    final double centerY = widget.height / 2;
    final double radius = min(widget.width, widget.height) * 0.35;
    
    // Criar nó central
    nodes.add(DataNode(
      id: 0,
      x: centerX,
      y: centerY,
      size: 15.0,
      shape: NodeShape.circle,
      color: widget.primaryColor,
      processing: true,
    ));
    
    // Criar nós em círculo
    for (int i = 0; i < nodeCount; i++) {
      final angle = 2 * pi * i / nodeCount;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      
      nodes.add(DataNode(
        id: i + 1,
        x: x,
        y: y,
        size: 10.0,
        shape: i % 3 == 0 ? NodeShape.square : i % 3 == 1 ? NodeShape.diamond : NodeShape.circle,
        color: i % 2 == 0 ? widget.secondaryColor : widget.primaryColor,
        processing: random.nextBool(),
      ));
      
      // Conectar ao nó central
      connections.add(DataConnection(
        sourceId: 0,
        targetId: i + 1,
        active: random.nextBool(),
        dataPackets: [],
      ));
      
      // Conectar ao próximo nó no círculo
      connections.add(DataConnection(
        sourceId: i + 1,
        targetId: ((i + 1) % nodeCount) + 1,
        active: random.nextBool(),
        dataPackets: [],
      ));
    }
  }

  void updateDataProcessingNetwork() {
    // Ativar/desativar nós aleatoriamente
    if (random.nextDouble() < 0.1) {
      final nodeIdx = random.nextInt(nodes.length);
      nodes[nodeIdx].processing = !nodes[nodeIdx].processing;
    }
    
    // Ativar/desativar conexões aleatoriamente
    if (random.nextDouble() < 0.05) {
      final connectionIdx = random.nextInt(connections.length);
      connections[connectionIdx].active = !connections[connectionIdx].active;
    }
    
    // Adicionar novos pacotes de dados em conexões ativas
    for (var connection in connections) {
      if (connection.active && random.nextDouble() < 0.1) {
        connection.dataPackets.add(DataPacket(
          position: 0.0,
          speed: 0.02 + random.nextDouble() * 0.03,
          size: 3.0 + random.nextDouble() * 2.0,
          color: random.nextBool() ? widget.primaryColor : widget.secondaryColor,
        ));
      }
      
      // Atualizar pacotes de dados existentes
      for (int i = connection.dataPackets.length - 1; i >= 0; i--) {
        final packet = connection.dataPackets[i];
        packet.position += packet.speed;
        
        // Remover pacotes que chegaram ao destino
        if (packet.position >= 1.0) {
          connection.dataPackets.removeAt(i);
          
          // Ativar o nó de destino
          final targetNode = nodes.firstWhere((n) => n.id == connection.targetId);
          targetNode.processing = true;
          
          // Ativar conexões de saída do nó de destino
          for (var outConnection in connections) {
            if (outConnection.sourceId == targetNode.id && random.nextDouble() < 0.5) {
              outConnection.active = true;
            }
          }
        }
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
          // Camada de fundo para a rede de processamento
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: DataProcessingPainter(
                  nodes: nodes, 
                  connections: connections,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  rotationAngle: _rotationAnimation.value,
                ),
              );
            },
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

enum NodeShape { circle, square, diamond }

class DataNode {
  final int id;
  final double x;
  final double y;
  final double size;
  final NodeShape shape;
  final Color color;
  bool processing;

  DataNode({
    required this.id,
    required this.x,
    required this.y,
    this.size = 10.0,
    this.shape = NodeShape.circle,
    this.color = Colors.white,
    this.processing = false,
  });
}

class DataConnection {
  final int sourceId;
  final int targetId;
  bool active;
  List<DataPacket> dataPackets;

  DataConnection({
    required this.sourceId,
    required this.targetId,
    this.active = false,
    required this.dataPackets,
  });
}

class DataPacket {
  double position; // 0.0 a 1.0
  final double speed;
  final double size;
  final Color color;

  DataPacket({
    this.position = 0.0,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class DataProcessingPainter extends CustomPainter {
  final List<DataNode> nodes;
  final List<DataConnection> connections;
  final Color primaryColor;
  final Color secondaryColor;
  final double rotationAngle;

  DataProcessingPainter({
    required this.nodes,
    required this.connections,
    required this.primaryColor,
    required this.secondaryColor,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Aplicar rotação a toda a rede
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotationAngle * 0.1); // Rotação lenta
    canvas.translate(-centerX, -centerY);
    
    // Desenhar conexões
    for (var connection in connections) {
      final sourceNode = nodes.firstWhere((n) => n.id == connection.sourceId);
      final targetNode = nodes.firstWhere((n) => n.id == connection.targetId);
      
      // Definir cor da conexão
      final paint = Paint()
        ..color = connection.active 
            ? Colors.white.withOpacity(0.4) 
            : Colors.white.withOpacity(0.1)
        ..strokeWidth = connection.active ? 1.5 : 0.8
        ..style = PaintingStyle.stroke;
      
      // Desenhar linha de conexão
      canvas.drawLine(
        Offset(sourceNode.x, sourceNode.y),
        Offset(targetNode.x, targetNode.y),
        paint,
      );
      
      // Desenhar pacotes de dados
      for (var packet in connection.dataPackets) {
        final startPoint = Offset(sourceNode.x, sourceNode.y);
        final endPoint = Offset(targetNode.x, targetNode.y);
        
        // Calcular posição do pacote ao longo da conexão
        final packetX = startPoint.dx + (endPoint.dx - startPoint.dx) * packet.position;
        final packetY = startPoint.dy + (endPoint.dy - startPoint.dy) * packet.position;
        
        // Desenhar o pacote de dados
        final packetPaint = Paint()
          ..color = packet.color
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(packetX, packetY),
          packet.size,
          packetPaint,
        );
        
        // Adicionar brilho ao redor do pacote
        final glowPaint = Paint()
          ..color = packet.color.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
        
        canvas.drawCircle(
          Offset(packetX, packetY),
          packet.size * 1.5,
          glowPaint,
        );
      }
    }
    
    // Desenhar nós
    for (var node in nodes) {
      // Definir cor do nó baseado no estado
      final color = node.processing 
          ? node.color 
          : node.color.withOpacity(0.3);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      // Desenhar o nó com base em sua forma
      switch (node.shape) {
        case NodeShape.circle:
          canvas.drawCircle(
            Offset(node.x, node.y),
            node.size,
            paint,
          );
          break;
          
        case NodeShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(node.x, node.y),
              width: node.size * 1.8,
              height: node.size * 1.8,
            ),
            paint,
          );
          break;
          
        case NodeShape.diamond:
          final path = Path();
          path.moveTo(node.x, node.y - node.size);
          path.lineTo(node.x + node.size, node.y);
          path.lineTo(node.x, node.y + node.size);
          path.lineTo(node.x - node.size, node.y);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
      
      // Adicionar brilho para nós em processamento
      if (node.processing) {
        final glowPaint = Paint()
          ..color = node.color.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
        
        canvas.drawCircle(
          Offset(node.x, node.y),
          node.size * 1.8,
          glowPaint,
        );
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
