import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/category_model.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final Record? recordToEdit;

  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      _isEditing = true;
      _amountController.text = widget.recordToEdit!.amount.toStringAsFixed(2);
      _selectedCategoryId = widget.recordToEdit!.categoryId;
      _selectedDate = widget.recordToEdit!.recordDate;
      _noteController.text = widget.recordToEdit!.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return amount > 0 && _selectedCategoryId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          _isEditing ? '编辑记录' : '记账',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount input
            _buildAmountInput(),

            // Category selection
            _buildCategoryGrid(),

            // Date picker
            _buildDatePicker(),

            // Note input
            _buildNoteInput(),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(
              '¥',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: AppTypography.amountLarge.copyWith(
                  fontSize: 48,
                  color: AppColors.expense,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: AppTypography.amountLarge.copyWith(
                    fontSize: 48,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('选择分类', style: AppTypography.titleMedium),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: defaultCategories.length,
            itemBuilder: (context, index) {
              final category = defaultCategories[index];
              final isSelected = _selectedCategoryId == category.id;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = category.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final dateFormat = DateFormat('yyyy年MM月dd日', 'zh_CN');

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text('日期', style: AppTypography.bodyLarge),
          const Spacer(),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              dateFormat.format(_selectedDate),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备注', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: '选填，最多100字...',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _canSave ? _saveRecord : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.textHint.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isEditing ? '保存修改' : '保存',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmExit(BuildContext context) {
    if (_amountController.text.isEmpty && _noteController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃记账？'),
        content: const Text('已输入的内容将不会保存'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              '放弃',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _selectedCategoryId == null) return;

    final database = await ref.read(databaseProvider.future);

    if (_isEditing) {
      await database.updateRecord(RecordsCompanion(
        id: drift.Value(widget.recordToEdit!.id),
        amount: drift.Value(amount),
        categoryId: drift.Value(_selectedCategoryId!),
        recordDate: drift.Value(_selectedDate),
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
        createdAt: drift.Value(widget.recordToEdit!.createdAt),
        updatedAt: drift.Value(DateTime.now()),
      ));
    } else {
      await database.insertRecord(RecordsCompanion.insert(
        amount: amount,
        categoryId: _selectedCategoryId!,
        recordDate: _selectedDate,
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
      ));
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '修改成功' : '记账成功'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
