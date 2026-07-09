# ShareCart AI Service: Flutter Integration and Implementation Details

## 1. What This API Is For

The ShareCart AI Service is a stateless FastAPI microservice that does one job:
- Accept grocery receipt or shelf price-tag images from Flutter
- Extract grocery items and prices using image preprocessing + OpenAI vision
- Return structured JSON back to Flutter for user confirmation

This service does not:
- Implement login
- Manage users
- Persist data to a database
- Replace business authorization from Spring Boot

Primary deployed base URL:
- https://sharecart-ai-services.onrender.com

## 2. End-to-End System Placement

Current ShareCart architecture:
- Flutter app captures image from camera
- Flutter sends image + existing JWT token to this AI service
- AI service validates JWT locally (shared secret with Spring Boot)
- AI service returns extracted items to Flutter
- Flutter shows extracted items to user for review/edit
- Flutter sends extracted text to Spring Boot capture API and confirmed items to Spring Boot confirm API for persistence

So the runtime flow is:
- Image source: Flutter
- Extraction response consumer: Flutter
- Final storage and business workflows: Spring Boot

## 2.1 OCR Replacement Decision (Important)

This integration is a replacement of the current on-device OCR path in Flutter.

What is being replaced:
- Existing Flutter OCR using google_mlkit_text_recognition in the price-capture flow

What replaces it:
- Flutter uploads the image to this ShareCart AI service
- This service performs image preprocessing + OpenAI-based extraction
- Flutter receives structured grocery items/prices and presents them for user confirmation

Expected Flutter changes:
- Keep image capture UI as camera-based capture (current implementation)
- Remove ML Kit OCR extraction logic from runtime flow
- Call POST /api/v1/receipt/extract with multipart image + scanType
- Continue to send user-confirmed final data to Spring Boot APIs for persistence

Scope note:
- Authentication source remains Spring Boot JWT
- AI service is extraction-only and does not replace Spring Boot business APIs

## 3. Detailed Request/Response Flow (Flutter <-> AI API)

### 3.1 Request sent by Flutter

Endpoint:
- POST /api/v1/receipt/extract

Primary production request URL:
- POST https://sharecart-ai-services.onrender.com/api/v1/receipt/extract

Headers:
- Authorization: Bearer <jwt>

Body type:
- multipart/form-data

Fields:
- image (required): jpg, jpeg, png, or webp only
- scanType (required): RECEIPT or PRICE_TAG
- latitude (optional)
- longitude (optional)

Hard limits and validation:
- Maximum file size: 10 MB
- Invalid extension -> 422
- Corrupt/non-image file -> 422
- Oversized file -> 413
- Missing or invalid JWT -> 401
- Rate limit exceeded -> 429

### 3.2 Processing done inside API

For each request, the service executes this sequence:
1. Generate request context (request id)
2. Authenticate using JWT bearer token
3. Enforce per-user rate limits using userId from JWT
4. Validate file extension and size
5. Validate file can be decoded as an image
6. Preprocess image in memory:
   - resize large image
   - deskew
   - contrast enhancement
   - brightness normalization
   - likely receipt-region crop
7. Send processed image + grocery-specific prompt to OpenAI model
8. Parse and validate JSON response
9. Return structured response to Flutter

No temporary image storage is kept for business use.

### 3.3 Response returned to Flutter

Success response shape:

{
  "success": true,
  "storeName": "Walmart",
  "confidence": 0.93,
  "scanType": "RECEIPT",
  "items": [
    {
      "name": "Whole Milk",
      "price": 4.89,
      "quantity": "1",
      "unit": "gallon",
      "confidence": 0.96
    }
  ]
}

Failure response shape (consistent across handled errors):

{
  "success": false,
  "message": "Unable to confidently extract grocery items"
}

Common error statuses Flutter should handle:
- 401: invalid or expired JWT
- 413: file too large
- 422: validation error / invalid image
- 429: rate limit exceeded
- 500: AI processing failure or timeout

### 3.4 Current Flutter persistence flow after AI extraction

After extraction succeeds, the current Flutter app calls Spring Boot endpoints in this order:
1. POST /api/v1/prices/capture
  - Sent once to capture extracted raw text and receive captureId.
2. POST /api/v1/prices/confirm
  - Sent once per valid item in a loop when user taps confirm.
  - Request body fields: captureId, itemName, price, unit, storeName, latitude (optional), longitude (optional).
3. POST /api/v1/prices/compare
  - Sent on the last confirmed item to show cheapest/best-known price feedback.

### 3.5 How confirmed item prices are saved (exact behavior)

Confirmed item prices are saved through POST /api/v1/prices/confirm.

Current Flutter request payload to /api/v1/prices/confirm:

