import 'category_model.dart';

class RecordModel {
  final int id;
  final double amount;
  final int categoryId;
  final DateTime recordDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecordModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.recordDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryModel? get category => getCategoryById(categoryId);

  RecordModel copyWith({
    int? id,
    double? amount,
    int? categoryId,
    DateTime? recordDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecordModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      recordDate: recordDate ?? this.recordDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
