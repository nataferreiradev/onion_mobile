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

  Future<List<ProdutoLista>> fetchProdutosDaLista(int listaId) async {
    try {
      final response = await _supabase
          .from('produtos_lista')
          .select('*, produto(*)')
          .eq('id_lista', listaId)
          .order('id');

      return response.map<ProdutoLista>((json) => ProdutoLista.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar produtos da lista: $e');
      rethrow;
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

// Classe auxiliar para representar produtos na lista
class ProdutoLista {
  final int id;
  final int idLista;
  final int idProduto;
  final int qtde;
  final String produtoDescricao;
  final String? unidade;

  ProdutoLista({
    required this.id,
    required this.idLista,
    required this.idProduto,
    required this.qtde,
    required this.produtoDescricao,
    this.unidade,
  });

  factory ProdutoLista.fromJson(Map<String, dynamic> json) => ProdutoLista(
        id: json['id'],
        idLista: json['id_lista'],
        idProduto: json['id_produto'],
        qtde: json['qtde'],
        produtoDescricao: json['produto']['descricao'],
        unidade: json['produto']['unidade'],
      );
}