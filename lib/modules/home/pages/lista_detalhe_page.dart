import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:onion_mobile/modules/lista/lista.dart';
import 'package:onion_mobile/modules/produto/produto.dart';
import 'package:onion_mobile/modules/produto/produto_controller.dart';
import 'package:provider/provider.dart';

class ListaDetalhesPage extends StatefulWidget {
  final Lista lista;

  const ListaDetalhesPage({super.key, required this.lista});

  @override
  State<ListaDetalhesPage> createState() => _ListaDetalhesPageState();
}

class _ListaDetalhesPageState extends State<ListaDetalhesPage> {
  List<ProdutoLista> _produtosLista = [];
  Map<int, int> _quantidadesAlteradas = {}; // id_produto_lista -> nova_qtde
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _hasChanges => _quantidadesAlteradas.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoading = true);
    try {
      final controller = context.read<ProdutoController>();
      _produtosLista = await controller.fetchProdutosDaLista(widget.lista.id);
      _quantidadesAlteradas.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_quantidadesAlteradas.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final controller = context.read<ProdutoController>();
      
      // Salvar todas as alterações
      for (final entry in _quantidadesAlteradas.entries) {
        await controller.updateQtde(entry.key, entry.value);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantidades atualizadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recarregar produtos e limpar alterações
      await _carregarProdutos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar alterações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _alterarQuantidade(ProdutoLista produtoLista, int novaQtde) {
    setState(() {
      // Se a quantidade for igual à original, remover da lista de alterações
      if (novaQtde == produtoLista.qtde) {
        _quantidadesAlteradas.remove(produtoLista.id);
      } else {
        _quantidadesAlteradas[produtoLista.id] = novaQtde;
      }
    });
  }

  int _getQuantidadeAtual(ProdutoLista produtoLista) {
    return _quantidadesAlteradas[produtoLista.id] ?? produtoLista.qtde;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await _confirmarSaida() ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lista.descricao),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarLista(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Banner de alterações pendentes
            if (_hasChanges)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_quantidadesAlteradas.length} alteração(ões) não salva(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _quantidadesAlteradas.clear());
                      },
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              ),
            // Lista de produtos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _produtosLista.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum produto adicionado',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toque no + para adicionar produtos',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _produtosLista.length,
                          itemBuilder: (context, index) {
                            final produtoLista = _produtosLista[index];
                            final qtdeAtual = _getQuantidadeAtual(produtoLista);
                            final foiAlterado =
                                _quantidadesAlteradas.containsKey(produtoLista.id);

                            return _ProdutoListaCard(
                              produtoLista: produtoLista,
                              quantidadeAtual: qtdeAtual,
                              foiAlterado: foiAlterado,
                              onQuantidadeChanged: (novaQtde) =>
                                  _alterarQuantidade(produtoLista, novaQtde),
                              onRemover: () async {
                                await context
                                    .read<ProdutoController>()
                                    .removeProdutoLista(produtoLista.id);
                                await _carregarProdutos();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Salvar (aparece apenas quando há alterações)
            if (_hasChanges)
              FloatingActionButton.extended(
                heroTag: 'salvar',
                onPressed: _isSaving ? null : _salvarAlteracoes,
                backgroundColor: Colors.green,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
              ),
            if (_hasChanges) const SizedBox(height: 8),
            // Botão Adicionar
            FloatingActionButton(
              heroTag: 'adicionar',
              onPressed: () => _adicionarProduto(context),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmarSaida() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
          'Você tem alterações não salvas. Deseja descartar as alterações?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarLista(BuildContext context) async {
    final nomeController = TextEditingController(text: widget.lista.descricao);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Lista'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome da lista',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Aqui você implementaria a atualização da lista
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarProduto(BuildContext context) async {
    final controller = context.read<ProdutoController>();
    await controller.fetchProdutos();

    if (!mounted) return;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AdicionarProdutoDialog(
        produtos: controller.produtos,
      ),
    );

    if (resultado != null) {
      try {
        await controller.addProdutoNaLista(
          widget.lista.id,
          resultado['produtoId'],
          resultado['quantidade'],
        );
        await _carregarProdutos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto adicionado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar produto: $e')),
          );
        }
      }
    }
  }
}

class _ProdutoListaCard extends StatelessWidget {
  final ProdutoLista produtoLista;
  final int quantidadeAtual;
  final bool foiAlterado;
  final Function(int) onQuantidadeChanged;
  final VoidCallback onRemover;

  const _ProdutoListaCard({
    required this.produtoLista,
    required this.quantidadeAtual,
    required this.foiAlterado,
    required this.onQuantidadeChanged,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _confirmarRemocao(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Remover',
          ),
        ],
      ),
      child: Card(
        color: foiAlterado ? Colors.orange.shade50 : null,
        child: ListTile(
          title: Row(
            children: [
              Expanded(child: Text(produtoLista.produtoDescricao)),
              if (foiAlterado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ALTERADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            'Unidade: ${produtoLista.unidade ?? "UN"}${foiAlterado ? " • Original: ${produtoLista.qtde}" : ""}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: quantidadeAtual > 1
                    ? () => onQuantidadeChanged(quantidadeAtual - 1)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: foiAlterado
                      ? Colors.orange.shade100
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: foiAlterado
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                child: Text(
                  '$quantidadeAtual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: foiAlterado ? Colors.orange.shade900 : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onQuantidadeChanged(quantidadeAtual + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarRemocao(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover produto'),
        content: Text(
          'Deseja remover ${produtoLista.produtoDescricao} da lista?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              onRemover();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _AdicionarProdutoDialog extends StatefulWidget {
  final List<Produto> produtos;

  const _AdicionarProdutoDialog({required this.produtos});

  @override
  State<_AdicionarProdutoDialog> createState() =>
      _AdicionarProdutoDialogState();
}

class _AdicionarProdutoDialogState extends State<_AdicionarProdutoDialog> {
  Produto? _produtoSelecionado;
  int _quantidade = 1;
  String _searchQuery = '';

  List<Produto> get _produtosFiltrados {
    if (_searchQuery.isEmpty) return widget.produtos;
    return widget.produtos
        .where((p) =>
            p.descricao.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Adicionar Produto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _produtosFiltrados.length,
                itemBuilder: (context, index) {
                  final produto = _produtosFiltrados[index];
                  return ListTile(
                    title: Text(produto.descricao),
                    subtitle: Text('Unidade: ${produto.unidade ?? "UN"}'),
                    selected: _produtoSelecionado?.id == produto.id,
                    onTap: () {
                      setState(() => _produtoSelecionado = produto);
                    },
                  );
                },
              ),
            ),
            if (_produtoSelecionado != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _quantidade > 1
                        ? () => setState(() => _quantidade--)
                        : null,
                  ),
                  Text(
                    '$_quantidade',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _quantidade++),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _produtoSelecionado == null
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'produtoId': _produtoSelecionado!.id,
                            'quantidade': _quantidade,
                          });
                        },
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
