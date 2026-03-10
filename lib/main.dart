import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

void main() => runApp(const ExpenseApp());

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gold Digger',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _filteredTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  String _selectedMonth = DateFormat('MM').format(DateTime.now());

  // User Preferences
  String? _profilePicPath;
  String _userName = "Tap to set name";
  String _currency = "\$";

  final List<String> _categories = [
    'Bills',
    'Groceries',
    'Mortgage',
    'Investment',
    'Lump Sum',
    'Salary',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _refreshData();
  }

  // --- PREFERENCES LOGIC (Name, Pic, Currency) ---
  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePicPath = prefs.getString('profile_pic');
      _userName = prefs.getString('user_name') ?? "Tap to set name";
      _currency = prefs.getString('currency') ?? "\$";
    });
  }

  void _updateCurrency(String newCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency);
    setState(() => _currency = newCurrency);
  }

  void _editUserName() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Username"),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', controller.text);
              setState(() => _userName = controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_pic', image.path);
      setState(() => _profilePicPath = image.path);
    }
  }

  // --- DATA REFRESH ---
  void _refreshData() async {
    final data = await DatabaseHelper.instance.queryAll();
    double income = 0;
    double expense = 0;
    List<Map<String, dynamic>> filtered = data
        .where((tx) => tx['date'].substring(5, 7) == _selectedMonth)
        .toList();
    for (var item in filtered) {
      if (item['type'] == 'Income')
        income += item['amount'];
      else
        expense += item['amount'];
    }
    setState(() {
      _filteredTransactions = filtered;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gold Digger',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade100,
        actions: [
          _buildCurrencyDropdown(),
          _buildMonthDropdown(),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportToCSV),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildBarChart(),
          _buildSummaryCard(),
          const Divider(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButton<String>(
      value: _currency,
      underline: Container(),
      icon: const Icon(Icons.payments_outlined, color: Colors.teal),
      items: ['\$', '₹', '£', '€'].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (val) {
        if (val != null) _updateCurrency(val);
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: InkWell(
              onTap: _editUserName,
              child: Row(
                children: [
                  Text(_userName, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 16, color: Colors.white70),
                ],
              ),
            ),
            accountEmail: const Text("Financial Dashboard"),
            currentAccountPicture: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _profilePicPath != null
                    ? FileImage(File(_profilePicPath!))
                    : null,
                child: _profilePicPath == null
                    ? const Icon(Icons.camera_alt, color: Colors.teal)
                    : null,
              ),
            ),
            decoration: BoxDecoration(color: Colors.teal.shade700),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Reset All Transactions"),
            onTap: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('transactions');
              _refreshData();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButton<String>(
      value: _selectedMonth,
      underline: Container(),
      icon: const Icon(Icons.calendar_month, color: Colors.teal),
      items: List.generate(12, (i) {
        String m = (i + 1).toString().padLeft(2, '0');
        return DropdownMenuItem(value: m, child: Text(" $m "));
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedMonth = val);
          _refreshData();
        }
      },
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              (_totalIncome > _totalExpense ? _totalIncome : _totalExpense) +
              500,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _totalIncome,
                  color: Colors.green,
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _totalExpense,
                  color: Colors.red,
                  width: 20,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value == 0 ? 'In' : 'Out', style: style),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double savings = _totalIncome - _totalExpense;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn("Income", _totalIncome, Colors.green),
            _statColumn("Expense", _totalExpense, Colors.red),
            _statColumn(
              "Net",
              savings,
              savings >= 0 ? Colors.teal : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          "$_currency${amount.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty)
      return const Center(child: Text("No data found for this month."));
    return ListView.builder(
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = _filteredTransactions[index];
        return Dismissible(
          key: Key(tx['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade300,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (dir) {
            final db = DatabaseHelper.instance.database; // Handled via ID
            DatabaseHelper.instance.database.then(
              (db) => db.delete(
                'transactions',
                where: 'id = ?',
                whereArgs: [tx['id']],
              ),
            );
            _refreshData();
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tx['type'] == 'Income'
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                tx['type'] == 'Income' ? Icons.north_east : Icons.south_west,
                color: tx['type'] == 'Income' ? Colors.green : Colors.red,
                size: 18,
              ),
            ),
            title: Text(
              tx['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${tx['category']} • ${tx['date'].substring(0, 10)}",
            ),
            trailing: Text(
              "$_currency${tx['amount']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tx['type'] == 'Income' ? Colors.green : Colors.black,
              ),
            ),
            onLongPress: () => _showAddDialog(editTx: tx),
          ),
        );
      },
    );
  }

  void _showAddDialog({Map<String, dynamic>? editTx}) {
    final nameController = TextEditingController(text: editTx?['title'] ?? '');
    final amountController = TextEditingController(
      text: editTx?['amount']?.toString() ?? '',
    );
    String selectedType = editTx?['type'] ?? 'Expense';
    String selectedCat = editTx?['category'] ?? 'Groceries';
    DateTime selectedDate = editTx != null
        ? DateTime.parse(editTx['date'])
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editTx == null ? 'New Entry' : 'Edit Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Expense', 'Income']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedCat = val!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null)
                      setDialogState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    amountController.text.isEmpty)
                  return;
                final data = {
                  'title': nameController.text,
                  'amount': double.parse(amountController.text),
                  'category': selectedCat,
                  'type': selectedType,
                  'date': selectedDate.toIso8601String(),
                };
                if (editTx == null)
                  await DatabaseHelper.instance.insert(data);
                else {
                  final db = await DatabaseHelper.instance.database;
                  await db.update(
                    'transactions',
                    data,
                    where: 'id = ?',
                    whereArgs: [editTx['id']],
                  );
                }
                _refreshData();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [
      ["ID", "Name", "Amount", "Category", "Type", "Date"],
    ];
    for (var tx in _filteredTransactions) {
      rows.add([
        tx['id'],
        tx['title'],
        tx['amount'],
        tx['category'],
        tx['type'],
        tx['date'],
      ]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File(
      "${directory.path}/GoldDigger_Report_$_selectedMonth.csv",
    );
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'My Finance Report');
  }
}
