import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInProvider extends ChangeNotifier {
  GoogleSignInAccount? user;
  GoogleSignIn googleSignIn = GoogleSignIn();

  Future signInWithGoogle() async {
    // Trigger the authentication flow
    user = await googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await user?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);

    notifyListeners();
  }

  Future addUserOnFirestoreIfNeeded(String userEmailId) async {
    var docRef =
        FirebaseFirestore.instance.collection("users").doc(userEmailId);
    await docRef.get().then((value) async => {
          if (!value.exists)
            {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user?.email)
                  .set({"name": user?.displayName})
            }
        });
    notifyListeners();
  }

  Future logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }
}
