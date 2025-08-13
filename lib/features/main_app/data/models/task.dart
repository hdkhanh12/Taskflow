import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  final String? id;
  final String title;
  final String time;
  final bool isCompleted;
  final String category; // Tên category
  final String? categoryId; // ID của category
  final Color color;
  final Timestamp? dueTimestamp;
  final String? dueDate;

  Task({
    this.id,
    required this.title,
    required this.time,
    this.isCompleted = false,
    required this.category,
    this.categoryId,
    required this.color,
    this.dueTimestamp,
    this.dueDate,
  });
}