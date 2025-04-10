class Usuario {
  final String id;
  final String nome;
  final String email;
  final String senha; // Em produção, seria apenas o hash
  final String nivelAssinatura; // 'free' ou 'premium'
  final String avatarId;
  final int pontosGamificacao;
  final int nivelGamificacao;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.nivelAssinatura = 'free',
    this.avatarId = 'default',
    this.pontosGamificacao = 0,
    this.nivelGamificacao = 1,
  });

  // Método para criar uma cópia do objeto com algumas propriedades alteradas
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? senha,
    String? nivelAssinatura,
    String? avatarId,
    int? pontosGamificacao,
    int? nivelGamificacao,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      nivelAssinatura: nivelAssinatura ?? this.nivelAssinatura,
      avatarId: avatarId ?? this.avatarId,
      pontosGamificacao: pontosGamificacao ?? this.pontosGamificacao,
      nivelGamificacao: nivelGamificacao ?? this.nivelGamificacao,
    );
  }

  // Método para converter o objeto para um Map (útil para armazenamento)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha': senha,
      'nivelAssinatura': nivelAssinatura,
      'avatarId': avatarId,
      'pontosGamificacao': pontosGamificacao,
      'nivelGamificacao': nivelGamificacao,
    };
  }

  // Método para criar um objeto a partir de um Map
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      senha: map['senha'],
      nivelAssinatura: map['nivelAssinatura'],
      avatarId: map['avatarId'],
      pontosGamificacao: map['pontosGamificacao'],
      nivelGamificacao: map['nivelGamificacao'],
    );
  }
}
