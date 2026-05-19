import 'package:flutter/material.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final bool isNew;

  ServiceItem({
    required this.title,
    required this.icon,
    this.isNew = false,
  });
}