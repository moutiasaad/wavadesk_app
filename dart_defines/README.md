# Dart Defines Configuration

This directory contains environment-specific configuration files for the Wavadesk app.

## Files

- `production.json` - Production environment configuration
- `phone.json` - Phone/device testing configuration (optional)
- `local.json` - Local development configuration (optional)

## Setup

1. Copy the `.example` files and remove the `.example` extension:
   ```bash
   cp production.json.example production.json
   ```

2. Edit the JSON files and add your API URLs:
   ```json
   {
     "WAVADESK_API_URL": "https://your-api-url.com"
   }
   ```

## Usage

These files are automatically loaded when using the run configurations in `.run/`:

- **wavadesk (production)** - Uses `dart_defines/production.json`

You can also pass defines manually:
```bash
flutter run --dart-define-from-file=dart_defines/production.json
```

Or use individual dart-define flags:
```bash
flutter run --dart-define=WAVADESK_API_URL=https://api.wavadesk.com
```

## Security

These files are in `.gitignore` and should **never** be committed to version control.
Keep your API URLs and any secrets secure.
