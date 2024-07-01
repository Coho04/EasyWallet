import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionCreateView extends StatefulWidget {
  const SubscriptionCreateView({super.key});

  @override
  _SubscriptionCreateViewState createState() => _SubscriptionCreateViewState();
}

class _SubscriptionCreateViewState extends State<SubscriptionCreateView> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedPayRate = 'Monatlich';
  String _selectedRememberCycle = 'Am selben Tag';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Abo hinzufügen'),
        actions: [
          TextButton(
            key: const Key('save_button'),
            onPressed: _isFormValid() ? _saveItem : null,
            child: const Text('Speichern', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (value) {
                if (!value.startsWith('https://')) {
                  _urlController.text = 'https://${value.replaceFirst('https://', '')}';
                  _urlController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _urlController.text.length));
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Anzahl'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Euro'),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Datum'),
              trailing: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Bezahlungsrate'),
              value: _selectedPayRate,
              items: ['Monatlich', 'Jährlich'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPayRate = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Erinnern Sie mich'),
              value: _selectedRememberCycle,
              items: ['Am selben Tag', 'Ein Tag vorher', 'Zwei Tage vorher', 'Eine Woche vorher'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRememberCycle = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notizen'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Abonnements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiken',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }

  bool _isFormValid() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    return _titleController.text.isNotEmpty && amount != null && amount >= 0 && amount <= 10000;
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveItem() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final url = _urlController.text;
    final notes = _notesController.text;

    if (amount != null) {
      final newSubscription = Subscription(
        title: title,
        amount: amount,
        date: _selectedDate,
        repeatPattern: _selectedPayRate,
        notes: notes,
        url: url,
        rememberCycle: _selectedRememberCycle,
        timestamp: DateTime.now(),
        isPaused: false,
        isPinned: false,
        repeating: true,
      );

      final viewContext = PersistenceController.instance;
      viewContext.saveSubscription(newSubscription);

      Navigator.of(context).pop();
    }
  }
}
