class Usuario {
  final int id;
  final String descricao;
  final int? idCargo;
  final int? idEmpresa;
  final String? userId;

  Usuario({
    required this.id,
    required this.descricao,
    this.idCargo,
    this.idEmpresa,
    this.userId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'],
    descricao: json['descricao'],
    idCargo: json['id_cargo'],
    idEmpresa: json['id_empresa'],
    userId: json['user_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'id_cargo': idCargo,
    'id_empresa': idEmpresa,
    'user_id': userId,
  };
}
