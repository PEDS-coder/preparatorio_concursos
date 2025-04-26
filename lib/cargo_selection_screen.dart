import 'package:flutter/material.dart';
import 'core/data/models/edital.dart';

class CargoSelectionScreen extends StatelessWidget {
  final List<Cargo> cargos;
  final void Function(Cargo) onSelect;
  const CargoSelectionScreen({super.key, required this.cargos, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13192b),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf43f7d),
        elevation: 0,
        title: const Text('Selecionar Cargo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cargos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final cargo = cargos[idx];
          return GestureDetector(
            onTap: () => onSelect(cargo),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo.nome,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.monetization_on, 'Salário: R\$ ${cargo.salario.toStringAsFixed(2)}'),
                    _infoRow(Icons.school, 'Escolaridade: ${cargo.escolaridade}'),
                    if ((cargo.requisitos).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          cargo.requisitos,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
