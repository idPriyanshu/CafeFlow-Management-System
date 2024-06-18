import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:manager/authenticationservice.dart';
import 'package:manager/environment.dart';
import 'package:manager/main.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SalesPage(),
      ),
    );
  }
}

class SalesPage extends StatefulWidget {
  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Map<String, dynamic>> copylist = [];
  List<Map<String, dynamic>> filterByDate(
      List<Map<String, dynamic>> orderingitems, String formattedDate) {
    copylist =
        orderingitems.where((item) => item['date'] == formattedDate).toList();

    return copylist;
  }

  List<Map<String, dynamic>> orderingItems = [];
  @override
  void initState() {
    super.initState();
    copylist = orderingItems;
    fetchdata();
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchdata();
    });
  }

  void fetchdata() async {
    var baseurl = Environment.config['IP'];
    var baseport = Environment.config['port'];
    var url = Uri.parse('http://${baseurl}:${baseport}/manager/orders/sales');

    var headers = {
      'Content-Type': 'application/json',

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
      deletePageInfoFromLocalStorage();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  int totalAmount = 0;
  void gettotal() {
    totalAmount = copylist.fold(
        0, (sum, item) => sum + ((item['count'] * item['price']) as int));
  }

  void tableupdate(List<Map<String, dynamic>> filtereddata) {
    copylist = filtereddata;
  }

  int check = 0;

  @override
  Widget build(BuildContext context) {
    gettotal();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: Text('Sales Window')), // Centered title
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
      body: Padding(
          padding: EdgeInsets.all(15),
          child: Card(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2025),
                          );
                          if (picked == null) {
                            setState(() {
                              tableupdate(orderingItems);
                            });
                          }
                          if (picked != null) {
                            var formatter = DateFormat('dd-MM-yy');
                            String formattedDate = formatter.format(picked);

                            var filteredData =
                                filterByDate(orderingItems, formattedDate);
                            setState(() {
                              tableupdate(filteredData);
                            });
                          }
                        },
                        child: Text("Choose Date"))
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (copylist.isEmpty)
                      Center(child: Text("No Data Available"))
                    else
                      DataTable(
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Text('Sr'),
                          ),
                          DataColumn(
                            label: Text('Date'),
                          ),
                          DataColumn(
                            label: Text('User ID'),
                          ),
                          DataColumn(
                            label: Text('Order Name'),
                          ),
                          DataColumn(
                            label: Text('Quantity'),
                          ),
                          DataColumn(
                            label: Text('Amount'),
                          ),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: List<DataRow>.generate(
                            copylist.length,
                            (index) => DataRow(cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(Text(copylist[index]['date'])),
                                  DataCell(Text(copylist[index]['userId'])),
                                  DataCell(Text(copylist[index]['itemName'])),
                                  DataCell(Text(
                                      copylist[index]['quantity'].toString())),
                                  DataCell(Text(copylist[index]['totalAmount']
                                      .toString())),
                                  DataCell(Text(copylist[index]['status'])),
                                ])),
                      )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Card(
                      color: const Color.fromARGB(255, 255, 64, 64),
                      child: Text(
                        '  Total Amount : ${totalAmount.toString()}  ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 165),
                  ],
                ),
              )
            ]),
          )),
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          savePageInfoToLocalStorage('manager');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManagerWindow()),
          );
        },
        child: Text("Home", style: TextStyle(color: Colors.black)),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
      ),
    );
  }
}
