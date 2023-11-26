import 'package:atelier4/login_ecran.dart';
import 'package:atelier4/produits.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListeProduits extends StatefulWidget {
  @override
  _ListeProduitsState createState() => _ListeProduitsState();
}

class _ListeProduitsState extends State<ListeProduits> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  TextEditingController labelController = TextEditingController();
  TextEditingController marqueController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController categorieController = TextEditingController();
 String editingProductId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Produits'),
         actions: [
    IconButton(
      icon: Icon(Icons.logout),
      onPressed: _logout,
    ),
  ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showCreateModal();
            },
            child: Text('Create Produit'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('produits').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Une erreur est survenue'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                List<Produit> produits = snapshot.data!.docs.map((doc) {
                  return Produit.fromFirestore(doc);
                }).toList();
                return DataTable(
                  columns: [
                    DataColumn(label: Text('Label')),
                    DataColumn(label: Text('Marque')),
                    DataColumn(label: Text('Prix')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Categorie')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: produits
                      .map(
                        (produit) => DataRow(
                          cells: [
                            DataCell(Text(produit.label)),
                            DataCell(Text(produit.marque)),
                            DataCell(Text('${produit.prix} £')),
                            DataCell(Text('${produit.quantity} unité')),
                            DataCell(Text(produit.categorie)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _showEditModal(produit);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _confirmDelete(produit.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String produitId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment supprimer ce produit ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _deleteProduit(produitId);
                Navigator.of(context).pop();
              },
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
  void _deleteProduit(String produitId) async {
    await db.collection('produits').doc(produitId).delete();
  }
void _showCreateModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un Produit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: marqueController,
                decoration: InputDecoration(labelText: 'Marque'),
              ),
              TextField(
                controller: prixController,
                decoration: InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categorieController,
                decoration: InputDecoration(labelText: 'Catégorie'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _createProduit();
                Navigator.of(context).pop();
              },
              child: Text('Créer'),
            ),
          ],
        );
      },
    );
  }


  void _showEditModal(Produit produit) {
    labelController.text = produit.label;
    marqueController.text = produit.marque;
    prixController.text = produit.prix.toString();
    quantityController.text = produit.quantity.toString();
    categorieController.text = produit.categorie;
    editingProductId = produit.id;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: marqueController,
                decoration: InputDecoration(labelText: 'Marque'),
              ),
              TextField(
                controller: prixController,
                decoration: InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categorieController,
                decoration: InputDecoration(labelText: 'Categorie'),
              ),
              ElevatedButton(
                onPressed: () {
                  _editProduit();
                  Navigator.pop(context); // Close the modal
                },
                child: Text('Edit'),
              ),
            ],
          ),
        );
      },
    );
  }
   void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the login screen or any other screen as needed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginEcran()),
    );
  }
  void _editProduit() async {
  // Extract data from controllers and update the product in the database
  await db.collection('produits').doc(editingProductId).update({
    'label': labelController.text,
    'brand': marqueController.text,
    'price': double.parse(prixController.text),
    'quantity': int.parse(quantityController.text),
    'categorie': categorieController.text,
  });

  // Clear controllers and reset editingProductId
  labelController.clear();
  marqueController.clear();
  prixController.clear();
  quantityController.clear();
  categorieController.clear();
  editingProductId = '';
}

 void _createProduit() async {

    await db.collection('produits').add({
      'label': labelController.text,
      'brand': marqueController.text,
      'price': double.parse(prixController.text),
      'quantity': int.parse(quantityController.text),
      'categorie': categorieController.text,
    });

    labelController.clear();
    marqueController.clear();
    prixController.clear();
    quantityController.clear();
    categorieController.clear();
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
