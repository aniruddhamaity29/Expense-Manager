class Expense {
  String purpose, date;
  int amount, user_id, id;
  Expense(this.id, this.purpose, this.amount, this.date, this.user_id);

  Expense.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        purpose = json['purpose'] as String,
        amount = int.parse(json['amount']),
        date = json['date'] as String,
        user_id = int.parse(json['user_id']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'purpose': purpose,
        'amount': amount,
        'date': date,
        'user_id': user_id,
      };
}
