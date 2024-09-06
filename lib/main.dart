import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,



      ),
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
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _message = "";
  String _verificationResult = "";

  final TextEditingController _signatureController = TextEditingController();

  Future<void> _getNativeMessage() async {
    String message;
    try {
      final String result = await platform.invokeMethod('getNativeMessage');
      message = result;
    } on PlatformException catch (e) {
      message = "Failed to get native message: '${e.message}'.";
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
      message = "Failed to check and generate key pair: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  Future<void> _requestBiometricAuth() async {
    if (_image == null) {
      setState(() {
        _message = "No image selected.";
      });
      return;
    }

    try {
      final imageBytes = await _image!.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      final String result = await platform.invokeMethod('requestBiometricAuth', {
        'imageBase64': imageBase64, // Pass the Base64 string to the native platform
      });

      setState(() {
        _message = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Failed to authenticate: '${e.message}'.";
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _verifySignature() async {
    try {
      final String signedKey = _signatureController.text;
// Replace with the actual original text used for signing

      if (_image == null) {
        setState(() {
          _verificationResult = "No image selected.";
        });
        return;
      }

      final imageBytes = await _image!.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      final String verificationResult = await platform.invokeMethod('verifySignature', {
        'signedKeyInput': signedKey,
        'imageBase64': imageBase64, // Pass Base64-encoded image data for verification
      });

      setState(() {
        _verificationResult = verificationResult;
      });
    } on PlatformException catch (e) {
      setState(() {
        _verificationResult = "Failed to verify signature: '${e.message}'.";
      });
    }
  }

  Future<void> _copySignedKey() async {
    try {
      final String result = await platform.invokeMethod('copySignedKeyToClipboard');
      setState(() {
        _message = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Failed to copy signed key: '${e.message}'.";
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Platform Channel Example with Camera'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
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
                  onPressed: _getImageFromCamera,
                  child: Text('Capture Image'),
                ),
                SizedBox(height: 20),
                if (_image != null) ...[
                  Image.file(_image!),
                  SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: _requestBiometricAuth,
                  child: Text('Sign Image with Biometric Authentication'),
                ),
                SizedBox(height: 20),
                // TextField for pasting the signed key
                TextField(
                  controller: _signatureController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Paste Signed Key',
                  ),
                  maxLines: 1,
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
      ),
    );
  }
}
