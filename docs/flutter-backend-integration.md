# ShareCart Spring Boot Backend Guide For Flutter

## Purpose

This document explains the current Spring Boot backend so a separate Flutter mobile application can integrate with it correctly. It is written to help GitHub Copilot generate Flutter code that matches the backend's real API contract, data model, and behavior.

The backend is a REST API for a shared shopping list application.

It currently supports these core flows:

- Create a shopping list
- Fetch a shopping list by ID
- Invite a user to a shopping list
- Add an item to a shopping list
- Update an item
- Delete an item

It does not currently support:

- Authentication or authorization
- Login or signup APIs
- Fetch all shopping lists
- Fetch all items
- Delete shopping lists
- Fetch an item by ID

That means the Flutter app should be designed around the APIs that already exist instead of assuming a full user/account platform is available.

---

## Backend Stack

- Java 21
- Spring Boot 4.0.4
- Spring Web MVC
- Spring Data JPA
- Hibernate 7
- PostgreSQL
- UUID-based identifiers
- JSON request and response payloads

---

## Architecture

The backend follows a layered Spring Boot architecture:

```text
Controller -> Service -> Repository -> Database
```

Key modules in the backend:

- `shoppinglist`
- `item`
- `user`
- `common.exception`

The mobile app only interacts with the REST controllers. Business rules are enforced in the service layer.

---

## Local Base URL

Use the following base URLs depending on where the Flutter app runs.

- Android emulator: `http://10.0.2.2:8080/api/v1`
- iOS simulator: `http://127.0.0.1:8080/api/v1`
- Flutter web on the same machine: `http://localhost:8080/api/v1`
- Physical device: `http://<your-local-ip>:8080/api/v1`

Example:

```text
http://10.0.2.2:8080/api/v1/lists
```

---

## Core Backend Behavior

These are the most important rules for the Flutter app.

- All IDs are UUID strings
- `GET /lists/{id}` is the main read endpoint because it returns list details, items, and members together
- `PUT /items/{id}` behaves like a partial update even though it uses PUT
- Creating a list with `ownerId` automatically adds that user as a member with role `OWNER`
- Inviting the same user twice returns `409 Conflict`
- Adding an item always starts with `isCompleted = false`
- `createdBy` on an item is optional
- `ownerId` on a list is optional
- If `createdBy` or `ownerId` is provided, that user must already exist in the backend database
- There is no list-discovery endpoint, so the Flutter app should store known list IDs locally if it wants a home screen with previously opened lists

---

## Data Models Returned By The Backend

### ShoppingListResponse

```json
{
  "id": "22222222-2222-2222-2222-222222222222",
  "name": "Weekend Groceries",
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "ownerName": "Paul",
  "items": [],
  "members": [],
  "createdAt": "2026-03-21T22:00:00",
  "updatedAt": "2026-03-21T22:00:00"
}
```

Fields:

- `id`: UUID
- `name`: string
- `ownerId`: UUID or null
- `ownerName`: string or null
- `items`: array of `ItemResponse`
- `members`: array of `MemberResponse`
- `createdAt`: ISO local date-time string
- `updatedAt`: ISO local date-time string

### ItemResponse

```json
{
  "id": "44444444-4444-4444-4444-444444444444",
  "listId": "22222222-2222-2222-2222-222222222222",
  "name": "Milk",
  "quantity": "2",
  "isCompleted": false,
  "category": "Dairy",
  "createdBy": "11111111-1111-1111-1111-111111111111",
  "createdAt": "2026-03-21T22:05:00",
  "updatedAt": "2026-03-21T22:05:00"
}
```

Fields:

- `id`: UUID
- `listId`: UUID
- `name`: string
- `quantity`: string or null
- `isCompleted`: boolean
- `category`: string or null
- `createdBy`: UUID or null
- `createdAt`: ISO local date-time string
- `updatedAt`: ISO local date-time string

### MemberResponse

```json
{
  "userId": "11111111-1111-1111-1111-111111111111",
  "name": "Paul",
  "email": "paul@example.com",
  "role": "OWNER",
  "joinedAt": "2026-03-21T22:00:00"
}
```

Fields:

- `userId`: UUID
- `name`: string or null
- `email`: string
- `role`: string
- `joinedAt`: ISO local date-time string

---

## API Endpoints

## 1. Create Shopping List

