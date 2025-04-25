import 'package:flutter/material.dart';
import '../../../../../core/widgets/modern_card.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para seleção de modo de entrada (texto ou upload)
class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;

  const ModeSelector({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildModeButton(
                'upload',
                'Upload de Documento',
                Icons.upload_file,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModeButton(
                'texto',
                'Inserir Texto',
                Icons.text_fields,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    final bool isSelected = currentMode == mode;

    return InkWell(
      onTap: () => onModeChanged(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
