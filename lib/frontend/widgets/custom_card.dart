import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title, subtitle; final IconData icon; final VoidCallback onTap; final Color? iconColor;
  const CustomCard({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: Icon(icon, color: iconColor), title: Text(title), subtitle: Text(subtitle), onTap: onTap));
  }
}
