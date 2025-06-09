// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa o pacote provider

import 'package:livros_simples_app/screens/livro_list_screen.dart'; // Importa a tela da lista de livros
import 'package:livros_simples_app/screens/livro_detail_screen.dart'; // Importa a tela de detalhes do livro
import 'package:livros_simples_app/screens/livro_form_screen.dart'; // Importa a tela de formulário do livro
import 'package:livros_simples_app/providers/livro_provider.dart'; // Importa o LivroProvider

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que o Flutter Binding esteja inicializado
  runApp(const MyApp()); // Inicia o aplicativo Flutter
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // <-- Onde LivroProvider é disponibilizado
      providers: [
        ChangeNotifierProvider(create: (_) => LivroProvider()), // <-- Adicione/confirme esta linha
      ],
      child: MaterialApp( // <-- MaterialApp deve ser filho do MultiProvider
        title: 'Minha Lista de Livros Simples', // Título do aplicativo
        theme: ThemeData(
          primarySwatch: Colors.blue, // Tema principal do aplicativo
          visualDensity: VisualDensity.adaptivePlatformDensity, // Densidade visual adaptável
        ),
        debugShowCheckedModeBanner: false, // Remove a faixa de "Debug" no canto superior direito
        home: const LivroListScreen(), // Define a tela inicial do aplicativo
        routes: {
          // Define rotas nomeadas para navegação
          '/add-livro': (ctx) => const LivroFormScreen(), // Rota para adicionar um novo livro
          '/edit-livro': (ctx) => LivroFormScreen(
            // Rota para editar um livro existente, passando o ID como argumento
            livroId: ModalRoute.of(ctx)!.settings.arguments as int,
          ),
        },
        // onGenerateRoute é usado para rotas que precisam de argumentos dinâmicos (como o ID do livro)
        onGenerateRoute: (settings) {
          if (settings.name == '/livro-detail') {
            // Se a rota for '/livro-detail', extrai o ID do livro dos argumentos
            final args = settings.arguments as int;
            return MaterialPageRoute(
              builder: (ctx) {
                // Retorna a tela de detalhes do livro com o ID fornecido
                return LivroDetailScreen(livroId: args);
              },
            );
          }
          return null; // Retorna nulo para rotas não mapeadas
        },
      ),
    );
  }
}
    