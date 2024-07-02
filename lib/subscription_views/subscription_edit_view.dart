import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionEditView extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionEditView({super.key, required this.subscription});

  @override
  SubscriptionEditViewState createState() => SubscriptionEditViewState();
}

class SubscriptionEditViewState extends State<SubscriptionEditView> {
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
    _titleController =
        TextEditingController(text: widget.subscription.title ?? '');
    _urlController = TextEditingController(text: widget.subscription.url ?? '');
    _amountController =
        TextEditingController(text: widget.subscription.amount.toString());
    _notesController =
        TextEditingController(text: widget.subscription.notes ?? '');
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
    return _titleController.text.isNotEmpty &&
        amount != null &&
        amount >= 0 &&
        amount <= 10000;
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Abo bearbeiten'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isFormValid ? _saveItem : null,
          child: const Text('Speichern'),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Titel',
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _urlController,
                placeholder: 'URL',
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child:
                      CupertinoTextField(
                        controller: _amountController,
                        placeholder: 'Kosten',
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
                prefix: const Text('Bezahlrate'),
                child: CupertinoPicker(
                  itemExtent: 32,
                  useMagnifier: true,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _paymentRate = ['monthly', 'yearly'][index];
                    });
                  },
                  children: ['monthly', 'yearly'].map((e) => Text(e.capitalize())).toList(),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoFormRow(
                prefix: const Text('Start Datum'),
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(_date),
                    style: const TextStyle(fontSize: 16, color: CupertinoColors.inactiveGray),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoFormRow(
                prefix: const Text('Erinnern an'),
                child: CupertinoPicker(
                  itemExtent: 32,
                  useMagnifier: true,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _rememberCycle = ['SameDay', 'OneDayBefore', 'OneWeekBefore'][index];
                    });
                  },
                  children: ['SameDay', 'OneDayBefore', 'OneWeekBefore'].map((e) => Text(e.capitalize())).toList(),
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
      ),
    );
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
                  initialDateTime: _date,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _date = newDate;
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
    if (pickedDate != null && pickedDate != _date) {
      setState(() {
        _date = pickedDate;
      });
    }
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
