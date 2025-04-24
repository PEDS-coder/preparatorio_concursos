import 'package:flutter/material.dart';

/// Widget para exibir informações em cards coloridos
class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color cardColor;
  final String emoji;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.label,
    required this.value,
    required this.cardColor,
    required this.emoji,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Text(
            emoji,
            style: TextStyle(fontSize: 24),
          ),
          title: Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
