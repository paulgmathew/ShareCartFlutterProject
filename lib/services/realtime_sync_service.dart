import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/models.dart';

class RealtimeSyncService {
  final String _wsUrl;
  final Future<String?> Function() _accessTokenProvider;

  StompClient? _client;
  bool _isConnected = false;
  Completer<void>? _connectCompleter;

  final Set<String> _subscribedListIds = <String>{};
  final Map<String, StompUnsubscribe> _unsubscribeByListId =
      <String, StompUnsubscribe>{};

  final StreamController<ListRealtimeEventModel> _eventController =
      StreamController<ListRealtimeEventModel>.broadcast();
  final StreamController<String> _resyncController =
      StreamController<String>.broadcast();

  RealtimeSyncService({
    required String wsUrl,
    required Future<String?> Function() accessTokenProvider,
  }) : _wsUrl = wsUrl,
       _accessTokenProvider = accessTokenProvider;

  Stream<ListRealtimeEventModel> get events => _eventController.stream;
  Stream<String> get resyncRequests => _resyncController.stream;

  Future<void> ensureConnected() async {
    if (_isConnected) return;

    if (_connectCompleter != null) {
      await _connectCompleter!.future;
      return;
    }

    final token = await _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Missing JWT token for STOMP CONNECT');
    }

    final completer = Completer<void>();
    _connectCompleter = completer;

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        reconnectDelay: const Duration(seconds: 3),
        stompConnectHeaders: <String, String>{'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: <String, dynamic>{
          'Authorization': 'Bearer $token',
        },
        onConnect: (_) {
          _isConnected = true;
          _attachActiveSubscriptions();
          for (final listId in _subscribedListIds) {
            _resyncController.add(listId);
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
          _connectCompleter = null;
        },
        onDisconnect: (_) {
          _isConnected = false;
          _requestResyncForAll();
        },
        onWebSocketDone: () {
          _isConnected = false;
          _requestResyncForAll();
        },
        onStompError: (frame) {
          _requestResyncForAll();
        },
        onWebSocketError: (dynamic _) {
          _requestResyncForAll();
        },
      ),
    );

    _client!.activate();
    await completer.future;
  }

  Future<void> subscribeToList(String listId) async {
    _subscribedListIds.add(listId);
    await ensureConnected();

    if (_unsubscribeByListId.containsKey(listId)) return;
    _subscribeInternal(listId);
  }

  void unsubscribeFromList(String listId) {
    _subscribedListIds.remove(listId);
    _unsubscribeByListId.remove(listId)?.call();
  }

  Future<void> dispose() async {
    for (final unsubscribe in _unsubscribeByListId.values) {
      unsubscribe();
    }
    _unsubscribeByListId.clear();
    _subscribedListIds.clear();
    _client?.deactivate();
    _isConnected = false;
    await _eventController.close();
    await _resyncController.close();
  }

  void _attachActiveSubscriptions() {
    for (final unsubscribe in _unsubscribeByListId.values) {
      unsubscribe();
    }
    _unsubscribeByListId.clear();

    for (final listId in _subscribedListIds) {
      _subscribeInternal(listId);
    }
  }

  void _subscribeInternal(String listId) {
    final client = _client;
    if (client == null) return;

    _unsubscribeByListId[listId] = client.subscribe(
      destination: '/topic/lists/$listId',
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) {
          _resyncController.add(listId);
          return;
        }

        try {
          final jsonMap = jsonDecode(body) as Map<String, dynamic>;
          final event = ListRealtimeEventModel.fromJson(jsonMap);
          _eventController.add(event);
        } catch (_) {
          _resyncController.add(listId);
        }
      },
    );
  }

  void _requestResyncForAll() {
    for (final listId in _subscribedListIds) {
      _resyncController.add(listId);
    }
  }
}
