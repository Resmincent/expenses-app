import 'package:expense_app/chart/chart.dart';
import 'package:expense_app/widgets/expenses_list/expenses_list.dart';
import 'package:expense_app/models/expense.dart';
import 'package:expense_app/widgets/new_expenses.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  late Box<Expense> _expenseBox;
  List<Expense> _registeredExpenses = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _expenseBox = Hive.box<Expense>('expenses');
    _loadExpenses();
  }

  void _loadExpenses() {
    setState(() {
      _registeredExpenses = _expenseBox.values.toList();
    });
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => NewExpenses(
        onAddExpense: _addExpense,
      ),
    );
  }

  Future<void> _addExpense(Expense expense) async {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  Future<void> _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    final deletedExpense = _registeredExpenses[expenseIndex];

    // Find the key in Hive box for this expense
    final key = _expenseBox.keys.firstWhere(
      (k) => _expenseBox.get(k)?.id == expense.id,
      orElse: () => -1,
    );

    if (key != -1) {
      await _expenseBox.delete(key);
    }

    setState(() {
      _registeredExpenses.remove(expense);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _expenseBox.add(deletedExpense);
            setState(() {
              _registeredExpenses.insert(expenseIndex, deletedExpense);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget mainContent = const Center(
      child: Text('Tidak ada pengeluaran'),
    );

    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengeluaran',
        ),
        actions: [
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(
              Icons.add,
            ),
          )
        ],
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _registeredExpenses),
                Expanded(child: mainContent),
              ],
            )
          : Column(
              children: [
                Expanded(child: Chart(expenses: _registeredExpenses)),
                Expanded(child: mainContent),
              ],
            ),
    );
  }
}
