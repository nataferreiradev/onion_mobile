class Lista {
  final int id;
  final String descricao;
  final DateTime? data;
  final int? usuario;
  final int? usuarioId;

  Lista({
    required this.id,
    required this.descricao,
    this.data,
    this.usuario,
    this.usuarioId,
  });

  factory Lista.fromJson(Map<String, dynamic> json) {
    return Lista(
      id: json['id'] as int,
      descricao: json['descricao'] as String,
      data: json['data'] != null ? DateTime.parse(json['data'] as String) : null,
      usuario: json['usuario'] as int?,
      usuarioId: json['usuario_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'data': data?.toIso8601String(),
    'usuario': usuario,
    'usuario_id': usuarioId,
  };
}