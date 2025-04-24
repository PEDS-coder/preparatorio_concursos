import 'package:flutter/material.dart';
import '../../../../../core/data/models/edital.dart';

/// Serviço para agrupamento de cargos
class CargoGroupingService {
  /// Agrupa cargos por nível de escolaridade ou tipo
  static Map<String, List<Cargo>> agruparCargos(Edital edital, List<String>? cargosSelecionados) {
    // Verificar se há cargos disponíveis
    if (edital.dadosExtraidos.cargos.isEmpty) {
      debugPrint('Nenhum cargo encontrado no edital');
      return {};
    }

    // Agrupar cargos por nível de escolaridade
    Map<String, List<Cargo>> grupos = {};

    // Filtrar cargos selecionados se houver
    List<Cargo> cargosParaAgrupar = edital.dadosExtraidos.cargos;
    if (cargosSelecionados != null && cargosSelecionados.isNotEmpty) {
      cargosParaAgrupar = edital.dadosExtraidos.cargos.where((cargo) {
        return cargosSelecionados.contains(cargo.nome) ||
               cargosSelecionados.contains(cargo.id);
      }).toList();

      // Se não encontrou nenhum cargo, usar todos os cargos
      if (cargosParaAgrupar.isEmpty) {
        cargosParaAgrupar = edital.dadosExtraidos.cargos;
      }
    }

    // Verificar se todos os cargos são de nível superior
    bool todosNivelSuperior = true;
    for (var cargo in cargosParaAgrupar) {
      final escolaridade = cargo.escolaridade.toLowerCase();
      if (!escolaridade.contains('superior') &&
          !escolaridade.contains('graduação') &&
          !escolaridade.contains('bacharel') &&
          !escolaridade.contains('licenciatura')) {
        todosNivelSuperior = false;
        break;
      }
    }

    // Verificar se o título do concurso contém MPU
    bool isMPU = edital.dadosExtraidos.titulo?.toLowerCase().contains('mpu') == true ||
                 edital.dadosExtraidos.orgao?.toLowerCase().contains('ministério público da união') == true;

    // Se todos os cargos são de nível superior ou se é um concurso do MPU
    if (todosNivelSuperior || isMPU) {
      // Agrupar por tipo de cargo em vez de nível de escolaridade
      for (var cargo in cargosParaAgrupar) {
        String grupo = 'Outros';
        final nomeCargo = cargo.nome.toLowerCase();

        // Para concursos do MPU
        if (isMPU) {
          if (nomeCargo.contains('analista')) {
            grupo = 'Analista do MPU';
          } else if (nomeCargo.contains('técnico')) {
            grupo = 'Técnico do MPU';
          }
        }
        // Para outros concursos onde todos os cargos são de nível superior
        else if (todosNivelSuperior) {
          // Extrair a área/especialidade do cargo
          if (nomeCargo.contains('analista')) {
            grupo = 'Analista';
          } else if (nomeCargo.contains('técnico')) {
            grupo = 'Técnico';
          } else if (nomeCargo.contains('auditor')) {
            grupo = 'Auditor';
          } else if (nomeCargo.contains('procurador')) {
            grupo = 'Procurador';
          } else if (nomeCargo.contains('advogado')) {
            grupo = 'Advogado';
          } else {
            // Tentar extrair a área principal do cargo
            List<String> partes = nomeCargo.split(' ');
            if (partes.length > 0) {
              grupo = partes[0].substring(0, 1).toUpperCase() + partes[0].substring(1);
            }
          }
        }

        if (!grupos.containsKey(grupo)) {
          grupos[grupo] = [];
        }

        grupos[grupo]!.add(cargo);
      }
    } else {
      // Comportamento padrão para outros editais com diferentes níveis de escolaridade
      for (var cargo in cargosParaAgrupar) {
        String grupo = 'Outros';
        final nomeCargo = cargo.nome.toLowerCase();
        final escolaridade = cargo.escolaridade.toLowerCase();

        // Determinar o nível pela escolaridade primeiro (mais preciso)
        if (escolaridade.contains('superior') ||
            escolaridade.contains('graduação') ||
            escolaridade.contains('bacharel') ||
            escolaridade.contains('licenciatura')) {
          grupo = 'Nível Superior';
        } else if (escolaridade.contains('médio') ||
                  escolaridade.contains('técnico') ||
                  escolaridade.contains('2º grau')) {
          grupo = 'Nível Médio';
        } else if (escolaridade.contains('fundamental') ||
                  escolaridade.contains('1º grau') ||
                  escolaridade.contains('elementar')) {
          grupo = 'Nível Fundamental';
        }
        // Se não encontrou pela escolaridade, tentar pelo nome do cargo
        else if (nomeCargo.contains('analista') ||
                nomeCargo.contains('auditor') ||
                nomeCargo.contains('procurador') ||
                nomeCargo.contains('advogado') ||
                nomeCargo.contains('contador') ||
                nomeCargo.contains('administrador')) {
          grupo = 'Nível Superior';
        } else if (nomeCargo.contains('técnico') ||
                  nomeCargo.contains('assistente') ||
                  nomeCargo.contains('agente')) {
          grupo = 'Nível Médio';
        } else if (nomeCargo.contains('auxiliar') ||
                  nomeCargo.contains('motorista') ||
                  nomeCargo.contains('operador')) {
          grupo = 'Nível Fundamental';
        }

        if (!grupos.containsKey(grupo)) {
          grupos[grupo] = [];
        }

        grupos[grupo]!.add(cargo);
      }
    }

    // Ordenar os cargos dentro de cada grupo por nome
    grupos.forEach((key, value) {
      value.sort((a, b) => a.nome.compareTo(b.nome));
    });

    // Log para depuração
    debugPrint('Grupos de cargos: ${grupos.keys.join(', ')}');
    grupos.forEach((grupo, cargos) {
      debugPrint('$grupo: ${cargos.length} cargos');
      for (var cargo in cargos) {
        debugPrint('  - ${cargo.nome}');
      }
    });

    return grupos;
  }

  /// Retorna o ícone apropriado para o grupo de cargos
  static IconData getIconForGrupo(String grupo) {
    if (grupo.contains('Superior')) {
      return Icons.school;
    } else if (grupo.contains('Médio')) {
      return Icons.work;
    } else if (grupo.contains('Fundamental')) {
      return Icons.engineering;
    } else {
      return Icons.group;
    }
  }
}
