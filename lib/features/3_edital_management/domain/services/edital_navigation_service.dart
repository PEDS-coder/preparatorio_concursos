import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/edital.dart';
import '../../../4_study_plan/presentation/screens/plano_questionario_screen.dart';

/// Serviço responsável por gerenciar a navegação entre telas relacionadas ao edital
class EditalNavigationService {
  /// Navega para a tela de questionário com o primeiro cargo do edital
  static void navegarParaQuestionario(BuildContext context, String editalId) {
    final editalService = Provider.of<EditalService>(context, listen: false);
    final edital = editalService.getEditalById(editalId);

    if (edital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edital não encontrado')),
      );
      return;
    }

    // Usar o primeiro cargo disponível
    final cargo = edital.dadosExtraidos.cargos.first;
    final cargoNome = cargo.nome;

    print('Iniciando criação de plano para o cargo: $cargoNome');

    // Preparar dados do edital
    Map<String, dynamic> dadosEdital = {
      'id': edital.id,
      'titulo': edital.nomeConcurso,
      'orgao': edital.dadosExtraidos.orgao ?? 'Não informado',
      'banca': edital.dadosExtraidos.banca ?? 'Não informado',
      'data_prova': edital.dadosExtraidos.dataProva ?? 'Não informado',
    };

    // Preparar dados do cargo
    Map<String, dynamic> dadosCargo = {
      'cargo': cargoNome,
    };

    // Extrair matérias do conteúdo programático
    if (cargo.conteudoProgramatico.isNotEmpty) {
      final materias = cargo.conteudoProgramatico.map((m) => m.nome).toList();
      dadosCargo['materias'] = materias;
    } else {
      dadosCargo['materias'] = ['Língua Portuguesa', 'Raciocínio Lógico', 'Conhecimentos Gerais'];
    }

    // Adicionar informações adicionais do cargo
    dadosCargo['escolaridade'] = cargo.escolaridade;
    dadosCargo['salario'] = cargo.salario;
    dadosCargo['nivel'] = cargo.nivel;

    print('Navegando para PlanoQuestionarioScreen');
    print('Dados do Edital: $dadosEdital');
    print('Dados do Cargo: $dadosCargo');

    // Navegar para a tela de questionário
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanoQuestionarioScreen(
          dadosEdital: dadosEdital,
          dadosCargo: dadosCargo,
        ),
      ),
    );
  }

  /// Exibe um diálogo de confirmação para excluir o edital
  static void showDeleteConfirmationDialog(BuildContext context, Edital edital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Edital'),
        content: Text(
          'Tem certeza que deseja excluir o edital "${edital.nomeConcurso}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final editalService = Provider.of<EditalService>(context, listen: false);
              editalService.removeEdital(edital.id);
              Navigator.pop(context); // Fechar o diálogo
              Navigator.pop(context); // Voltar para a tela anterior
            },
            child: Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
