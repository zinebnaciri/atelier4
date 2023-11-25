import 'package:atelier4/firebase_options.dart';
import 'package:atelier4/produits.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ListeProduits extends StatefulWidget {
  @override
  _ListeProduitsState createState() => _ListeProduitsState();
}
class _ListeProduitsState extends State<ListeProduits> {
FirebaseFirestore db = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Produits'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:db.collection('produits').snapshots() ,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
 if (snapshot.hasError){
return const Center(child: Text('une erreur est survenue'));
       }
if (snapshot.connectionState == ConnectionState.waiting){
return const Center(
  child: CircularProgressIndicator(),
);
}
List<Produit> produits = snapshot.data!.docs.map((doc) {
  return Produit.fromFirestore(doc);
}).toList();

return ListView.builder(
  itemCount: produits.length,
  itemBuilder: (context, index) => ProduitItem(
    produit: produits[index],
  ),
);
},
    ),
    );
  }
}
class ProduitItem extends StatelessWidget {
  ProduitItem({Key? key, required this.produit}) : super(key: key);

  final Produit produit;

  @override
  Widget build(BuildContext context){
    return ListTile(
      title: Text(produit.label),
      subtitle: Text(produit.marque),
      trailing: Text('${produit.prix} £'),
    );
  }
}
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(
    home: ListeProduits(),
  ));
}*/
