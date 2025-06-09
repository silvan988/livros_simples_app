// lib/screens/livro_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa o pacote provider
import 'package:livros_simples_app/database/database_helper.dart'; // Importa o helper do banco de dados
import 'package:livros_simples_app/models/livro.dart'; // Importa o modelo Livro
import 'package:intl/intl.dart'; // Importa para formatação de data
import 'package:livros_simples_app/providers/livro_provider.dart'; // Importa o LivroProvider

class LivroDetailScreen extends StatelessWidget {
  final int livroId; // ID do livro a ser exibido
  const LivroDetailScreen({super.key, required this.livroId});

  // Função para deletar um livro
  Future<void> _deleteLivro(BuildContext context, int id) async {
    print('LivroDetailScreen: Attempting to delete book with ID: $id'); // Log de depuração
    // Exibe um diálogo de confirmação antes de deletar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este livro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // Botão Cancelar
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true), // Botão Excluir
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    // Se a exclusão for confirmada
    if (confirmed == true) {
      try {
        // Usa o LivroProvider para deletar o livro
        await Provider.of<LivroProvider>(context, listen: false).deleteLivro(id);
        print('LivroDetailScreen: Book deleted successfully via provider (ID: $id).'); // Log de depuração
        if (context.mounted) { // Verifica se o widget ainda está montado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livro excluído com sucesso!')),
          );
          Navigator.of(context).pop(); // Volta para a tela anterior (lista)
          print('LivroDetailScreen: Popping back to list screen.'); // Log de depuração
        }
      } catch (e) {
        print('LivroDetailScreen: Error during deletion: $e'); // Log de depuração
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao excluir livro: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('LivroDetailScreen: Building for book ID: $livroId'); // Log de depuração
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Livro'), // Título da barra superior
      ),
      body: FutureBuilder<Livro?>(
        future: DatabaseHelper().getLivro(livroId), // Carrega o livro pelo ID
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Mostra indicador enquanto carrega
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}')); // Mostra erro se houver
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Livro não encontrado.')); // Mensagem se livro não for encontrado
          }

          final livro = snapshot.data!; // O livro carregado
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinha o conteúdo à esquerda
              children: [
                Text(
                  livro.titulo,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Autor: ${livro.autor}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ano de Publicação: ${livro.anoPublicacao}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      livro.lido ? 'Lido' : 'Não Lido', // Exibe o status
                      style: TextStyle(
                        color: livro.lido ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(livro.dataCriacao)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centraliza os botões
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/edit-livro', // Navega para a tela de edição
                          arguments: livro.id, // Passa o ID do livro para edição
                        );
                        // A tela de lista será recarregada via .then() do pushNamed ao retornar da edição
                      },
                      child: const Text('Editar Livro'),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre os botões
                    ElevatedButton(
                      onPressed: () => _deleteLivro(context, livro.id!), // Chama a função de deletar
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Botão vermelho para deletar
                      child: const Text('Excluir Livro'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Volta para a tela anterior
                    },
                    child: const Text('Voltar para a lista'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
