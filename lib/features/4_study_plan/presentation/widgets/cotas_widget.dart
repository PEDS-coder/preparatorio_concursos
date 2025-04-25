import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/models/models.dart';
import '../../domain/services/cotas_service.dart';

/// Widget para exibir informações sobre cotas e reserva de vagas
class CotasWidget extends StatelessWidget {
  final Edital? edital;

  const CotasWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (edital == null) return const SizedBox.shrink();

    final cotasInfo = CotasService.obterInformacoes(edital!);
    if (cotasInfo == 'Não informado') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Cotas e Reserva de Vagas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            cotasInfo,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
