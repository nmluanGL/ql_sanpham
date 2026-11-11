import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product(this.id, this.name, this.price, this.quantity, this.image);

  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      doc.id,
      data['name'] as String,
      data['price'] as num,
      data['soluong'] as int,
      data['image'] as String,
    );
  }

  final String id;
  final String name;
  final num price;
  final int quantity;
  final String image;
}

class ProductService {
  late final _products = FirebaseFirestore.instance.collection('products');

  // Firestore gửi danh sách mới khi có dữ liệu thay đổi.
  Stream<List<Product>> watchProducts() {
    return _products.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(Product.fromDocument).toList();
    });
  }

  Future<void> save({
    required Product? existing,
    required String name,
    required num price,
    required int quantity,
    required String imageUrl,
  }) async {
    final doc = existing == null ? _products.doc() : _products.doc(existing.id);
    final data = {
      'name': name,
      'price': price,
      'soluong': quantity,
      'image': imageUrl,
    };
    // ID nằm ở đường dẫn document. Firestore chỉ nhận bốn trường.
    if (existing == null) {
      await doc.set(data);
      return;
    }

    await doc.update(data);
  }

  Future<void> delete(String id) => _products.doc(id).delete();
}