Endpoint:

```text
POST /api/v1/lists
```

Request body:

```json
{
  "name": "Weekend Groceries",
  "ownerId": "11111111-1111-1111-1111-111111111111"
}
```

Rules:

- `name` is required
- `ownerId` is optional
- if `ownerId` is present, the user must exist
- if `ownerId` is present, the backend automatically creates a list member with role `OWNER`

Success:

- Status: `201 Created`
- Response body: `ShoppingListResponse`
- Response also includes a `Location` header pointing to `/api/v1/lists/{id}`

Example response:

```json
{
  "id": "22222222-2222-2222-2222-222222222222",
  "name": "Weekend Groceries",
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "ownerName": "Paul",
  "items": [],
  "members": [
    {
      "userId": "11111111-1111-1111-1111-111111111111",
      "name": "Paul",
      "email": "paul@example.com",
      "role": "OWNER",
      "joinedAt": "2026-03-21T22:00:00"
    }
  ],
  "createdAt": "2026-03-21T22:00:00",
  "updatedAt": "2026-03-21T22:00:00"
}
```

Flutter implications:

- After creating a list, store the returned `id`
- Navigate to the list details screen using that ID
- Because there is no `GET /lists` endpoint, storing created list IDs locally is useful

## 2. Get Shopping List By ID

Endpoint:

```text
GET /api/v1/lists/{id}
```

Example:

```text
GET /api/v1/lists/22222222-2222-2222-2222-222222222222
```

Success:

- Status: `200 OK`
- Response body: `ShoppingListResponse`

This endpoint returns:

- list metadata
- all current items in the list
- all current members in the list

Flutter implications:

- Use this as the main source of truth for the list details page
- Refresh this endpoint after creating items, updating items, deleting items, or inviting members

## 3. Invite User To List

Endpoint:

```text
POST /api/v1/lists/{id}/invite
```

Request body:

```json
{
  "userId": "33333333-3333-3333-3333-333333333333",
  "role": "MEMBER"
}
```

Rules:

- `userId` is required
- `role` is optional
- if `role` is missing or blank, backend defaults it to `MEMBER`
- backend uppercases the role value
- if the user is already a member of the list, backend returns `409 Conflict`

Success:

- Status: `200 OK`
- Empty response body

Flutter implications:

- After a successful invite, call `GET /lists/{id}` again to refresh members
- Handle `409` by showing a clear message like "User is already a member of this list"

## 4. Add Item To List

Endpoint:

```text
POST /api/v1/lists/{listId}/items
```

Request body:

```json
{
  "name": "Milk",
  "quantity": "2",
  "category": "Dairy",
  "createdBy": "11111111-1111-1111-1111-111111111111"
}
```

Rules:

- `name` is required
- `quantity` is optional
- `category` is optional
- `createdBy` is optional
- if `createdBy` is present, that user must exist
- backend sets `isCompleted` to `false` when the item is created

Success:

- Status: `201 Created`
- Response body: `ItemResponse`
- Response also includes a `Location` header pointing to `/api/v1/items/{id}`

Example response:

```json
{
  "id": "44444444-4444-4444-4444-444444444444",
  "listId": "22222222-2222-2222-2222-222222222222",
  "name": "Milk",
  "quantity": "2",
  "isCompleted": false,
  "category": "Dairy",
  "createdBy": "11111111-1111-1111-1111-111111111111",
  "createdAt": "2026-03-21T22:05:00",
  "updatedAt": "2026-03-21T22:05:00"
}
```

Flutter implications:

- You can either append the created item locally or refetch the list
- Refetching with `GET /lists/{id}` is the safest approach because it matches the backend source of truth

## 5. Update Item

Endpoint:

```text
PUT /api/v1/items/{id}
```

Request body:

```json
{
  "name": "Milk",
  "quantity": "3",
  "isCompleted": true,
  "category": "Dairy"
}
```

Rules:

- all request fields are optional
- only provided fields are updated
- despite using PUT, the backend behaves like a partial update endpoint
- this endpoint is suitable for toggling completion status by sending only `isCompleted`

Success:

- Status: `200 OK`
- Response body: `ItemResponse`

Example response:

