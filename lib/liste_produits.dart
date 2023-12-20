import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atelier4/login_ecran.dart';
import 'package:atelier4/produits.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

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
  String imageUrl = '';
  bool img = false;
  String userRole = '';

  @override
  Widget build(BuildContext context) {
     print('User Role: $userRole');
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
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('produits').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          List<Produit> produits = snapshot.data!.docs.map((doc) {
            return Produit.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: produits.length,
            itemBuilder: (BuildContext context, int index) {
              Produit produit = produits[index];
              return Card(
                child: ListTile(
                  title: Text(produit.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marque: ${produit.marque}'),
                      if (produit.image.isNotEmpty)
                        Image.network(
                          produit.image,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stackTrace) {
                            return Center(
                              child: Icon(Icons.error),
                            );
                          },
                        ),
                      Text('Prix: ${produit.prix} £'),
                      Text('Quantity: ${produit.quantity} unité'),
                      Text('Catégorie: ${produit.categorie}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     if (userRole != 'user')
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditModal(produit);
                        },
                      ),
                        if (userRole != 'user')
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _confirmDelete(produit.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
       floatingActionButton: userRole != 'user'
          ?FloatingActionButton(
        onPressed: _showCreateModal,
        child: Icon(Icons.add),
      )
       : null,
    );
  }
 @override
  void initState() {
    super.initState();
    // Retrieve the user's role when the widget initializes
    _getUserRole();
  }
 void _getUserRole() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Query the 'users' collection to find the user document with the matching email
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      // Retrieve the user role from the first document in the query result
      DocumentSnapshot userDocument = userSnapshot.docs.first;
      setState(() {
        userRole = userDocument['role'] ?? '';
      });
    } else {
      print('User document not found in the "users" collection.');
    }
  }
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
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categorieController,
                decoration: InputDecoration(labelText: 'Catégorie'),
              ),
              ElevatedButton(
                onPressed: () {
                  _createProduit();
                  Navigator.of(context).pop();
                },
                child: Text('Créer'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? imageUrl = await _pickAndUploadImage();
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    print('Image URL: $imageUrl');
                  }
                },
                child: Text('Choisir une image'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickAndUploadImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final imageExtension = path.extension(image.path).toLowerCase();

      if (imageExtension == '.png' ||
          imageExtension == '.jpeg' ||
          imageExtension == '.jpg') {
        setState(() {
          imageUrl = image.path;
          img = true;
        });
        return imageUrl;
      } else {
        print("Échec de la mise à jour de l'image, essayez avec une autre image");
      }
    } else {
      print("Le fichier n'est pas une image");
    }

    return null;
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
                  Navigator.pop(context);
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginEcran()),
    );
  }

  void _editProduit() async {
    await db.collection('produits').doc(editingProductId).update({
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
    editingProductId = '';
  }
  void _createProduit() async {
    if (img) {
      String uploadedImageUrl = await uploadImageToStorage(File(imageUrl));
      await db.collection('produits').add({
        'label': labelController.text,
        'brand': marqueController.text,
        'price': double.parse(prixController.text),
        'quantity': int.parse(quantityController.text),
        'categorie': categorieController.text,
        'image': uploadedImageUrl,
      });
      img = false;
    } else {
      print("Veuillez choisir une image.");
    }

    labelController.clear();
    marqueController.clear();
    prixController.clear();
    quantityController.clear();
    categorieController.clear();
  }
}

Future<String> uploadImageToStorage(File imageFile) async {
  try {
    final FirebaseStorage storage = FirebaseStorage.instance;
    final Reference storageReference = storage
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageReference.putFile(imageFile);
    String downloadURL = await storageReference.getDownloadURL();
    return downloadURL;
  } catch (error) {
    print("Error uploading image: $error");
    return '';
  }
}
