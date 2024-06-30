import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_wallet/persistence_controller.dart'; // Assuming this file contains PersistenceController class

class SubscriptionEditView extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionEditView({super.key, required this.subscription});

  @override
  _SubscriptionEditViewState createState() => _SubscriptionEditViewState();
}

class _SubscriptionEditViewState extends State<SubscriptionEditView> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _date = DateTime.now();
  String _paymentRate = 'monthly';
  String _rememberCycle = 'SameDay';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subscription.title ?? '');
    _urlController = TextEditingController(text: widget.subscription.url ?? '');
    _amountController = TextEditingController(text: widget.subscription.amount.toString());
    _notesController = TextEditingController(text: widget.subscription.notes ?? '');
    _date = widget.subscription.date ?? DateTime.now();
    _paymentRate = widget.subscription.repeatPattern ?? 'monthly';
    _rememberCycle = widget.subscription.rememberCycle ?? 'SameDay';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    return _titleController.text.isNotEmpty && amount != null && amount >= 0 && amount <= 10000;
  }

  void _saveItem() {
    final subscription = widget.subscription;
    subscription.title = _titleController.text;
    subscription.url = _urlController.text;
    subscription.amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    subscription.date = _date;
    subscription.notes = _notesController.text;
    subscription.repeatPattern = _paymentRate;
    subscription.rememberCycle = _rememberCycle;

    final viewContext = Provider.of<PersistenceController>(context, listen: false);
    viewContext.saveSubscription(subscription);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isFormValid ? _saveItem : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autocorrect: false,
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autocorrect: false,
              ),
              DropdownButtonFormField<String>(
                value: _paymentRate,
                decoration: const InputDecoration(labelText: 'Payment rate'),
                items: ['monthly', 'yearly'].map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text(rate.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentRate = value!;
                  });
                },
              ),
              InputDatePickerFormField(
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                fieldLabelText: 'Start Date',
                onDateSaved: (date) {
                  setState(() {
                    _date = date;
                  });
                },
                onDateSubmitted: (date) {
                  setState(() {
                    _date = date;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _rememberCycle,
                decoration: const InputDecoration(labelText: 'Remind me'),
                items: ['SameDay', 'OneDayBefore', 'OneWeekBefore'].map((cycle) {
                  return DropdownMenuItem(
                    value: cycle,
                    child: Text(cycle.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _rememberCycle = value!;
                  });
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const  InputDecoration(labelText: 'Notes'),
                autocorrect: false,
              ),
              ElevatedButton(
                onPressed: _isFormValid ? _saveItem : null,
                child: const  Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this == null) {
      throw ArgumentError("string: $this");
    }

    if (this.isEmpty) {
      return this;
    }

    return this[0].toUpperCase() + this.substring(1);
  }
}