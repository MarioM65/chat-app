
class Attachment {
  final int id;
  final String nomeArquivo;
  final String caminhoArquivo;
  final String tipo;
  final int tamanho;

  Attachment({
    required this.id,
    required this.nomeArquivo,
    required this.caminhoArquivo,
    required this.tipo,
    required this.tamanho,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      nomeArquivo: json['nome_arquivo'],
      caminhoArquivo: json['caminho_arquivo'],
      tipo: json['tipo'],
      tamanho: json['tamanho'],
    );
  }
}
