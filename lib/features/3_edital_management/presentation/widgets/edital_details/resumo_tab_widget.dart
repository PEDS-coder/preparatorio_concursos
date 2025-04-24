import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';

/// Widget que exibe a aba de resumo do edital
class ResumoTabWidget extends StatelessWidget {
  final Edital edital;

  const ResumoTabWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informações Gerais'),
          _buildInfoCard(
            context,
            [
              _buildInfoItem('Título', edital.nomeConcurso),
              _buildInfoItem('Órgão', edital.dadosExtraidos.orgao ?? 'Não informado'),
              _buildInfoItem('Banca', edital.dadosExtraidos.banca ?? 'Não informado'),
              _buildInfoItem(
                'Inscrições',
                '${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
              ),
              if (edital.dadosExtraidos.valorTaxa != null)
                _buildInfoItem(
                  'Taxa de Inscrição',
                  'R\$ ${edital.dadosExtraidos.valorTaxa!.toStringAsFixed(2)}',
                ),
            ],
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Informações da Prova'),
          _buildInfoCard(
            context,
            [
              _buildInfoItem(
                'Data da Prova',
                edital.dadosExtraidos.dataProva ?? 'Não informado',
              ),
              _buildInfoItem(
                'Local da Prova',
                edital.dadosExtraidos.localProva ?? 'Não informado',
              ),
              if (edital.dadosExtraidos.dadosProva?.formato != null)
                _buildInfoItem(
                  'Formato da Prova',
                  edital.dadosExtraidos.dadosProva!.formato!.join(', '),
                ),
              if (edital.dadosExtraidos.cotas != null)
                _buildInfoItem('Cotas', _formatarCotas(edital.dadosExtraidos.cotas!)),
              if (edital.dadosExtraidos.dadosProva?.temaDiscursiva != null)
                _buildInfoItem(
                  'Tema da Prova Subjetiva',
                  edital.dadosExtraidos.dadosProva!.temaDiscursiva!,
                ),
            ],
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Cargos Disponíveis'),
          _buildCargosCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargosCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var cargo in edital.dadosExtraidos.cargos)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildCargoInfoItem('Salário', 'R\$ ${_formatarSalario(cargo.salario)}'),
                    _buildCargoInfoItem('Escolaridade', cargo.escolaridade),
                    if (cargo.dataProva != null)
                      _buildCargoInfoItem(
                        'Data da Prova',
                        _formatDate(cargo.dataProva),
                      ),
                    if (cargo.horarioProva != null && cargo.horarioProva!.isNotEmpty)
                      _buildCargoInfoItem('Horário da Prova', cargo.horarioProva!),
                    if (cargo.requisitos != null && cargo.requisitos != 'Não informado')
                      _buildCargoInfoItem('Requisitos', cargo.requisitos),
                    Divider(height: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Não informado';
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  String _formatarSalario(double salario) {
    if (salario <= 0) return '0,00';

    // Formatar o salário com separador de milhares e duas casas decimais
    final valorInteiro = salario.floor();
    final valorDecimal = ((salario - valorInteiro) * 100).round();

    // Formatar a parte inteira com separadores de milhar
    String valorInteiroStr = valorInteiro.toString();
    String resultado = '';

    for (int i = 0; i < valorInteiroStr.length; i++) {
      if (i > 0 && (valorInteiroStr.length - i) % 3 == 0) {
        resultado += '.';
      }
      resultado += valorInteiroStr[i];
    }

    // Adicionar a parte decimal
    return resultado + ',' + valorDecimal.toString().padLeft(2, '0');
  }

  String _formatarCotas(List<DadosCota> cotas) {
    if (cotas.isEmpty) return 'Não informado';

    return cotas.map((cota) {
      String texto = cota.nome;
      if (cota.percentual != null && cota.percentual! > 0) {
        texto += ' (${cota.percentual}%)';
      } else if (cota.numeroVagas != null && cota.numeroVagas! > 0) {
        texto += ' (${cota.numeroVagas} vagas)';
      }
      return texto;
    }).join(', ');
  }
}
