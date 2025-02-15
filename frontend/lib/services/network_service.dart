import 'dart:convert';

import 'package:http/http.dart' as http;

class NetworkService {
  static const String baseUrl = "http://127.0.0.1:5000"; // Adjust if needed

  // Sign Up API
  static Future<Map<String, dynamic>> signUp(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Sign In API
  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signin'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Add Transaction API
  static Future<Map<String, dynamic>> addTransaction(String uid, double amount,
      String merchant, String bank, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_transaction'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uid": uid,
        "amount": amount,
        "merchant": merchant,
        "bank": bank,
        "message": message,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get Transactions API
  static Future<Map<String, dynamic>> getTransactions(String uid) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_transactions?uid=$uid'),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }
}
