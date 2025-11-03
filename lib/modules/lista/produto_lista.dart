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

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_lista': idLista,
        'id_produto': idProduto,
        'qtde': qtde,
      };
}