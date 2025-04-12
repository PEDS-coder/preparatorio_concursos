import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/recompensa_mercado.dart';
import '../models/usuario.dart';
import '../../auth/auth_service.dart';

class MercadoService extends ChangeNotifier {
  final AuthService _authService;
  List<RecompensaMercado> _recompensas = [];
  List<HistoricoMoedas> _historicoMoedas = [];
  
  // Mapa para armazenar streaks de estudo por usuário
  Map<String, int> _streaksDiarios = {};
  
  // Mapa para armazenar horas de estudo semanais por usuário
  Map<String, double> _horasEstudoSemanais = {};
  
  // Mapa para armazenar a última data de estudo por usuário
  Map<String, DateTime> _ultimaDataEstudo = {};
  
  // Mapa para armazenar se o usuário já recebeu o bônus diário
  Map<String, bool> _bonusDiarioRecebido = {};
  
  MercadoService(this._authService) {
    _loadRecompensas();
    _loadHistoricoMoedas();
    _loadStreaks();
  }
  
  // Getters
  List<RecompensaMercado> get recompensas => _recompensas;
  List<HistoricoMoedas> get historicoMoedas => _historicoMoedas;
  
  // Carregar recompensas do armazenamento local
  Future<void> _loadRecompensas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recompensasJson = prefs.getStringList('recompensas_mercado') ?? [];
      
