import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manager/Sales.dart';
import 'package:manager/authenticationservice.dart';
import 'package:manager/environment.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:manager/updatmenu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user is already logged in
  String? jwtToken = await getTokenFromLocalStorage();
  String? pageInfo = await getPageInfoFromLocalStorage();
  Widget page;
  if (pageInfo == 'menu') {
    page = MenuUpdatePage();
  } else if (pageInfo == 'sales') {
    page = SalesPage();
  } else if (pageInfo == 'manager') {
    page = ManagerWindow();
  } else {
    page = HomePage();
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: jwtToken != null ? page : HomePage(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  // Define controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: Container(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 50,
                    child: Icon(
                      Icons.person_2,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      var baseurl = Environment.config['IP'];
                      var baseport = Environment.config['port'];
                      var url =
                          Uri.parse('http://${baseurl}:${baseport}/user/login');
                      var body = jsonEncode({
                        'userId': usernameController.text,
                        'password': passwordController.text,
                        'userRole': "manager"
                      });
                      var headers = {
                        'Content-Type': 'application/json',
                        // Add other headers if required
                      };
                      var response =
                          await http.post(url, headers: headers, body: body);

                      if (response.statusCode == 200) {
                        var jsonResponse = jsonDecode(response.body);

                        String token = jsonResponse['token'];

                        // Save the token
                        await saveTokenToLocalStorage(token);
                        usernameController.clear();
                        passwordController.clear();
                        savePageInfoToLocalStorage('manager');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManagerWindow()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid Login Credentials'),
                          ),
                        );
                      }
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManagerWindow extends StatefulWidget {
  @override
  _ManagerWindowState createState() => _ManagerWindowState();
}

class _ManagerWindowState extends State<ManagerWindow> {
  List<Map<String, dynamic>> orderingItems =
      []; // This should be updated from the server every 5 seconds
  List<Map<String, dynamic>> orderedPlastic =
      []; // This should be updated from the server every 5 seconds
  late Timer _timer;
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    circleColor = Colors.green;
    getplasticdeliverydetails();
    getorderdetails();
    returnplasticrequest();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      getplasticdeliverydetails();
      getorderdetails();
      returnplasticrequest();
      // Fetch the updated data from the server and update orderingItems and orderedPlastic
    });
  }

  void getplasticdeliverydetails() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/manager/plastics/paid');
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
        orderedPlastic = jsonResponse.cast<Map<String, dynamic>>();
      });
    } else {
      await deleteTokenFromLocalStorage();
      await deletePageInfoFromLocalStorage();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  void getorderdetails() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/manager/orders');
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
        orderingItems = jsonResponse.cast<Map<String, dynamic>>();
      });
    } else {
      await deleteTokenFromLocalStorage();
      await deletePageInfoFromLocalStorage();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  void orderconfirmed(String oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/manager/orders/accept');
    var body = jsonEncode({'orderId': "${oi}"});
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.put(url, headers: headers, body: body);
  }

  void orderrejected(String oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/manager/orders/reject');
    //Save the token
    String? token = await getTokenFromLocalStorage();
    var body = jsonEncode({"orderId": "${oi}"});
    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.put(url, headers: headers, body: body);
  }

  plasticreturned(int oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url =
        Uri.parse('http://${baseurl}:${baseport}/manager/plastics/deliver');
    var body = jsonEncode({'token': "${oi}"});
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.put(url, headers: headers, body: body);
  }

  Color circleColor = Colors.red;
  void toggleColor(String color) {
    setState(() {
      circleColor = color == 'red' ? Colors.red : Colors.green;
    });
  }

  Future<void> logoutpressed() async {
    toggleColor(circleColor == Colors.red ? 'green' : 'red');
    await deleteTokenFromLocalStorage();
    await deletePageInfoFromLocalStorage();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  List<Map<String, dynamic>> returnplastic = [];
  void returnplasticrequest() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url =
        Uri.parse('http://${baseurl}:${baseport}/manager/plastics/returning');
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
        returnplastic = jsonResponse.cast<Map<String, dynamic>>();
      });
    } else {
      await deleteTokenFromLocalStorage();
      await deletePageInfoFromLocalStorage();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  void crossedpressed(oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url =
        Uri.parse('http://${baseurl}:${baseport}/manager/plastics/reject');
    var body = jsonEncode({'token': "${oi}"});
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.put(url, headers: headers, body: body);
  }

  void tickpressed(oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url =
        Uri.parse('http://${baseurl}:${baseport}/manager/plastics/return');
    var body = jsonEncode({'token': "${oi}"});
    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.put(url, headers: headers, body: body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Manager Window'),
            IconButton(
              icon: Icon(Icons.circle, color: circleColor),
              onPressed: () =>
                  toggleColor(circleColor == Colors.red ? 'green' : 'red'),
            ),
            SizedBox(width: 60),
          ],
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: circleColor == Colors.green
          ? Padding(
              padding: EdgeInsets.all(15),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () {
                            savePageInfoToLocalStorage('menu');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MenuUpdatePage()),
                            );
                          },
                          child: Text('Update Menu'))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () {
                            savePageInfoToLocalStorage('sales');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SalesPage()),
                            );
                          },
                          child: Text('Sales'))),
                ]),
                Expanded(
                  child: Column(children: [
                    Card(
                      child: Text(
                        " Incoming Return Plastic ",
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Card(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: 1,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      child: DataTable(
                                        columns: const <DataColumn>[
                                          DataColumn(label: Text('Token')),
                                          DataColumn(
                                              label: Text('Plastic Item')),
                                          DataColumn(label: Text('Select')),
                                        ],
                                        rows: List<DataRow>.generate(
                                          returnplastic.length,
                                          (index) => DataRow(
                                            cells: [
                                              DataCell(Text(returnplastic[index]
                                                      ['token']
                                                  .toString())),
                                              DataCell(Text(returnplastic[index]
                                                  ['itemName'])),
                                              DataCell(Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.close),
                                                    onPressed: () {
                                                      setState(() {
                                                        crossedpressed(
                                                            returnplastic[index]
                                                                ['token']);
                                                      });
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.check),
                                                    onPressed: () {
                                                      setState(() {
                                                        tickpressed(
                                                            returnplastic[index]
                                                                ['token']);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ]),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                    child: Row(children: [
                  Expanded(
                    child: Column(children: [
                      Card(
                        child: Text(
                          " Incoming Orders ",
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Card(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: 1,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        child: DataTable(
                                          columns: const <DataColumn>[
                                            DataColumn(label: Text('Date')),
                                            DataColumn(
                                                label: Text('Order Item')),
                                            DataColumn(label: Text('Select')),
                                          ],
                                          rows: List<DataRow>.generate(
                                            orderingItems.length,
                                            (index) => DataRow(
                                              cells: [
                                                DataCell(Text(
                                                    orderingItems[index]
                                                        ['date'])),
                                                DataCell(Text(
                                                    orderingItems[index]
                                                        ['itemName'])),
                                                DataCell(Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.close),
                                                      onPressed: () {
                                                        setState(() {
                                                          orderrejected(
                                                              orderingItems[
                                                                      index]
                                                                  ['orderId']);
                                                        });
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.check),
                                                      onPressed: () {
                                                        setState(() {
                                                          orderconfirmed(
                                                              orderingItems[
                                                                      index]
                                                                  ['orderId']);
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(children: [
                            Card(child: Text(" Plastic Item Dilevery ")),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Card(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ListView.builder(
                                          itemCount: 1,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              child: DataTable(
                                                columns: [
                                                  DataColumn(
                                                      label: Text('Token')),
                                                  DataColumn(
                                                      label: Text('Date')),
                                                  DataColumn(
                                                      label:
                                                          Text('Plastic Item')),
                                                  DataColumn(
                                                      label: Text('Status')),
                                                ],
                                                rows: List<DataRow>.generate(
                                                  orderedPlastic.length,
                                                  (index) => DataRow(
                                                    cells: [
                                                      DataCell(Text(
                                                          orderedPlastic[index]
                                                                  ['token']
                                                              .toString())),
                                                      DataCell(Text(
                                                          orderedPlastic[index]
                                                              ['date'])),
                                                      DataCell(Text(
                                                          orderedPlastic[index]
                                                              ['itemName'])),
                                                      DataCell(IconButton(
                                                        icon: Icon(Icons.check),
                                                        onPressed: () {
                                                          setState(() {
                                                            plasticreturned(
                                                                orderedPlastic[
                                                                        index]
                                                                    ['token']);
                                                          });
                                                        },
                                                      )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ]),
                        ),
                      ],
                    ),
                  ),
                ]))
              ]))
          : Expanded(
              child: Container(
                alignment: Alignment.center,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Window Not Active"),
                  SizedBox(width: 15),
                  IconButton(
                    icon: Icon(Icons.circle, color: circleColor),
                    onPressed: () => toggleColor(
                        circleColor == Colors.red ? 'green' : 'red'),
                  ),
                ]),
              ),
            ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () => logoutpressed(),
        child: Text("Logout", style: TextStyle(color: Colors.black)),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
      ),
    );
  }
}
