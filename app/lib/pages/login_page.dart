import 'package:app/services/auth_service.dart';
import 'package:app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class LoginScreen extends StatefulWidget {
 @Preview(
  name: 'Login Screen',
  textScaleFactor: 1.0,
  brightness: Brightness.dark,
  size: Size(1920 , 600)
)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final userName = _userNameController.text.trim();
    final password = _passwordController.text.trim();

    if (userName.isEmpty || password.isEmpty) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password are required')),
      );
      return;
    }

    try {
      final isSuccess = await AuthService.loginUser(userName, password);
      if (!mounted) return;
      if (isSuccess) {
        Navigator.of(context).pushReplacementNamed('/directMessages');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials, please try again')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred, please try again')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) =>
             Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(
                Icons.chat_bubble_outline,
                size: 40,
              ),
                SizedBox(height: 20),
                Text(
                  "Welcome Again!",
                  
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Login to continue...",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _userNameController,
                    cursorColor: AppColor.primaryColor,
                    decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey, width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColor.primaryColor, width: 1))),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    cursorColor: AppColor.primaryColor,
                    decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey, width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColor.primaryColor, width: 1))),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  //height: MediaQuery.sizeOf(context).height * 0.06, 
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColor.primaryColor,
                        padding: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/register'),
                        child: Text(
                          " Register Now",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColor.primaryColor),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}