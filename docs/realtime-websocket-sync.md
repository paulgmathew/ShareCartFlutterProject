# ShareCart Realtime Sync (WebSocket + STOMP)

## Goal

Enable live list updates so all members see item changes instantly without polling.

## Backend Contract (Implemented)

1. STOMP WebSocket endpoint: `/ws`
2. Topic destination pattern: `/topic/lists/{listId}`
3. Event types: `ITEM_ADDED`, `ITEM_UPDATED`, `ITEM_DELETED`
4. Events are published only after transaction commit

## Phase 2 Security (Implemented)

1. STOMP CONNECT must include `Authorization: Bearer <jwt>` in CONNECT headers.
2. STOMP SUBSCRIBE to `/topic/lists/{listId}` is accepted only if user is owner/member of that list.

If either check fails, the server rejects the STOMP frame.

## Why This Uses STOMP + WebSocket

1. WebSocket gives server push, so collaborators get updates instantly.
2. STOMP provides a standard messaging contract with destinations, headers, and frame types.
3. STOMP works well with Spring messaging abstractions and client libraries.
4. Topic model (`/topic/lists/{listId}`) maps naturally to collaborative list screens.

## Flutter Setup

`stomp_dart_client` is already included in `pubspec.yaml`:

```yaml
dependencies:
  stomp_dart_client: ^2.1.3
```

## URL Mapping For Flutter Environments

Use websocket URL matching your runtime:

1. Android emulator: `ws://10.0.2.2:8080/ws`
2. iOS simulator: `ws://127.0.0.1:8080/ws`
3. Flutter web (same machine): `ws://localhost:8080/ws`
4. Physical device: `ws://<your-local-ip>:8080/ws`
5. Render/Prod: `wss://<your-render-domain>/ws`

## Event Payload

Every message sent to `/topic/lists/{listId}` has this shape:

```json
{
  "eventType": "ITEM_ADDED",
  "listId": "22222222-2222-2222-2222-222222222222",
  "item": {
    "id": "44444444-4444-4444-4444-444444444444",
    "listId": "22222222-2222-2222-2222-222222222222",
    "name": "Milk",
    "quantity": "2",
    "isCompleted": false,
    "category": "Dairy",
    "createdBy": "11111111-1111-1111-1111-111111111111",
    "createdAt": "2026-03-27T09:00:00",
    "updatedAt": "2026-03-27T09:00:00"
  },
  "occurredAt": "2026-03-27T09:00:00Z"
}
```

The Flutter model for this payload is `ListRealtimeEventModel` (`lib/models/list_realtime_event_model.dart`). The `item` field is parsed directly into a typed `ItemModel`, not a raw map.

## Implemented Service: `RealtimeSyncService`

The actual implementation is in `lib/services/realtime_sync_service.dart`.

### Key API

| Method | Purpose |
|---|---|
| `ensureConnected()` | Connects STOMP (idempotent — safe to call multiple times) |
| `subscribeToList(listId)` | Subscribes to `/topic/lists/{listId}`, calls `ensureConnected()` first |
| `unsubscribeFromList(listId)` | Removes subscription for that list |
| `dispose()` | Unsubscribes all, deactivates STOMP client, closes streams |

### Streams

| Stream | Type | Purpose |
|---|---|---|
| `events` | `Stream<ListRealtimeEventModel>` | Emits parsed events for all subscribed lists |
| `resyncRequests` | `Stream<String>` | Emits a `listId` when a REST resync is required (parse error, disconnect, reconnect) |

### Reconnect behaviour

- `reconnectDelay` is set to 3 seconds.
- On reconnect (`onConnect`), all active subscriptions are re-attached and a resync is requested for each.
- On disconnect / WebSocket error / STOMP error, a resync is requested for all active subscriptions via `resyncRequests`.

### Integration with `ListDetailProvider`

`ListDetailProvider` subscribes via `_startRealtimeForList(listId)` after loading the list:

1. Calls `realtimeSyncService.subscribeToList(listId)`.
2. Listens to `events` stream and applies `_applyRealtimeEvent(event)`.
3. Listens to `resyncRequests` stream and calls `loadList(id)` (full REST refresh).
4. On `dispose()`, calls `unsubscribeFromList(listId)` and cancels both subscriptions.

## UI State Update Logic

`ListDetailProvider._applyRealtimeEvent()` handles each event type:

1. `ITEM_ADDED`: appends `item` to the list if not already present (deduplication by `id`)
2. `ITEM_UPDATED`: finds item by `id` and replaces it; if not found, triggers full REST resync
3. `ITEM_DELETED`: removes item by `id`; if not found, no-op
4. **Unknown `eventType`**: triggers full REST resync via `loadList()`

All state changes call `notifyListeners()` so the UI rebuilds immediately without waiting for a round-trip.

## Minimal Integration Sequence

1. Login and store JWT.
2. Load list screen using REST `GET /api/v1/lists/{id}`.
3. `ListDetailProvider.loadList(listId)` calls `_startRealtimeForList(listId)` automatically.
4. `RealtimeSyncService.subscribeToList(listId)` calls `ensureConnected()` then subscribes.
5. STOMP CONNECT sends `Authorization: Bearer <jwt>` in headers.
6. Subscribe to `/topic/lists/{listId}`.
7. Events flow through `events` stream → `_applyRealtimeEvent()` → `notifyListeners()`.
8. On disconnect/error, `resyncRequests` stream triggers a full REST reload.

## Paste-Ready Prompt For Copilot In Flutter Project

```md
The ShareCart realtime service is implemented in lib/services/realtime_sync_service.dart.

Backend contract:
- WebSocket endpoint: /ws
- STOMP CONNECT header required: Authorization: Bearer <jwt>
- Subscribe destination: /topic/lists/{listId}
- Event types: ITEM_ADDED, ITEM_UPDATED, ITEM_DELETED
- Event payload fields: eventType, listId, item (typed as ItemModel), occurredAt

Implemented classes:
- RealtimeSyncService: ensureConnected(), subscribeToList(), unsubscribeFromList(), dispose()
  - Stream<ListRealtimeEventModel> events
  - Stream<String> resyncRequests
- ListRealtimeEventModel: fromJson parses item as ItemModel
- ListDetailProvider: calls _startRealtimeForList(), applies events via _applyRealtimeEvent()

When extending:
1. Add new event types to the switch in ListDetailProvider._applyRealtimeEvent().
2. The default case already triggers a full REST resync as a safe fallback.
3. RealtimeSyncService is provided at the root via Provider and injected into ListDetailProvider.
```
