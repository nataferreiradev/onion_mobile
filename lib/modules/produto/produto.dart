class Produto {
  final int id;
  final String descricao;
  final int? qtdMinima;
  final int? idFornecedor;
  final String? unidade;

  Produto({
    required this.id,
    required this.descricao,
    this.qtdMinima,
    this.idFornecedor,
    this.unidade,
  });

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
    id: json['id'],
    descricao: json['descricao'],
    qtdMinima: json['qtd_minima'],
    idFornecedor: json['id_fornecedor'],
    unidade: json['unidade'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'qtd_minima': qtdMinima,
    'id_fornecedor': idFornecedor,
    'unidade': unidade,
  };
}