import 'package:corr/Auth/SignUpPage.dart';
import 'package:corr/main.dart';
import 'package:flutter/material.dart';
import 'package:firedart/firedart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class signInpage extends StatefulWidget {
  const signInpage({super.key});

  @override
  _signInpageState createState() => _signInpageState();
}

class _signInpageState extends State<signInpage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  void onSuccessfulSignIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Ensure that FirebaseAuth.instance.tokenProvider.refreshToken is not null.
    String? refreshToken = FirebaseAuth.instance.tokenProvider.refreshToken;
    if (refreshToken != null) {
      await prefs.setString('accessToken', refreshToken);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FirebaseAuth.instance.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      onSuccessfulSignIn();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'signIn successful!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FireStoreHome()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('signIn failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: AppBar(
            backgroundColor: Colors.red,
            title: Column(
              children: [
                Text('CVs Management System',
                    style: TextStyle(color: Colors.white)),
                Text('Sign In', style: TextStyle(color: Colors.white)),
              ],
            ),
            centerTitle: true,
          ),
        ),
        body: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                  ),
                  Center(
                    child: SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        )),
                  ),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your Password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) => value!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: Text('Sign In',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Signuppage()));
                },
                child: Text(
                  'Dont have account? signUp',
                  style: TextStyle(color: Colors.red),
                ))
          ],
        ));
  }
}
