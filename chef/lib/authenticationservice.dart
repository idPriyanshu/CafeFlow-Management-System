import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTokenToLocalStorage(String token) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwt_token', token);
}

// Function to retrieve JWT token from local storage
Future<String?> getTokenFromLocalStorage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwt_token');
}

Future<void> deleteTokenFromLocalStorage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('jwt_token');
}
