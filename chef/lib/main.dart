import 'dart:convert';

import 'package:chef/authenticationservice.dart';
import 'package:chef/environment.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user is already logged in
  String? jwtToken = await getTokenFromLocalStorage();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: jwtToken != null ? ChefWindow() : HomePage(),
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
                        'userRole': "chef"
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChefWindow()),
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

class ChefWindow extends StatefulWidget {
  @override
  _ChefWindowState createState() => _ChefWindowState();
}

class _ChefWindowState extends State<ChefWindow> {
  Color circleColor = Colors.green;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse(
        'http://${baseurl}:${baseport}/cooking_staff/chef_window/orders');
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
        orderedItems = jsonResponse.cast<Map<String, dynamic>>();
      });
    } else {
      await deleteTokenFromLocalStorage();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  List<Map<String, dynamic>> orderedItems = [];

  void toggleColor(String color) {
    setState(() {
      circleColor = color == 'red' ? Colors.red : Colors.green;
    });
  }

  void removeItem(int index) {
    setState(() {
      orderedItems.removeAt(index);
    });
  }

  Future<void> logoutpressed() async {
    toggleColor(circleColor == Colors.red ? 'green' : 'red');
    await deleteTokenFromLocalStorage();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  void tickpressed(String oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse(
        'http://${baseurl}:${baseport}/cooking_staff/chef_window/deliver');
    var body = jsonEncode({"orderId": "${oi}"});

    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.post(url, headers: headers, body: body);
  }

  void notificationpressed(String ui, String oi) async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse(
        'http://${baseurl}:${baseport}/cooking_staff/chef_window/notify/${oi}');
    var body = jsonEncode({"userId": "$ui"});

    //Save the token
    String? token = await getTokenFromLocalStorage();

    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${token}"

      // Add other headers if required
    };
    await http.post(url, headers: headers, body: body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chef Window'),
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
              padding: EdgeInsets.all(20),
              child: Card(
                child: SingleChildScrollView(
                  child: Row(children: [
                    Expanded(
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(label: Text('Token')),
                          DataColumn(label: Text('Item Name')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: List<DataRow>.generate(
                          orderedItems.length,
                          (index) => DataRow(cells: [
                            DataCell(
                                Text(orderedItems[index]['token'].toString())),
                            DataCell(Text(orderedItems[index]['itemName'])),
                            DataCell(Row(
                              children: [
                                IconButton(
                                    icon: Icon(Icons.notifications),
                                    onPressed: () {
                                      notificationpressed(
                                          orderedItems[index]['userId'],
                                          orderedItems[index]['orderId']);
                                    }), // Define the function for this button
                                IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () => tickpressed(
                                        orderedItems[index]['orderId'])),
                              ],
                            )),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            )
          : Container(
              alignment: Alignment.center,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Window Not Active"),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.circle, color: circleColor),
                  onPressed: () =>
                      toggleColor(circleColor == Colors.red ? 'green' : 'red'),
                ),
              ]),
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
