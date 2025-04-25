/// Interface para uma trace de desempenho
abstract class Trace {
  /// Nome da trace
  String get name;
  
  /// Inicia a trace
  void start();
  
  /// Para a trace
  Future<void> stop();
}

/// Interface para uma métrica HTTP
abstract class HttpMetric {
  /// URL da requisição
  String get url;
  
  /// Método HTTP
  AppHttpMethod get method;
  
  /// Inicia a métrica
  void start();
  
  /// Para a métrica
  Future<void> stop();
  
  /// Define o código de resposta HTTP
  void setHttpResponseCode(int responseCode);
  
  /// Define o tamanho do payload da requisição
  void setRequestPayloadSize(int bytes);
  
  /// Define o tamanho do payload da resposta
  void setResponsePayloadSize(int bytes);
  
  /// Define o tipo de conteúdo da resposta
  void setResponseContentType(String contentType);
}

/// Enum para métodos HTTP
enum AppHttpMethod {
  /// GET
  get,

  /// POST
  post,

  /// PUT
  put,

  /// DELETE
  delete,

  /// PATCH
  patch,

  /// HEAD
  head,

  /// OPTIONS
  options,
}
