import 'package:hive/hive.dart';

part 'used_amount_model.g.dart';

class AmountState {

  AmountState(this.requiredAmount, this.usedAmount);
  final double requiredAmount;
  final double usedAmount;
}

@HiveType(typeId: 7) // You can change the typeId as needed, ensure that no two classes share the same typeId
class UsedAmountData {

  UsedAmountData({required this.date, required this.usedAmount});

  factory UsedAmountData.fromMap(Map<String, dynamic> data) => UsedAmountData(
    date: data['date'] as String,
    usedAmount: data['usedAmount'] as double,
  );

  @HiveField(0)
  final String date;

  @HiveField(1)
  final double usedAmount;

  Map<String, dynamic> toMap() => {
    'date': date,
    'usedAmount': usedAmount,
  };
}
