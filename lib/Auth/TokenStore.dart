import 'package:corr/Auth/Login.dart';
import 'package:corr/main.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTokenStore extends StatefulWidget {
  const MyTokenStore({super.key});

  @override
  State<MyTokenStore> createState() => _MyTokenStoreState();
}

class _MyTokenStoreState extends State<MyTokenStore> {
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('accessToken');
      isLoading = false;
      print('Token: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      if (token == null) {
        return signInpage();
      } else {
        return FireStoreHome();
      }
    }
  }
}
