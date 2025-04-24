import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/matrix_rain_animation.dart';

/// Widget que representa o overlay de análise com animação Matrix
class AnalysisOverlayWidget extends StatelessWidget {
  const AnalysisOverlayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: Center(
          child: Card(
            elevation: 8,
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: MatrixRainAnimation(
                width: 350,
                height: 300,
                primaryColor: AppTheme.primaryColor,
                secondaryColor: AppTheme.accentColor,
                message: 'Analisando Edital',
                statusMessages: [
                  'Processando PDF do edital...',
                  'Identificando cargos disponíveis...',
                  'Identificando requisitos dos cargos...',
                  'Identificando nível de escolaridade...',
                  'Identificando número de vagas...',
                  'Organizando informações dos cargos...',
                  'Estruturando dados para seleção...',
                  'Finalizando processamento...',
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
