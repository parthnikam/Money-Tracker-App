import 'package:flutter/material.dart';

import '../../../core/utils/icon_utils.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  IconData get icon => iconFromCodePoint(iconCodePoint);
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
