import 'package:cafeflow/authenticationservice.dart';
import 'package:cafeflow/environment.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  // Define controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (ActivateIntent intent) => print('Enter Pressed'),
                ),
              },
              child: Builder(
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
                            var url = Uri.parse(
                                'http://${baseurl}:${baseport}/user/login');
                            var body = jsonEncode({
                              'userId': usernameController.text,
                              'password': passwordController.text,
                              'userRole': "user"
                            });
                            var headers = {
                              'Content-Type': 'application/json',
                              // Add other headers if required
                            };
                            var response = await http.post(url,
                                headers: headers, body: body);

                            if (response.statusCode == 200) {
                              var jsonResponse = jsonDecode(response.body);

                              String token = jsonResponse['token'];

                              // Save the token
                              await saveTokenToLocalStorage(token);
                              usernameController.clear();
                              passwordController.clear();
                              savePageInfoToLocalStorage('homepage');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MyHomePage(title: 'Welcome')),
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
          ),
        ));
  }
}

class ActivateIntent extends Intent {}
