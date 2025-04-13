import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Classe para representar uma tarefa em segundo plano
///
/// Esta classe encapsula todos os dados necessários para executar uma tarefa
/// em segundo plano usando isolates. Ela contém o identificador da tarefa,
/// nome descritivo, dados de entrada, função de processamento, completer para
/// retornar o resultado, data de criação e prioridade.
///
/// A prioridade é usada pelo [BackgroundProcessorService] para determinar a ordem
/// de execução das tarefas quando há mais tarefas do que isolates disponíveis.
/// Valores maiores indicam maior prioridade.
///
/// Exemplo:
/// ```dart
/// final task = BackgroundTask<String, int>(
///   id: 'task_1',
///   name: 'Processamento de texto',
///   input: 'Texto para processar',
///   processor: (text) => text.length,
///   completer: Completer<int>(),
///   createdAt: DateTime.now(),
///   priority: 5,
/// );
/// ```
class BackgroundTask<T, R> {
  final String id;
  final String name;
  final T input;
  final Function(T) processor;
  final Completer<R> completer;
  final DateTime createdAt;
  final int priority;

  BackgroundTask({
    required this.id,
    required this.name,
    required this.input,
    required this.processor,
    required this.completer,
    required this.createdAt,
    required this.priority,
  });
}

/// Mensagem para comunicação com o isolate
class IsolateMessage<T> {
  final String taskId;
  final T data;
  final SendPort sendPort;

  IsolateMessage({
    required this.taskId,
    required this.data,
    required this.sendPort,
  });
}

/// Resultado de uma tarefa em segundo plano
class TaskResult<R> {
  final String taskId;
  final R? result;
  final String? error;

