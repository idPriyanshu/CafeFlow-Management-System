import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/cafemenuordering.dart';
import 'package:cafeflow/homepage.dart';
import 'package:cafeflow/login.dart';
import 'package:cafeflow/orderconfirmation.dart';
import 'package:cafeflow/plasticreturn.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user is already logged in
  String? jwtToken = await getTokenFromLocalStorage();
  String? pageInfo = await getPageInfoFromLocalStorage();
  Widget page;
  if (pageInfo == 'homepage') {
    page = MyHomePage(title: "Welcome");
  } else if (pageInfo == 'menu') {
    page = MenuPage();
  } else if (pageInfo == 'plastic') {
    page = PlasticReturn(
        PlasticItems: await getList()); // Add your else condition here
  } else if (pageInfo == 'orderconfirmation') {
    page = OrderConfirmation(selectedItems: await getList());
  } else {
    page = MyApp();
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: jwtToken != null ? page : MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CafeFlow+',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: LoginApp() // Use MyHomePage from homepage.dart
        );
  }
}
