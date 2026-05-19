import 'package:flutter/material.dart';

extension ColorOpacity on Color {
  Color o(double opacity) => withAlpha((opacity * 255).round());
}