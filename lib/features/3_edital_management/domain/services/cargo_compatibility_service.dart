import 'package:intl/intl.dart';
import '../../../../../core/data/models/edital.dart';

/// Serviço para verificar compatibilidade entre cargos
class CargoCompatibilityService {
  /// Verifica se duas datas são no mesmo dia
  static bool mesmodia(DateTime data1, DateTime data2) {
    return data1.year == data2.year && data1.month == data2.month && data1.day == data2.day;
  }

  /// Identifica o período (manhã, tarde, noite) com base no texto do horário
  static String? identificarPeriodo(String horario) {
    final horarioLower = horario.toLowerCase();

    if (horarioLower.contains('manhã') ||
        horarioLower.contains('manha') ||
        horarioLower.contains('8h') ||
        horarioLower.contains('9h') ||
        horarioLower.contains('10h') ||
        horarioLower.contains('11h') ||
        horarioLower.contains('12h') ||
        horarioLower.contains('08:') ||
        horarioLower.contains('09:') ||
        horarioLower.contains('10:') ||
        horarioLower.contains('11:') ||
        horarioLower.contains('am')) {
      return 'manha';
    }

    if (horarioLower.contains('tarde') ||
        horarioLower.contains('13h') ||
        horarioLower.contains('14h') ||
        horarioLower.contains('15h') ||
        horarioLower.contains('16h') ||
        horarioLower.contains('17h') ||
        horarioLower.contains('13:') ||
        horarioLower.contains('14:') ||
        horarioLower.contains('15:') ||
        horarioLower.contains('16:') ||
        horarioLower.contains('17:') ||
        (horarioLower.contains('pm') && !horarioLower.contains('18:') && !horarioLower.contains('19:'))) {
      return 'tarde';
    }

    if (horarioLower.contains('noite') ||
        horarioLower.contains('18h') ||
        horarioLower.contains('19h') ||
        horarioLower.contains('20h') ||
        horarioLower.contains('21h') ||
        horarioLower.contains('22h') ||
        horarioLower.contains('18:') ||
        horarioLower.contains('19:') ||
        horarioLower.contains('20:') ||
        horarioLower.contains('21:') ||
        horarioLower.contains('22:')) {
      return 'noite';
    }

    return null; // Não foi possível identificar o período
  }

  /// Verifica se há compatibilidade de datas entre um novo cargo e cargos já selecionados
  static bool verificarCompatibilidadeDatas(Cargo novoCargo, List<String> cargosSelecionados, Edital edital) {
    // Se o cargo não tem data de prova, é compatível
    if (novoCargo.dataProva == null) {
      return true;
    }

    // Verificar se algum cargo já selecionado tem data de prova que colide
    for (final cargoNome in cargosSelecionados) {
      // Encontrar o cargo pelo nome
      final cargoSelecionado = edital.dadosExtraidos.cargos.firstWhere(
        (cargo) => cargo.nome == cargoNome || cargo.id == cargoNome,
        orElse: () => Cargo(
          id: 'dummy',
          nome: 'Dummy',
          vagas: 0,
          salario: 0,
          escolaridade: '',
          conteudoProgramatico: [],
          dataProva: null,
        ),
      );

      // Se o cargo selecionado tem data de prova e é a mesma do novo cargo, há conflito
      if (cargoSelecionado.dataProva != null && novoCargo.dataProva != null) {
        // Verificar se as datas são no mesmo dia
        final mesmaData = mesmodia(cargoSelecionado.dataProva!, novoCargo.dataProva!);

        if (mesmaData) {
          // Verificar se há informações de horário nos dados originais
          bool conflitoPeriodo = true; // Por padrão, considerar conflito se for no mesmo dia

          // Verificar se há informações de horário nos dados originais
          if (edital.dadosOriginais != null &&
              edital.dadosOriginais!.containsKey('cargos') &&
              edital.dadosOriginais!['cargos'] is List) {

            final cargosOriginais = edital.dadosOriginais!['cargos'] as List;

            // Buscar informações de horário para o cargo selecionado
            Map<dynamic, dynamic>? cargoSelecionadoOriginal;
            Map<dynamic, dynamic>? novoCargoOriginal;

            for (var cargo in cargosOriginais) {
              if (cargo is Map) {
                final nomeCargo = cargo['nome']?.toString() ?? '';

                if (nomeCargo == cargoSelecionado.nome) {
                  cargoSelecionadoOriginal = cargo as Map<dynamic, dynamic>;
                }

                if (nomeCargo == novoCargo.nome) {
                  novoCargoOriginal = cargo as Map<dynamic, dynamic>;
                }
              }
            }

            // Verificar se ambos os cargos têm informações de horário
            if (cargoSelecionadoOriginal != null && novoCargoOriginal != null) {
              // Verificar diferentes campos possíveis para horário
              final camposHorario = ['horario_prova', 'horario', 'periodo_prova', 'periodo', 'turno'];

              String? horarioSelecionado;
              String? horarioNovo;

              for (var campo in camposHorario) {
                if (cargoSelecionadoOriginal.containsKey(campo)) {
                  horarioSelecionado = cargoSelecionadoOriginal[campo]?.toString();
                }

                if (novoCargoOriginal.containsKey(campo)) {
                  horarioNovo = novoCargoOriginal[campo]?.toString();
                }
              }

              // Se ambos os cargos têm horários definidos, verificar se são diferentes
              if (horarioSelecionado != null && horarioNovo != null) {
                // Verificar se os horários são diferentes
                if (horarioSelecionado != horarioNovo) {
                  // Verificar se são períodos diferentes (manhã/tarde/noite)
                  final periodoSelecionado = identificarPeriodo(horarioSelecionado);
                  final periodoNovo = identificarPeriodo(horarioNovo);

                  if (periodoSelecionado != null && periodoNovo != null && periodoSelecionado != periodoNovo) {
                    conflitoPeriodo = false; // Não há conflito se os períodos são diferentes
                  }
                }
              }
            }
          }

          if (conflitoPeriodo) {
            return false; // Datas colidem no mesmo período
          }
        }
      }
    }

    return true; // Não há conflito
  }

  /// Verifica conflitos de datas entre os cargos selecionados
  static List<String> verificarConflitoDatas(List<Cargo> cargos) {
    final List<String> conflitos = [];

    // Verificar conflitos apenas se houver mais de um cargo e se tiverem datas de prova definidas
    if (cargos.length <= 1) return conflitos;

    // Agrupar cargos por data de prova
    final Map<String, List<String>> cargosPorData = {};

    for (final cargo in cargos) {
      if (cargo.dataProva != null) {
        final dataStr = DateFormat('dd/MM/yyyy').format(cargo.dataProva!);
        cargosPorData.putIfAbsent(dataStr, () => []).add(cargo.nome);
      }
    }

    // Verificar conflitos (mais de um cargo na mesma data)
    cargosPorData.forEach((data, cargosList) {
      if (cargosList.length > 1) {
        conflitos.add('${cargosList.join(' e ')} têm prova na mesma data ($data)');
      }
    });

    return conflitos;
  }
}