      _recompensas = recompensasJson
          .map((json) => RecompensaMercado.fromMap(jsonDecode(json)))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar recompensas: $e');
    }
  }
  
  // Carregar histórico de moedas do armazenamento local
  Future<void> _loadHistoricoMoedas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historicoJson = prefs.getStringList('historico_moedas') ?? [];
      
      _historicoMoedas = historicoJson
          .map((json) => HistoricoMoedas.fromMap(jsonDecode(json)))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar histórico de moedas: $e');
    }
  }
  
  // Carregar streaks do armazenamento local
  Future<void> _loadStreaks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar streaks diários
      final streaksJson = prefs.getString('streaks_diarios');
      if (streaksJson != null) {
        _streaksDiarios = Map<String, int>.from(jsonDecode(streaksJson));
      }
      
      // Carregar horas de estudo semanais
      final horasJson = prefs.getString('horas_estudo_semanais');
      if (horasJson != null) {
        _horasEstudoSemanais = Map<String, double>.from(jsonDecode(horasJson));
      }
      
      // Carregar última data de estudo
      final datasJson = prefs.getString('ultima_data_estudo');
      if (datasJson != null) {
        final Map<String, dynamic> datasMap = jsonDecode(datasJson);
        _ultimaDataEstudo = {};
        datasMap.forEach((key, value) {
          _ultimaDataEstudo[key] = DateTime.parse(value);
        });
      }
      
      // Carregar status do bônus diário
      final bonusJson = prefs.getString('bonus_diario_recebido');
      if (bonusJson != null) {
        _bonusDiarioRecebido = Map<String, bool>.from(jsonDecode(bonusJson));
      }
      
    } catch (e) {
      debugPrint('Erro ao carregar streaks: $e');
    }
  }
  
  // Salvar recompensas no armazenamento local
  Future<void> _saveRecompensas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recompensasJson = _recompensas
          .map((recompensa) => jsonEncode(recompensa.toMap()))
          .toList();
      
      await prefs.setStringList('recompensas_mercado', recompensasJson);
    } catch (e) {
      debugPrint('Erro ao salvar recompensas: $e');
    }
  }
  
  // Salvar histórico de moedas no armazenamento local
  Future<void> _saveHistoricoMoedas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historicoJson = _historicoMoedas
          .map((item) => jsonEncode(item.toMap()))
          .toList();
      
      await prefs.setStringList('historico_moedas', historicoJson);
    } catch (e) {
      debugPrint('Erro ao salvar histórico de moedas: $e');
    }
  }
  
  // Salvar streaks no armazenamento local
  Future<void> _saveStreaks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar streaks diários
      await prefs.setString('streaks_diarios', jsonEncode(_streaksDiarios));
      
      // Salvar horas de estudo semanais
      await prefs.setString('horas_estudo_semanais', jsonEncode(_horasEstudoSemanais));
      
      // Salvar última data de estudo
      final Map<String, String> datasMap = {};
      _ultimaDataEstudo.forEach((key, value) {
        datasMap[key] = value.toIso8601String();
      });
      await prefs.setString('ultima_data_estudo', jsonEncode(datasMap));
      
      // Salvar status do bônus diário
      await prefs.setString('bonus_diario_recebido', jsonEncode(_bonusDiarioRecebido));
      
    } catch (e) {
      debugPrint('Erro ao salvar streaks: $e');
    }
  }
  
  // Adicionar uma nova recompensa
  Future<RecompensaMercado> adicionarRecompensa(
    String titulo,
    String descricao,
    String categoria,
    int? custoMoedas,
  ) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      throw Exception('Usuário não autenticado');
    }
    
    // Determinar o custo baseado na categoria se não for fornecido
    final custo = custoMoedas ?? RecompensaMercado.sugerirCusto(categoria);
    
    final recompensa = RecompensaMercado(
      id: const Uuid().v4(),
      userId: usuario.id,
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      custoMoedas: custo,
      dataCriacao: DateTime.now(),
    );
    
    _recompensas.add(recompensa);
    await _saveRecompensas();
    
    // Registrar a primeira recompensa criada (bônus)
    if (_recompensas.where((r) => r.userId == usuario.id).length == 1) {
      await adicionarMoedas(25, 'primeira_recompensa', 'Bônus pela primeira recompensa criada');
    }
    
    notifyListeners();
    return recompensa;
  }
  
  // Obter recompensas de um usuário
  List<RecompensaMercado> getRecompensasByUserId(String userId) {
    return _recompensas.where((r) => r.userId == userId).toList();
  }
  
  // Obter recompensas não resgatadas de um usuário
  List<RecompensaMercado> getRecompensasNaoResgatadas(String userId) {
    return _recompensas.where((r) => r.userId == userId && !r.resgatada).toList();
  }
  
  // Obter recompensas resgatadas de um usuário
  List<RecompensaMercado> getRecompensasResgatadas(String userId) {
    return _recompensas.where((r) => r.userId == userId && r.resgatada).toList();
  }
  
  // Resgatar uma recompensa
  Future<bool> resgatarRecompensa(String recompensaId) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return false;
    }
    
    // Encontrar a recompensa
    final index = _recompensas.indexWhere((r) => r.id == recompensaId);
    if (index == -1) {
      return false;
    }
    
    final recompensa = _recompensas[index];
    
    // Verificar se o usuário tem moedas suficientes
    if (usuario.pontosGamificacao < recompensa.custoMoedas) {
      return false;
    }
    
    // Atualizar a recompensa
    _recompensas[index] = recompensa.copyWith(
      resgatada: true,
      dataResgate: DateTime.now(),
    );
    
    // Deduzir as moedas do usuário
    await _gastarMoedas(recompensa.custoMoedas, 'resgate', 'Resgate de recompensa: ${recompensa.titulo}');
    
    await _saveRecompensas();
    notifyListeners();
    return true;
  }
  
  // Excluir uma recompensa
  Future<bool> excluirRecompensa(String recompensaId) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return false;
    }
    
    // Encontrar a recompensa
    final index = _recompensas.indexWhere((r) => r.id == recompensaId && r.userId == usuario.id);
    if (index == -1) {
      return false;
    }
    
    // Verificar se a recompensa já foi resgatada
    if (_recompensas[index].resgatada) {
      return false;
    }
    
    // Remover a recompensa
    _recompensas.removeAt(index);
    await _saveRecompensas();
    notifyListeners();
    return true;
  }
  
  // Adicionar moedas ao usuário
  Future<void> adicionarMoedas(int quantidade, String origem, String? descricao) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return;
    }
    
    // Atualizar pontos do usuário
    final novosPontos = usuario.pontosGamificacao + quantidade;
    
    // Criar usuário atualizado
    final usuarioAtualizado = usuario.copyWith(
      pontosGamificacao: novosPontos,
    );
    
    // Salvar no AuthService
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', json.encode(usuarioAtualizado.toMap()));
    
    // Registrar no histórico
    final historico = HistoricoMoedas(
      id: const Uuid().v4(),
      userId: usuario.id,
      quantidade: quantidade,
      tipo: 'ganho',
      origem: origem,
      descricao: descricao,
      data: DateTime.now(),
    );
    
    _historicoMoedas.add(historico);
    await _saveHistoricoMoedas();
    
    notifyListeners();
  }
  
  // Gastar moedas do usuário
  Future<void> _gastarMoedas(int quantidade, String origem, String? descricao) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return;
    }
    
    // Verificar se o usuário tem moedas suficientes
    if (usuario.pontosGamificacao < quantidade) {
      throw Exception('Moedas insuficientes');
    }
    
    // Atualizar pontos do usuário
    final novosPontos = usuario.pontosGamificacao - quantidade;
    
    // Criar usuário atualizado
    final usuarioAtualizado = usuario.copyWith(
      pontosGamificacao: novosPontos,
    );
    
    // Salvar no AuthService
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', json.encode(usuarioAtualizado.toMap()));
    
    // Registrar no histórico
    final historico = HistoricoMoedas(
      id: const Uuid().v4(),
      userId: usuario.id,
      quantidade: quantidade,
      tipo: 'gasto',
      origem: origem,
      descricao: descricao,
      data: DateTime.now(),
    );
    
    _historicoMoedas.add(historico);
    await _saveHistoricoMoedas();
    
    notifyListeners();
  }
  
  // Obter o histórico de moedas de um usuário
  List<HistoricoMoedas> getHistoricoMoedasByUserId(String userId) {
    return _historicoMoedas.where((h) => h.userId == userId).toList();
  }
  
  // Registrar uma sessão de estudo e conceder moedas
  Future<void> registrarSessaoEstudo(int duracaoMinutos) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return;
    }
    
    // Calcular moedas baseado no tempo (1 moeda por minuto)
    final moedas = duracaoMinutos;
    
    // Verificar se é a primeira sessão do dia para conceder bônus
    final hoje = DateTime.now();
    final hojeFormatado = DateTime(hoje.year, hoje.month, hoje.day);
    
    // Verificar se o usuário já recebeu o bônus diário hoje
    final bonusRecebidoHoje = _bonusDiarioRecebido[usuario.id] ?? false;
    
    // Conceder bônus diário se for a primeira sessão do dia e durar pelo menos 15 minutos
    if (!bonusRecebidoHoje && duracaoMinutos >= 15) {
      await adicionarMoedas(10, 'bonus_diario', 'Bônus pela primeira sessão do dia');
      _bonusDiarioRecebido[usuario.id] = true;
      await _saveStreaks();
    }
    
    // Atualizar última data de estudo
    final ultimaData = _ultimaDataEstudo[usuario.id];
    _ultimaDataEstudo[usuario.id] = hojeFormatado;
    
    // Verificar streak
    if (ultimaData != null) {
      final ontem = DateTime(hojeFormatado.year, hojeFormatado.month, hojeFormatado.day - 1);
      
      if (ultimaData.isAtSameMomentAs(ontem)) {
        // Incrementar streak
        _streaksDiarios[usuario.id] = (_streaksDiarios[usuario.id] ?? 0) + 1;
        
        // Verificar se atingiu algum marco de streak
        final streak = _streaksDiarios[usuario.id] ?? 0;
        
        if (streak == 3) {
          await adicionarMoedas(30, 'streak_3_dias', 'Bônus por 3 dias consecutivos de estudo');
        } else if (streak == 7) {
          await adicionarMoedas(100, 'streak_7_dias', 'Bônus por 7 dias consecutivos de estudo');
        } else if (streak == 14) {
          await adicionarMoedas(150, 'streak_14_dias', 'Bônus por 14 dias consecutivos de estudo');
        } else if (streak == 30) {
          await adicionarMoedas(500, 'streak_30_dias', 'Bônus por 30 dias consecutivos de estudo');
        }
      } else if (!ultimaData.isAtSameMomentAs(hojeFormatado)) {
        // Reiniciar streak se não for ontem nem hoje
        _streaksDiarios[usuario.id] = 1;
      }
    } else {
      // Primeira sessão registrada
      _streaksDiarios[usuario.id] = 1;
    }
    
    // Atualizar horas de estudo semanais
    final horasAtuais = _horasEstudoSemanais[usuario.id] ?? 0.0;
    _horasEstudoSemanais[usuario.id] = horasAtuais + (duracaoMinutos / 60.0);
    
    // Verificar se atingiu a meta semanal (considerando 7 horas como meta padrão)
    final horasSemanais = _horasEstudoSemanais[usuario.id] ?? 0.0;
    if (horasSemanais >= 7.0 && horasAtuais < 7.0) {
      await adicionarMoedas(150, 'meta_semanal', 'Bônus por atingir a meta semanal de 7 horas');
    }
    
    // Verificar se é domingo para resetar as horas semanais
    if (hoje.weekday == DateTime.sunday && hoje.hour >= 20) {
      _horasEstudoSemanais[usuario.id] = 0.0;
    }
    
    // Salvar streaks
    await _saveStreaks();
    
    // Adicionar moedas pela sessão de estudo
    await adicionarMoedas(moedas, 'sessao_estudo', 'Sessão de estudo de $duracaoMinutos minutos');
  }
  
  // Obter o streak atual de um usuário
  int getStreakAtual(String userId) {
    return _streaksDiarios[userId] ?? 0;
  }
  
  // Obter as horas de estudo semanais de um usuário
  double getHorasEstudoSemanais(String userId) {
    return _horasEstudoSemanais[userId] ?? 0.0;
  }
  
  // Verificar se o usuário já recebeu o bônus diário hoje
  bool getBonusDiarioRecebidoHoje(String userId) {
    return _bonusDiarioRecebido[userId] ?? false;
  }
  
  // Resetar o bônus diário à meia-noite
  Future<void> resetarBonusDiario() async {
    _bonusDiarioRecebido = {};
    await _saveStreaks();
    notifyListeners();
  }
  
  // Verificar marcos de horas totais estudadas
  Future<void> verificarMarcosHorasTotais(int horasTotais, int horasAnteriores) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      return;
    }
    
    // Verificar se atingiu algum marco
    if (horasTotais >= 10 && horasAnteriores < 10) {
      await adicionarMoedas(100, 'marco_10_horas', 'Bônus por atingir 10 horas totais de estudo');
    } else if (horasTotais >= 50 && horasAnteriores < 50) {
      await adicionarMoedas(500, 'marco_50_horas', 'Bônus por atingir 50 horas totais de estudo');
    } else if (horasTotais >= 100 && horasAnteriores < 100) {
      await adicionarMoedas(1000, 'marco_100_horas', 'Bônus por atingir 100 horas totais de estudo');
    }
  }
}
