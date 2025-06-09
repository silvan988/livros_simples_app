// lib/screens/livro_list_screen.dart
import 'package:flutter/material.dart';
import 'package:livros_simples_app/models/livro.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Importa o pacote provider
import 'package:livros_simples_app/providers/livro_provider.dart'; // Importa o LivroProvider

class LivroListScreen extends StatefulWidget {
  const LivroListScreen({super.key});

  @override
  State<LivroListScreen> createState() => _LivroListScreenState();
}

class _LivroListScreenState extends State<LivroListScreen> {
  String? _searchText;
  bool? _selectedLido;
  String? _selectedOrderBy = 'dataCriacao';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLivros(); // Carrega os livros quando a tela é inicializada
    });
  }

  // Função para carregar os livros usando o LivroProvider
  Future<void> _loadLivros() async {
    print('LivroListScreen: _loadLivros called.'); // Log de depuração
    await Provider.of<LivroProvider>(context, listen: false).fetchLivros(
      query: _searchText,
      lido: _selectedLido,
      orderBy: _selectedOrderBy,
    );
    // Não precisa de setState aqui, pois o Provider fará o notifyListeners()
    // e o Consumer/Selector no build() reagirá a isso.
  }

  // Função para alternar o status de 'lido' de um livro
  Future<void> _toggleLivroLido(Livro livro) async {
    print('LivroListScreen: _toggleLivroLido called for ${livro.titulo}.'); // Log de depuração
    final updatedLivro = livro.copyWith(lido: !livro.lido);
    // Usa o LivroProvider para atualizar o livro
    await Provider.of<LivroProvider>(context, listen: false).updateLivro(
      livro.id!, // Passa o ID do livro
      updatedLivro,
    );
    // Após a atualização via provider, a lista será recarregada automaticamente
    // se o fetchLivros for chamado após a atualização ou se a lista do provider for observável.
    // Para garantir a atualização, vamos recarregar explicitamente aqui:
    _loadLivros();
  }

  @override
  Widget build(BuildContext context) {
    // Acessa o LivroProvider. O 'listen: true' é o padrão, mas explicito aqui
    // para indicar que este widget deve reconstruir quando o provider mudar.
    final livroProvider = Provider.of<LivroProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Lista de Livros Simples'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Título ou Autor',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchText = _searchController.text;
                    });
                    _loadLivros();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchText = value;
                });
                _loadLivros();
              },
            ),
          ),
          // Filtros e ordenação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    decoration: const InputDecoration(
                      labelText: 'Lido',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedLido,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _selectedLido = newValue;
                      });
                      _loadLivros();
                    },
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: true, child: Text('Lido')),
                      DropdownMenuItem(value: false, child: Text('Não Lido')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ordenar por',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedOrderBy,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOrderBy = newValue;
                      });
                      _loadLivros();
                    },
                    items: const [
                      DropdownMenuItem(value: 'dataCriacao', child: Text('Mais Recente')),
                      DropdownMenuItem(value: '-dataCriacao', child: Text('Mais Antigo')),
                      DropdownMenuItem(value: 'titulo', child: Text('Título (A-Z)')),
                      DropdownMenuItem(value: '-titulo', child: Text('Título (Z-A)')),
                      DropdownMenuItem(value: 'autor', child: Text('Autor (A-Z)')),
                      DropdownMenuItem(value: '-autor', child: Text('Autor (Z-A)')),
                      DropdownMenuItem(value: 'anoPublicacao', child: Text('Ano (Antigo-Novo)')),
                      DropdownMenuItem(value: '-anoPublicacao', child: Text('Ano (Novo-Antigo)')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Exibição da lista de livros ou mensagens de estado
          livroProvider.isLoading // Usa o isLoading do provedor
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : livroProvider.livros.isEmpty // Usa a lista de livros do provedor
              ? const Expanded(child: Center(child: Text('Nenhum livro cadastrado ainda.')))
              : Expanded(
            child: ListView.builder(
              itemCount: livroProvider.livros.length, // Usa a lista do provedor
              itemBuilder: (context, index) {
                final livro = livroProvider.livros[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: Checkbox(
                      value: livro.lido,
                      onChanged: (bool? newValue) {
                        _toggleLivroLido(livro);
                      },
                    ),
                    title: Text(
                      livro.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        decoration: livro.lido ? TextDecoration.none : TextDecoration.none,
                        color: livro.lido ? Colors.black : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Autor: ${livro.autor}'),
                        Text('Ano: ${livro.anoPublicacao}'),
                        Text('Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(livro.dataCriacao)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/edit-livro',
                          arguments: livro.id,
                        ).then((_) {
                          print('LivroListScreen: Navigated back from edit. Loading books...'); // Log de depuração
                          _loadLivros(); // Recarrega ao voltar
                        });
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/livro-detail',
                        arguments: livro.id,
                      ).then((_) {
                        print('LivroListScreen: Navigated back from detail. Loading books...'); // Log de depuração
                        _loadLivros(); // Recarrega ao voltar
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-livro').then((_) {
            print('LivroListScreen: Navigated back from add. Loading books...'); // Log de depuração
            _loadLivros(); // Recarrega ao voltar
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
