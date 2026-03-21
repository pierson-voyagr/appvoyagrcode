# ComplyCube Backend Integration Guide

This document explains how to set up a backend service to perform ComplyCube verification checks and retrieve results.

## Overview

After users complete the ComplyCube verification flow in the mobile app, you need a backend service to:
1. Trigger verification checks (Document Check, Identity Check)
2. Receive webhook notifications when checks complete
3. Update user verification status in Firebase

## What Happens After User Verification

When a user completes verification in the app, the following data is stored in Firestore:

```javascript
{
  "complycubeClientId": "client_id",
  "complycubeDocumentIds": ["doc_id_1"],
  "complycubeLivePhotoIds": ["photo_id_1"],
  "verificationStatus": "pending",
  "verificationStartedAt": timestamp
}
```

## Backend Service Requirements

You should create a backend service (Node.js, Python, PHP, etc.) to handle:

### 1. Triggering Verification Checks

When you receive notification that a user completed verification (via Firestore triggers or Cloud Functions), trigger the appropriate checks:

#### Document Check

Verifies the authenticity of the uploaded ID document.

```bash
curl -X POST https://api.complycube.com/v1/checks \
     -H 'Authorization: YOUR_API_KEY' \
     -H 'Content-Type: application/json' \
     -d '{
          "clientId": "CLIENT_ID",
          "type": "document_check",
          "documentId": "DOCUMENT_ID"
        }'
```

#### Identity Check

Performs face matching between the ID document and the selfie, plus liveness detection.

```bash
curl -X POST https://api.complycube.com/v1/checks \
     -H 'Authorization: YOUR_API_KEY' \
     -H 'Content-Type: application/json' \
     -d '{
          "clientId": "CLIENT_ID",
          "type": "identity_check",
          "documentId": "DOCUMENT_ID",
          "livePhotoId": "LIVE_PHOTO_ID"
        }'
```

### 2. Setting Up Webhooks

ComplyCube can notify your backend when checks complete. Set up webhooks in your ComplyCube dashboard:

1. Go to Settings > Webhooks
2. Add your webhook URL (e.g., `https://yourbackend.com/webhooks/complycube`)
3. Subscribe to these events:
   - `check.completed` - When a check finishes
   - `check.pending` - When a check needs manual review

#### Webhook Payload Example

```json
{
  "event": "check.completed",
  "payload": {
    "id": "check_id",
    "clientId": "client_id",
    "type": "identity_check",
    "outcome": "clear", // or "attention", "rejected"
    "completedAt": "2024-01-15T10:30:00Z"
  }
}
```

### 3. Retrieving Check Results

Retrieve the results of a specific check:

```bash
curl -X GET https://api.complycube.com/v1/checks/CHECK_ID \
     -H 'Authorization: YOUR_API_KEY'
```

Response:

```json
{
  "id": "check_id",
  "clientId": "client_id",
  "type": "identity_check",
  "outcome": "clear",
  "status": "complete",
  "breakdown": {
    "documentValidation": "clear",
    "faceMatching": "clear",
    "livenessDetection": "clear"
  }
}
```

## Firebase Cloud Functions Example

Here's an example Firebase Cloud Function (Node.js) that triggers checks when a user completes verification:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

const COMPLYCUBE_API_KEY = functions.config().complycube.api_key;
const COMPLYCUBE_BASE_URL = 'https://api.complycube.com/v1';

