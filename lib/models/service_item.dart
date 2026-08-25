import 'package:flutter/material.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final bool isNew;
  final bool isSoon;

  ServiceItem({
    required this.title,
    required this.icon,
    this.isNew = false,
    this.isSoon = false,
  });
}