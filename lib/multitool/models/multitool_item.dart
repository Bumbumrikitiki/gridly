import 'package:flutter/material.dart';

class MultitoolItem {
  const MultitoolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String category;
}
