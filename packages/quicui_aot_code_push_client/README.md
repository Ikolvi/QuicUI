## Quicui CodePush Client

The Quicui CodePush Client is a Dart library which allows Dart applications to interact with the Quicui CodePush API.

### Installing

To get started, add the library to your `pubspec.yaml`:

```yaml
dependencies:
  quicui_aot_code_push_client:
    git:
      url: https://github.com/quicuitech/quicui
      path: packages/quicui_aot_code_push_client
```

### Usage

```dart
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';

Future<void> main() async {
  final client = CodePushClient(apiKey: '<API KEY>');

  // Download the latest engine revision.
  final engine = await client.downloadEngine('latest');

  // Create a new Quicui application.
  await client.createApp(appId: '<APP ID>');

  // List all apps.
  final apps = await client.getApps();

  // Create a new patch.
  await client.createPatch(
    artifactPath: '<PATH TO ARTIFACT>', // e.g. 'libapp.so'
    releaseVersion: '<RELEASE VERSION>', // e.g. '1.0.0'
    appId: '<APP ID>', // e.g. 'quicui-example'
    channel: '<CHANNEL>', // e.g. 'stable'
  );

  // Close the client.
  client.close();
}
```
