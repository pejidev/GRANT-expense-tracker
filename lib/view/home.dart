import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:endterm/view/create_transaction_screen.dart';
import 'package:endterm/view/main_screen.dart';
import 'package:endterm/view/transactions_list_screen.dart';
import 'package:endterm/view/expenses_page.dart';
import 'package:endterm/view/savings_page.dart'; // Import the SavingsPage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MainScreen(),
      const TransactionsListScreen(),
      ExpensesPage(onNext: _handleExpensesFinished),
      const SavingsPage(), // Add SavingsPage
    ];
  }

  void _handleExpensesFinished() {
    // Handle navigation after expenses setup is finished
    setState(() {
      _selectedIndex = 0; // Navigate to home screen
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expenses setup completed!')),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRANT'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Required for more than 3 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_square_fill),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.money_dollar_circle),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard),
            label: 'Savings',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTransactionScreen(),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }
}