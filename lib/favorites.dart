import 'package:atelier4/produits.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: FutureBuilder<List<Produit>>(
        future: _getUserFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Produit> favoriteProducts = snapshot.data ?? [];

          if (favoriteProducts.isEmpty) {
            return Center(child: Text('No favorite products.'));
          }

          return ListView.builder(
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              Produit product = favoriteProducts[index];
              return ListTile(
                title: Text(product.label),
                leading: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : SizedBox(
                        width: 50,
                        height: 50,
                        child: Placeholder(),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Produit>> _getUserFavorites() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDocument =
            await db.collection('users').doc(user.uid).get();

        List<String> userFavorites =
            List<String>.from(userDocument['favorites'] ?? []);

        List<Produit> favoriteProducts = [];

        for (String productId in userFavorites) {
          DocumentSnapshot productDocument =
              await db.collection('produits').doc(productId).get();
          Produit product = Produit.fromFirestore(productDocument);
          favoriteProducts.add(product);
        }

        return favoriteProducts;
      } catch (error) {
        print('Error fetching user favorites: $error');
        return [];
      }
    }

    return [];
  }
}
