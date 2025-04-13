import 'package:flutter/material.dart';

class PlanoResumoScreen extends StatefulWidget {
  const PlanoResumoScreen({Key? key}) : super(key: key);

  @override
  _PlanoResumoScreenState createState() => _PlanoResumoScreenState();
}

class _PlanoResumoScreenState extends State<PlanoResumoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo do Plano'),
      ),
      body: Center(
        child: Text('Conteúdo temporário'),
      ),
    );
  }
}
