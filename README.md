# LeaderBoard App

The **LeaderBoard App** is a Flutter application designed to manage and display leaderboards. It uses Firebase for backend services and Riverpod for state management.

## Features

- **User Authentication**: Sign-in functionality for users.
- **Leaderboard Management**: Display and manage leaderboard data.
- **Firebase Integration**: Uses Firebase for authentication and data storage.
- **State Management**: Powered by Riverpod for efficient state handling.

## Technologies Used

- **Flutter**: For building the cross-platform app.
- **Firebase**: Backend services for authentication and data storage.
- **Riverpod**: State management solution.

## Getting Started

### Prerequisites

- Install [Flutter](https://flutter.dev/docs/get-started/install).
- Set up [Firebase](https://firebase.google.com/) for your project.
- Configure the `firebase_options.dart` file with your Firebase project settings.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/MAD-LeaderBoard-App.git
   cd MAD-LeaderBoard-App
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Firebase Setup

Ensure you have configured Firebase for your app:
- Add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files to their respective directories.
- Update the `firebase_options.dart` file with your Firebase configuration.

## Folder Structure

```
lib/
├── main.dart                # Entry point of the app
├── screens/                 # Contains all the app screens
│   ├── signin/              # Sign-in screen
│   ├── wrapper.dart         # Wrapper screen
├── firebase_options.dart    # Firebase configuration
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
