
import 'package:atelier4/liste_produits.dart';
import 'package:atelier4/login_ecran.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState== ConnectionState.waiting){
            return const CircularProgressIndicator();
          } else{
            if (snapshot.hasData){
              return ListeProduits();

            }else{
              return  LoginEcran();
            }
          }
        },
      ),

    );
  }
}
