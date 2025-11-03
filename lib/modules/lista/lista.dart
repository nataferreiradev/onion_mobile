class Lista {
  final int id;
  final String descricao;
  final DateTime? data;
  final int usuario;

  Lista({
    required this.id,
    required this.descricao,
    this.data,
    required this.usuario,
  });

  factory Lista.fromJson(Map<String, dynamic> json) => Lista(
    id: json['id'],
    descricao: json['descricao'],
    data: json['data'] != null ? DateTime.parse(json['data']) : null,
    usuario: json['usuario'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'data': data?.toIso8601String(),
    'usuario': usuario,
  };
}
