import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/record_provider.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final Record? recordToEdit;

  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  /// 九宫格数字键盘输入的原始字符串（含小数点，最多 9 位）。
  /// 替代原来的 _amountController + TextField。
  String _amountInput = '';
  final _noteController = TextEditingController();
  int? _selectedCategoryId;
  String _recordType = 'expense'; // 'expense' or 'income'
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      _isEditing = true;
      _amountInput = widget.recordToEdit!.amount.toStringAsFixed(2);
      _selectedCategoryId = widget.recordToEdit!.categoryId;
      _recordType = widget.recordToEdit!.type;
      _noteController.text = widget.recordToEdit!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final amount = double.tryParse(_amountInput) ?? 0;
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
          key: const Key('close-btn'),
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          '记一笔',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 顶部内容区（可滚动）：切换、金额、分类、备注
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Type toggle
                  _buildTypeToggle(),

                  // 金额显示（数字由 _amountInput 驱动，仅展示，不可点击编辑）
                  _buildAmountDisplay(),

                  // Category selection
                  _buildCategoryGrid(),

                  // 备注输入（最多 100 字）
                  _buildNoteInput(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 九宫格数字键盘（固定底部，始终可见，对齐原型 numpad）
          _buildNumpad(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypeButton('支出', 'expense'),
          const SizedBox(width: 16),
          _buildTypeButton('收入', 'income'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _recordType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_recordType != type) {
            _recordType = type;
            _selectedCategoryId = null; // Clear category when switching type
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 金额显示区：¥ + 大字金额（来自 _amountInput）+ 闪烁光标。
  /// 不可编辑，纯展示；编辑通过下方九宫格键盘。
  Widget _buildAmountDisplay() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: Column(
        children: [
          Text(
            '金额（元）',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _amountInput.isEmpty ? '0' : _amountInput,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: -1,
                ),
              ),
              // 闪烁光标
              _BlinkingCursor(),
            ],
          ),
        ],
      ),
    );
  }

  /// 九宫格数字键盘：3 列 × 4 行 = 12 键。
  /// 1 2 3 / 4 5 6 / 7 8 9 / . 0 ⌫
  Widget _buildNumpad() {
    final keys = <_NumpadKey>[
      const _NumpadKey('1'),
      const _NumpadKey('2'),
      const _NumpadKey('3'),
      const _NumpadKey('4'),
      const _NumpadKey('5'),
      const _NumpadKey('6'),
      const _NumpadKey('7'),
      const _NumpadKey('8'),
      const _NumpadKey('9'),
      const _NumpadKey('.'),
      const _NumpadKey('0'),
      const _NumpadKey.del(),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: keys.map((k) => _buildNumpadKey(k)).toList(),
      ),
    );
  }

  Widget _buildNumpadKey(_NumpadKey k) {
    final isDel = k.value == 'del';
    return GestureDetector(
      onTap: () => _onNumpadTap(k.value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          k.display,
          style: TextStyle(
            fontSize: isDel ? 18 : 20,
            fontWeight: FontWeight.w500,
            color: isDel ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// 处理数字键盘按键：
  /// - 限制总长度 9 位
  /// - 小数点仅允许一个
  /// - del 退格
  void _onNumpadTap(String key) {
    setState(() {
      if (key == 'del') {
        if (_amountInput.isNotEmpty) {
          _amountInput = _amountInput.substring(0, _amountInput.length - 1);
        }
        return;
      }
      if (_amountInput.length >= 9) return;
      if (key == '.' && _amountInput.contains('.')) return;
      _amountInput += key;
    });
  }

  Widget _buildCategoryGrid() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Filter categories by current type
        final filteredCategories = categories.where((c) => c.type == _recordType).toList();
        final count = filteredCategories.length;
        final typeLabel = _recordType == 'expense' ? '支出' : '收入';

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('选择分类（$typeLabel $count 类）', style: AppTypography.titleMedium),
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
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final isSelected = _selectedCategoryId == category.id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = category.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('加载分类失败')),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备注（选填）', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: '备注（选填）...',
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
            color: Colors.black.withValues(alpha: 0.05),
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
            disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
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

  void _confirmExit(BuildContext context) {
    if (_amountInput.isEmpty && _noteController.text.isEmpty) {
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
    final amount = double.tryParse(_amountInput) ?? 0;
    if (amount <= 0 || _selectedCategoryId == null) return;

    final database = await ref.read(databaseProvider.future);

    if (_isEditing) {
      await database.updateRecord(RecordsCompanion(
        id: drift.Value(widget.recordToEdit!.id),
        amount: drift.Value(amount),
        categoryId: drift.Value(_selectedCategoryId!),
        recordDate: drift.Value(widget.recordToEdit!.recordDate),
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
        type: drift.Value(_recordType),
        createdAt: drift.Value(widget.recordToEdit!.createdAt),
        updatedAt: drift.Value(DateTime.now()),
      ));
    } else {
      await database.insertRecord(RecordsCompanion.insert(
        amount: amount,
        categoryId: _selectedCategoryId!,
        recordDate: DateTime.now(),
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
        type: drift.Value(_recordType),
      ));
    }

    if (mounted) {
      // D3: 保存成功后，首页自动切到对应收支类型视图（原型 A6 / 6.1）
      ref.read(selectedTypeProvider.notifier).state = _recordType;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_recordType == 'expense' ? '支出已记录 ✓' : '收入已记录 ✓'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

/// 数字键盘按键值
class _NumpadKey {
  final String value; // '0'..'9' / '.' / 'del'
  const _NumpadKey(this.value);
  const _NumpadKey.del() : value = 'del';

  String get display {
    if (value == 'del') return '⌫';
    return value;
  }
}

/// 金额显示区右侧的竖线光标（静态，避免 AnimationController 让 widget test pumpAndSettle 超时）
class _BlinkingCursor extends StatelessWidget {
  const _BlinkingCursor();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 32,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
