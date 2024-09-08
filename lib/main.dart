import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import for MediaType
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
  final TextEditingController _aliasPrefixController = TextEditingController();

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
    String aliasPrefix = _aliasPrefixController.text;
    if (aliasPrefix.isEmpty) {
      setState(() {
        _message = "Alias prefix cannot be empty.";
      });
      return;
    }

    String message;
    try {
      final String result = await platform.invokeMethod('checkAndGenerateKeyPair', {
        'aliasPrefix': aliasPrefix,
      });
      message = result;

      await _sendMessageToServer(message);
    } on PlatformException catch (e) {
      message = "Failed to check and generate key pair: '${e.message}'.";
    }

    setState(() {
      _message = message;
    });
  }

  Future<void> _sendMessageToServer(String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.221.176:3000/keypair-success'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('Message sent to server: $message');
      } else {
        print('Failed to send message to server: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error sending message to server: $e');
    }
  }

  Future<void> _uploadImageToServer() async {
    if (_image == null) {
      setState(() {
        _message = "No image selected.";
      });
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.221.176:3000/upload-image'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await _image!.readAsBytes(),
          filename: _image!.path.split('/').last,
          contentType: MediaType('image', 'jpeg'), // Adjust based on actual image type
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _message = "Image uploaded successfully.";
        });
        print("Server response: $responseBody");
      } else {
        setState(() {
          _message = "Failed to upload image: ${response.reasonPhrase}";
        });
        print("Failed to upload image: ${response.reasonPhrase} - $responseBody");
      }
    } catch (e) {
      setState(() {
        _message = "Error uploading image: $e";
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _image = File(image.path);
          _message = "Image selected: ${image.name}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Failed to pick image: $e";
      });
    }
  }

  Future<void> _requestBiometricAuth() async {
    if (_image == null) {
      setState(() {
        _message = "No image selected.";
      });
      return;
    }

    try {
      await _uploadImageToServer();

      final imageBytes = await _image!.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      final String result = await platform.invokeMethod('requestBiometricAuth', {
        'imageBase64': imageBase64,
      });

      setState(() {
        _message = result;
        _verificationResult = result; // Save the result as the signed key
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Failed to authenticate: '${e.message}'.";
      });
    }
  }

  Future<void> _verifySignature() async {
    try {
      final String signedKey = _signatureController.text;

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
        'imageBase64': imageBase64,
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
      final String signedKey = _verificationResult; // Use _verificationResult for the signed key

      if (signedKey.isEmpty) {
        setState(() {
          _message = "Signed key is empty.";
        });
        return;
      }

      // Print the signed key to debug
      print('Signed Key to be copied: $signedKey');

      // Copy to clipboard using Flutter's clipboard API
      await Clipboard.setData(ClipboardData(text: signedKey));

      // Verify the copied content (optional)
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text == signedKey) {
        setState(() {
          _message = "Signed key copied to clipboard.";
        });
      } else {
        setState(() {
          _message = "Failed to copy signed key to clipboard.";
        });
      }

      // Directly send the signed key to the server
      await _sendSignedKeyToServer(signedKey);
    } on PlatformException catch (e) {
      setState(() {
        _message = "Failed to copy signed key: '${e.message}'.";
      });
    }
  }

  Future<void> _sendSignedKeyToServer(String signedKey) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.221.176:3000/signed-key'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'signedKey': signedKey,
        }),
      );

      if (response.statusCode == 200) {
        print('Signed key sent to server successfully.');
      } else {
        print('Failed to send signed key to server: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error sending signed key to server: $e');
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _aliasPrefixController.dispose();
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
                Text('Debug Information:'),
                Text('Message: $_message'),
                Text('Verification Result: $_verificationResult'),
                SizedBox(height: 20),
                TextField(
                  controller: _aliasPrefixController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Alias Prefix',
                  ),
                ),
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
                ElevatedButton(
                  onPressed: _copySignedKey,
                  child: Text('Copy Signed Key to Clipboard and Send'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
