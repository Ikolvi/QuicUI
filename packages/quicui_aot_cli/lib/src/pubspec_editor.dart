import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A reference to a [PubspecEditor] instance.
final pubspecEditorRef = create(PubspecEditor.new);

/// The [PubspecEditor] instance available in the current zone.
PubspecEditor get pubspecEditor => read(pubspecEditorRef);

/// {@template pubspec_editor}
/// A class that exposes APIs to edit the current project's `pubspec.yaml`.
/// {@endtemplate}
class PubspecEditor {
  /// Adds quicui.yaml to the assets section of the pubspec.yaml file.
  /// Does nothing if the pubspec.yaml file already contains quicui.yaml.
  /// Does nothing if a flutter project root cannot be found.
  void addQuicuiYamlToPubspecAssets() {
    if (quicuiEnv.pubspecContainsQuicuiYaml) return;

    final root = quicuiEnv.getFlutterProjectRoot();
    // TODO(felangel): this should throw an exception instead of returning
    // to make it explicit that the edit operation failed.
    if (root == null) return;

    final pubspecFile = quicuiEnv.getPubspecYamlFile(cwd: root);
    final pubspecContents = pubspecFile.readAsStringSync();
    final editor = YamlEditor(pubspecContents);
    final yaml = loadYaml(pubspecContents, sourceUrl: pubspecFile.uri) as Map;

    if (!yaml.containsKey('flutter') || yaml['flutter'] == null) {
      editor.update(
        ['flutter'],
        {
          'assets': ['quicui.yaml'],
        },
      );
    } else {
      if (!(yaml['flutter'] as Map).containsKey('assets')) {
        editor.update(['flutter', 'assets'], ['quicui.yaml']);
      } else {
        final assets = (yaml['flutter'] as Map)['assets'] as List;
        if (!assets.contains('quicui.yaml')) {
          editor.update(['flutter', 'assets'], [...assets, 'quicui.yaml']);
        }
      }
    }

    if (editor.edits.isEmpty) return;

    pubspecFile.writeAsStringSync(editor.toString());
  }
}
