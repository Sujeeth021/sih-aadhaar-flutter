import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Keystore Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Keystore Home Page'),
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
  final storage = FlutterSecureStorage();
  String _storedValue = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Stored Value:'),
            Text(
              _storedValue,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () async {
                await storeKey('my_key', 'Hello, Flutter!');
                setState(() {
                  _storedValue = 'Hello, Flutter!';
                });
              },
              child: const Text('Store Key'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = await retrieveKey('my_key');
                setState(() {
                  _storedValue = value ?? 'No value found';
                });
              },
              child: const Text('Retrieve Key'),
            ),
            ElevatedButton(
              onPressed: () async {
                await deleteKey('my_key');
                setState(() {
                  _storedValue = 'Key deleted';
                });
              },
              child: const Text('Delete Key'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> storeKey(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  Future<String?> retrieveKey(String key) async {
    return await storage.read(key: key);
  }

  Future<void> deleteKey(String key) async {
    await storage.delete(key: key);
  }
}