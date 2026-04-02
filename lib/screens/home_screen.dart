import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../viewmodels/home_view_model.dart';
import 'cart_screen.dart';
import 'order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(firebaseService: FirebaseService());
    _viewModel.loadProducts();
    _viewModel.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const Center(child: Text('Home Content')), const Center(child: Text('Chi nhánh')), const OrderScreen(), const Center(child: Text('Tôi'))];
    return Scaffold(
      appBar: AppBar(title: const Text('Rentify'), actions: [IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())))]),
      body: pages[_viewModel.selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _viewModel.selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _viewModel.onTabChanged,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Chi nhánh'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}