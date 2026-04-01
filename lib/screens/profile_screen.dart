import 'package:flutter/material.dart';

import '../viewmodels/profile_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final ProfileViewModel _viewModel = const ProfileViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_viewModel.title)),
      body: Center(child: Text(_viewModel.heading)),
    );
  }
}
