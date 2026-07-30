You are working on an existing Flutter application called ShareCart.

The project already follows a layered architecture consisting of:

Models
API Services
Repository (if applicable)
Providers (State Management)
UI Screens

Maintain the existing architecture, naming conventions, coding style, dependency injection, navigation, and state management patterns.

Do NOT rewrite the application.

Refactor only the price confirmation workflow.

Current Implementation

The application currently:

Calls the AI Service.
Receives extracted grocery items.
Displays a confirmation screen.
Loops through every confirmed item.
Sends one HTTP request per grocery item.

This implementation must be removed.

New Backend API

The backend now exposes only one endpoint:

POST /api/v1/prices/confirm

Flutter must make exactly ONE API call regardless of whether:

one shelf price was scanned
an entire grocery receipt was scanned

Flutter must never perform multiple POST requests.

New Request Model

Create a request DTO named:

ConfirmPricesRequest

The request body must be:

{
  "captureId": "CAP-12345",
  "scanType": "RECEIPT",
  "store": {
    "name": "Walmart",
    "address": null,
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "items": [
    {
      "itemName": "Whole Milk",
      "price": 4.89,
      "quantity": 1,
      "unit": "gallon",
      "confidence": 0.98,
      "edited": false
    },
    {
      "itemName": "Eggs",
      "price": 3.49,
      "quantity": 1,
      "unit": "12 count",
      "confidence": 0.94,
      "edited": true
    }
  ]
}

The items field must ALWAYS be a list.

Even a single grocery item should be sent as a list containing one object.

Important Design Rule

Flutter does NOT know about store IDs.

Flutter does NOT resolve stores.

Flutter does NOT create stores.

Flutter simply sends the store information observed during the scan.

The Spring Boot backend is responsible for:

finding an existing store
creating a new store if necessary
generating the storeId
saving all confirmed prices

Flutter should remain completely unaware of this backend logic.

Required Flutter Changes
Create Models

Create the following models:

StoreInfo

Fields:

name
address
latitude
longitude

ConfirmPriceItem

Fields:

itemName
price
quantity
unit
confidence
edited

ConfirmPricesRequest

Fields:

captureId
scanType
store
items

Use the existing serialization approach used throughout the project.

Update API Service

Replace the existing method:

confirmPrice(...)

with

confirmPrices(ConfirmPricesRequest request)

Serialize the complete object and send one POST request.

Update Provider

Locate the provider responsible for confirming extracted grocery prices.

Remove the loop that submits one request per item.

Instead:

Collect all confirmed items.
Build a ConfirmPricesRequest.
Call confirmPrices() once.

The provider should not contain duplicate logic for:

receipt scans
single price scans

Both should follow the same code path.

Update Confirmation Screen

Keep all existing UI functionality.

The user must still be able to:

edit item name
edit price
edit quantity
edit unit
delete extracted items
manually add grocery items

When Confirm is pressed:

Collect every visible item.
Create one ConfirmPricesRequest.
Submit one API request.
Edited Flag

If the user changes:

name
price
quantity
unit

set:

edited = true

Otherwise:

edited = false

Confidence

Preserve the confidence returned by the AI service.

Do not calculate confidence in Flutter.

If confidence is unavailable, send null.

Validation

Prevent submission when:

no items exist
store name is empty
required price values are missing

Show validation errors using the project's existing UI components.

Error Handling

If the backend returns an error:

display one error dialog/snackbar
preserve all user edits
do not retry individual items
do not submit partial requests
Remove Legacy Code

Delete obsolete code related to:

one API call per item
old request DTOs
old confirmPrice() methods
loops that submit HTTP requests

The application should use only the new bulk confirmation workflow.

Testing Requirements

Verify:

Single shelf price confirmation
Multiple receipt items
Manual item addition
Item deletion
Item editing
Empty confirmation list
Network failure
Backend validation failure
Successful confirmation

The final implementation must make exactly one HTTP request regardless of the number of confirmed grocery items.

Use clean, maintainable, production-quality Flutter code that matches the existing project architecture.