// Classe simulada para File na web
// Esta classe é usada apenas para compilação na web e não tem funcionalidade real

class File {
  final String path;

  File(this.path);

  Future<bool> exists() async => false;

  Future<void> writeAsBytes(List<int> bytes) async {
    // Não faz nada na web
  }

  Future<void> delete() async {
    // Não faz nada na web
  }
}
