import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class MeuEditalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final editalService = Provider.of<EditalService>(context);
    final planoEstudoService = Provider.of<PlanoEstudoService>(context);

    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    // Obter editais do usuário
    final editais = usuario != null
        ? editalService.getEditaisByUserId(usuario.id)
        : [];

    // Obter planos de estudo do usuário
    final planos = usuario != null
        ? planoEstudoService.getPlanosByUserId(usuario.id)
        : [];

    // Verificar se o usuário tem um edital selecionado
    final editalAtivo = editais.isNotEmpty ? editais.first : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Meu Edital',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Detalhes do seu concurso',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),

          // Conteúdo principal
          Expanded(
            child: editalAtivo == null
                ? _buildEmptyState(context, isPremium)
                : _buildEditalDetalhes(context, editalAtivo, planos),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isPremium) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum edital selecionado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Adicione um edital para começar sua preparação',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('ADICIONAR EDITAL'),
            onPressed: () {
              Navigator.pushNamed(context, '/edital/add');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Versão gratuita: limite de 1 edital',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditalDetalhes(BuildContext context, dynamic edital, List planos) {
    // Verificar se há um plano de estudo para este edital
    final planoAtivo = planos.isNotEmpty
        ? planos.firstWhere((p) => p.editalId == edital.id, orElse: () => null)
        : null;

    // Obter o cargo selecionado
    final cargoSelecionado = edital.dadosExtraidos.cargos.isNotEmpty
        ? edital.dadosExtraidos.cargos.first
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card principal com informações do concurso
          ModernCard(
            gradient: LinearGradient(
              colors: [AppTheme.darkCardColor, Color(0xFF1E3A6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do concurso com badge de status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          edital.nomeConcurso,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFF9C1AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Ativo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Informações do concurso
                  _buildInfoRow(Icons.business, 'Órgão', edital.dadosExtraidos.orgao),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.school, 'Banca', edital.dadosExtraidos.banca),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Inscrições',
                    '${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}'
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Taxa',
                    'R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}'
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Local da Prova',
                    edital.dadosExtraidos.localProva
                  ),

                  // Botões de ação
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.visibility),
                          label: Text('Ver Detalhes'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/edital/detalhes',
                              arguments: edital.id,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Seção de conteúdo programático
          Text(
            'Conteúdo Programático',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Card do conteúdo programático
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verificar se há um cargo selecionado
                  if (cargoSelecionado != null) ...[
                    Text(
                      cargoSelecionado.nome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Separar matérias por tipo (básico e específico)
                    _buildConteudoProgramatico(cargoSelecionado),
                  ] else
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum cargo selecionado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Selecionar Cargo'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/cargo/select',
                                arguments: edital.id,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Seção de plano de estudo
          Text(
            'Plano de Estudo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Card do plano de estudo
          ModernCard(
            gradient: planoAtivo != null
                ? LinearGradient(
                    colors: [Color(0xFF2E7BFF).withOpacity(0.8), Color(0xFF00CFFD).withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: planoAtivo != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Plano de Estudo Ativo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Criado em ${_formatDate(planoAtivo.dataCriacao)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Duração: ${planoAtivo.duracaoSemanas} semanas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.visibility),
                        label: Text('VER PLANO COMPLETO'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/plano');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum plano de estudo criado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('CRIAR PLANO DE ESTUDO'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/plano/add',
                              arguments: edital.id,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade400,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == 'Não especificado') {
      return 'Não especificado';
    }

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildConteudoProgramatico(dynamic cargo) {
    // Separar matérias por tipo (básico e específico)
    List<dynamic> conhecimentosBasicos = [];
    List<dynamic> conhecimentosEspecificos = [];

    for (var conteudo in cargo.conteudoProgramatico) {
      if (conteudo.tipo?.toLowerCase() == 'básico' ||
          conteudo.tipo?.toLowerCase() == 'basico' ||
          conteudo.tipo?.toLowerCase() == 'conhecimentos básicos' ||
          conteudo.tipo?.toLowerCase() == 'conhecimentos basicos') {
        conhecimentosBasicos.add(conteudo);
      } else {
        conhecimentosEspecificos.add(conteudo);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conhecimentosBasicos.isNotEmpty) ...[
          Text(
            'Conhecimentos Básicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade300,
            ),
          ),
          SizedBox(height: 8),
          ...conhecimentosBasicos.map((conteudo) => _buildMateriaItem(conteudo)),
          SizedBox(height: 16),
        ],
        if (conhecimentosEspecificos.isNotEmpty) ...[
          Text(
            'Conhecimentos Específicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 8),
          ...conhecimentosEspecificos.map((conteudo) => _buildMateriaItem(conteudo)),
        ],
        if (cargo.conteudoProgramatico.isEmpty)
          Text(
            'Nenhum conteúdo programático disponível para este cargo.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400),
          ),
      ],
    );
  }

  Widget _buildMateriaItem(dynamic conteudo) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: AppTheme.darkCardColor,
      child: ExpansionTile(
        title: Text(
          conteudo.nome,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conteudo.topicos.asMap().entries.map<Widget>((entry) {
                final index = entry.key + 1; // Começar do 1
                final topico = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$index. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Expanded(child: Text(topico, style: TextStyle(color: Colors.white))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
