import 'package:flutter/material.dart';

class DbConfigScreen extends StatelessWidget {
  const DbConfigScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Config')), body: const Center(child: Text('Database Configuration')));
  }
}
