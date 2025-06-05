import 'package:flutter/material.dart';

class CardModel {
  final String rank;
  final String suit;

  CardModel({required this.rank, required this.suit});

  String get label => '$rank$suit';

  Color get flutterColor {
    if (suit == '♠' || suit == '♣') {
      return Colors.black;
    } else {
      return Colors.red;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;
}