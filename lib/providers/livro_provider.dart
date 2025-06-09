// lib/providers/livro_provider.dart
import 'package:flutter/material.dart';
import 'package:livros_simples_app/database/database_helper.dart'; // Importa o helper do banco de dados SQLite
import 'package:livros_simples_app/models/livro.dart'; // Importa o modelo Livro

class LivroProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instância do helper do banco de dados

  List<Livro> _livros = []; // Lista interna de livros
  bool _isLoading = false; // Estado de carregamento
  String? _errorMessage; // Mensagem de erro, se houver

  // Getters para acessar o estado a partir de outros widgets
  List<Livro> get livros => _livros;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Carrega a lista de livros do banco de dados
  // userId foi removido pois este é um app local sem autenticação de usuário no BD
  Future<void> fetchLivros({String? query, bool? lido, String? orderBy}) async {
    _isLoading = true; // Inicia o estado de carregamento
    _errorMessage = null; // Limpa qualquer mensagem de erro anterior
    notifyListeners(); // Notifica os ouvintes que o estado mudou (para mostrar o CircularProgressIndicator)

    try {
      // Obtém os livros do banco de dados usando o DatabaseHelper
      _livros = await _dbHelper.getLivros(
        query: query,
        lido: lido,
        orderBy: orderBy,
      );
    } catch (e) {
      _errorMessage = 'Erro ao carregar livros: $e'; // Define a mensagem de erro
      print(_errorMessage); // Imprime o erro no console para depuração
    } finally {
      _isLoading = false; // Finaliza o estado de carregamento
      notifyListeners(); // Notifica os ouvintes novamente (para atualizar a UI com a lista ou erro)
    }
  }

  // Busca um único livro pelo ID
  Future<Livro?> fetchLivro(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Obtém um livro específico do banco de dados
      return await _dbHelper.getLivro(id);
    } catch (e) {
      _errorMessage = 'Erro ao carregar livro: $e';
      print(_errorMessage);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adiciona um novo livro ao banco de dados e à lista em memória
  Future<bool> addLivro(Livro livro) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Insere o livro no banco de dados e obtém o ID gerado
      final id = await _dbHelper.insertLivro(livro);
      // Adiciona o livro à lista em memória com o ID gerado
      _livros.add(livro.copyWith(id: id));
      return true; // Sucesso
    } catch (e) {
      _errorMessage = 'Erro ao adicionar livro: $e';
      print(_errorMessage);
      return false; // Falha
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualiza um livro existente no banco de dados e na lista em memória
  // O ID agora é um int, compatível com o modelo Livro e o SQLite
  Future<bool> updateLivro(int id, Livro livro) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Atualiza o livro no banco de dados
      await _dbHelper.updateLivro(livro.copyWith(id: id));
      // Encontra o índice do livro na lista em memória e o atualiza
      final index = _livros.indexWhere((l) => l.id == id);
      if (index != -1) {
        _livros[index] = livro.copyWith(id: id);
      }
      return true; // Sucesso
    } catch (e) {
      _errorMessage = 'Erro ao atualizar livro: $e';
      print(_errorMessage);
      return false; // Falha
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deleta um livro do banco de dados e da lista em memória
  // O ID agora é um int, compatível com o modelo Livro e o SQLite
  Future<bool> deleteLivro(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Deleta o livro do banco de dados
      await _dbHelper.deleteLivro(id);
      // Remove o livro da lista em memória
      _livros.removeWhere((livro) => livro.id == id);
      return true; // Sucesso
    } catch (e) {
      _errorMessage = 'Erro ao deletar livro: $e';
      print(_errorMessage);
      return false; // Falha
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