  TaskResult({
    required this.taskId,
    this.result,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Serviço para otimizar o uso de recursos em segundo plano com isolates
///
/// Este serviço permite executar tarefas intensivas em CPU em segundo plano
/// usando isolates do Dart, evitando bloqueios na thread principal da UI.
/// O serviço gerencia automaticamente um pool de isolates e distribui as tarefas
/// entre eles com base em prioridade e ordem de chegada.
///
/// Principais funcionalidades:
/// - Execução de tarefas em isolates separados
/// - Gerenciamento automático de pool de isolates
/// - Priorização de tarefas
/// - Fila de tarefas pendentes quando todos os isolates estão ocupados
/// - Estatísticas de uso e desempenho
///
/// Exemplo de uso:
/// ```dart
/// final processor = getIt<BackgroundProcessorService>();
///
/// // Executar uma tarefa em segundo plano
/// final resultado = await processor.executeTask<String, int>(
///   name: 'Processamento de texto',
///   input: 'Texto para processar',
///   processor: (texto) => texto.length,
///   priority: 10,
/// );
///
/// print('Resultado: $resultado');
/// ```
///
/// Para dispositivos web, onde isolates não são suportados, o serviço
/// executa as tarefas na thread principal, mas mantém a mesma API.
@singleton
class BackgroundProcessorService {
  static const String _tag = 'BackgroundProcessorService';

  /// Número máximo de isolates
  static const int _maxIsolates = 4;

  /// Logger
  final Logger _logger;

  /// Mapa de isolates
  final Map<String, Isolate> _isolates = {};

  /// Mapa de portas de envio
  final Map<String, SendPort> _sendPorts = {};

  /// Mapa de tarefas em execução
  final Map<String, BackgroundTask> _runningTasks = {};

  /// Fila de tarefas pendentes
  final List<BackgroundTask> _pendingTasks = [];

  /// Porta de recebimento
  late ReceivePort _receivePort;

  /// Construtor
  BackgroundProcessorService(this._logger) {
    _init();
  }

  /// Inicializa o serviço
  void _init() {
    try {
      if (kIsWeb) {
        _logger.warning('Isolates não são suportados na Web', tag: _tag);
        return;
      }

      _logger.debug('Inicializando serviço de processamento em segundo plano', tag: _tag);

      // Criar porta de recebimento
      _receivePort = ReceivePort();

      // Escutar mensagens
      _receivePort.listen(_handleMessage);

      // Inicializar isolates
      for (var i = 0; i < _maxIsolates; i++) {
        _createIsolate('isolate_$i');
      }
    } catch (e) {
      _logger.error('Erro ao inicializar serviço de processamento em segundo plano', tag: _tag, error: e);
    }
  }

  /// Cria um isolate
  Future<void> _createIsolate(String isolateId) async {
    try {
      if (kIsWeb) return;

      _logger.debug('Criando isolate: $isolateId', tag: _tag);

      // Criar porta de recebimento para o isolate
      final isolateReceivePort = ReceivePort();

      // Criar isolate
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        isolateReceivePort.sendPort,
      );

      // Armazenar isolate
      _isolates[isolateId] = isolate;

      // Escutar mensagens do isolate
      isolateReceivePort.listen((message) {
        if (message is SendPort) {
          // Armazenar porta de envio
          _sendPorts[isolateId] = message;

          // Processar tarefas pendentes
          _processPendingTasks();
        } else if (message is TaskResult) {
          // Processar resultado da tarefa
          _handleTaskResult(message);
        }
      });
    } catch (e) {
      _logger.error('Erro ao criar isolate: $isolateId', tag: _tag, error: e);
    }
  }

  /// Função de entrada do isolate
  static void _isolateEntryPoint(SendPort sendPort) {
    // Criar porta de recebimento
    final receivePort = ReceivePort();

    // Enviar porta de recebimento para o isolate principal
    sendPort.send(receivePort.sendPort);

    // Escutar mensagens
    receivePort.listen((message) {
      if (message is IsolateMessage) {
        try {
          // Processar tarefa
          final processor = message.data as Function;
          final result = processor();

          // Enviar resultado
          sendPort.send(TaskResult(
            taskId: message.taskId,
            result: result,
          ));
        } catch (e) {
          // Enviar erro
          sendPort.send(TaskResult(
            taskId: message.taskId,
            error: e.toString(),
          ));
        }
      }
    });
  }

  /// Processa tarefas pendentes
  void _processPendingTasks() {
    try {
      if (_pendingTasks.isEmpty) return;

      // Verificar se há isolates disponíveis
      final availableIsolates = _sendPorts.keys
          .where((isolateId) => !_isIsolateBusy(isolateId))
          .toList();

      if (availableIsolates.isEmpty) return;

      // Ordenar tarefas por prioridade (maior primeiro) e data de criação (mais antigas primeiro)
      _pendingTasks.sort((a, b) {
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      // Processar tarefas pendentes
      for (var i = 0; i < availableIsolates.length && i < _pendingTasks.length; i++) {
        final isolateId = availableIsolates[i];
        final task = _pendingTasks[i];

        // Executar tarefa
        _executeTask(isolateId, task);

        // Remover tarefa da fila
        _pendingTasks.remove(task);
      }
    } catch (e) {
      _logger.error('Erro ao processar tarefas pendentes', tag: _tag, error: e);
    }
  }

  /// Verifica se um isolate está ocupado
  bool _isIsolateBusy(String isolateId) {
    return _runningTasks.values.any((task) => task.id.startsWith(isolateId));
  }

  /// Executa uma tarefa em um isolate
  void _executeTask(String isolateId, BackgroundTask task) {
    try {
      _logger.debug('Executando tarefa ${task.name} (${task.id}) no isolate $isolateId', tag: _tag);

      // Marcar tarefa como em execução
      _runningTasks['${isolateId}_${task.id}'] = task;

      // Enviar mensagem para o isolate
      _sendPorts[isolateId]?.send(IsolateMessage(
        taskId: task.id,
        data: task.processor,
        sendPort: _receivePort.sendPort,
      ));
    } catch (e) {
      _logger.error('Erro ao executar tarefa ${task.name} (${task.id})', tag: _tag, error: e);

      // Remover tarefa da lista de tarefas em execução
      _runningTasks.remove('${isolateId}_${task.id}');

      // Completar tarefa com erro
      task.completer.completeError(e);
    }
  }

  /// Processa o resultado de uma tarefa
  void _handleTaskResult(TaskResult result) {
    try {
      // Encontrar tarefa
      final taskEntry = _runningTasks.entries
          .firstWhere((entry) => entry.key.endsWith(result.taskId),
              orElse: () => MapEntry('', BackgroundTask(
                id: '',
                name: '',
                input: null,
                processor: (_) {},
                completer: Completer(),
                createdAt: DateTime.now(),
                priority: 0,
              )));

      if (taskEntry.key.isEmpty) {
        _logger.warning('Tarefa não encontrada: ${result.taskId}', tag: _tag);
        return;
      }

      final task = taskEntry.value;

      // Remover tarefa da lista de tarefas em execução
      _runningTasks.remove(taskEntry.key);

      // Completar tarefa
      if (result.isSuccess) {
        _logger.debug('Tarefa ${task.name} (${task.id}) concluída com sucesso', tag: _tag);
        task.completer.complete(result.result);
      } else {
        _logger.warning('Tarefa ${task.name} (${task.id}) concluída com erro: ${result.error}', tag: _tag);
        task.completer.completeError(result.error ?? 'Erro desconhecido');
      }

      // Processar tarefas pendentes
      _processPendingTasks();
    } catch (e) {
      _logger.error('Erro ao processar resultado de tarefa', tag: _tag, error: e);
    }
  }

  /// Processa uma mensagem recebida
  void _handleMessage(dynamic message) {
    try {
      if (message is TaskResult) {
        _handleTaskResult(message);
      }
    } catch (e) {
      _logger.error('Erro ao processar mensagem', tag: _tag, error: e);
    }
  }

  /// Executa uma tarefa em segundo plano
  ///
  /// Este método cria e agenda uma tarefa para ser executada em um isolate separado.
  /// A tarefa é colocada em uma fila e executada quando um isolate estiver disponível.
  /// Se todos os isolates estiverem ocupados, as tarefas são executadas em ordem de
  /// prioridade (valores maiores têm prioridade) e, em caso de empate, em ordem de criação.
  ///
  /// Parâmetros:
  /// - [name]: Nome descritivo da tarefa (usado para logging)
  /// - [input]: Dados de entrada para a tarefa
  /// - [processor]: Função que processa os dados de entrada e retorna um resultado
  /// - [priority]: Prioridade da tarefa (padrão: 5, valores maiores têm prioridade)
  ///
  /// Retorna um [Future] que será completado com o resultado da tarefa quando ela for executada.
  ///
  /// Em dispositivos web, onde isolates não são suportados, a tarefa é executada
  /// diretamente na thread principal.
  ///
  /// Exemplo:
  /// ```dart
  /// final resultado = await backgroundProcessor.executeTask<String, int>(
  ///   name: 'Contar caracteres',
  ///   input: 'Texto de exemplo',
  ///   processor: (texto) => texto.length,
  ///   priority: 10,
  /// );
  /// ```
  Future<R> executeTask<T, R>({
    required String name,
    required T input,
    required R Function(T) processor,
    int priority = 5,
  }) async {
    try {
      if (kIsWeb) {
        _logger.warning('Isolates não são suportados na Web, executando tarefa na thread principal', tag: _tag);
        return processor(input);
      }

      // Criar completer
      final completer = Completer<R>();

      // Criar tarefa
      final task = BackgroundTask<T, R>(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_pendingTasks.length}',
        name: name,
        input: input,
        processor: (input) => processor(input as T),
        completer: completer,
        createdAt: DateTime.now(),
        priority: priority,
      );

      // Adicionar tarefa à fila
      _pendingTasks.add(task);

      _logger.debug('Tarefa ${task.name} (${task.id}) adicionada à fila', tag: _tag);

      // Processar tarefas pendentes
      _processPendingTasks();

      // Aguardar resultado
      return completer.future;
    } catch (e) {
      _logger.error('Erro ao executar tarefa em segundo plano', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Executa uma tarefa em segundo plano com computeAsync
  Future<R> computeAsync<T, R>({
    required String name,
    required T input,
    required R Function(T) processor,
    int priority = 5,
  }) async {
    try {
      _logger.debug('Executando tarefa $name com computeAsync', tag: _tag);
      return await compute(processor, input);
    } catch (e) {
      _logger.error('Erro ao executar tarefa com computeAsync', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Obtém estatísticas do serviço
  Map<String, dynamic> getStats() {
    try {
      final stats = {
        'isolates': _isolates.length,
        'runningTasks': _runningTasks.length,
        'pendingTasks': _pendingTasks.length,
        'runningTaskNames': _runningTasks.values.map((task) => task.name).toList(),
        'pendingTaskNames': _pendingTasks.map((task) => task.name).toList(),
      };

      _logger.debug('Estatísticas do serviço de processamento em segundo plano: $stats', tag: _tag);
      return stats;
    } catch (e) {
      _logger.error('Erro ao obter estatísticas do serviço', tag: _tag, error: e);
      return {
        'error': e.toString(),
      };
    }
  }

  /// Cancela todas as tarefas pendentes
  void cancelPendingTasks() {
    try {
      for (var task in _pendingTasks) {
        task.completer.completeError('Tarefa cancelada');
      }

      _pendingTasks.clear();

      _logger.debug('Tarefas pendentes canceladas', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao cancelar tarefas pendentes', tag: _tag, error: e);
    }
  }

  /// Fecha o serviço
  void dispose() {
    try {
      // Cancelar tarefas pendentes
      cancelPendingTasks();

      // Fechar isolates
      for (var isolate in _isolates.values) {
        isolate.kill(priority: Isolate.immediate);
      }

      // Fechar porta de recebimento
      _receivePort.close();

      _logger.debug('Serviço de processamento em segundo plano fechado', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao fechar serviço de processamento em segundo plano', tag: _tag, error: e);
    }
  }
}
