import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() {

void main() {  runApp(const MyApp());

  runApp(const MyApp());}

}

class MyApp extends StatelessWidget {

class MyApp extends StatelessWidget {  const MyApp({super.key});

  const MyApp({super.key});

  // This widget is the root of your application.

  @override  @override

  Widget build(BuildContext context) {  Widget build(BuildContext context) {

    return MaterialApp(    return MaterialApp(

      title: 'QuicUI v1 Test',      title: 'Flutter Demo',

      theme: ThemeData(      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),        // This is the theme of your application.

        useMaterial3: true,        //

      ),        // TRY THIS: Try running your application with "flutter run". You'll see

      home: const MyHomePage(title: 'QuicUI Code Push v1 Test'),        // the application has a purple toolbar. Then, without quitting the app,

    );        // try changing the seedColor in the colorScheme below to Colors.green

  }        // and then invoke "hot reload" (save your changes or press the "hot

}        // reload" button in a Flutter-supported IDE, or press "r" if you used

        // the command line to start the app).

class MyHomePage extends StatefulWidget {        //

  const MyHomePage({super.key, required this.title});        // Notice that the counter didn't reset back to zero; the application

        // state is not lost during the reload. To reset the state, use hot

  final String title;        // restart instead.

        //

  @override        // This works for code too, not just values: Most code changes can be

  State<MyHomePage> createState() => _MyHomePageState();        // tested with just a hot reload.

}        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

      ),

class _MyHomePageState extends State<MyHomePage> {      home: const MyHomePage(title: 'Flutter Demo Home Page'),

  int _counter = 0;    );

  String _status = 'Not initialized';  }

  late QuicUICodePush _quicui;}

  bool _isInitialized = false;

class MyHomePage extends StatefulWidget {

  @override  const MyHomePage({super.key, required this.title});

  void initState() {

    super.initState();  // This widget is the home page of your application. It is stateful, meaning

    _initializeQuicUI();  // that it has a State object (defined below) that contains fields that affect

  }  // how it looks.



  Future<void> _initializeQuicUI() async {  // This class is the configuration for the state. It holds the values (in this

    try {  // case the title) provided by the parent (in this case the App widget) and

      setState(() {  // used by the build method of the State. Fields in a Widget subclass are

        _status = 'Initializing QuicUI...';  // always marked "final".

      });

  final String title;

      _quicui = QuicUICodePush(

        appId: 'com.quicui.quicui_v1_test',  @override

        clientSecret: 'test-secret-key',  State<MyHomePage> createState() => _MyHomePageState();

        appVersion: '1.0.0',}

        autoCheckOnStart: false, // Manual check for testing

      );class _MyHomePageState extends State<MyHomePage> {

  int _counter = 0;

      await _quicui.initialize();

  void _incrementCounter() {

      setState(() {    setState(() {

        _isInitialized = true;      // This call to setState tells the Flutter framework that something has

        _status = 'QuicUI initialized\nBackend: https://quicui-backend.onrender.com';      // changed in this State, which causes it to rerun the build method below

      });      // so that the display can reflect the updated values. If we changed

    } catch (e) {      // _counter without calling setState(), then the build method would not be

      setState(() {      // called again, and so nothing would appear to happen.

        _status = 'Initialization error: $e';      _counter++;

      });    });

    }  }

  }

  @override

  Future<void> _checkForUpdates() async {  Widget build(BuildContext context) {

    if (!_isInitialized) {    // This method is rerun every time setState is called, for instance as done

      setState(() {    // by the _incrementCounter method above.

        _status = 'Please wait for initialization...';    //

      });    // The Flutter framework has been optimized to make rerunning build methods

      return;    // fast, so that you can just rebuild anything that needs updating rather

    }    // than having to individually change instances of widgets.

    return Scaffold(

    try {      appBar: AppBar(

      setState(() {        // TRY THIS: Try changing the color here to a specific color (to

        _status = 'Checking for updates...';        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar

      });        // change color while the other colors stay the same.

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

      final updateAvailable = await _quicui.checkForUpdate();        // Here we take the value from the MyHomePage object that was created by

        // the App.build method, and use it to set our appbar title.

      if (updateAvailable) {        title: Text(widget.title),

        setState(() {      ),

          _status = 'Update available! Downloading...';      body: Center(

        });        // Center is a layout widget. It takes a single child and positions it

        // in the middle of the parent.

        await _quicui.downloadAndApplyUpdate();        child: Column(

          // Column is also a layout widget. It takes a list of children and

        setState(() {          // arranges them vertically. By default, it sizes itself to fit its

          _status = 'Update downloaded! Restart app to apply.';          // children horizontally, and tries to be as tall as its parent.

        });          //

      } else {          // Column has various properties to control how it sizes itself and

        setState(() {          // how it positions its children. Here we use mainAxisAlignment to

          _status = 'No updates available. App is up to date!';          // center the children vertically; the main axis here is the vertical

        });          // axis because Columns are vertical (the cross axis would be

      }          // horizontal).

    } catch (e) {          //

      setState(() {          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"

        _status = 'Error checking updates: $e';          // action in the IDE, or press "p" in the console), to see the

      });          // wireframe for each widget.

    }          mainAxisAlignment: MainAxisAlignment.center,

  }          children: <Widget>[

            const Text('You have pushed the button this many times:'),

  void _incrementCounter() {            Text(

    setState(() {              '$_counter',

      _counter++;              style: Theme.of(context).textTheme.headlineMedium,

    });            ),

  }          ],

        ),

  @override      ),

  Widget build(BuildContext context) {      floatingActionButton: FloatingActionButton(

    return Scaffold(        onPressed: _incrementCounter,

      appBar: AppBar(        tooltip: 'Increment',

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,        child: const Icon(Icons.add),

        title: Text(widget.title),      ), // This trailing comma makes auto-formatting nicer for build methods.

      ),    );

      body: Center(  }

        child: Column(}

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'QuicUI Code Push v1',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Button press counter:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isInitialized ? _checkForUpdates : null,
              icon: const Icon(Icons.system_update),
              label: const Text('Check for Updates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
