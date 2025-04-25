import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget para exibir um banner de manutenção ou atualização
class MaintenanceBanner extends StatelessWidget {
  final Widget child;

  const MaintenanceBanner({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remoteConfigService = Provider.of<IRemoteConfigService>(context, listen: false);

    // Verificar se o aplicativo está em modo de manutenção
    if (remoteConfigService.isInMaintenanceMode) {
      return _buildMaintenanceScreen(context, remoteConfigService.maintenanceMessage);
    }

    // Verificar se o aplicativo precisa ser atualizado
    if (remoteConfigService.needsUpdate) {
      if (remoteConfigService.isForceUpdate) {
        return _buildUpdateScreen(context, remoteConfigService.updateMessage);
      } else {
        return _buildUpdateBanner(context, remoteConfigService.updateMessage, child);
      }
    }

    return child;
  }

  /// Constrói a tela de manutenção
  Widget _buildMaintenanceScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Manutenção em Andamento',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Tentar novamente
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MaintenanceBanner(child: child),
                    ),
                  );
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a tela de atualização
  Widget _buildUpdateScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Atualização Necessária',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Abrir a loja de aplicativos
                  _openAppStore();
                },
                child: const Text('Atualizar Agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o banner de atualização
  Widget _buildUpdateBanner(BuildContext context, String message, Widget child) {
    return Scaffold(
      body: child,
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Abrir a loja de aplicativos
                _openAppStore();
              },
              child: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre a loja de aplicativos
  Future<void> _openAppStore() async {
    // URL da loja de aplicativos
    const url = 'https://play.google.com/store/apps/details?id=com.example.preparatorio_concursos';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
