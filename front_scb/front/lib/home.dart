import 'package:flutter/material.dart';
import 'package:front/history.dart';
import 'package:front/scan.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:html' as html;

class HomePage extends StatefulWidget {
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  bool isLoading = false;

  void uploadFile(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    final input = html.FileUploadInputElement()..accept = 'image/*,.pdf';
    input.click();

    input.onChange.listen((event) async {
      final file = input.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2232A)),
            ),
          );
        },
      );

      // Upload file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/upload_file'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          reader.result as List<int>,
          filename: file.name,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      Navigator.pop(context);

      // Create new data
      if (response.statusCode == 200) {
        final extractedText = jsonResponse['text'];
        final dbResponse = await http.post(
          Uri.parse('http://127.0.0.1:5000/create_new'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"text": extractedText}),
        );

        if (dbResponse.statusCode == 200) {
          setState(() {
            extractedText;
          });

          // Show dialog
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text(
                    'Results',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  content: SizedBox(
                    width: 100,
                    height: 150,
                    child: SingleChildScrollView(child: Text(extractedText)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF0D6EFD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'DONE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
          );
        } else {
          setState(() {
            print('Error from data recording.');
          });
        }
      } else {
        setState(() {
          print('Error from extracting data.');
        });
      }
    });
  }

  Widget buildButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD2232A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(width: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt, color: Colors.white, size: 50),
            Expanded(
              child: Center(
                child: Text(
                  'SCAN TEXT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                  ),
                ),
              ),
            ),
            SizedBox(width: 50),
          ],
        ),
        backgroundColor: Color(0xFFD2232A),
        toolbarHeight: 70,
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(
              context,
              icon: Icons.camera_alt,
              text: 'SCAN PICTURE',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScanPage()),
                );
              },
            ),
            SizedBox(height: 20),
            buildButton(
              context,
              icon: Icons.history,
              text: 'VIEW HISTORY',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage()),
                );
              },
            ),
            SizedBox(height: 20),
            buildButton(
              context,
              icon: Icons.file_copy,
              text: 'UPLOAD FILE',
              onPressed: () => uploadFile(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Color(0xFFD2232A),
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '@Contact XX-XXXX-XXXX',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
