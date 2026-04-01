import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<OrderModel>> _loadOrders() async {
    final user = _authService.currentUser;
    if (user == null) {
      return [];
    }
    return _firebaseService.getOrdersByUser(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('L\u1ecbch s\u1eed thu\u00ea')),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c l\u1ecbch s\u1eed thu\u00ea',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Ch\u01b0a c\u00f3 \u0111\u01a1n thu\u00ea n\u00e0o'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final dateText = DateFormat(
                AppConstants.dateTimeFormat,
              ).format(order.createdAt);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.branchName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        _OrderStatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Ng\u00e0y t\u1ea1o: $dateText'),
                    Text('S\u1ed1 s\u1ea3n ph\u1ea9m: ${order.totalItemCount}'),
                    Text('S\u1ed1 ng\u00e0y thu\u00ea: ${order.rentalDays}'),
                    const SizedBox(height: 6),
                    Text(
                      'T\u1ed5ng ph\u00ed thu\u00ea: ${AppConstants.formatPrice(order.totalRentalFee)}',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getStatusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppConstants.getStatusName(status),
        style: TextStyle(
          color: AppColors.getStatusColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
