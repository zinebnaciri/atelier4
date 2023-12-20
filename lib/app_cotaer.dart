import 'package:atelier4/authPage.dart';
import 'package:atelier4/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class AppContainer extends StatelessWidget {
  const AppContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (routeSettings) {
          late Widget page;
          switch (routeSettings.name) {
            case '/':
              page = const AuthPage();
              break;
            case '/home':
              page = const HomePage();
              break;
            default:
              page = const AuthPage();
          }
          return MaterialPageRoute(builder: (context) => page);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}