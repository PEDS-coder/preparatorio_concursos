import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/progresso_estudo.dart';

class ProgressoEstudoService {
  static const String _storageKey = 'progresso_estudo';
  const Uuid _uuid = Uuid();
  List<ProgressoEstudo> _progressos = [];
  bool _initialized = false;

  // Cache para otimizar o acesso aos dados
  final Map<String, List<ProgressoEstudo>> _progressosPorEdital = {};

  // Inicializar o serviço carregando dados do armazenamento local
  Future<void> init() async {
    if (_initialized) return;

    await loadProgressos();

    _initialized = true;
  }

  // Carregar progressos do armazenamento local
  Future<void> loadProgressos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progressosJson = prefs.getString(_storageKey);

    if (progressosJson != null) {
      final List<dynamic> decodedList = jsonDecode(progressosJson);
      _progressos = decodedList.map((item) => ProgressoEstudo.fromMap(item)).toList();

      // Preencher o cache
      _atualizarCache();
    }
  }

  // Atualizar o cache de progressos por edital
  void _atualizarCache() {
    _progressosPorEdital.clear();

    for (final progresso in _progressos) {
      final key = '${progresso.userId}_${progresso.editalId}';
      if (!_progressosPorEdital.containsKey(key)) {
        _progressosPorEdital[key] = [];
      }
      _progressosPorEdital[key]!.add(progresso);
    }
  }

  // Salvar todos os progressos no armazenamento local
  Future<void> _saveProgressos() async {
    final prefs = await SharedPreferences.getInstance();
    final String progressosJson = jsonEncode(_progressos.map((p) => p.toMap()).toList());
    await prefs.setString(_storageKey, progressosJson);

    // Atualizar o cache
    _atualizarCache();
  }

  // Obter progresso de uma matéria específica
  ProgressoEstudo getProgressoMateria(String userId, String editalId, String materiaId) {
    final key = '${userId}_$editalId';
    final progressosEdital = _progressosPorEdital[key] ?? [];

    return progressosEdital.firstWhere(
      (p) => p.materiaId == materiaId && p.topicoId == null,
      orElse: () {
        final novoProgresso = ProgressoEstudo(
          id: _uuid.v4(),
          userId: userId,
          editalId: editalId,
          materiaId: materiaId,
          topicoId: null,
          estado: EstadoProgresso.naoEstudado,
          dataAtualizacao: DateTime.now(),
        );
        return novoProgresso;
      },
    );
  }

  // Obter progresso de um tópico específico
  ProgressoEstudo getProgressoTopico(String userId, String editalId, String materiaId, String topicoId) {
    final key = '${userId}_$editalId';
    final progressosEdital = _progressosPorEdital[key] ?? [];

    return progressosEdital.firstWhere(
      (p) => p.materiaId == materiaId && p.topicoId == topicoId,
      orElse: () {
        final novoProgresso = ProgressoEstudo(
          id: _uuid.v4(),
          userId: userId,
          editalId: editalId,
          materiaId: materiaId,
          topicoId: topicoId,
          estado: EstadoProgresso.naoEstudado,
          dataAtualizacao: DateTime.now(),
        );
        return novoProgresso;
      },
    );
  }

  // Atualizar o progresso de uma matéria
  Future<void> atualizarProgressoMateria(String userId, String editalId, String materiaId, EstadoProgresso estado) async {
    // Verificar se já existe um progresso para esta matéria
    final index = _progressos.indexWhere(
      (p) => p.userId == userId && p.editalId == editalId && p.materiaId == materiaId && p.topicoId == null
    );

    final novoProgresso = ProgressoEstudo(
      id: index >= 0 ? _progressos[index].id : _uuid.v4(),
      userId: userId,
      editalId: editalId,
      materiaId: materiaId,
      topicoId: null,
      estado: estado,
      dataAtualizacao: DateTime.now(),
    );

    if (index >= 0) {
      _progressos[index] = novoProgresso;
    } else {
      _progressos.add(novoProgresso);
    }

    // Obter todos os tópicos desta matéria
    final topicos = _progressos.where(
      (p) => p.userId == userId && p.editalId == editalId && p.materiaId == materiaId && p.topicoId != null
    ).toList();

    // Sempre atualizar todos os tópicos com o mesmo estado da matéria
    // Isso garante que quando a matéria é marcada, todos os tópicos são marcados adequadamente
    for (final topico in topicos) {
      final topicoIndex = _progressos.indexWhere((p) => p.id == topico.id);
      if (topicoIndex >= 0) {
        // Atualizar o estado do tópico para o mesmo estado da matéria
        // Se a matéria for desmarcada (naoEstudado), desmarcar todos os tópicos também
        _progressos[topicoIndex] = ProgressoEstudo(
          id: topico.id,
          userId: userId,
          editalId: editalId,
          materiaId: materiaId,
          topicoId: topico.topicoId,
          estado: estado,
          dataAtualizacao: DateTime.now(),
        );
      }
    }

    await _saveProgressos();
  }

  // Atualizar o progresso de um tópico
  Future<void> atualizarProgressoTopico(String userId, String editalId, String materiaId, String topicoId, EstadoProgresso estado) async {
    // Verificar se já existe um progresso para este tópico
    final index = _progressos.indexWhere(
      (p) => p.userId == userId && p.editalId == editalId && p.materiaId == materiaId && p.topicoId == topicoId
    );

    // Ao marcar um estado superior, marcar automaticamente todos os estados anteriores
    final novoProgresso = ProgressoEstudo(
      id: index >= 0 ? _progressos[index].id : _uuid.v4(),
      userId: userId,
      editalId: editalId,
      materiaId: materiaId,
      topicoId: topicoId,
      estado: estado,
      dataAtualizacao: DateTime.now(),
    );

    if (index >= 0) {
      _progressos[index] = novoProgresso;
    } else {
      _progressos.add(novoProgresso);
    }

    // Obter todos os tópicos desta matéria diretamente da lista _progressos para garantir dados atualizados
    final topicos = _progressos.where(
      (p) => p.userId == userId && p.editalId == editalId && p.materiaId == materiaId && p.topicoId != null
    ).toList();

    if (topicos.isNotEmpty) {
      // Calcular a porcentagem de tópicos em cada estado
      int totalTopicos = topicos.length;
      int naoEstudados = 0;
      int estudados = 0;
      int primeiraRevisao = 0;
      int segundaRevisao = 0;
      int terceiraRevisao = 0;

      for (final topico in topicos) {
        switch (topico.estado) {
          case EstadoProgresso.naoEstudado:
            naoEstudados++;
            break;
          case EstadoProgresso.estudado:
            estudados++;
            break;
          case EstadoProgresso.primeiraRevisao:
            primeiraRevisao++;
            break;
          case EstadoProgresso.segundaRevisao:
            segundaRevisao++;
            break;
          case EstadoProgresso.terceiraRevisao:
            terceiraRevisao++;
            break;
        }
      }

      // Atualizar a matéria com base no estado dos tópicos
      final materiaIndex = _progressos.indexWhere(
        (p) => p.userId == userId && p.editalId == editalId && p.materiaId == materiaId && p.topicoId == null
      );

      // Calcular o progresso proporcional
      double percentualEstudado = (estudados + primeiraRevisao + segundaRevisao + terceiraRevisao) / totalTopicos;
      double percentualPrimeiraRevisao = (primeiraRevisao + segundaRevisao + terceiraRevisao) / totalTopicos;
      double percentualSegundaRevisao = (segundaRevisao + terceiraRevisao) / totalTopicos;
      double percentualTerceiraRevisao = terceiraRevisao / totalTopicos;

      // Determinar o estado da matéria com base nos percentuais
      EstadoProgresso novoEstadoMateria;

      // Verificar se todos os tópicos estão no mesmo estado
      if (naoEstudados == totalTopicos) {
        novoEstadoMateria = EstadoProgresso.naoEstudado;
      } else if (terceiraRevisao == totalTopicos) {
        // Se 100% dos tópicos estão na terceira revisão
        novoEstadoMateria = EstadoProgresso.terceiraRevisao;
      } else if (segundaRevisao + terceiraRevisao == totalTopicos) {
        // Se 100% dos tópicos estão pelo menos na segunda revisão
        novoEstadoMateria = EstadoProgresso.segundaRevisao;
      } else if (primeiraRevisao + segundaRevisao + terceiraRevisao == totalTopicos) {
        // Se 100% dos tópicos estão pelo menos na primeira revisão
        novoEstadoMateria = EstadoProgresso.primeiraRevisao;
      } else if (estudados + primeiraRevisao + segundaRevisao + terceiraRevisao == totalTopicos) {
        // Se 100% dos tópicos estão pelo menos estudados
        novoEstadoMateria = EstadoProgresso.estudado;
      } else {
        // Se nem todos os tópicos estão no mesmo estado, usar o estado mais baixo
        novoEstadoMateria = EstadoProgresso.naoEstudado;
      }

      if (materiaIndex >= 0) {
        _progressos[materiaIndex] = ProgressoEstudo(
          id: _progressos[materiaIndex].id,
          userId: userId,
          editalId: editalId,
          materiaId: materiaId,
          topicoId: null,
          estado: novoEstadoMateria,
          dataAtualizacao: DateTime.now(),
        );
      } else {
        // Se a matéria não existir, criá-la
        _progressos.add(ProgressoEstudo(
          id: _uuid.v4(),
          userId: userId,
          editalId: editalId,
          materiaId: materiaId,
          topicoId: null,
          estado: novoEstadoMateria,
          dataAtualizacao: DateTime.now(),
        ));
      }
    }

    await _saveProgressos();
  }

  // Obter todos os progressos de um usuário para um edital específico
  List<ProgressoEstudo> getProgressosByEdital(String userId, String editalId) {
    final key = '${userId}_$editalId';
    return _progressosPorEdital[key] ?? [];
  }

  // Obter todos os tópicos de uma matéria
  List<ProgressoEstudo> getTopicosByMateria(String userId, String editalId, String materiaId) {
    final key = '${userId}_$editalId';
    final progressosEdital = _progressosPorEdital[key] ?? [];

    return progressosEdital.where(
      (p) => p.materiaId == materiaId && p.topicoId != null
    ).toList();
  }

  // Calcular estatísticas de progresso para uma matéria
  Map<String, double> calcularEstatisticasMateria(String userId, String editalId, String materiaId) {
    final topicos = getTopicosByMateria(userId, editalId, materiaId);

    if (topicos.isEmpty) {
      // Se não houver tópicos, verificar o estado da matéria
      final materiaProgresso = getProgressoMateria(userId, editalId, materiaId);

      // Se a matéria estiver estudada ou revisada, considerar 100% para o estado correspondente
      if (materiaProgresso.estado != EstadoProgresso.naoEstudado) {
        final result = {
          'estudado': materiaProgresso.estado.index >= EstadoProgresso.estudado.index ? 100.0 : 0.0,
          'primeiraRevisao': materiaProgresso.estado.index >= EstadoProgresso.primeiraRevisao.index ? 100.0 : 0.0,
          'segundaRevisao': materiaProgresso.estado.index >= EstadoProgresso.segundaRevisao.index ? 100.0 : 0.0,
          'terceiraRevisao': materiaProgresso.estado.index >= EstadoProgresso.terceiraRevisao.index ? 100.0 : 0.0,
        };
        return result;
      }

      // Se não houver tópicos e a matéria não estiver estudada, retornar 0%
      return {
        'estudado': 0.0,
        'primeiraRevisao': 0.0,
        'segundaRevisao': 0.0,
        'terceiraRevisao': 0.0,
      };
    }

    // Contar tópicos em cada estado
    int totalTopicos = topicos.length;
    int naoEstudados = 0;
    int apenasEstudados = 0;
    int comPrimeiraRevisao = 0;
    int comSegundaRevisao = 0;
    int comTerceiraRevisao = 0;

    for (final topico in topicos) {
      switch (topico.estado) {
        case EstadoProgresso.naoEstudado:
          naoEstudados++;
          break;
        case EstadoProgresso.estudado:
          apenasEstudados++;
          break;
        case EstadoProgresso.primeiraRevisao:
          comPrimeiraRevisao++;
          break;
        case EstadoProgresso.segundaRevisao:
          comSegundaRevisao++;
          break;
        case EstadoProgresso.terceiraRevisao:
          comTerceiraRevisao++;
          break;
      }
    }

    // Calcular percentuais com base no número total de tópicos
    // Cada tópico contribui com uma porcentagem igual para o total (100% / totalTopicos)
    double percentualPorTopico = 100.0 / totalTopicos;

    return {
      'estudado': apenasEstudados * percentualPorTopico + comPrimeiraRevisao * percentualPorTopico + comSegundaRevisao * percentualPorTopico + comTerceiraRevisao * percentualPorTopico,
      'primeiraRevisao': comPrimeiraRevisao * percentualPorTopico + comSegundaRevisao * percentualPorTopico + comTerceiraRevisao * percentualPorTopico,
      'segundaRevisao': comSegundaRevisao * percentualPorTopico + comTerceiraRevisao * percentualPorTopico,
      'terceiraRevisao': comTerceiraRevisao * percentualPorTopico,
    };
  }

  // Formatar estatísticas para exibição
  String formatarEstatisticasMateria(String userId, String editalId, String materiaId) {
    final estatisticas = calcularEstatisticasMateria(userId, editalId, materiaId);

    // Verificar se há tópicos para esta matéria
    final topicos = getTopicosByMateria(userId, editalId, materiaId);
    if (topicos.isEmpty) {
      // Se não houver tópicos, verificar o estado da matéria
      final materiaProgresso = getProgressoMateria(userId, editalId, materiaId);

      // Exibir o estado atual da matéria
      switch (materiaProgresso.estado) {
        case EstadoProgresso.naoEstudado:
          return 'Não estudado';
        case EstadoProgresso.estudado:
          return 'Estudado: 100%';
        case EstadoProgresso.primeiraRevisao:
          return 'Estudado: 100% / 1ª Revisão: 100%';
        case EstadoProgresso.segundaRevisao:
          return 'Estudado: 100% / 1ª Revisão: 100% / 2ª Revisão: 100%';
        case EstadoProgresso.terceiraRevisao:
          return 'Estudado: 100% / 1ª Revisão: 100% / 2ª Revisão: 100% / 3ª Revisão: 100%';
      }
    }

    return 'Estudado: ${estatisticas['estudado']!.toStringAsFixed(0)}% / '
           'Revisões: 1ª: ${estatisticas['primeiraRevisao']!.toStringAsFixed(0)}%; '
           '2ª: ${estatisticas['segundaRevisao']!.toStringAsFixed(0)}%; '
           '3ª: ${estatisticas['terceiraRevisao']!.toStringAsFixed(0)}%';
  }

  // Limpar todos os progressos de um usuário
  Future<void> limparProgressos(String userId) async {
    _progressos.removeWhere((p) => p.userId == userId);
    await _saveProgressos();
  }

  // Limpar o cache de progresso sem remover os dados
  Future<void> limparCacheProgresso() async {
    // Recarregar os dados do armazenamento para garantir que temos os dados mais recentes
    final prefs = await SharedPreferences.getInstance();
    final String? progressosJson = prefs.getString(_storageKey);

    if (progressosJson != null) {
      final List<dynamic> decodedList = jsonDecode(progressosJson);
      _progressos = decodedList.map((item) => ProgressoEstudo.fromMap(item)).toList();
    }

    // Atualizar o cache
    _atualizarCache();

    print('Cache de progresso atualizado com sucesso');
  }
}
