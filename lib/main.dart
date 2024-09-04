import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.main/platform_channel');
  String _message = 'Waiting for message...';

  Future<void> _getNativeMessage() async {
    String message;
    try {
      final String result = await platform.invokeMethod('getNativeMessage');
      message = result;
    } on PlatformException catch (e) {
      message = "Failed to get message: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  Future<void> _checkAndGenerateKeyPair() async {
    String message;
    try {
      final String result = await platform.invokeMethod('checkAndGenerateKeyPair');
      message = result;
    } on PlatformException catch (e) {
      message = "Failed to generate key pair: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  Future<void> _requestBiometricAuth() async {
    String message;
    try {
      final String result = await platform.invokeMethod('requestBiometricAuth');
      message = result;
    } on PlatformException catch (e) {
      message = "Failed to authenticate: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Platform Channel Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_message),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getNativeMessage,
              child: Text('Get Native Message'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAndGenerateKeyPair,
              child: Text('Check and Generate Key Pair'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestBiometricAuth,
              child: Text('Request Biometric Authentication'),
            ),
          ],
        ),
      ),
    );
  }
}
