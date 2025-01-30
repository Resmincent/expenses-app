import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart';

const uuid = Uuid();

@HiveType(typeId: 0)
enum Category {
  @HiveField(0)
  food,
  @HiveField(1)
  travel,
  @HiveField(2)
  vehicle,
  @HiveField(3)
  family,
  @HiveField(4)
  etc
}

const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.travel: Icons.flight_takeoff,
  Category.vehicle: Icons.bike_scooter,
  Category.family: Icons.family_restroom,
  Category.etc: Icons.category,
};

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final Category category;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = uuid.v4();

  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String get formattedDate {
    final formatter = DateFormat.yMEd();
    return formatter.format(date);
  }
}

@HiveType(typeId: 2)
class ExpenseBucket extends HiveObject {
  @HiveField(0)
  final Category category;

  @HiveField(1)
  final List<Expense> expenses;

  ExpenseBucket({required this.category, required this.expenses});

  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((expense) => expense.category == category)
            .toList();

  double get totalExpense {
    double sum = 0;
    for (final expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }
}
