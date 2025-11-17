import 'package:flutter/material.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🚀 QuicUI v3.0.0 - MEGA UPDATE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '🚀 QuicUI v3.0.0 MEGA UPDATE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _patchStatus = 'Initializing...';
  String _currentVersion = '3.0.0';
  bool _isChecking = false;
  late QuicUICodePush _quicui;
  int _animationCounter = 0;

  @override
  void initState() {
    super.initState();
    _initQuicUI();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _animationCounter++;
        });
        _startAnimation();
      }
    });
  }

  Future<void> _initQuicUI() async {
    try {
      _quicui = QuicUICodePush(
        appId: 'com.quicui.quicui_v1_test',
        clientSecret: 'test-secret-123',
        appVersion: _currentVersion,
      );
      
      await _quicui.initialize();
      
      setState(() {
        _patchStatus = 'Ready - Tap button to check for updates';
      });
    } catch (e) {
      setState(() {
        _patchStatus = 'Error: $e';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _patchStatus = 'Checking for updates...';
    });

    try {
      final patch = await _quicui.checkForUpdates();
      
      if (patch != null) {
        setState(() {
          _patchStatus = 'Update available: ${patch.version}\nDownloading...';
        });
        
        final success = await _quicui.downloadAndInstall(patch);
        
        setState(() {
          if (success) {
            _patchStatus = 'Update installed! Restart app to apply.';
          } else {
            _patchStatus = 'Update download failed';
          }
        });
      } else {
        setState(() {
          _patchStatus = 'No updates available';
        });
      }
    } catch (e) {
      setState(() {
        _patchStatus = 'Check failed: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade700,
        elevation: 8,
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade900,
              Colors.purple.shade900,
              Colors.pink.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Animated header
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.cyan.shade300,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 100,
                            color: Colors.yellowAccent,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '🎊 MASSIVE UPDATE 🎊',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellowAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '✨ v$_currentVersion RELEASED ✨',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Feature cards
                  _buildFeatureCard(
                    icon: Icons.speed,
                    title: 'Lightning Fast',
                    description: 'Optimized performance with new engine',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.palette,
                    title: 'Beautiful UI',
                    description: 'Completely redesigned interface',
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.security,
                    title: 'Secure Updates',
                    description: 'Hash-verified patch system',
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Status container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.cyanAccent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.cyanAccent,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _patchStatus,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Update button
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkForUpdates,
                    icon: _isChecking 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_download, size: 28),
                    label: Text(
                      _isChecking ? 'CHECKING...' : 'CHECK FOR UPDATES',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.cyan.shade600,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current Version: $_currentVersion',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
