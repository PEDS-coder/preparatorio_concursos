  // Método para navegar diretamente para a tela de questionário
  void _navegarParaQuestionario() async {
    final editalService = Provider.of<EditalService>(context, listen: false);
    final edital = editalService.getEditalById(widget.editalId);
    
    if (edital == null || edital.dadosExtraidos.cargos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum cargo disponível para criar plano')),
      );
      return;
    }
    
    // Usar o primeiro cargo disponível
    final cargo = edital.dadosExtraidos.cargos.first;
    final cargoNome = cargo.nome;
    
    print('Iniciando criação de plano para o cargo: $cargoNome');
    
    // Preparar dados do edital
    Map<String, dynamic> dadosEdital = {
      'id': edital.id,
      'titulo': edital.nomeConcurso,
      'orgao': edital.dadosExtraidos.orgao ?? 'Não informado',
      'banca': edital.dadosExtraidos.banca ?? 'Não informado',
      'data_prova': edital.dadosExtraidos.dataProva ?? 'Não informado',
    };
    
    // Preparar dados do cargo
    Map<String, dynamic> dadosCargo = {
      'cargo': cargoNome,
    };
    
    // Extrair matérias do conteúdo programático
    if (cargo.conteudoProgramatico.isNotEmpty) {
      print('Extraindo matérias do conteúdo programático do cargo: ${cargo.nome}');
      print('Número de matérias encontradas: ${cargo.conteudoProgramatico.length}');
      
      // Listar todas as matérias encontradas
      final materias = cargo.conteudoProgramatico.map((m) => m.nome).toList();
      print('Matérias encontradas: $materias');
      
      dadosCargo['materias'] = materias;
    } else {
      print('AVISO: Nenhuma matéria encontrada no conteúdo programático. Usando matérias padrão.');
      dadosCargo['materias'] = ['Língua Portuguesa', 'Raciocínio Lógico', 'Conhecimentos Gerais'];
    }
    
    // Adicionar informações adicionais do cargo
    dadosCargo['escolaridade'] = cargo.escolaridade;
    dadosCargo['salario'] = cargo.salario;
    dadosCargo['nivel'] = cargo.nivel;
    
    print('Navegando para PlanoQuestionarioScreen');
    print('Dados do Edital: $dadosEdital');
    print('Dados do Cargo: $dadosCargo');
    
    // Navegar para a tela de questionário
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanoQuestionarioScreen(
          dadosEdital: dadosEdital,
          dadosCargo: dadosCargo,
        ),
      ),
    );
  }
