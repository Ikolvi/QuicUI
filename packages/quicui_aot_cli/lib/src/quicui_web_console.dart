/// Quicui Web Console URLs.
class QuicuiWebConsole {
  /// Returns a [Uri] for the Quicui Web Console.
  static Uri uri(String path) {
    return Uri.parse('https://console.quicui.dev/$path');
  }

  /// Returns a [Uri] for the Quicui Web Console login page.
  static Uri appReleaseUri(String appId, int releaseId) {
    return QuicuiWebConsole.uri('apps/$appId/releases/$releaseId');
  }
}
