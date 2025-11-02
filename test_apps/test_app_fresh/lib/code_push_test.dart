import 'package:flutter/material.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

/// Test page for QuicUI Code Push functionality
class CodePushTestPage extends StatefulWidget {
  const CodePushTestPage({Key? key}) : super(key: key);

  @override
  State<CodePushTestPage> createState() => _CodePushTestPageState();
}

class _CodePushTestPageState extends State<CodePushTestPage> {
  late QuicUICodePush _codePush;
  String _status = 'Initializing...';
  String _log = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCodePush();
  }

  Future<void> _initializeCodePush() async {
    setState(() {
      _status = 'Initializing Code Push...';
      _addLog('Initializing QuicUI Code Push');
    });

    try {
      // Initialize WITHOUT exposing server URL
      // Server URL is managed internally by CodePush client
      _codePush = QuicUICodePush(
        appId: 'com.quicui.test_app_fresh',
        clientSecret: 'test-secret',
        appVersion: '1.0.0',
      );

      await _codePush.initialize();

      setState(() {
        _status = 'Ready';
        _addLog('✅ QuicUI Code Push initialized');
        _addLog('   App ID: com.quicui.test_app_fresh');
        _addLog('   Version: 1.0.0');
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization Failed';
        _addLog('❌ Error: $e');
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking for updates...';
      _addLog('\n📡 Checking for updates...');
    });

    try {
      final patch = await _codePush.checkForUpdates();

      if (patch != null) {
        setState(() {
          _status = 'Update Available!';
          _addLog('✅ Patch available!');
          _addLog('   Patch ID: ${patch.patchId}');
          _addLog('   Version: ${patch.version}');
          _addLog('   Size: ${_formatBytes(patch.size)}');
          _addLog('   Download URL: ${patch.downloadUrl}');
        });
      } else {
        setState(() {
          _status = 'No updates available';
          _addLog('ℹ️  No updates available');
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Check Failed';
        _addLog('❌ Error checking updates: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndApplyPatch() async {
    setState(() {
      _isLoading = true;
      _status = 'Downloading patch...';
      _addLog('\n📥 Downloading patch...');
    });

    try {
      final patch = await _codePush.checkForUpdates();

      if (patch == null) {
        setState(() {
          _status = 'No patch to download';
          _addLog('❌ No patch available');
        });
        return;
      }

      setState(() {
        _status = 'Applying patch...';
        _addLog('📦 Applying patch: ${patch.patchId}');
      });

      await _codePush.downloadAndInstall(patch);

      setState(() {
        _status = 'Patch Applied! Restart app to see changes';
        _addLog('✅ Patch applied successfully!');
        _addLog('🔄 Restart the app to see the counter button');
      });
    } catch (e) {
      setState(() {
        _status = 'Download/Apply Failed';
        _addLog('❌ Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
  }

  void _clearLog() {
    setState(() {
      _log = '';
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuicUI Code Push Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkForUpdates,
                    icon: Icon(Icons.cloud_download),
                    label: Text('Check for Updates'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _downloadAndApplyPatch,
                    icon: Icon(Icons.system_update),
                    label: Text('Download & Apply Patch'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _clearLog,
                    icon: Icon(Icons.clear_all),
                    label: Text('Clear Log'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Log Section
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _log.isEmpty ? 'No logs yet...' : _log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Help Text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Server URL is managed internally by CodePush client\n'
              'Set QUICUI_SERVER_URL=http://192.168.20.102:8080 to connect to PC',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('Failed') || _status.contains('Error')) {
      return Colors.red;
    }
    if (_status.contains('Available') || _status.contains('Applied')) {
      return Colors.green;
    }
    if (_isLoading) {
      return Colors.orange;
    }
    return Colors.blue;
  }
}
