import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/environment.dart';
import 'package:cafeflow/homepage.dart';
import 'package:cafeflow/login.dart';
import 'package:cafeflow/orderconfirmation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MenuPage(),
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  void initState() {
    super.initState();
    getmenu();
  }

  void getmenu() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/menu');

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        items = jsonResponse['menu'].cast<Map<String, dynamic>>();
        for (var i = 0; i < items.length; i++) {
          items[i]['count'] = 0;
          check = 1;
        }
      });
    } else {
      await deleteTokenFromLocalStorage();
      deletePageInfoFromLocalStorage();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginApp()),
        (route) => false,
      );
    }
  }

  List<Map<String, dynamic>> getSelectedItems() {
    return items.where((item) => item['count'] > 0).toList();
  }

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];

  String search = '';
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
            title: Center(child: Text('Cafe Menu')), // Centered title
            backgroundColor: Colors.deepPurple,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
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
                              SizedBox(width: 100),
                              Text('Food Item Name'),
                              Spacer(),
                              Text('Price'),
                              SizedBox(width: 100),
                              Text('Cost'),
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
                                        Text(filteredItems[index]['itemName']),
                                        Spacer(),
                                        Text(
                                            '\$${filteredItems[index]['price']}'),
                                        SizedBox(width: 90),
                                      ],
                                    ),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed: () {
                                            setState(() {
                                              if (filteredItems[index]
                                                      ['count'] >
                                                  0) {
                                                filteredItems[index]['count']--;
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                            '${filteredItems[index]['count']}'),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              filteredItems[index]['count']++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                        '\$${filteredItems[index]['price'] * filteredItems[index]['count']}'),
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
                                  savePageInfoToLocalStorage('homepage');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            MyHomePage(title: 'Welcome')),
                                  );
                                },
                              ),
                              SizedBox(width: 960),
                              ElevatedButton(
                                child: Text('Reset'),
                                onPressed: () {
                                  setState(() {
                                    for (var item in items) {
                                      item['count'] = 0;
                                    }
                                  });
                                },
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                child: Text('Confirm Order'),
                                onPressed: () {
                                  savePageInfoToLocalStorage(
                                      'orderconfirmation');
                                  storeList(getSelectedItems());
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderConfirmation(
                                          selectedItems: getSelectedItems()),
                                    ),
                                  );
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
