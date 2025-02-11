class Earn {
  String source, date;
  int amount, user_id, id;
  Earn(this.id, this.source, this.amount, this.date, this.user_id);

  Earn.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        source = json['source'] as String,
        amount = int.parse(json['amount']),
        date = json['date'] as String,
        user_id = int.parse(json['user_id']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'amount': amount,
        'date': date,
        'user_id': user_id,
      };
}
