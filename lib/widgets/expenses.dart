import 'package:expense_app/chart/chart.dart';
import 'package:expense_app/widgets/expenses_list/expenses_list.dart';
import 'package:expense_app/models/expense.dart';
import 'package:expense_app/widgets/new_expenses.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  late Box<Expense> _expenseBox;
  List<Expense> _registeredExpenses = [];
  DateTime _selectedMonth = DateTime.now();

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

  List<Expense> get _filteredExpenses {
    return _registeredExpenses.where((expense) {
      return expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;
    }).toList();
  }

  double get _totalMonthlyExpenses {
    return _filteredExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  void _showMonthPicker() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
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
    try {
      final key = _expenseBox.length + 1;
      await _expenseBox.put(key, expense);

      setState(() {
        _registeredExpenses.add(expense);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add expense. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    final deletedExpense = _registeredExpenses[expenseIndex];

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
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 2,
    );

    Widget mainContent = const Center(
      child: Text('Tidak ada pengeluaran'),
    );

    if (_filteredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _filteredExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        actions: [
          TextButton.icon(
            onPressed: _showMonthPicker,
            icon: const Icon(
              Icons.calendar_month,
              color: Colors.white,
            ),
            label: Text(
              DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _filteredExpenses),
                Expanded(child: mainContent),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Chart(expenses: _filteredExpenses),
                ),
                Expanded(child: mainContent),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Pengeluaran Bulan Ini:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              formatter.format(_totalMonthlyExpenses),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
