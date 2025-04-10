import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/gamificacao_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';

class GamificacaoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final gamificacaoService = Provider.of<GamificacaoService>(context);
    final sessaoService = Provider.of<SessaoEstudoService>(context);
    
    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;
    
    // Obter troféus do usuário
    final trofeus = usuario != null 
        ? gamificacaoService.getTrofeusByUserId(usuario.id)
        : [];
    
    // Calcular estatísticas
    final horasEstudadas = usuario != null 
        ? sessaoService.calcularTempoTotalEstudo(usuario.id) / 60
        : 0.0;
    
    final nivel = usuario?.nivelGamificacao ?? 1;
    final pontos = usuario?.pontosGamificacao ?? 0;
    final pontosProximoNivel = nivel * 500;
    final progresso = pontos / pontosProximoNivel;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gamificação',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Limitado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Acompanhe seu progresso e conquistas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          
          // Avatar e nível
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  
                  // Informações de nível
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nível $nivel',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getNivelColor(nivel),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getNivelTitulo(nivel),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$pontos / $pontosProximoNivel pontos para o próximo nível',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progresso,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Estatísticas
          Text(
            'Suas Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Horas Estudadas',
                  horasEstudadas.toStringAsFixed(1),
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Troféus',
                  trofeus.length.toString(),
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pontos',
                  pontos.toString(),
                  Icons.star,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Troféus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seus Troféus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trofeus.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/trofeus');
                  },
                  child: Text('Ver Todos'),
                ),
            ],
          ),
          SizedBox(height: 16),
          
          // Lista de troféus
          Expanded(
            child: trofeus.isEmpty
                ? _buildEmptyTrofeus(isPremium)
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: trofeus.length,
                    itemBuilder: (context, index) {
                      final trofeu = trofeus[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 32,
                                color: Colors.amber,
                              ),
                              SizedBox(height: 8),
                              Text(
                                trofeu.nomeTrofeu,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                trofeu.descricaoTrofeu,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyTrofeus(bool isPremium) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum troféu conquistado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete atividades para ganhar troféus',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Versão Premium: Desbloqueie mais troféus e recompensas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  String _getNivelTitulo(int nivel) {
    if (nivel <= 2) return 'Iniciante';
    if (nivel <= 5) return 'Intermediário';
    if (nivel <= 10) return 'Avançado';
    if (nivel <= 15) return 'Especialista';
    return 'Mestre';
  }
  
  Color _getNivelColor(int nivel) {
    if (nivel <= 2) return Colors.green;
    if (nivel <= 5) return Colors.blue;
    if (nivel <= 10) return Colors.purple;
    if (nivel <= 15) return Colors.orange;
    return Colors.red;
  }
}
