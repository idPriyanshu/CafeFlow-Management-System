// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'dart:convert';

import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/environment.dart';
import 'package:cafeflow/login.dart';
import 'package:http/http.dart' as http;

import 'package:cafeflow/cafemenuordering.dart';
import 'package:cafeflow/plasticreturn.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Cafeflow+',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(title: 'Welcome'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getplasticitemsdetails();
    getorderdetails();
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      List<Map<String, dynamic>> newStatus = getorderstatus();

      if (_statuses.isEmpty || _statuses.last != newStatus) {
        getplasticitemsdetails();
        getorderdetails();
        if (mounted) {
          setState(() {
            _statuses.clear();

            _statuses.addAll(newStatus);
          });
        }
      }
    });
  }

  void getplasticitemsdetails() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/user/plastics');
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        plasticitems = jsonResponse.cast<Map<String, dynamic>>();
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

  void getorderdetails() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/user/orders');
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        orders = jsonResponse['orderDetails'].cast<Map<String, dynamic>>();
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

  List<Map<String, dynamic>> getorderstatus() {
    List<Map<String, dynamic>> copy =
        orders.where((item) => item['status'] == "ready").toList();

    return copy;
  }

  List<Map<String, dynamic>> _statuses = [];
  //data lists
  List<Map<String, dynamic>> plasticitems = [];
  List<Map<String, dynamic>> orders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await deleteTokenFromLocalStorage();
              deletePageInfoFromLocalStorage();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginApp()),
                (route) => false,
              );
            },
          ),
          SizedBox(width: 10)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Icon(Icons.account_circle, size: 50.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Name'),
                    Text('Unique ID'),
                  ],
                ),
                Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        savePageInfoToLocalStorage('menu');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MenuPage()),
                        );
                      },
                      child: Text('Order Food'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        savePageInfoToLocalStorage('plastic');
                        storeList(plasticitems);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PlasticReturn(PlasticItems: plasticitems)),
                        );
                      },
                      child: Text('Return Plastic'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        Text('Plastic count: '),
                        Text('${plasticitems.length}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      Text('Issued Plastic'),
                      Container(
                        height: MediaQuery.of(context).size.height *
                            0.4, // Adjust this value as needed
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount:
                                      1, // replace with your actual row count
                                  itemBuilder: (context, index) {
                                    return Container(
                                      child: DataTable(
                                        columns: const <DataColumn>[
                                          DataColumn(
                                            label: Text('Date'),
                                          ),
                                          DataColumn(
                                            label: Text('Plastic Item'),
                                          ),
                                          DataColumn(
                                            label: Text('Token'),
                                          ),
                                        ],
                                        rows: List<DataRow>.generate(
                                            plasticitems.length,
                                            (index) => DataRow(cells: [
                                                  DataCell(Text(
                                                      (plasticitems[index]
                                                          ['date']))),
                                                  DataCell(Text(
                                                      plasticitems[index]
                                                          ['itemName'])),
                                                  DataCell(Text(
                                                      plasticitems[index]
                                                              ['token']
                                                          .toString())),
                                                ])),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(children: [
                      Text('Orders'),
                      Container(
                        height: MediaQuery.of(context).size.height *
                            0.4, // Adjust this value as needed
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Card(
                                child: DataTable(
                                  columns: const <DataColumn>[
                                    DataColumn(
                                      label: Text('Date'),
                                    ),
                                    DataColumn(
                                      label: Text('Token'),
                                    ),
                                    DataColumn(
                                      label: Text('Order'),
                                    ),
                                    DataColumn(label: Text('Quantity')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(
                                      label: Text('Payment'),
                                    ),
                                  ],
                                  rows: List<DataRow>.generate(
                                      orders.length,
                                      (index) => DataRow(cells: [
                                            DataCell(
                                                Text(orders[index]['date'])),
                                            DataCell(Text(orders[index]['token']
                                                .toString())),
                                            DataCell(Text(
                                                orders[index]['itemName'])),
                                            DataCell(Text(orders[index]
                                                    ['quantity']
                                                .toString())),
                                            DataCell(
                                                Text(orders[index]['status'])),
                                            DataCell(Text(orders[index]
                                                    ['totalAmount']
                                                .toString())),
                                          ])),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.2,
                child: Card(
                  child: ListView.builder(
                    itemCount: _statuses.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        textColor: Colors.deepPurple,
                        title: Text(
                            'Your order ${_statuses[_statuses.length - index - 1]['itemName']} is now ${_statuses[_statuses.length - index - 1]['status']}'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