{
  "captureId": "<capture-id-from-prices-capture>",
  "itemName": "Whole Milk",
  "price": 4.89,
  "unit": "1 gallon",
  "storeName": "Walmart",
  "latitude": 12.9716,
  "longitude": 77.5946
}

Notes:
- latitude and longitude are included only when location is available.
- The Flutter app sends one /prices/confirm call per valid item (not a bulk payload).
- createdBy is not passed in this request body by Flutter; Spring Boot should derive it from JWT.

Other Spring Boot APIs in this flow and whether they save confirmed prices:
- POST /api/v1/prices/capture: used to store extraction summary/raw text and return captureId. It is not the confirmed-price save call.
- POST /api/v1/prices/compare: used for price comparison response. It is not a confirmed-price save call.

Conclusion:
- In the current Flutter implementation, confirmed prices are saved via /api/v1/prices/confirm only.

## 4. JWT Reuse with Spring Boot

This AI service reuses your existing Spring Boot JWT ecosystem.

How it works:
- Flutter already has JWT from Spring Boot login flow
- Flutter sends same token to AI service
- AI service validates token locally using shared JWT_SECRET and HS256
- Token claims extracted: userId, email, exp

Why this design:
- No extra network call to Spring Boot for token introspection
- Lower latency
- No duplicate auth system
- Same auth boundary across services

## 5. Security and Abuse Protection

Implemented controls:
- Bearer JWT authentication for extraction endpoint
- Signature and expiration validation
- Claim presence checks
- Per-user in-memory rate limiting
  - 10 scans/hour
  - 50 scans/day
- Input validation and size limits
- Controlled error responses

Logging safety:
- Logs request id, user id, processing time, image byte size, scan type, confidence, failures
- Does not log JWT value
- Does not log image content

## 6. Grocery Extraction Behavior

Prompt and output are tuned for grocery use:
- Focus on item names and item-level prices
- Ignore subtotal, taxes, discounts, coupons, totals, transaction metadata
- Handle shelf pricing patterns such as:
  - 2 for $7
  - $3.99 each
  - member price
  - $0.29 / oz
- Use conservative confidence behavior for partially visible labels
- Avoid hallucination
- Return JSON only

## 7. What Was Implemented (Change Summary)

### 7.1 New core application modules
- app/main.py
- app/config/settings.py
- app/api/health_routes.py
- app/api/receipt_routes.py
- app/middleware/request_context.py
- app/middleware/auth_middleware.py
- app/middleware/rate_limit.py
- app/security/jwt_validator.py
- app/services/image_preprocessing_service.py
- app/services/openai_extraction_service.py
- app/services/extraction_service.py
- app/models/request_models.py
- app/models/response_models.py
- app/models/auth_models.py
- app/prompts/grocery_extraction_prompt.py
- app/utils/image_utils.py

### 7.2 Quality and operations files
- app/tests/test_auth.py
- app/tests/test_receipt_extraction.py
- app/tests/test_rate_limit.py
- requirements.txt
- Dockerfile
- .env.example
- .env
- .gitignore
- .dockerignore
- scripts/smoke_test.sh
- .github/workflows/ci.yml
- README.md (expanded)

### 7.3 Health and readiness
- GET /health
- GET /ready

### 7.4 Verified test status
- pytest app/tests -q
- Result: all tests passing

## 8. How Flutter Team Should Integrate

Flutter integration contract:
1. Keep using Spring Boot login as-is.
2. Pass same JWT in Authorization header to AI endpoint.
3. Send image as multipart with scanType.
4. On success, show extracted items for user confirmation.
5. After user confirms/edits, send final payload to Spring Boot /api/v1/prices/confirm (one request per valid item in current Flutter implementation).
6. Handle AI endpoint error statuses gracefully:
   - Retry suggestion for 500/timeout
   - User message for 429 with backoff
   - Re-login flow for 401

## 9. Operational Notes

- For production, set JWT_SECRET exactly to Spring Boot secret.
- Set OPENAI_API_KEY in environment.
- In-memory rate limits are suitable for MVP and single-instance deployment.
- For multi-instance scaling, replace limiter storage with Redis while keeping limiter interface intact.

## 10. Quick Reference Commands

Run API locally:
- uvicorn app.main:app --reload

Run tests:
- pytest app/tests -q

Run smoke test with real token and image:
- API_URL=https://sharecart-ai-services.onrender.com JWT_TOKEN=<token> IMAGE_PATH=/path/to/image.jpg SCAN_TYPE=RECEIPT ./scripts/smoke_test.sh

Optional local override:
- API_URL=http://localhost:8000 JWT_TOKEN=<token> IMAGE_PATH=/path/to/image.jpg SCAN_TYPE=RECEIPT ./scripts/smoke_test.sh
