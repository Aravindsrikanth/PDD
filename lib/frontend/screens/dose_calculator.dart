import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icu_app/backend/models/medication.dart';
import 'package:icu_app/backend/state/app_state.dart';

class DoseCalculatorScreen extends StatefulWidget {
  const DoseCalculatorScreen({super.key});
  @override State<DoseCalculatorScreen> createState() => _DoseCalculatorScreenState();
}

class _DoseCalculatorScreenState extends State<DoseCalculatorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Dose Calculator')), body: const Center(child: Text('Calculator Ready')));
  }
}
