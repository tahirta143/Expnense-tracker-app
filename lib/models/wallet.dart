class Wallet {
  final int? id;
  final String name;
  final double balance;
  final String type; // Cash, Bank, Easypaisa, JazzCash, Credit Card
  final String icon;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0.0,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'icon': icon,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      type: map['type'] as String,
      icon: map['icon'] as String,
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
    String? type,
    String? icon,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      icon: icon ?? this.icon,
    );
  }
}
