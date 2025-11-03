import 'package:flutter/material.dart';
import 'package:onion_mobile/core/supabase_config.dart';
import 'package:onion_mobile/modules/produto/produto.dart';

class ProdutoController extends ChangeNotifier {
  final _supabase = SupabaseConfig.client;
  List<Produto> _produtos = [];
  bool isLoading = false;

  List<Produto> get produtos => _produtos;

  Future<void> fetchProdutos() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('produto')
          .select()
          .order('descricao');
      
      _produtos = response.map<Produto>((json) => Produto.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar produtos: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProdutoNaLista(int listaId, int produtoId, int qtde) async {
    try {
      await _supabase.from('produtos_lista').insert({
        'id_lista': listaId,
        'id_produto': produtoId,
        'qtde': qtde,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar produto na lista: $e');
      rethrow;
    }
  }

  Future<void> updateQtde(int produtosListaId, int qtde) async {
    try {
      await _supabase
          .from('produtos_lista')
          .update({'qtde': qtde})
          .eq('id', produtosListaId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar quantidade: $e');
      rethrow;
    }
  }

  Future<void> removeProdutoLista(int produtosListaId) async {
    try {
      await _supabase
          .from('produtos_lista')
          .delete()
          .eq('id', produtosListaId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao remover produto da lista: $e');
      rethrow;
    }
  }
}