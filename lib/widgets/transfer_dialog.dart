import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../themes/app_theme.dart';

class TransferDialog extends StatefulWidget {
  const TransferDialog({super.key});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  int? _fromWalletId;
  int? _toWalletId;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallets = Provider.of<WalletProvider>(context).wallets;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Transfer Money',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _fromWalletId,
              dropdownColor: theme.cardColor,
              hint: const Text('From Wallet'),
              items: wallets.map((w) => DropdownMenuItem(
                value: w.id, 
                child: Text('${w.icon} ${w.name}', style: TextStyle(color: theme.textTheme.bodyLarge?.color))
              )).toList(),
              onChanged: (val) => setState(() => _fromWalletId = val),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.outbox_rounded, color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _toWalletId,
              dropdownColor: theme.cardColor,
              hint: const Text('To Wallet'),
              items: wallets.map((w) => DropdownMenuItem(
                value: w.id, 
                child: Text('${w.icon} ${w.name}', style: TextStyle(color: theme.textTheme.bodyLarge?.color))
              )).toList(),
              onChanged: (val) => setState(() => _toWalletId = val),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.move_to_inbox_rounded, color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Amount', 
                prefixText: 'Rs ',
                prefixStyle: TextStyle(color: AppTheme.primaryColor),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color))
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination wallets')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    Provider.of<WalletProvider>(context, listen: false).performTransfer(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      date: _selectedDate,
      notes: _notesController.text,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer recorded successfully!')),
    );
  }
}
