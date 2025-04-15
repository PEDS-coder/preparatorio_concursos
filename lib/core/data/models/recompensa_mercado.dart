class RecompensaMercado {
  final String id;
  final String userId;
  final String titulo;
  final String descricao;
  final String categoria; // 'pequena', 'media', 'grande'
  final int custoMoedas;
  final DateTime dataCriacao;
  final bool resgatada;
  final DateTime? dataResgate;

  RecompensaMercado({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.custoMoedas,
    required this.dataCriacao,
    this.resgatada = false,
    this.dataResgate,
  });

  // Método para criar uma cópia do objeto com algumas propriedades alteradas
  RecompensaMercado copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? descricao,
    String? categoria,
    int? custoMoedas,
    DateTime? dataCriacao,
    bool? resgatada,
    DateTime? dataResgate,
  }) {
    return RecompensaMercado(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      custoMoedas: custoMoedas ?? this.custoMoedas,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      resgatada: resgatada ?? this.resgatada,
      dataResgate: dataResgate ?? this.dataResgate,
    );
  }

  // Método para converter o objeto para um Map (útil para armazenamento)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'custoMoedas': custoMoedas,
      'dataCriacao': dataCriacao.toIso8601String(),
      'resgatada': resgatada,
      'dataResgate': dataResgate?.toIso8601String(),
    };
  }

  // Método para criar um objeto a partir de um Map
  factory RecompensaMercado.fromMap(Map<String, dynamic> map) {
    return RecompensaMercado(
      id: map['id'],
      userId: map['userId'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      categoria: map['categoria'],
      custoMoedas: map['custoMoedas'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
      resgatada: map['resgatada'] ?? false,
      dataResgate: map['dataResgate'] != null ? DateTime.parse(map['dataResgate']) : null,
    );
  }

  // Método para sugerir um custo baseado na categoria
  static int sugerirCusto(String categoria) {
    switch (categoria) {
      case 'pequena':
        return 250; // Média entre 150 e 400
      case 'media':
        return 1000; // Média entre 500 e 1500
      case 'grande':
        return 3000; // Média entre 2000 e 5000
      default:
        return 500;
    }
  }
}

class HistoricoMoedas {
  final String id;
  final String userId;
  final int quantidade;
  final String tipo; // 'ganho' ou 'gasto'
  final String origem; // 'sessao_estudo', 'streak', 'meta_semanal', 'resgate', etc.
  final String? descricao;
  final DateTime data;

  HistoricoMoedas({
    required this.id,
    required this.userId,
    required this.quantidade,
    required this.tipo,
    required this.origem,
    this.descricao,
    required this.data,
  });

  // Método para converter o objeto para um Map (útil para armazenamento)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'quantidade': quantidade,
      'tipo': tipo,
      'origem': origem,
      'descricao': descricao,
      'data': data.toIso8601String(),
    };
  }

  // Método para criar um objeto a partir de um Map
  factory HistoricoMoedas.fromMap(Map<String, dynamic> map) {
    return HistoricoMoedas(
      id: map['id'],
      userId: map['userId'],
      quantidade: map['quantidade'],
      tipo: map['tipo'],
      origem: map['origem'],
      descricao: map['descricao'],
      data: DateTime.parse(map['data']),
    );
  }
}
