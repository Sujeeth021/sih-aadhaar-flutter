import 'package:flutter/material.dart';

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

  void _encryptText() {
    setState(() {
      _encryptedText = "Encrypted: ${_inputController.text}";
    });
  }

  void _decryptText() {
    setState(() {
      _decryptedText = "Decrypted: ${_decryptionKeyController.text}";
    });
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
              controller: _inputController,
              decoration: InputDecoration(labelText: 'Enter text to encrypt'),
            ),
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
