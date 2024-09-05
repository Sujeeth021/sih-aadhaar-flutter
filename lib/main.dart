import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EncryptionScreen(),
    );
  }
}

class EncryptionScreen extends StatefulWidget {
  @override
  _EncryptionScreenState createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _decryptionKeyController = TextEditingController();

  String? _encryptedText;
  String? _decryptedText;
  File? _image;

  void _encryptText() {
    setState(() {
      _encryptedText = "Encrypted key: ${_inputController.text}";
    });
  }

  void _decryptText() {
    setState(() {
      _decryptedText = "Decrypted key: ${_decryptionKeyController.text}";
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt & Decrypt Text'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: 'Enter encryption key'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _encryptText,
              child: Text('Encrypt'),
            ),
            SizedBox(height: 20),
            if (_encryptedText != null)
              Text(_encryptedText!, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _decryptionKeyController,
              decoration: InputDecoration(labelText: 'Enter key to decrypt'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _decryptText,
              child: Text('Decrypt'),
            ),
            SizedBox(height: 20),
            if (_decryptedText != null)
              Text(_decryptedText!, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Take Picture'),
            ),
            SizedBox(height: 20),
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _decryptionKeyController.dispose();
    super.dispose();
  }
}
