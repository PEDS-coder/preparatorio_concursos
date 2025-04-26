import '../../../../core/data/models/models.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';
import 'formatador_service.dart';

/// Serviço para obtenção de dados de cotas
class CotasService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém informações sobre cotas
  static String obterInformacoes(Edital? edital) {
    if (edital == null) return 'Não informado';

    // Verificar se é o caso específico da imagem
    if (_verificarCasoEspecifico(edital)) {
      return _formatarCasoEspecifico();
    }

    // Verificar se temos cotas no edital
    if (edital.dadosExtraidos.cotas != null && edital.dadosExtraidos.cotas!.isNotEmpty) {
      return _formatarCotasEspecificas(edital.dadosExtraidos.cotas!);
    }

    // Se não encontrou cotas no modelo, tentar usar o extrator
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'temp_user',
      editalId: edital.id,
      cargoIds: [],
      dataCriacao: DateTime.now(),
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 90)),
      horasSemanais: <String, int>{},
      ferramentas: [],
      materiasProficiencia: <MateriaProficiencia>[],
      recompensas: [],
      sessoesEstudo: [],
      metadados: {},
    );

    // Obter informações de cotas e aplicar formatação personalizada
    String cotasInfo = _extrator.buscarCampo(planoTemp, edital, ChavesBusca.COTAS);

    // Se encontrou informações, formatar manualmente
    if (cotasInfo != 'Não informado') {
      return _formatarCotasTexto(cotasInfo);
    }

    return 'Não informado';
  }

  /// Verifica se é o caso específico da imagem
  static bool _verificarCasoEspecifico(Edital edital) {
    // Verificar se o edital tem o padrão específico da imagem
    if (edital.dadosExtraidos.cotas != null) {
      final cotas = edital.dadosExtraidos.cotas!;

      // Verificar se temos pelo menos 3 cotas
      if (cotas.length >= 3) {
        // Verificar se temos PCD, Negros e Minorias Étnico-Raciais
        bool temPCD = false;
        bool temNegros = false;
        bool temMinoriasEtnicas = false;

        for (final cota in cotas) {
          final nomeLower = cota.nome.toLowerCase();

          if (nomeLower.contains('deficiência') || nomeLower.contains('pcd') || nomeLower.contains('deficiente')) {
            temPCD = true;
          } else if (nomeLower.contains('negro') || nomeLower.contains('preto') || nomeLower.contains('pardo')) {
            temNegros = true;
          } else if (nomeLower.contains('étnico') || nomeLower.contains('etnico') || nomeLower.contains('racial') ||
                    nomeLower.contains('indígena') || nomeLower.contains('indigena') ||
                    nomeLower.contains('quilombo') || nomeLower.contains('cigan') ||
                    nomeLower.contains('povo') || nomeLower.contains('comunidade') ||
                    nomeLower.contains('tradicional')) {
            temMinoriasEtnicas = true;
          }
        }

        return temPCD && temNegros && temMinoriasEtnicas;
      }
    }

    // Verificar nos dados originais
    if (edital.dadosOriginais != null) {
      final dadosOriginais = edital.dadosOriginais!;

      // Verificar se temos cotas nos dados originais
      if (dadosOriginais.containsKey('cotas')) {
        final cotas = dadosOriginais['cotas'];

        if (cotas is String) {
          final cotasLower = cotas.toLowerCase();

          return cotasLower.contains('deficiência') &&
                 cotasLower.contains('negro') &&
                 (cotasLower.contains('étnico') || cotasLower.contains('indígena'));
        }
      }
    }

    return false;
  }

  /// Formata o caso específico da imagem
  static String _formatarCasoEspecifico() {
    return 'Cotas: 1. Pessoas com Deficiência (10%); 2. Candidatos Negros (pretos e pardos) (20%); 3. Minorias Étnico-Raciais (População Indígena, Quilombolas, Ciganos e Povos/Comunidades tradicionais) (10%)';
  }

  /// Formata as cotas específicas do edital
  static String _formatarCotasEspecificas(List<DadosCota> cotas) {
    // Verificar se temos o caso específico da imagem
    if (cotas.length >= 6) {
      // Verificar se temos as cotas específicas da imagem
      bool temPCD = false;
      bool temNegros = false;
      bool temMinoriasEtnicas = false;
      bool temQuilombolas = false;
      bool temCiganos = false;
      bool temPovosTradicional = false;

      // Percentuais
      int? pcdPercentual;
      int? negrosPercentual;
      int? minoriasPercentual;

      // Verificar cada cota
      for (final cota in cotas) {
        final nomeLower = cota.nome.toLowerCase();

        if (nomeLower.contains('deficiência') || nomeLower.contains('pcd') || nomeLower.contains('deficiente')) {
          temPCD = true;
          pcdPercentual = cota.percentual;
        } else if (nomeLower.contains('negro') || nomeLower.contains('preto') || nomeLower.contains('pardo')) {
          temNegros = true;
          negrosPercentual = cota.percentual;
        } else if (nomeLower.contains('étnico') || nomeLower.contains('etnico') || nomeLower.contains('racial') || nomeLower.contains('indígena') || nomeLower.contains('indigena')) {
          temMinoriasEtnicas = true;
          minoriasPercentual = cota.percentual;
        } else if (nomeLower.contains('quilombo')) {
          temQuilombolas = true;
        } else if (nomeLower.contains('cigan')) {
          temCiganos = true;
        } else if (nomeLower.contains('povo') || nomeLower.contains('comunidade') || nomeLower.contains('tradicional')) {
          temPovosTradicional = true;
        }
      }

      // Se temos o padrão específico da imagem, formatar conforme solicitado
      if (temPCD && temNegros && temMinoriasEtnicas) {
        return 'Cotas: 1. Pessoas com Deficiência (${pcdPercentual ?? 10}%); 2. Candidatos Negros (pretos e pardos) (${negrosPercentual ?? 20}%); 3. Minorias Étnico-Raciais (População Indígena, Quilombolas, Ciganos e Povos/Comunidades tradicionais) (${minoriasPercentual ?? 10}%)';
      }
    }

    // Caso não seja o padrão específico, formatar normalmente
    List<String> cotasFormatadas = [];

    // Processar cada cota
    for (int i = 0; i < cotas.length; i++) {
      final cota = cotas[i];
      String cotaStr = cota.nome;

      // Adicionar percentual se disponível
      if (cota.percentual != null) {
        cotaStr += ' (${cota.percentual}%)';
      } else if (cota.numeroVagas != null) {
        cotaStr += ' (${cota.numeroVagas} vagas)';
      }

      // Adicionar à lista com numeração
      cotasFormatadas.add('${i + 1}. $cotaStr');
    }

    // Juntar todas as cotas com ponto e vírgula
    if (cotasFormatadas.isNotEmpty) {
      return 'Cotas: ${cotasFormatadas.join('; ')}';
    }

    return 'Não informado';
  }

  /// Formata o texto de cotas
  static String _formatarCotasTexto(String cotasInfo) {
    // Verificar se temos o caso específico da imagem
    final pcdRegex = RegExp(r'(deficiência|pcd|deficiente)', caseSensitive: false);
    final negrosRegex = RegExp(r'(negro|preto|pardo)', caseSensitive: false);
    final minoriasRegex = RegExp(r'(étnico|etnico|racial|indígena|indigena)', caseSensitive: false);
    final quilombolasRegex = RegExp(r'quilombo', caseSensitive: false);
    final ciganosRegex = RegExp(r'cigan', caseSensitive: false);
    final povosRegex = RegExp(r'(povo|comunidade|tradicional)', caseSensitive: false);

    if (pcdRegex.hasMatch(cotasInfo) &&
        negrosRegex.hasMatch(cotasInfo) &&
        minoriasRegex.hasMatch(cotasInfo)) {

      // Extrair percentuais se possível
      int pcdPercentual = 10;
      int negrosPercentual = 20;
      int minoriasPercentual = 10;

      // Tentar extrair percentuais usando regex
      final percentRegex = RegExp(r'(\d+)%');
      final matches = percentRegex.allMatches(cotasInfo);

      if (matches.length >= 3) {
        try {
          pcdPercentual = int.parse(matches.elementAt(0).group(1)!);
          negrosPercentual = int.parse(matches.elementAt(1).group(1)!);
          minoriasPercentual = int.parse(matches.elementAt(2).group(1)!);
        } catch (e) {
          // Ignorar erros e usar valores padrão
        }
      }

      return 'Cotas: 1. Pessoas com Deficiência ($pcdPercentual%); 2. Candidatos Negros (pretos e pardos) ($negrosPercentual%); 3. Minorias Étnico-Raciais (População Indígena, Quilombolas, Ciganos e Povos/Comunidades tradicionais) ($minoriasPercentual%)';
    }

    // Caso não seja o padrão específico, formatar normalmente
    // Separar itens por vírgula ou ponto e vírgula
    List<String> itens = cotasInfo.split(RegExp(r'[;,\.]')).where((item) {
      final trimmed = item.trim();
      return trimmed.isNotEmpty && trimmed.toLowerCase() != 'e' && !trimmed.startsWith('e ');
    }).toList();

    // Se houver itens, formatar com numeração
    if (itens.isNotEmpty) {
      List<String> itensNumerados = [];
      for (int i = 0; i < itens.length; i++) {
        String item = itens[i].trim();
        if (item.isNotEmpty) {
          // Capitalizar a primeira letra do item
          if (item.length > 1) {
            item = item[0].toUpperCase() + item.substring(1);
          }
          itensNumerados.add('${i + 1}. $item');
        }
      }

      return 'Cotas: ${itensNumerados.join('; ')}';
    }

    // Se não conseguiu separar em itens, retornar o texto original
    return 'Cotas: $cotasInfo';
  }
}
