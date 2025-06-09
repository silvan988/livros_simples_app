// lib/models/livro.dart
class Livro {
  final int? id; // ID único do livro no banco de dados (gerado automaticamente)
  final String titulo; // Título do livro (obrigatório)
  final String autor; // Autor do livro (obrigatório)
  final int anoPublicacao; // Ano de publicação do livro (obrigatório)
  final bool lido; // Status do livro (true se lido, false caso contrário)
  final DateTime dataCriacao; // Data e hora de criação do registro do livro

  // Construtor do Livro
  Livro({
    this.id,
    required this.titulo,
    required this.autor,
    required this.anoPublicacao,
    this.lido = false, // Valor padrão para 'lido'
    required this.dataCriacao,
  });

  // Converte um mapa (Map<String, dynamic>) recebido do banco de dados para um objeto Livro
  factory Livro.fromMap(Map<String, dynamic> map) {
    return Livro(
      id: map['id'],
      titulo: map['titulo'],
      autor: map['autor'],
      anoPublicacao: map['anoPublicacao'],
      lido: map['lido'] == 1, // SQLite armazena booleanos como 0 (false) ou 1 (true)
      dataCriacao: DateTime.parse(map['dataCriacao']), // Converte a string de data para DateTime
    );
  }

  // Converte um objeto Livro para um mapa (Map<String, dynamic>) para ser armazenado no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'autor': autor,
      'anoPublicacao': anoPublicacao,
      'lido': lido ? 1 : 0, // Converte booleano para 0 ou 1 para SQLite
      'dataCriacao': dataCriacao.toIso8601String(), // Converte DateTime para string ISO 8601
    };
  }

  // Método para criar uma cópia modificada do Livro (útil para atualizações, mantendo a imutabilidade)
  Livro copyWith({
    int? id,
    String? titulo,
    String? autor,
    int? anoPublicacao,
    bool? lido,
    DateTime? dataCriacao,
  }) {
    return Livro(
      id: id ?? this.id, // Se 'id' for nulo, mantém o ID original
      titulo: titulo ?? this.titulo,
      autor: autor ?? this.autor,
      anoPublicacao: anoPublicacao ?? this.anoPublicacao,
      lido: lido ?? this.lido,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
