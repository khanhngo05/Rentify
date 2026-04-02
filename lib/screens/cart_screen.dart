import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../constants/app_constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng'), centerTitle: true),
      body: ListenableBuilder(
        listenable: cartController,
        builder: (context, _) {
          if (cartController.items.isEmpty) return const Center(child: Text('Giỏ hàng trống'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: cartController.items.map((i) => Card(child: ListTile(title: Text(i.productName), subtitle: Text('Size: ${i.size}')))).toList(),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton(onPressed: () { cartController.clearCart(); Navigator.pop(context); }, child: const Text('Xác nhận đặt thuê')),
      ),
    );
  }
}