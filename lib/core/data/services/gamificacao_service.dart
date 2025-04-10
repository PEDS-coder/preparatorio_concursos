import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/trofeu.dart';
import '../models/usuario.dart';
import '../../auth/auth_service.dart';

class GamificacaoService extends ChangeNotifier {
  final AuthService _authService;
  List<Trofeu> _trofeus = [];
  List<UsuarioTrofeu> _usuarioTrofeus = [];
  
  GamificacaoService(this._authService) {
    _initTrofeus();
  }
  
  List<Trofeu> get trofeus => _trofeus;
  List<UsuarioTrofeu> get usuarioTrofeus => _usuarioTrofeus;
  
  // Inicializar lista de troféus disponíveis
  void _initTrofeus() {
    _trofeus = [
      Trofeu(
        id: '1',
        nomeTrofeu: 'Primeiro Passo',
        descricaoTrofeu: 'Completou sua primeira sessão de estudo',
        icone: 'assets/icons/trofeu_primeiro_passo.png',
      ),
      Trofeu(
        id: '2',
        nomeTrofeu: 'Consistência',
        descricaoTrofeu: 'Estudou por 7 dias consecutivos',
        icone: 'assets/icons/trofeu_consistencia.png',
      ),
      Trofeu(
        id: '3',
        nomeTrofeu: 'Maratonista',
        descricaoTrofeu: 'Completou 10 horas de estudo em uma semana',
        icone: 'assets/icons/trofeu_maratonista.png',
      ),
      Trofeu(
        id: '4',
        nomeTrofeu: 'Mestre em Questões',
        descricaoTrofeu: 'Resolveu mais de 100 questões',
        icone: 'assets/icons/trofeu_questoes.png',
      ),
      Trofeu(
        id: '5',
        nomeTrofeu: 'Planejador',
        descricaoTrofeu: 'Criou seu primeiro plano de estudos',
        icone: 'assets/icons/trofeu_planejador.png',
      ),
    ];
  }
  
  // Carregar troféus do usuário do armazenamento local
  Future<void> loadUsuarioTrofeus() async {
    final prefs = await SharedPreferences.getInstance();
    final trofeusJson = prefs.getStringList('usuario_trofeus') ?? [];
    
    _usuarioTrofeus = trofeusJson.map((json) => UsuarioTrofeu.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }
  
  // Salvar troféus do usuário no armazenamento local
  Future<void> _saveUsuarioTrofeus() async {
    final prefs = await SharedPreferences.getInstance();
    final trofeusJson = _usuarioTrofeus.map((trofeu) => jsonEncode(trofeu.toMap())).toList();
    
    await prefs.setStringList('usuario_trofeus', trofeusJson);
  }
  
  // Conceder um troféu ao usuário
  Future<bool> concederTrofeu(String trofeuId) async {
    final usuario = _authService.currentUser;
    if (usuario == null) return false;
    
    // Verificar se o usuário já possui este troféu
    final jaTemTrofeu = _usuarioTrofeus.any((t) => 
      t.userId == usuario.id && t.trofeuId == trofeuId
    );
    
    if (jaTemTrofeu) return false;
    
    // Adicionar o troféu
    final usuarioTrofeu = UsuarioTrofeu(
      userId: usuario.id,
      trofeuId: trofeuId,
      dataConquista: DateTime.now(),
    );
    
    _usuarioTrofeus.add(usuarioTrofeu);
    await _saveUsuarioTrofeus();
    
    // Adicionar pontos ao usuário
    await _adicionarPontos(100); // 100 pontos por troféu
    
    notifyListeners();
    return true;
  }
  
  // Obter troféus de um usuário
  List<Trofeu> getTrofeusByUserId(String userId) {
    final trofeuIds = _usuarioTrofeus
      .where((ut) => ut.userId == userId)
      .map((ut) => ut.trofeuId)
      .toList();
    
    return _trofeus.where((trofeu) => trofeuIds.contains(trofeu.id)).toList();
  }
  
  // Adicionar pontos ao usuário
  Future<void> _adicionarPontos(int pontos) async {
    final usuario = _authService.currentUser;
    if (usuario == null) return;
    
    // Atualizar pontos e verificar se subiu de nível
    final novosPontos = usuario.pontosGamificacao + pontos;
    final novoNivel = _calcularNivel(novosPontos);
    
    // Criar usuário atualizado
    final usuarioAtualizado = usuario.copyWith(
      pontosGamificacao: novosPontos,
      nivelGamificacao: novoNivel,
    );
    
    // Salvar no AuthService (simulação)
    // Em um app real, isso seria feito através de uma API
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', json.encode(usuarioAtualizado.toMap()));
    
    notifyListeners();
  }
  
  // Calcular nível com base nos pontos
  int _calcularNivel(int pontos) {
    // Fórmula simples: cada 500 pontos = 1 nível
    return (pontos / 500).floor() + 1;
  }
  
  // Registrar atividade e conceder pontos
  Future<void> registrarAtividade(String tipoAtividade, {int? pontos}) async {
    final pontosAtividade = pontos ?? _getPontosPorAtividade(tipoAtividade);
    await _adicionarPontos(pontosAtividade);
    
    // Verificar conquistas
    await _verificarConquistas(tipoAtividade);
  }
  
  // Obter pontos por tipo de atividade
  int _getPontosPorAtividade(String tipoAtividade) {
    switch (tipoAtividade) {
      case 'sessao_estudo':
        return 50;
      case 'questao_resolvida':
        return 5;
      case 'plano_criado':
        return 100;
      case 'edital_analisado':
        return 75;
      default:
        return 10;
    }
  }
  
  // Verificar se o usuário conquistou algum troféu
  Future<void> _verificarConquistas(String tipoAtividade) async {
    // Implementação simplificada
    // Em um app real, isso seria mais complexo e baseado em dados reais
    
    switch (tipoAtividade) {
      case 'sessao_estudo':
        await concederTrofeu('1'); // Primeiro Passo
        break;
      case 'plano_criado':
        await concederTrofeu('5'); // Planejador
        break;
      // Outros casos seriam verificados com base em dados reais
    }
  }
}
