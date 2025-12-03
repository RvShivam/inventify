# Inventify Client

The frontend application for Inventify, built with Flutter.

## Features

- **Product Management**: Add, edit, and view products.
- **Settings**: Configure store settings and user profile.
- **Responsive Design**: Works on Mobile and Web.

## Setup

1.  **Install Flutter**: Follow instructions at [flutter.dev](https://flutter.dev/docs/get-started/install).
2.  **Dependencies**:
    ```bash
    flutter pub get
    ```

## Running

### Development
```bash
flutter run
```

### Build
```bash
flutter build apk
# or
flutter build web
```

## Configuration

Update `lib/config.dart` or equivalent constants file to point to your local server URL (e.g., `http://localhost:8080` or your machine's IP if running on a real device).
