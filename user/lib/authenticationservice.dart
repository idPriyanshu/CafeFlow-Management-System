import 'dart:convert';

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

// Function to delete JWT token from local storage
Future<void> deleteTokenFromLocalStorage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('jwt_token');
}

Future<void> savePageInfoToLocalStorage(String page) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_page', page);
}

Future<String?> getPageInfoFromLocalStorage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('current_page');
}

Future<void> deletePageInfoFromLocalStorage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_page');
}

// Function to store a list in the format of List<Map<String, dynamic>>
Future<void> storeList(List<Map<String, dynamic>> list) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final encodedList = list.map((map) => jsonEncode(map)).toList();
  await prefs.setStringList('my_list', encodedList);
}

// Function to delete the list from local storage
Future<void> deleteList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('my_list');
}

// Function to access the stored list
Future<List<Map<String, dynamic>>> getList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final encodedList = prefs.getStringList('my_list');
  if (encodedList != null) {
    final decodedList = encodedList.map((json) => jsonDecode(json)).toList();
    final list = decodedList.cast<Map<String, dynamic>>();
    return list;
  }
  return [];
}
