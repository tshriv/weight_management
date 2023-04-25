import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weight_management/sign_in_provider.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => SignInProvider(),
        child: MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: Scaffold(
                appBar: AppBar(
                  title: const Text("Weight Management"),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      FlutterLogo(
                        size: 120,
                      ),
                      // Spacer(),
                      SizedBox(height: 60),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Please Login to use the app",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: FaIcon(FontAwesomeIcons.google),
                          label: Text("Sign in/Sign Up with Google"),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50)),
                          onPressed: () {
                            final provider = Provider.of<SignInProvider>(
                                context,
                                listen: false);
                            provider.signInWithGoogle();
                            //  provider.addUserOnFirestoreIfNeeded();
                          },
                        ),
                      ),
                      SizedBox(height: 50), Spacer()
                    ],
                  ),
                ))),
      );
}
