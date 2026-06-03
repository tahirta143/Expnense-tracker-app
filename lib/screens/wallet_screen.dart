import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../themes/app_theme.dart';
import '../widgets/transfer_dialog.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallets = walletProvider.wallets;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120), // More padding for curved nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalBalance(context, walletProvider.totalBalance),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Accounts',
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showTransferDialog(context),
                      icon: const Icon(Icons.compare_arrows_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Transfer',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return _buildWalletCard(context, wallet);
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddWalletDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalBalance(BuildContext context, double total) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark 
            ? AppTheme.getPrimaryGradient() 
            : const LinearGradient(
                colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? AppTheme.primaryColor.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Net Balance',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.black87 : Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs ${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(wallet.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          wallet.name,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          wallet.type,
          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${wallet.balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: wallet.balance >= 0 ? AppTheme.primaryColor : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.textTheme.bodySmall?.color, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditWalletDialog(context, wallet);
                } else if (value == 'delete') {
                  _confirmDeleteWallet(context, wallet);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 10),
                      Text('Edit', style: TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: AppTheme.errorColor, size: 18),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, Wallet wallet) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.balance.toStringAsFixed(0));
    String selectedType = wallet.type;
    final types = ['Cash', 'Bank', 'Easypaisa', 'JazzCash', 'Credit Card'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Wallet Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Balance', prefixText: 'Rs '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              dropdownColor: theme.cardColor,
              items: types.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
              )).toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: 'Wallet Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final updatedWallet = wallet.copyWith(
                name: nameController.text,
                balance: double.tryParse(balanceController.text) ?? wallet.balance,
                type: selectedType,
                icon: _getIconForType(selectedType),
              );
              Provider.of<WalletProvider>(context, listen: false).updateWallet(updatedWallet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, Wallet wallet) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text('Are you sure you want to delete "${wallet.name}"? All associated transaction links will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color))),
          TextButton(
            onPressed: () {
              Provider.of<WalletProvider>(context, listen: false).deleteWallet(wallet.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TransferDialog(),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'Cash';
    final types = ['Cash', 'Bank', 'Easypaisa', 'JazzCash', 'Credit Card'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add New Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Wallet Name',
                hintText: 'e.g., My Savings',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Initial Balance',
                prefixText: 'Rs ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              dropdownColor: theme.cardColor,
              items: types.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
              )).toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: 'Wallet Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final wallet = Wallet(
                name: nameController.text,
                balance: double.tryParse(balanceController.text) ?? 0.0,
                type: selectedType,
                icon: _getIconForType(selectedType),
              );
              Provider.of<WalletProvider>(context, listen: false).addWallet(wallet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getIconForType(String type) {
    switch (type) {
      case 'Cash': return '💵';
      case 'Bank': return '🏦';
      case 'Easypaisa': return '📱';
      case 'JazzCash': return '📲';
      case 'Credit Card': return '💳';
      default: return '👛';
    }
  }
}
