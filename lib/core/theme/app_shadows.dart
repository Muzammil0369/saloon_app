import 'package:flutter/material.dart';

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x14D4487A),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const soft = [
    BoxShadow(
      color: Color(0x0AD4487A),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  static const banner = [
    BoxShadow(
      color: Color(0x4DD4487A),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];
}