```json
{
  "id": "44444444-4444-4444-4444-444444444444",
  "listId": "22222222-2222-2222-2222-222222222222",
  "name": "Milk",
  "quantity": "3",
  "isCompleted": true,
  "category": "Dairy",
  "createdBy": "11111111-1111-1111-1111-111111111111",
  "createdAt": "2026-03-21T22:05:00",
  "updatedAt": "2026-03-21T22:06:00"
}
```

Flutter implications:

- Use this endpoint for both edit-item flows and simple complete/incomplete toggles
- After a successful update, either patch local state or refetch the list details

## 6. Delete Item

Endpoint:

```text
DELETE /api/v1/items/{id}
```

Success:

- Status: `204 No Content`

Flutter implications:

- Remove the item locally after success or refetch the parent list

---

## Validation And Error Format

The backend uses centralized exception handling and returns JSON for common failures.

### 400 Validation Error

Example:

```json
{
  "timestamp": "2026-03-21T22:10:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "details": {
    "name": "Item name is required"
  }
}
```

Use this for field-level form errors in Flutter.

### 404 Not Found

Example:

```json
{
  "timestamp": "2026-03-21T22:10:00Z",
  "status": 404,
  "error": "Not Found",
  "message": "Shopping list not found with id: ..."
}
```

Use this when a list, item, or user ID does not exist.

### 409 Conflict

Example:

```json
{
  "timestamp": "2026-03-21T22:10:00Z",
  "status": 409,
  "error": "Conflict",
  "message": "User is already a member of this list"
}
```

Use this for business-rule conflicts such as duplicate membership.

Recommended Flutter error mapping:

- `400` -> validation or user input error
- `404` -> missing list, item, or user
- `409` -> duplicate member or business conflict
- `500` -> unexpected backend failure

---

## Recommended Flutter Features Based On Current Backend

These screens fit the current API well.

- Create List screen
- List Details screen
- Add Item bottom sheet or page
- Edit Item page or dialog
- Invite Member sheet or page

These features are not fully supported by the current backend without adding more APIs.

- Login screen
- Signup screen
- My Lists screen that loads all lists for a user from backend
- User search screen backed by an API

---

## Recommended Flutter State Flow

Suggested flow:

1. User enters list name and optional owner UUID
2. App calls `POST /lists`
3. App stores returned `listId`
4. App navigates to list details
5. List details screen calls `GET /lists/{id}`
6. Add item uses `POST /lists/{listId}/items`
7. Toggle completed uses `PUT /items/{id}` with `isCompleted`
8. Edit item uses `PUT /items/{id}`
9. Delete item uses `DELETE /items/{id}`
10. Invite member uses `POST /lists/{id}/invite`
11. After each write operation, refresh `GET /lists/{id}` or update local state carefully

---

## Recommended Flutter Models

Create these Dart models:

- `ShoppingListModel`
- `ItemModel`
- `MemberModel`
- `ApiErrorModel`

Recommendations:

- represent UUID values as `String`
- parse timestamps with `DateTime.parse(...)`
- make nullable backend fields nullable in Dart models

Suggested field mapping:

### ShoppingListModel

- `String id`
- `String name`
- `String? ownerId`
- `String? ownerName`
- `List<ItemModel> items`
- `List<MemberModel> members`
- `DateTime createdAt`
- `DateTime updatedAt`

### ItemModel

- `String id`
- `String listId`
- `String name`
- `String? quantity`
- `bool isCompleted`
- `String? category`
- `String? createdBy`
- `DateTime createdAt`
- `DateTime updatedAt`

### MemberModel

- `String userId`
- `String? name`
- `String email`
- `String role`
- `DateTime joinedAt`

### ApiErrorModel

- `DateTime? timestamp`
- `int status`
- `String error`
- `String message`
- `Map<String, dynamic>? details`

---

## Recommended Flutter Service Layer

Copilot should generate a service layer similar to this:

- `ApiClient`
- `ShoppingListApiService`
- `ItemApiService`
- optional repository layer on top of the API layer

Recommended methods:

```dart
Future<ShoppingListModel> createList(String name, {String? ownerId});
Future<ShoppingListModel> getListById(String listId);
Future<void> inviteUser(String listId, String userId, {String? role});
Future<ItemModel> addItem(String listId, CreateItemRequest request);
Future<ItemModel> updateItem(String itemId, UpdateItemRequest request);
Future<void> deleteItem(String itemId);
```

Good Flutter technology choices for this app:

