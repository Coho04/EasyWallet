import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';

class SubscriptionCreateView extends StatefulWidget {
  const SubscriptionCreateView({super.key});

  @override
  SubscriptionCreateViewState createState() => SubscriptionCreateViewState();
}

class SubscriptionCreateViewState extends State<SubscriptionCreateView> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedPayRate = PaymentRate.monthly.value;
  String _selectedRememberCycle = RememberCycle.sameDay.value;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Abo hinzufügen'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isFormValid() ? _saveItem : null,
          child: const Text('Speichern'),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Title',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _urlController,
              placeholder: 'URL',
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _amountController,
                    placeholder: 'Anzahl',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Euro'),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoFormRow(
              child: GestureDetector(
                onTap: _pickDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Start Datum'),
                    Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoFormRow(
              child: GestureDetector(
                onTap: () => _showPicker(
                  context,
                  PaymentRate.all(),
                      (index) {
                    setState(() {
                      _selectedPayRate = PaymentRate.all()[index];
                    });
                  },
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment rate'),
                    Text(_selectedPayRate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoFormRow(
              child: GestureDetector(
                onTap: () => _showPicker(
                  context,
                  RememberCycle.all(),
                      (index) {
                    setState(() {
                      _selectedRememberCycle = RememberCycle.all()[index];
                    });
                  },
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remind me'),
                    Text(_selectedRememberCycle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'Notizen',
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
    final DateTime? pickedDate = await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _showPicker(BuildContext context, List<String> items, Function(int) onSelectedItemChanged) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32,
                  useMagnifier: true,
                  onSelectedItemChanged: onSelectedItemChanged,
                  children: items.map((e) => Text(e)).toList(),
                ),
              ),
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
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
