import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/progresso_estudo.dart';
import '../data/services/progresso_estudo_service.dart';
import '../auth/auth_service.dart';
import 'dart:math' as math;

class ProgressoEstudoWidget extends StatefulWidget {
  final String editalId;
  final String materiaId;
  final String? topicoId;
  final Function(EstadoProgresso) onEstadoChanged;
  final bool isLegend;
  final bool showAbove; // Novo parâmetro para mostrar checkboxes acima do texto

  const ProgressoEstudoWidget({
    Key? key,
    required this.editalId,
    required this.materiaId,
    this.topicoId,
    required this.onEstadoChanged,
    this.isLegend = false,
    this.showAbove = true, // Por padrão, mostrar acima
  }) : super(key: key);

  @override
  _ProgressoEstudoWidgetState createState() => _ProgressoEstudoWidgetState();
}

class _ProgressoEstudoWidgetState extends State<ProgressoEstudoWidget> {
  EstadoProgresso _estadoAtual = EstadoProgresso.naoEstudado;

  @override
  void initState() {
    super.initState();
    _carregarEstadoAtual();
  }

  void _carregarEstadoAtual() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final progressoService = Provider.of<ProgressoEstudoService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';

    if (userId.isEmpty) return;

    ProgressoEstudo? progresso;
    if (widget.topicoId != null) {
      progresso = progressoService.getProgressoTopico(
        userId, widget.editalId, widget.materiaId, widget.topicoId!);
    } else {
      progresso = progressoService.getProgressoMateria(
        userId, widget.editalId, widget.materiaId);
    }

    if (progresso != null) {
      setState(() {
        _estadoAtual = progresso!.estado;
      });
    }
  }

  void _atualizarEstado(EstadoProgresso novoEstado) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final progressoService = Provider.of<ProgressoEstudoService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';

    if (userId.isEmpty) return;

    // Se o estado atual já for o mesmo que o novo estado, desmarcar (voltar para não estudado)
    if (_estadoAtual == novoEstado) {
      novoEstado = EstadoProgresso.naoEstudado;
    }

    setState(() {
      _estadoAtual = novoEstado;
    });

    if (widget.topicoId != null) {
      await progressoService.atualizarProgressoTopico(
        userId, widget.editalId, widget.materiaId, widget.topicoId!, novoEstado);

      // Recarregar o estado atual após a atualização
      _carregarEstadoAtual();
    } else {
      await progressoService.atualizarProgressoMateria(
        userId, widget.editalId, widget.materiaId, novoEstado);
    }

    // Atualizar a UI após a operação ser concluída
    // Aumentar o delay para garantir que todas as atualizações sejam concluídas
    Future.delayed(Duration(milliseconds: 200), () {
      widget.onEstadoChanged(novoEstado);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLegend) {
      return _buildLegenda();
    }

    // Criar os checkboxes
    final checkboxes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCheckbox(EstadoProgresso.estudado),
        SizedBox(width: 4),
        _buildCheckbox(EstadoProgresso.primeiraRevisao),
        SizedBox(width: 4),
        _buildCheckbox(EstadoProgresso.segundaRevisao),
        SizedBox(width: 4),
        _buildCheckbox(EstadoProgresso.terceiraRevisao),
      ],
    );

    return checkboxes;
  }

  Widget _buildLegenda() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendaItem(EstadoProgresso.estudado),
        SizedBox(width: 8),
        _buildLegendaItem(EstadoProgresso.primeiraRevisao),
        SizedBox(width: 8),
        _buildLegendaItem(EstadoProgresso.segundaRevisao),
        SizedBox(width: 8),
        _buildLegendaItem(EstadoProgresso.terceiraRevisao),
      ],
    );
  }

  Widget _buildLegendaItem(EstadoProgresso estado) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _getCor(estado),
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 4),
        Text(
          estado.nome,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCheckbox(EstadoProgresso estado) {
    bool isChecked = _estadoAtual.index >= estado.index;
    return InkWell(
      onTap: () => _atualizarEstado(estado),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          // Sempre mostrar a cor do checkbox, mesmo quando desmarcado
          color: _getCor(estado),
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isChecked
            ? Icon(Icons.check, size: 16, color: _getCheckColor(estado))
            : null,
      ),
    );
  }



  Color _getCor(EstadoProgresso estado) {
    switch (estado) {
      case EstadoProgresso.naoEstudado:
        return Colors.white.withOpacity(0.3); // Branco semi-transparente
      case EstadoProgresso.estudado:
        return Color(0xFF4CAF50).withOpacity(_estadoAtual.index >= estado.index ? 1.0 : 0.5); // Verde
      case EstadoProgresso.primeiraRevisao:
        return Color(0xFFFFEB3B).withOpacity(_estadoAtual.index >= estado.index ? 1.0 : 0.5); // Amarelo
      case EstadoProgresso.segundaRevisao:
        return Color(0xFFFF9800).withOpacity(_estadoAtual.index >= estado.index ? 1.0 : 0.5); // Laranja
      case EstadoProgresso.terceiraRevisao:
        return Color(0xFFF44336).withOpacity(_estadoAtual.index >= estado.index ? 1.0 : 0.5); // Vermelho
    }
  }

  Color _getCheckColor(EstadoProgresso estado) {
    switch (estado) {
      case EstadoProgresso.naoEstudado:
        return Colors.black;
      case EstadoProgresso.estudado:
        return Colors.white;
      case EstadoProgresso.primeiraRevisao:
        return Colors.black;
      case EstadoProgresso.segundaRevisao:
        return Colors.white;
      case EstadoProgresso.terceiraRevisao:
        return Colors.white;
    }
  }
}
