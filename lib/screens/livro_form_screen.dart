// lib/screens/livro_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter (filtrar entrada de texto)
import 'package:livros_simples_app/database/database_helper.dart'; // Importa o helper do banco de dados
import 'package:livros_simples_app/models/livro.dart'; // Importa o modelo Livro
import 'package:provider/provider.dart'; // Importa o pacote provider
import 'package:livros_simples_app/providers/livro_provider.dart'; // Importa o LivroProvider

class LivroFormScreen extends StatefulWidget {
  final int? livroId; // ID do livro a ser editado (será nulo para adicionar novo livro)
  const LivroFormScreen({super.key, this.livroId});

  @override
  State<LivroFormScreen> createState() => _LivroFormScreenState();
}

class _LivroFormScreenState extends State<LivroFormScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário, usada para validação
  final _tituloController = TextEditingController(); // Controlador para o campo 'titulo'
  final _autorController = TextEditingController(); // Controlador para o campo 'autor'
  final _anoPublicacaoController = TextEditingController(); // Controlador para o campo 'anoPublicacao'
  bool _lido = false; // Estado do checkbox 'lido'

  bool _isLoading = false; // Flag para indicar se os dados estão sendo carregados ou salvos

  @override
  void initState() {
    super.initState();
    if (widget.livroId != null) {
      _loadLivroForEdit(); // Se livroId não for nulo, carrega o livro para edição
    }
  }

  // Carrega os dados de um livro existente para preencher o formulário
  Future<void> _loadLivroForEdit() async {
    setState(() {
      _isLoading = true; // Inicia o estado de carregamento
    });
    // Usa o DatabaseHelper diretamente para carregar o livro na inicialização
    final livro = await DatabaseHelper().getLivro(widget.livroId!);

    if (livro != null) {
      // Preenche os controladores e o estado do checkbox com os dados do livro
      _tituloController.text = livro.titulo;
      _autorController.text = livro.autor;
      _anoPublicacaoController.text = livro.anoPublicacao.toString();
      _lido = livro.lido;
    }
    setState(() {
      _isLoading = false; // Finaliza o estado de carregamento
    });
  }

  // Processa o envio do formulário (adicionar ou editar)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Se a validação falhar, não faz nada
    }
    _formKey.currentState!.save(); // Salva os dados do formulário

    setState(() {
      _isLoading = true; // Inicia o estado de carregamento/salvamento
    });

    // Cria um novo objeto Livro com os dados do formulário
    final livro = Livro(
      id: widget.livroId, // Mantém o ID se for edição, ou nulo para novo livro
      titulo: _tituloController.text,
      autor: _autorController.text,
      anoPublicacao: int.parse(_anoPublicacaoController.text),
      lido: _lido,
      // Se for um novo livro, usa a data atual; se for edição, mantém a data de criação original
      dataCriacao: widget.livroId == null ? DateTime.now() : (await DatabaseHelper().getLivro(widget.livroId!))!.dataCriacao,
    );

    // Obtém a instância do LivroProvider
    final livroProvider = Provider.of<LivroProvider>(context, listen: false);

    try {
      if (widget.livroId == null) {
        // Se livroId for nulo, insere um novo livro usando o provider
        await livroProvider.addLivro(livro);
      } else {
        // Caso contrário, atualiza o livro existente usando o provider
        await livroProvider.updateLivro(widget.livroId!, livro);
      }

      if (context.mounted) { // Verifica se o widget ainda está na árvore de widgets
        // Se estiver editando, precisamos retornar 2 telas: o formulário e a tela de detalhes.
        if (widget.livroId != null) {
          Navigator.of(context).pop(); // Volta da tela de formulário
          Navigator.of(context).pop(); // Volta da tela de detalhes (para a lista)
        } else {
          // Se estiver adicionando, apenas volta da tela de formulário para a lista
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Em caso de erro, exibe uma mensagem para o usuário
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar o livro: $e')),
        );
      }
      print('Erro ao salvar livro: $e'); // Loga o erro no console
    } finally {
      setState(() {
        _isLoading = false; // Finaliza o estado de carregamento, mesmo em caso de erro
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define se o campo de título deve ser somente leitura (readOnly)
    final bool isEditing = widget.livroId != null;

    return Scaffold(
      appBar: AppBar(
        // Título dinâmico: 'Adicionar Livro' ou 'Editar Livro'
        title: Text(isEditing ? 'Editar Livro' : 'Adicionar Livro'),
      ),
      body: _isLoading // Se estiver carregando, mostra um CircularProgressIndicator
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Permite rolagem se o conteúdo for grande
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Associa a chave ao formulário
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Estende os filhos horizontalmente
            children: [
              // Campo de texto para o Título
              TextFormField(
                controller: _tituloController,
                readOnly: isEditing, // Campo é somente leitura se estiver editando
                decoration: InputDecoration(
                  labelText: 'Título do Livro',
                  // Adiciona um ícone de cadeado se for somente leitura
                  suffixIcon: isEditing ? const Icon(Icons.lock) : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o título do livro.'; // Validação obrigatória
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de texto para o Autor
              TextFormField(
                controller: _autorController,
                decoration: const InputDecoration(labelText: 'Autor'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o autor.'; // Validação obrigatória
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de texto para o Ano de Publicação
              TextFormField(
                controller: _anoPublicacaoController,
                decoration: const InputDecoration(labelText: 'Ano de Publicação'),
                keyboardType: TextInputType.number, // Tipo de teclado numérico
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Permite apenas dígitos
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o ano de publicação.'; // Validação obrigatória
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Ano inválido.'; // Validação de número positivo
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Checkbox para o status 'Lido' (agora usando CheckboxListTile)
              CheckboxListTile(
                title: const Text('Já Lido?'), // O rótulo do checkbox
                value: _lido,
                onChanged: (bool? newValue) {
                  setState(() {
                    _lido = newValue ?? false; // Atualiza o estado do checkbox
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // Coloca o checkbox à esquerda
              ),
              const SizedBox(height: 32),
              // Botão para adicionar/salvar livro
              ElevatedButton(
                onPressed: _submitForm, // Chama a função de envio do formulário
                child: Text(isEditing ? 'Salvar Alterações' : 'Adicionar Livro'),
              ),
              const SizedBox(height: 16),
              // Botão para cancelar e voltar
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Volta para a tela anterior
                },
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
