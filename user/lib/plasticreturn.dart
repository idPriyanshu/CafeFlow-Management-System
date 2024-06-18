import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/environment.dart';
import 'package:cafeflow/homepage.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: PlasticReturn(
          PlasticItems: [],
        ),
      ),
    );
  }
}

class PlasticReturn extends StatefulWidget {
  final List<Map<String, dynamic>> PlasticItems;
  PlasticReturn({Key? key, required this.PlasticItems}) : super(key: key);
  @override
  _PlasticReturnState createState() => _PlasticReturnState();
}

class _PlasticReturnState extends State<PlasticReturn> {
  Timer? _timer;
  StreamController<List<Map<String, dynamic>>> _statusController =
      StreamController.broadcast();

  Future<void> _onConfirmPressed() async {
    savePageInfoToLocalStorage('homepage');
    deleteList();
    for (int i = 0; i < selectedItems.length; i++) {
      var baseurl = Environment.config['IP'];
      var baseport = Environment.config['port'];
      var url = Uri.parse('http://${baseurl}:${baseport}/user/plastics/return');
      var body = jsonEncode({"token": selectedItems[i]['token']});

      //Save the token
      String? token = await getTokenFromLocalStorage();

      var headers = {
        'Content-Type': 'application/json',
        "Authorization": "Bearer ${token}"

        // Add other headers if required
      };
      await http.post(url, headers: headers, body: body);
    }
    // Freeze the screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _statusController.stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            return AlertDialog(
              title: Text('Verifying'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: selectedItems.map((item) {
                    return ListTile(
                      leading: item['status'] == "null"
                          ? CircularProgressIndicator()
                          : item['status'] == 'Accepted'
                              ? Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.close, color: Colors.red),
                      title: Text(item['itemName']),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    savePageInfoToLocalStorage('homepage');
                    deleteList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(title: 'Welcome'),
                      ),
                    );
                  },
                  child: Text('Home'),
                ),
              ],
            );
          },
        );
      },
    );

    // Update data server
    for (var item in selectedItems) {
      await Future.delayed(Duration(seconds: 2)); // simulate delay
      item['status'] = getorderstatus();
      _statusController.add(selectedItems);
    }
  }

  @override
  void initState() {
    super.initState();
    items = widget.PlasticItems;
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      for (var item in selectedItems) {
        String newStatus = getorderstatus();
        if (item['status'] != newStatus) {
          item['status'] = newStatus;
          _statusController.add(selectedItems);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusController.close();
    super.dispose();
  }

  String getorderstatus() {
    List<String> statuses = ['Accepted', 'Not Accepted', "null"];
    Random random = new Random();
    return statuses[random.nextInt(statuses.length)];
  }

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Plastic Return',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.deepPurple,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                deleteList();
                savePageInfoToLocalStorage('homepage');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage(title: "Welcome")),
                  (route) => false,
                );
              },
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Token')),
                        DataColumn(label: Text('Select')),
                      ],
                      rows: List<DataRow>.generate(
                          items.length,
                          (index) => DataRow(cells: [
                                DataCell(Text(items[index]['date'])),
                                DataCell(Text(items[index]['itemName'])),
                                DataCell(
                                    Text(items[index]['token'].toString())),
                                DataCell(Checkbox(
                                  value: selectedItems.contains(items[index]),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedItems.add(items[index]);
                                      } else {
                                        selectedItems.remove(items[index]);
                                      }
                                    });
                                  },
                                )),
                              ])),
                    ),
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        savePageInfoToLocalStorage('homepage');
                        deleteList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MyHomePage(title: 'Welcome')),
                        );
                      },
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 100),
                    ElevatedButton(
                      onPressed: _onConfirmPressed,
                      child: Text('Confirm'),
                    ),
                    SizedBox(width: 100),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
