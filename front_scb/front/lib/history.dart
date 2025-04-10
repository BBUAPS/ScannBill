import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historyData = [];
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  // History
  Future<void> fetchHistoryData() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_history'),
      );

      if (response.statusCode == 200) {
        setState(() {
          historyData = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          historyData.sort((a, b) {
            var dateA = a['date'];
            var dateB = b['date'];

            if (dateA == null) return 1;
            if (dateB == null) return -1;

            return dateB.compareTo(dateA);
          });
        });
      } else {
        setState(() {
          historyData = [];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data.')));
      }
    } catch (e) {
      setState(() {
        historyData = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Delete data
  Future<void> deleteHistoryItem(String title) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/remove_it/$title'),
      );

      if (response.statusCode == 200) {
        fetchHistoryData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to find the data to be deleted.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting data.')));
    }
  }

  // Show dialog
  void confirmDelete(String title) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Confirm?',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            content: Text('Do you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteHistoryItem(title);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFDC3545),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'DELETE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFFFC107),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'CANCEL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            setState(() {
              _isAtBottom = true;
            });
          } else {
            setState(() {
              _isAtBottom = false;
            });
          }
          return true;
        },
        child:
            historyData.isEmpty
                ? Center(child: CircularProgressIndicator())
                : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: Color(0xFFD2232A),
                      toolbarHeight: 70,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(
                        'HISTORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = historyData[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Card(
                            color: Colors.white,
                            elevation: 10.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFD2232A),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] ?? 'Title not found.',
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          confirmDelete(item['title']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    item['text'] ?? 'Data not found.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: historyData.length),
                    ),
                  ],
                ),
      ),
      bottomNavigationBar:
          _isAtBottom
              ? Container(
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
              )
              : null,
    );
  }
}
