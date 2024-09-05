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
      debugShowCheckedModeBanner: false,
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
  String _signedKeyInput = '';
  String _verificationResult = '';
  String _textToSign = '';

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
      final String result = await platform.invokeMethod('requestBiometricAuth', {'textToSign': _textToSign});
      message = result;
    } on PlatformException catch (e) {
      message = "Failed to authenticate: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  Future<void> _verifySignature() async {
    String verificationResult;
    try {
      final String result = await platform.invokeMethod('verifySignature', {'signedKeyInput': _signedKeyInput, 'originalText': _textToSign});
      verificationResult = result;
    } on PlatformException catch (e) {
      verificationResult = "Failed to verify signature: '${e.message}'.";
    }

    setState(() {
      _verificationResult = verificationResult;
    });
  }

  Future<void> _copySignedKey() async {
    try {
      await platform.invokeMethod('copySignedKeyToClipboard');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed key copied to clipboard.')));
    } on PlatformException catch (e) {
      print("Failed to copy signed key: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Platform Channel Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
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
              TextField(
                decoration: InputDecoration(labelText: 'Enter text to sign'),
                onChanged: (value) {
                  setState(() {
                    _textToSign = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestBiometricAuth,
                child: Text('Sign Text with Biometric Authentication'),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: 'Enter signed key input'),
                onChanged: (value) {
                  setState(() {
                    _signedKeyInput = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifySignature,
                child: Text('Verify Signature'),
              ),
              SizedBox(height: 20),
              Text('Verification Result: $_verificationResult'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _copySignedKey,
                child: Text('Copy Signed Key to Clipboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
