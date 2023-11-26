import 'package:cloud_firestore/cloud_firestore.dart';
class Produit{
  String id;
  String marque;
  String label;
  String categorie;
  double prix;
  int quantity;

Produit ({
  required this.id,
  required this.marque,
  required this.label,
  required this.categorie,
  required this.prix,
  required this.quantity,
});
factory Produit.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Produit(
        id: doc.id,
        marque: data['brand'] ?? '',
        label: data['label'] ?? '',
        categorie: data['categorie'] ?? '',
        prix: (data['price'] ?? 0.0).toDouble(),
        quantity: data['quantity'] ?? 0);
  }
}