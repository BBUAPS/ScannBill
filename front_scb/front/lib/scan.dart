import 'package:flutter/material.dart';
import 'package:front/history.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  String scannedText = 'No data found.';
  bool isLoading = false;
  bool canScanMore = false;
  bool isScanMoreLoading = false;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory('open_camera', (
      int viewId,
    ) {
      final image = html.ImageElement();

      // Open your camera
      image.src = 'http://127.0.0.1:5000/open_camera';
      image.style.width = '100%';
      image.style.height = '100%';
      image.style.objectFit = 'cover';
      return image;
    });
  }

  Widget showCameraStream() {
    return SizedBox(
      width: 300,
      height: 370,
      child: HtmlElementView(viewType: 'open_camera'),
    );
  }

  // Scan image
  Future<void> scanImage({bool append = false, bool createNew = false}) async {
    if (append) {
      setState(() {
        isLoadingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/scan_image'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          scannedText = jsonResponse["text"];
        });
        showScannedTextDialog(context);

        // More option
        final dbResponse = await http.post(
          Uri.parse(
            createNew
                ? 'http://127.0.0.1:5000/create_new'
                : append
                ? 'http://127.0.0.1:5000/try_more'
                : 'http://127.0.0.1:5000/try_again',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"text": scannedText}),
        );

        if (dbResponse.statusCode != 200) {
          setState(() {
            scannedText = 'Error from data recording.';
          });
        }
      } else {
        setState(() {
          scannedText = 'Error from scanning.';
        });
      }
    } catch (e) {
      setState(() {
        scannedText = 'Unable to connect to the server.';
      });
    } finally {
      setState(() {
        if (append) {
          isLoadingMore = false;
          canScanMore = false;
        } else {
          isLoading = false;
        }
      });
    }
  }

  // Show dialog
  void showScannedTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Results',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 100,
            height: 150,
            child: SingleChildScrollView(child: Text(scannedText)),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      canScanMore = true;
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF6F42C1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'MORE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final response = await http.post(
                      Uri.parse('http://127.0.0.1:5000/try_again'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({"text": scannedText}),
                    );

                    if (response.statusCode == 200) {
                      setState(() {
                        scannedText = '';
                      });
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        scannedText = 'Error from data deletion.';
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFFFC107),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'SCAN AGAIN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD2232A),
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 30, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SCAN PICTURE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),

      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            showCameraStream(),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2232A)),
                )
                : SizedBox(
                  width: 250,
                  height: 60,
                  child:
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD2232A),
                              ),
                            ),
                          )
                          : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  canScanMore ? Colors.grey : Color(0xFFD2232A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed:
                                canScanMore
                                    ? null // ปิดการทำงานเมื่อเปิด SCAN MORE
                                    : () {
                                      scanImage(createNew: true);
                                    },
                            icon: Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 30,
                            ),
                            label: Text(
                              'SCAN PICTURE',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),

            SizedBox(height: 10),
            SizedBox(
              width: 250,
              height: 60,
              child:
                  isLoadingMore
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFD2232A),
                          ),
                        ),
                      )
                      : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canScanMore ? Color(0xFFD2232A) : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed:
                            canScanMore
                                ? () {
                                  scanImage(append: true);
                                }
                                : null,
                        icon: Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 30,
                        ),
                        label: Text(
                          'SCAN MORE',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),

            SizedBox(height: 10),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD2232A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryPage()),
                  );
                },
                icon: Icon(Icons.history, color: Colors.white, size: 30),
                label: Text(
                  'VIEW HISTORY',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
