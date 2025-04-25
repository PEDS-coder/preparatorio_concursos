import 'package:flutter/material.dart';

/// Widget que representa um item de detalhe de cargo
class CargoDetailItemWidget extends StatelessWidget {
  final String label;
  final String value;

  const CargoDetailItemWidget({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