// Trigger when user verification data is added
exports.onVerificationSubmitted = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Check if verification was just submitted
    if (newData.verificationStatus === 'pending' &&
        previousData.verificationStatus !== 'pending') {

      const userId = context.params.userId;
      const clientId = newData.complycubeClientId;
      const documentIds = newData.complycubeDocumentIds || [];
      const livePhotoIds = newData.complycubeLivePhotoIds || [];

      try {
        // Trigger Document Check
        if (documentIds.length > 0) {
          await axios.post(`${COMPLYCUBE_BASE_URL}/checks`, {
            clientId: clientId,
            type: 'document_check',
            documentId: documentIds[0]
          }, {
            headers: {
              'Authorization': COMPLYCUBE_API_KEY,
              'Content-Type': 'application/json'
            }
          });
        }

        // Trigger Identity Check (document + face matching)
        if (documentIds.length > 0 && livePhotoIds.length > 0) {
          const response = await axios.post(`${COMPLYCUBE_BASE_URL}/checks`, {
            clientId: clientId,
            type: 'identity_check',
            documentId: documentIds[0],
            livePhotoId: livePhotoIds[0]
          }, {
            headers: {
              'Authorization': COMPLYCUBE_API_KEY,
              'Content-Type': 'application/json'
            }
          });

          // Store the check ID
          await admin.firestore().collection('users').doc(userId).update({
            complycubeCheckId: response.data.id,
            verificationStatus: 'processing'
          });
        }

        console.log(`Verification checks triggered for user ${userId}`);
      } catch (error) {
        console.error('Error triggering verification checks:', error);
        await admin.firestore().collection('users').doc(userId).update({
          verificationStatus: 'error',
          verificationError: error.message
        });
      }
    }
  });

// Webhook endpoint to receive ComplyCube notifications
exports.complycubeWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;

    if (event.event === 'check.completed') {
      const checkId = event.payload.id;
      const clientId = event.payload.clientId;
      const outcome = event.payload.outcome; // 'clear', 'attention', or 'rejected'

      // Find the user with this clientId
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('complycubeClientId', '==', clientId)
        .limit(1)
        .get();

      if (!usersSnapshot.empty) {
        const userDoc = usersSnapshot.docs[0];

        // Update verification status based on outcome
        let verificationStatus = 'rejected';
        if (outcome === 'clear') {
          verificationStatus = 'verified';
        } else if (outcome === 'attention') {
          verificationStatus = 'review'; // Needs manual review
        }

        await userDoc.ref.update({
          verificationStatus: verificationStatus,
          verificationCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
          complycubeCheckOutcome: outcome
        });

        console.log(`Updated verification status for client ${clientId}: ${verificationStatus}`);
      }
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).send('Error');
  }
});
```

## Deployment Steps

1. **Set up Firebase Cloud Functions**:
   ```bash
   firebase init functions
   cd functions
   npm install axios
   ```

2. **Set the ComplyCube API key**:
   ```bash
   firebase functions:config:set complycube.api_key="YOUR_API_KEY"
   ```

3. **Deploy the functions**:
   ```bash
   firebase deploy --only functions
   ```

4. **Configure the webhook in ComplyCube dashboard**:
   - URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/complycubeWebhook`
   - Events: `check.completed`, `check.pending`

## Security Considerations

1. **Webhook Signature Verification**: ComplyCube signs webhook requests. Verify signatures before processing.
2. **API Key Security**: Store API keys in environment variables, never in code.
3. **Rate Limiting**: Implement rate limiting on webhook endpoints.
4. **Data Privacy**: Store only necessary verification data, comply with GDPR/privacy laws.
5. **Error Handling**: Implement retry logic for failed API calls.

## Verification Status Flow

```
pending → processing → verified/review/rejected
```

- **pending**: User submitted documents, checks not yet triggered
- **processing**: Checks are running
- **verified**: All checks passed (outcome: clear)
- **review**: Needs manual review (outcome: attention)
- **rejected**: Checks failed (outcome: rejected)

## Testing

Use ComplyCube's test mode:
1. Get a test API key from ComplyCube dashboard
2. Use test documents from ComplyCube docs
3. Verify webhooks are working correctly
4. Test all verification outcomes (clear, attention, rejected)

## Monitoring

Set up monitoring for:
- Failed verification checks
- Webhook delivery failures
- Users stuck in "processing" status
- Average verification completion time

## Support

For ComplyCube API issues:
- API Docs: https://docs.complycube.com/
- Support: support@complycube.com
- Dashboard: https://portal.complycube.com/
