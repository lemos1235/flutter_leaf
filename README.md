# Flutter Leaf

A Flutter VPN plugin based on [Leaf](https://github.com/eycorsican/leaf).

## Installation

```yaml
dependencies:
  flutter_leaf: ^0.0.1
```

## Usage

```dart
import 'package:flutter_leaf/flutter_leaf.dart';

// Check VPN permission (only required for Android)
bool prepared = await FlutterLeaf.prepared;
if (!prepared) {
  prepared = await FlutterLeaf.prepare();
}

// Connect to VPN
await FlutterLeaf.connect(
  configContent: yourConfigContent,
);

// Listen for state changes
FlutterLeaf.onStateChanged.listen((state) {
  print('VPN state: $state');
});

// Disconnect
await FlutterLeaf.disconnect();
```

## License

This project is open-sourced under the MIT License.

