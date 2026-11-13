import 'package:flutter/material.dart';

/// Ícone de cada avatar do catálogo (`kAvatarCatalog`).
IconData iconeDoAvatar(String? chave) {
  switch (chave) {
    case 'sword':
      return Icons.gavel;
    case 'shield':
      return Icons.shield;
    case 'bolt':
      return Icons.bolt;
    case 'star':
      return Icons.star;
    case 'flame':
      return Icons.local_fire_department;
    case 'person':
    default:
      return Icons.person;
  }
}
