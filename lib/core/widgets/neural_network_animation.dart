import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NeuralNetworkAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final String message;
  final List<String> statusMessages;

  const NeuralNetworkAnimation({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.primaryColor = Colors.purpleAccent,
    this.secondaryColor = Colors.deepPurple,
    this.message = 'Processando dados...',
    this.statusMessages = const [],
  }) : super(key: key);

  @override
  _NeuralNetworkAnimationState createState() => _NeuralNetworkAnimationState();
}

class _NeuralNetworkAnimationState extends State<NeuralNetworkAnimation> with TickerProviderStateMixin {
  late List<Neuron> neurons;
  late List<Connection> connections;
  late Timer timer;
  late Random random;
  int currentMessageIndex = 0;
  late Timer messageTimer;
  String currentStatusMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    random = Random();
    neurons = [];
    connections = [];

    // Configurar animações
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );

    // Inicializar rede neural
    initNeuralNetwork();

    // Atualizar a animação a cada 50ms
    timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          updateNeuralNetwork();
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
    _fadeController.dispose();
    if (widget.statusMessages.isNotEmpty) {
      messageTimer.cancel();
    }
    super.dispose();
  }

  void initNeuralNetwork() {
    // Criar camadas de neurônios
    final int layerCount = 3;
    final List<int> neuronsPerLayer = [6, 8, 6];
    
    // Posições iniciais para cada camada
    final List<double> layerXPositions = List.generate(
      layerCount, 
      (i) => widget.width * (i + 1) / (layerCount + 1)
    );
    
    // Criar neurônios em cada camada
    int neuronId = 0;
    for (int layer = 0; layer < layerCount; layer++) {
      final layerX = layerXPositions[layer];
      final neuronCount = neuronsPerLayer[layer];
      
      for (int i = 0; i < neuronCount; i++) {
        final neuronY = widget.height * (i + 1) / (neuronCount + 1);
        
        neurons.add(Neuron(
          id: neuronId++,
          x: layerX,
          y: neuronY,
          radius: 6.0,
          active: random.nextBool(),
          color: layer == 0 
              ? widget.primaryColor 
              : layer == layerCount - 1 
                  ? widget.secondaryColor 
                  : Colors.white,
        ));
      }
    }
    
    // Criar conexões entre camadas
    for (int layer = 0; layer < layerCount - 1; layer++) {
      final startIdx = layer == 0 ? 0 : neuronsPerLayer.sublist(0, layer).reduce((a, b) => a + b);
      final endIdx = neuronsPerLayer.sublist(0, layer + 1).reduce((a, b) => a + b);
      final nextStartIdx = endIdx;
      final nextEndIdx = nextStartIdx + neuronsPerLayer[layer + 1];
      
      // Conectar cada neurônio da camada atual com todos da próxima camada
      for (int i = startIdx; i < endIdx; i++) {
        for (int j = nextStartIdx; j < nextEndIdx; j++) {
          connections.add(Connection(
            sourceId: neurons[i].id,
            targetId: neurons[j].id,
            active: false,
            signalPosition: 0.0,
            signalSpeed: 0.05 + random.nextDouble() * 0.1,
          ));
        }
      }
    }
  }

  void updateNeuralNetwork() {
    // Ativar/desativar neurônios aleatoriamente
    if (random.nextDouble() < 0.1) {
      final neuronIdx = random.nextInt(neurons.length);
      neurons[neuronIdx].active = !neurons[neuronIdx].active;
      
      // Se um neurônio for ativado, ativar suas conexões de saída
      if (neurons[neuronIdx].active) {
        for (var connection in connections) {
          if (connection.sourceId == neurons[neuronIdx].id) {
            connection.active = true;
            connection.signalPosition = 0.0;
          }
        }
      }
    }
    
    // Atualizar sinais nas conexões
    for (var connection in connections) {
      if (connection.active) {
        connection.signalPosition += connection.signalSpeed;
        
        // Quando o sinal chega ao final da conexão
        if (connection.signalPosition >= 1.0) {
          connection.active = false;
          connection.signalPosition = 0.0;
          
          // Ativar o neurônio de destino
          final targetNeuron = neurons.firstWhere((n) => n.id == connection.targetId);
          targetNeuron.active = true;
          
          // Ativar conexões de saída do neurônio de destino
          for (var outConnection in connections) {
            if (outConnection.sourceId == targetNeuron.id && random.nextDouble() < 0.7) {
              outConnection.active = true;
              outConnection.signalPosition = 0.0;
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
          // Camada de fundo para a rede neural
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: NeuralNetworkPainter(
              neurons: neurons, 
              connections: connections,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              fadeAnimation: _fadeAnimation.value,
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

class Neuron {
  final int id;
  final double x;
  final double y;
  final double radius;
  bool active;
  final Color color;

  Neuron({
    required this.id,
    required this.x,
    required this.y,
    this.radius = 5.0,
    this.active = false,
    this.color = Colors.white,
  });
}

class Connection {
  final int sourceId;
  final int targetId;
  bool active;
  double signalPosition; // 0.0 a 1.0
  final double signalSpeed;

  Connection({
    required this.sourceId,
    required this.targetId,
    this.active = false,
    this.signalPosition = 0.0,
    this.signalSpeed = 0.05,
  });
}

class NeuralNetworkPainter extends CustomPainter {
  final List<Neuron> neurons;
  final List<Connection> connections;
  final Color primaryColor;
  final Color secondaryColor;
  final double fadeAnimation;

  NeuralNetworkPainter({
    required this.neurons,
    required this.connections,
    required this.primaryColor,
    required this.secondaryColor,
    required this.fadeAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar conexões
    for (var connection in connections) {
      final sourceNeuron = neurons.firstWhere((n) => n.id == connection.sourceId);
      final targetNeuron = neurons.firstWhere((n) => n.id == connection.targetId);
      
      // Definir cor da conexão
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.2 * fadeAnimation)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      // Desenhar linha de conexão
      canvas.drawLine(
        Offset(sourceNeuron.x, sourceNeuron.y),
        Offset(targetNeuron.x, targetNeuron.y),
        paint,
      );
      
      // Desenhar sinal se a conexão estiver ativa
      if (connection.active) {
        final startPoint = Offset(sourceNeuron.x, sourceNeuron.y);
        final endPoint = Offset(targetNeuron.x, targetNeuron.y);
        
        // Calcular posição do sinal ao longo da conexão
        final signalX = startPoint.dx + (endPoint.dx - startPoint.dx) * connection.signalPosition;
        final signalY = startPoint.dy + (endPoint.dy - startPoint.dy) * connection.signalPosition;
        
        // Desenhar o sinal como um pequeno círculo brilhante
        final signalPaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(signalX, signalY),
          3.0,
          signalPaint,
        );
        
        // Adicionar brilho ao redor do sinal
        final glowPaint = Paint()
          ..color = primaryColor.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
        
        canvas.drawCircle(
          Offset(signalX, signalY),
          5.0,
          glowPaint,
        );
      }
    }
    
    // Desenhar neurônios
    for (var neuron in neurons) {
      // Definir cor do neurônio baseado no estado
      final color = neuron.active 
          ? neuron.color 
          : neuron.color.withOpacity(0.3 * fadeAnimation);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      // Desenhar o neurônio
      canvas.drawCircle(
        Offset(neuron.x, neuron.y),
        neuron.radius,
        paint,
      );
      
      // Adicionar brilho para neurônios ativos
      if (neuron.active) {
        final glowPaint = Paint()
          ..color = neuron.color.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
        
        canvas.drawCircle(
          Offset(neuron.x, neuron.y),
          neuron.radius * 1.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
