// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart'; // Importa a biblioteca sqflite
import 'package:path/path.dart'; // Importa a biblioteca path para manipular caminhos de arquivos
import 'package:livros_simples_app/models/livro.dart'; // Importa o modelo Livro

class DatabaseHelper {
  // Padrão Singleton para garantir que há apenas uma instância do DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database; // Instância do banco de dados

  // Getter para a instância do banco de dados. Inicializa se ainda não estiver inicializada.
  Future<Database> get database async {
    if (_database != null) return _database!; // Retorna a instância existente se já houver uma
    _database = await _initDatabase(); // Caso contrário, inicializa o banco de dados
    return _database!;
  }

  // Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath(); // Obtém o caminho padrão para bancos de dados
    String path = join(databasesPath, 'simple_livros.db'); // Define o nome do arquivo do banco de dados
    print('DB: Initializing database at $path'); // Log de depuração
    return await openDatabase(
        path, // Caminho completo para o arquivo do banco de dados
        version: 1, // Versão do esquema do banco de dados
        onCreate: _onCreate, // Função chamada quando o banco de dados é criado pela primeira vez
        onOpen: (db) { // Callback chamado quando o banco de dados é aberto com sucesso
          print('DB: Database opened successfully!'); // Log de depuração
        }
    );
  }

  // Cria as tabelas do banco de dados
  Future<void> _onCreate(Database db, int version) async {
    print('DB: Creating table "livros"...'); // Log de depuração
    // Cria a tabela 'livros'
    await db.execute('''
      CREATE TABLE livros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        autor TEXT NOT NULL,
        anoPublicacao INTEGER NOT NULL,
        lido INTEGER DEFAULT 0,
        dataCriacao TEXT NOT NULL
      )
    ''');
    print('DB: Table "livros" created!'); // Log de depuração
  }

  // --- Operações CRUD (Create, Read, Update, Delete) para o modelo Livro ---

  // Insere um novo livro no banco de dados
  Future<int> insertLivro(Livro livro) async {
    Database db = await database;
    print('DB: Inserting book: ${livro.titulo}'); // Log de depuração
    return await db.insert('livros', livro.toMap()); // Insere o mapa do livro na tabela 'livros'
  }

  // Obtém uma lista de livros do banco de dados, com opções de filtro e ordenação
  Future<List<Livro>> getLivros({
    String? query, // Termo de busca para título ou autor
    bool? lido, // Filtro por status lido (true/false)
    String? orderBy, // Campo para ordenação (ex: 'titulo', '-dataCriacao')
  }) async {
    Database db = await database; // Garante que o banco de dados está inicializado
    print('DB: Fetching books with query: $query, lido: $lido, orderBy: $orderBy'); // Log de depuração

    List<String> whereClauses = []; // Cláusulas WHERE para filtros
    List<dynamic> whereArgs = []; // Argumentos para as cláusulas WHERE

    // Adiciona filtro por status 'lido' se fornecido
    if (lido != null) {
      whereClauses.add('lido = ?');
      whereArgs.add(lido ? 1 : 0); // Converte bool para 1 ou 0
    }

    // Constrói a string WHERE para o método query
    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    String? orderByColumn;
    bool descending = false;

    // Define a ordenação padrão se nenhuma for fornecida
    if (orderBy != null && orderBy.isNotEmpty) {
      if (orderBy.startsWith('-')) { // Se o campo começar com '-', é ordem decrescente
        orderByColumn = orderBy.substring(1); // Remove o '-'
        descending = true;
      } else {
        orderByColumn = orderBy; // Campo para ordenação
        descending = false;
      }
    } else {
      // Ordenação padrão para a listagem inicial
      orderByColumn = 'dataCriacao';
      descending = true;
    }

    // Executa a consulta usando o método db.query para maior segurança
    List<Map<String, dynamic>> maps = await db.query(
      'livros',
      where: whereString, // Passa a string WHERE ou null
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null, // Passa os argumentos WHERE ou null
      orderBy: orderByColumn != null ? '$orderByColumn ${descending ? 'DESC' : 'ASC'}' : null, // Constrói a string de ordenação
    );

    // Converte os mapas resultantes em objetos Livro
    List<Livro> livros = maps.map((map) => Livro.fromMap(map)).toList();

    // Implementação de busca em memória para campos de texto (SQLite LIKE seria mais eficiente, mas para simplificar)
    if (query != null && query.isNotEmpty) {
      final qLower = query.toLowerCase();
      livros = livros.where((livro) {
        return livro.titulo.toLowerCase().contains(qLower) || // Procura no título
            livro.autor.toLowerCase().contains(qLower); // Procura no autor
      }).toList();
    }
    print('DB: Fetched ${livros.length} books.'); // Log de depuração
    return livros;
  }

  // Obtém um livro específico pelo seu ID
  Future<Livro?> getLivro(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'livros',
      where: 'id = ?', // Cláusula WHERE para buscar pelo ID
      whereArgs: [id], // Argumento para a cláusula WHERE
    );
    if (maps.isNotEmpty) {
      return Livro.fromMap(maps.first); // Retorna o primeiro livro encontrado
    }
    return null; // Retorna nulo se nenhum livro for encontrado
  }

  // Atualiza um livro existente no banco de dados
  Future<int> updateLivro(Livro livro) async {
    Database db = await database;
    print('DB: Updating book: ${livro.titulo} (ID: ${livro.id})'); // Log de depuração
    return await db.update(
      'livros',
      livro.toMap(), // Mapa com os novos valores do livro
      where: 'id = ?', // Cláusula WHERE para encontrar o livro a ser atualizado
      whereArgs: [livro.id], // ID do livro a ser atualizado
    );
  }

  // Deleta um livro do banco de dados pelo seu ID
  Future<int> deleteLivro(int id) async {
    Database db = await database;
    print('DB: Deleting book with ID: $id'); // Log de depuração
    return await db.delete(
      'livros',
      where: 'id = ?', // Cláusula WHERE para encontrar o livro a ser deletado
      whereArgs: [id], // ID do livro a ser deletado
    );
  }
}
