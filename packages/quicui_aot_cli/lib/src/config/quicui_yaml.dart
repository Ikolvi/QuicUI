import 'package:json_annotation/json_annotation.dart';

part 'quicui_yaml.g.dart';

/// {@template quicui_yaml}
/// A Quicui configuration file which contains metadata about the app.
/// {@endtemplate}
@JsonSerializable(anyMap: true, disallowUnrecognizedKeys: true)
class QuicuiYaml {
  /// {@macro quicui_yaml}
  const QuicuiYaml({
    required this.appId,
    this.flavors,
    this.baseUrl,
    this.autoUpdate,
  });

  /// Creates a [QuicuiYaml] from a JSON map.
  factory QuicuiYaml.fromJson(Map<dynamic, dynamic> json) =>
      _$QuicuiYamlFromJson(json);

  /// Converts this [QuicuiYaml] to a JSON map.
  Map<String, dynamic> toJson() => _$QuicuiYamlToJson(this);

  /// The base app id.
  ///
  /// Example:
  /// `"8d3155a8-a048-4820-acca-824d26c29b71"`
  final String appId;

  /// A map of flavor names to app ids.
  ///
  /// Will be `null` for apps with no flavors.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "development": "8d3155a8-a048-4820-acca-824d26c29b71",
  ///   "production": "d458e87a-7362-4386-9eeb-629db2af413a"
  /// }
  /// ```
  final Map<String, String>? flavors;

  /// The base url used to check for updates.
  final String? baseUrl;

  /// Whether or not to automatically update the app.
  final bool? autoUpdate;
}

/// Extension on [QuicuiYaml] to get the app id for a specific flavor.
extension AppIdExtension on QuicuiYaml {
  /// Returns the app id for the given flavor.
  String getAppId({String? flavor}) {
    if (flavor == null || flavors == null) return appId;
    return flavors![flavor] ?? appId;
  }
}
