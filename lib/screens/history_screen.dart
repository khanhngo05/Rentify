import 'package:flutter/material.dart';

import '../viewmodels/history_view_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final HistoryViewModel _viewModel = const HistoryViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_viewModel.title)),
      body: Center(child: Text(_viewModel.emptyMessage)),
    );
  }
}
