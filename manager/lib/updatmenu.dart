import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:manager/authenticationservice.dart';
import 'package:manager/main.dart';
import 'package:manager/environment.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MenuUpdatePage(),
      ),
    );
  }
}

class MenuUpdatePage extends StatefulWidget {
  @override
  _MenuUpdatePageState createState() => _MenuUpdatePageState();
}

class _MenuUpdatePageState extends State<MenuUpdatePage> {
  List<Map<String, dynamic>> getSelectedItems() {
    return items.where((item) => item['count'] > 0).toList();
  }

  List<Map<String, dynamic>> items = [];

  String search = '';

  @override
  void initState() {
    super.initState();
    getmenu();
  }

  void getmenu() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/menu');

    var headers = {
      'Content-Type': 'application/json',

      // Add other headers if required
    };
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        items = jsonResponse['menu'].cast<Map<String, dynamic>>();
        for (int i = 0; i < items.length; i++) {
          items[i]['status'] = 'Available';
        }

        check = 1;
      });
    } else {
      await deleteTokenFromLocalStorage();
      deletePageInfoFromLocalStorage();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  List<Map<String, dynamic>> filteredItems = [];
  int check = 0;
  @override
  Widget build(BuildContext context) {
    if (check == 1) {
      filteredItems = items
          .where((item) =>
              item['itemName'].toLowerCase().contains(search.toLowerCase()))
          .toList();
      return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Center(child: Text('Cafe Menu Updation')), // Centered title
            backgroundColor: Colors.deepPurple,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                savePageInfoToLocalStorage('manager');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerWindow()),
                  (route) => false,
                );
              },
            ),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 100),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          search = '';
                        });
                      },
                      icon: Icon(Icons.clear),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 100),
                  child: Card(
                    // Background card
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              SizedBox(width: 25),
                              Text('Availability'),
                              SizedBox(width: 130),
                              Text('Food Item Name'),
                              Spacer(),
                            ],
                          ),
                        ),
                        Divider(), // Line between rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: <Widget>[
                                  ListTile(
                                    title: Row(
                                      children: <Widget>[
                                        SizedBox(width: 100),
                                        Text(filteredItems[index]['itemName']),
                                      ],
                                    ),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        ElevatedButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty
                                                    .resolveWith<Color>(
                                              (Set<MaterialState> states) {
                                                if (states.contains(
                                                    MaterialState.pressed))
                                                  return Colors
                                                      .green; // Color when the button is pressed
                                                return filteredItems[index]
                                                            ['status'] ==
                                                        'Available'
                                                    ? Colors.green
                                                    : Colors
                                                        .red; // Use green for available items and red for unavailable items
                                              },
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              filteredItems[index]
                                                  ['status'] = filteredItems[
                                                          index]['status'] ==
                                                      'Available'
                                                  ? 'Not Available'
                                                  : 'Available'; // Update the status when the button is pressed
                                            });
                                          },
                                          child: Text(
                                            filteredItems[index]['status'],
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(), // Line between rows
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 20, horizontal: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text('Home'),
                                onPressed: () {
                                  savePageInfoToLocalStorage('manager');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ManagerWindow()),
                                  );
                                },
                              ),
                              SizedBox(width: 960),
                              ElevatedButton(
                                child: Text('Reset'),
                                onPressed: () {
                                  setState(() {
                                    for (var item in filteredItems) {
                                      item['status'] = "Available";
                                    }
                                  });
                                },
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                child: Text('Confirm Order'),
                                onPressed: () {
                                  //Confirm update function
                                },
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ));
    } else {
      return Scaffold(
          body: Center(
        child: Icon(Icons.train, size: 50),
      ));
    }
  }
}