- `dio` or `http` for REST calls
- `freezed` and `json_serializable` if you want strong typed models
- Riverpod, Bloc, or Provider for state management

---

## Practical UX Guidance For The Mobile App

Because the backend has no auth and no list-discovery endpoint, a practical first version of the mobile app should do the following:

- create a list
- persist the list ID locally using local storage
- reopen known lists by ID
- allow adding, editing, completing, and deleting items inside a known list
- allow inviting members using existing backend user UUIDs

If a future backend adds authentication and list discovery, the Flutter app can later add:

- login
- per-user home dashboard
- list history synced from backend
- user search and invite flows backed by real search APIs

---

## Paste-Ready Copilot Context For The Flutter Project

You can copy the section below into the Flutter project's own Copilot instructions.

```md
This Flutter app is a mobile client for an existing Spring Boot REST API backend called ShareCart.

Backend base URL:
- Android emulator: http://10.0.2.2:8080/api/v1
- iOS simulator: http://127.0.0.1:8080/api/v1
- Physical device: use the local network IP of the backend machine

Backend purpose:
- Shared shopping list app
- Users can create shopping lists, invite members, add items, update items, and delete items

Important backend constraints:
- No authentication is implemented
- No signup/login endpoints exist
- No endpoint exists to fetch all lists
- No endpoint exists to fetch all items
- The app should rely on GET /lists/{id} as the primary read endpoint
- UUIDs are used for all ids and should be represented as String in Flutter
- Timestamps are ISO date strings and should be parsed into DateTime

Endpoints:
1. POST /lists
Request:
{
  "name": "Weekend Groceries",
  "ownerId": "optional-user-uuid"
}
Response: ShoppingListResponse
Behavior:
- name is required
- ownerId is optional
- if ownerId is provided, the owner must exist
- if ownerId is provided, backend automatically adds that user as OWNER member

2. GET /lists/{id}
Response: ShoppingListResponse containing:
- list metadata
- items
- members

3. POST /lists/{id}/invite
Request:
{
  "userId": "required-user-uuid",
  "role": "optional role"
}
Behavior:
- role defaults to MEMBER if missing or blank
- duplicate invite returns 409 Conflict

4. POST /lists/{listId}/items
Request:
{
  "name": "Milk",
  "quantity": "2",
  "category": "Dairy",
  "createdBy": "optional-user-uuid"
}
Response: ItemResponse
Behavior:
- name is required
- quantity/category/createdBy are optional
- isCompleted defaults to false

5. PUT /items/{id}
Request fields are all optional:
{
  "name": "Milk",
  "quantity": "3",
  "isCompleted": true,
  "category": "Dairy"
}
Behavior:
- backend only updates provided fields

6. DELETE /items/{id}
Response: 204 No Content

ShoppingListResponse:
- id: String
- name: String
- ownerId: String?
- ownerName: String?
- items: List<ItemModel>
- members: List<MemberModel>
- createdAt: DateTime
- updatedAt: DateTime

ItemResponse:
- id: String
- listId: String
- name: String
- quantity: String?
- isCompleted: bool
- category: String?
- createdBy: String?
- createdAt: DateTime
- updatedAt: DateTime

MemberResponse:
- userId: String
- name: String?
- email: String
- role: String
- joinedAt: DateTime

Error handling:
- 400 validation error returns JSON with a details map
- 404 not found returns JSON with a message
- 409 conflict returns JSON with a message

When generating Flutter code:
- create typed models for ShoppingList, Item, Member, and API errors
- create API service classes for list and item operations
- use GET /lists/{id} after create, invite, add, update, or delete to refresh state
- build screens for create list, list details, add item, edit item, invite member
- do not generate auth/token logic unless explicitly requested
- do not assume there is an endpoint to load all lists
```

---

## Source Of Truth In This Backend

These backend files define the behavior described in this document:

- `src/main/java/com/sharecart/sharecart/shoppinglist/controller/ShoppingListController.java`
- `src/main/java/com/sharecart/sharecart/item/controller/ItemController.java`
- `src/main/java/com/sharecart/sharecart/shoppinglist/service/impl/ShoppingListServiceImpl.java`
- `src/main/java/com/sharecart/sharecart/item/service/impl/ItemServiceImpl.java`
- `src/main/java/com/sharecart/sharecart/common/exception/GlobalExceptionHandler.java`
