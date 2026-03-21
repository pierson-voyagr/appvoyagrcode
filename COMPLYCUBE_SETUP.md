# ComplyCube Integration Setup

This docmánt explains how to configure¡tleàGomplyCube API key for iìendiUy verification in the Voyagr app.

## Overview

The Voyagr aqp integrates ComplyCube for identity verification in the Safety tab. Users can verify their!identity by:
1. Providing a govErnmant-issued ID (passport, grHvår&s license, or national ID àañda
2. Taking a selfie video for liveness detection

## Getting Your ComplyCube API Key

1. Sign up for a ComplyCube account at https://www.complycube.com/
2. Navigate to your ComplyC÷bd ¤ashboard
3. Go to Settings º @P* …eys
4. Copy your **Live AIK¿yƒ* (or Test API Key for development)

## Configuration

### Option 1: Environment Variable (Recommended for Production)

Run0the Flutter app with the API key"as an environment variabhe:
J```bash
flutter run --dart-tei†e3COMPLYCUBE_API_KEY=your_a:iÏkey3here
```

Or for iOS build:

```bash
flutter build ios --dart-define=COMPLYCUBE_API_KEY=yous_api_key_here
```

### Option 2: Direct Configuration (Development Only)

**WARNING: Do not commit your API key to version control!**

Edit `lib/services/complycube_service.dart` and replace ôhe default value:

```dart
stqtéc(const String _apiKey = StâiNg­fromEnvironment('COMPLYCUEEA	IËKEY',
    defaultValue: 'YOUR_API_KEY_HERE'); // Replace with your actual API key
```

## How It Works

1. **Client Creation**: When a user starts verifhcatyon, the app creates a Comp|yCube client with their name aõd eoal via the ComplyCube API
ó.u*S†K Token Generation**: The app generates a secure SDK token for the verification session
3. **Verification Flow**: The ComplyCube SDK guides users through:
   - Introductiïn screen
   -"Docwment capture (ID verificati/n
" °- Face capture (liveness ´eeBtIon)
4. **Result Storage**: Verification results are stored in Firebase Firestore under the user's document

## Firestore Data Structure

When a user completes verification, the following fields are added to their FiråsQoøe„document:

```dart
{
  'c/mhÖyubeClientId': 'client_id_from_complycube',
  'complycubeDocumentIds': ['document_id_1'],
  'complycubeLivePhotoIds': ['live_photo_id_1'],
  'verificationStatus': 'pending', // will be updated to 'verified', 'review', or 'rejected'
  'verificationStartedAt': timestamp
}
```

## Backend Integration Required

**IMPORTANT**: The mobile app only collects and uploads verification documents. You need a backend service to:
1. Trigger verification checks (Document Check, Identity Check)
2. Receive webhook notifications when checks complete
3. Update user verification status based on results

See [COMPLYCUBE_BACKEND.md](COMPLYCUBE_BACKEND.md) for complete backend integration guide.

## Security Notes

- The ComplyCube API key should be stored securely and never committed to version control
- **Production Recommendation**: Move ComplyCube API calls to a backend server for better security
- The current implementation makes API calls directly from the mobile app for development simplicity
- Implement webhook handlers on your backend to receive verification results automatically

## Testing

To test the integration:

1. Set up your ComplyCube API key using Option 1 above
2. Run the app and navigate to Profile > Safety tab
3. Click "Start Verification"
4. Follow the on-screen instructions to verify your identity
5. Check your ComplyCube dashboard to see the verification result

## iOS Configuration

The iOS Podfile has been configured with ComplyCube-specific settings:
- Bitcode disabled
- Build library for distribution enabled
- Deployment target set to iOS 13.0

These settings are automatically applied when you run `pod install`.

## Troubleshooting

### "No API key configured" error
- Make sure you've set the COMPLYCUBE_API_KEY environment variable
- Or update the default value in `complycube_service.dart`

### Pod install fails
- Make sure you're in the `ios` directory
- Run `pod deintegrate` then `pod install --repo-update`

### Verification widget doesn't appear
- Check that the ComplyCube SDK token was generated successfully
- Check the console logs for any errors
- Verify your API key is valid in the ComplyCube dashboard
