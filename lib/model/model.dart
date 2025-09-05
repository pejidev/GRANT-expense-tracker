class Recipes {
  final int? id;
  final String product_name;
  final num quantity;
  final num price;
  final num totalPrice;

  Recipes({
    this.id,
    required this.product_name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory Recipes.fromMap(Map<String, dynamic> map) {
    return Recipes(
      id: map['id'],
      product_name: map['product_name'],
      quantity: map['quantity'],
      price: map['price'],
      totalPrice: map['totalPrice'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_name': product_name,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }
}
