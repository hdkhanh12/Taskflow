import 'package:flutter/material.dart';

class Category {
  final String? id;
  final String name;
  final String iconPath;
  final Color color;
  final int taskCount;

  Category({
    this.id,
    required this.name,
    required this.iconPath,
    required this.color,
    required this.taskCount,
  });
}