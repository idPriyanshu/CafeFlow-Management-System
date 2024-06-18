import 'dart:math';
import 'dart:async';
import 'package:cafeflow/cafemenuordering.dart';
import 'package:cafeflow/environment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/homepage.dart';
import 'package:cafeflow/login.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: OrderConfirmation(
          selectedItems: [],
        ),
      ),
    );
  }
}

class OrderConfirmation extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  OrderConfirmation({Key? key, required this.selectedItems}) : super(key: key);
  @override
  _OrderConfirmationState createState() => _OrderConfirmationState();
}

String _formatDateElement(int element) {
  // Formats date element (month/day) to ensure it always has two digits
  return element.toString().padLeft(2, '0');
}

class _OrderConfirmationState extends State<OrderConfirmation> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> confirmeditems = [];
  Timer? _timer;
  StreamController<List<Map<String, dynamic>>> _statusController =
      StreamController.broadcast();
  Future<void> _onConfirmPressed() async {
    savePageInfoToLocalStorage('homepage');
    deleteList();
    var t = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      var baseurl = Environment.config['IP'];
      var baseport = Environment.config['port'];
      var url = Uri.parse('http://${baseurl}:${baseport}/user/orders');
      String? token = await getTokenFromLocalStorage();
      var d =
          "${t.year}-${_formatDateElement(t.month)}-${_formatDateElement(t.day)}";

      var n = items[i]['itemName'];
      var q = items[i]['count'];

      var body = jsonEncode({"date": d, "itemName": n, "quantity": q});
      var headers = {
        'Content-Type': 'application/json',
        "Authorization": "Bearer ${token}"

        // Add other headers if required
      };
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        continue;
      } else {
        await deleteTokenFromLocalStorage();
        deletePageInfoFromLocalStorage();
        deleteList();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginApp()),
          (route) => false,
        );
      }
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
                  children: items.map((item) {
                    return ListTile(
                      leading: item['status'] == "Processing"
                          ? CircularProgressIndicator()
                          : item['status'] == 'Accepted'
                              ? Icon(Icons.check, color: Colors.green)
                              : item['status'] == 'Not Accepted'
                                  ? Icon(Icons.close, color: Colors.red)
                                  : Container(), // default widget when item['status'] is null

                      title: Text(item['itemName'] ?? 'default value'),
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
                  child: Text('Cancel'),
                ),
                SizedBox(width: 200),
                TextButton(
                    onPressed: () {
                      // Handle pay button press
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.payment),
                                  title: Text('Payment Method 1'),
                                  onTap: () {
                                    // Handle payment method 1
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.payment),
                                  title: Text('Payment Method 2'),
                                  onTap: () {
                                    // Handle payment method 2
                                  },
                                ),
                                Spacer(),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: ElevatedButton(
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
                                )
                                // Add more payment methods here
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Text('Pay')),
              ],
            );
          },
        );
      },
    );

    //dailog box for informiung user to pay within a time limit
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Title'),
          content: Text(
              "This window is open for next 5 minutes.\nPlease confirm within 5 minutes."),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(width: 100)
          ],
        );
      },
    );

    // Update data server
    for (var item in items) {
      await Future.delayed(Duration(seconds: 2)); // simulate delay
      item['status'] = getorderstatus();
      _statusController.add(items);
      if (item['status'] == 'Accepted') {
        confirmeditems.add(item);
      } else if (item['status'] == 'Not Accepted') {
        confirmeditems.remove(item);
      }
    }
    // Redirect to home page if pay button is not clicked within 10 seconds
    await Future.delayed(Duration(minutes: 5));
    Navigator.of(context).pop();
    savePageInfoToLocalStorage('homepage');
    deleteList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: 'Welcome'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    items = widget.selectedItems;

    for (var item in items) {
      item['status'] = 'Processing';
    }
    // Now you can use 'items' in your OrderConfirmation page
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      for (var item in items) {
        String newStatus = getorderstatus();
        if (item['status'] != newStatus) {
          item['status'] = newStatus;
          _statusController.add(items);
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
    List<String> statuses = ['Accepted', 'Not Accepted'];
    Random random = new Random();
    return statuses[random.nextInt(statuses.length)];
  }

  int totalQuantity = 0;
  double totalAmount = 0;

  // Function to calculate total quantity and amount
  void calculateTotal() {
    totalQuantity =
        items.fold(0, (sum, item) => sum + (item['count'] ?? 0) as int);
    totalAmount = items.fold(
        0, (sum, item) => sum + ((item['count'] * item['price']) ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    calculateTotal();
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Order Confirmation',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.deepPurple,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                savePageInfoToLocalStorage('menu');
                deleteList();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MenuPage()),
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
                        DataColumn(label: Text('Sr.')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Amount')),
                      ],
                      rows: List<DataRow>.generate(
                          items.length,
                          (index) => DataRow(cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(Text(items[index]['itemName'])),
                                DataCell(
                                    Text(items[index]['count'].toString())),
                                DataCell(Text(((items[index]['price']) *
                                        (items[index]['count']))
                                    .toString())),
                              ])),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Card(
                      child: Text(
                        'Total Quantity : ${totalQuantity.toString()}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 90),
                    Card(
                      child: Text(
                        ' Total Amount : ${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 530),
                  ],
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
