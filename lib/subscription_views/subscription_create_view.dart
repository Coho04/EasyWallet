import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart'; // Assuming this file contains PersistenceController class

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
  String _selectedPayRate = 'Monthly';
  String _selectedRememberCycle = 'SameDay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isFormValid() ? _saveItem : null,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Euro'),
              ],
            ),
            ListTile(
              title: Text('Start Date: ${DateFormat.yMd().format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            DropdownButtonFormField<String>(
              decoration: const  InputDecoration(labelText: 'Payment rate'),
              value: _selectedPayRate,
              items: ['Monthly', 'Yearly', 'Weekly'].map((String value) {
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
            DropdownButtonFormField<String>(
              decoration: const  InputDecoration(labelText: 'Remind me'),
              value: _selectedRememberCycle,
              items: ['SameDay', 'OneDayBefore', 'TwoDaysBefore', 'OneWeekBefore'].map((String value) {
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
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
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
