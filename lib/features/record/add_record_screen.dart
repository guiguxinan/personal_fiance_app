import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/record_provider.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final Record? recordToEdit;
  /// V3.1 (M3b)：复记预填（与编辑互斥；预填=新记录，日期=今天，备注清空）
  final Record? prefillRecord;

  const AddRecordScreen({super.key, this.recordToEdit, this.prefillRecord});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  /// 九宫格数字键盘输入的原始字符串（含小数点，最多 9 位）。
  String _amountInput = '';
  /// V3.0 N2：金额区默认折叠，点击金额区才唤起键盘
  bool _showNumpad = false;
  /// V3.0 N1：所选记录日期（默认当天，可通过日期行改选当天及以前）
  DateTime _selectedDate = DateTime.now();
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
      // 编辑模式：日期回填为原记录日期
      _selectedDate = widget.recordToEdit!.recordDate;
      _noteController.text = widget.recordToEdit!.note ?? '';
    } else if (widget.prefillRecord != null) {
      // M3b 复记：预填 type/amount/categoryId；日期=今天；备注清空
      _amountInput = widget.prefillRecord!.amount.toStringAsFixed(2);
      _selectedCategoryId = widget.prefillRecord!.categoryId;
      _recordType = widget.prefillRecord!.type;
      _selectedDate = DateTime.now();
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
          // S2 修复：恢复 V2.1 布局——内容区可滚动，键盘固定底部始终可见
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Type toggle
                  _buildTypeToggle(),

                  // 金额显示（点击切换键盘显示，对齐 V3.0 N2）
                  _buildAmountDisplay(),

                  // Category selection
                  _buildCategoryGrid(),

                  // V3.0 N1：日期行（点击弹出日历选择器）
                  _buildDateRow(),

                  // V3.0 N3：备注行（点击弹出输入框）
                  _buildNoteRow(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // S2 修复：键盘作为 Column 第二项，固定在 bottomNavigationBar 上方，_showNumpad 仅控制显隐
          if (_showNumpad) _buildNumpad(),
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
          _buildTypeButton('收入', 'income'),
          const SizedBox(width: 16),
          _buildTypeButton('支出', 'expense'),
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
  /// V3.0 N2：点击金额区唤起/收起九宫格键盘；label 文案"金额（元）· 点我输入"。
  Widget _buildAmountDisplay() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showNumpad = !_showNumpad),
        child: Column(
          children: [
            Text(
              _showNumpad ? '金额（元）' : '金额（元）· 点我输入',
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
                // 键盘唤起时显示静态光标
                if (_showNumpad) const _BlinkingCursor(),
              ],
            ),
          ],
        ),
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
  /// - O5 修复：输入即净化（去前导 0、".5" → "0.5"、"12." → "12"）
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
      // O5：去前导 0（保留单个 "0"）；孤立 "." 补 "0."
      if (_amountInput.length > 1 && _amountInput.startsWith('0') && !_amountInput.startsWith('0.')) {
        _amountInput = _amountInput.replaceFirst(RegExp(r'^0+'), '');
        if (_amountInput.isEmpty) _amountInput = '0';
      }
      if (_amountInput == '.') _amountInput = '0.';
    });
  }

  /// V3.0 N1：日期行（form-row 样式）
  /// 真机 bug 修复：原 InkWell 包裹 Row + 嵌套在 Container(color:surface) 中
  /// 导致部分真机 InkWell tap 区域被吃。改用 GestureDetector(behavior: opaque) 显式吞事件。
  Widget _buildDateRow() {
    final dateFormat = DateFormat('yyyy年MM月dd日', 'zh_CN');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.surface,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.textHint),
              const SizedBox(width: 12),
              Text('日期', style: AppTypography.bodyLarge),
              const Spacer(),
              Text(
                dateFormat.format(_selectedDate),
                style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// V3.0 N1：弹出日历选择器，禁止未来日期
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now, // 禁止未来日期
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  /// V3.0 N3：备注行（点击弹出 BottomSheet 输入框）
  Widget _buildNoteRow() {
    final hasNote = _noteController.text.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.surface,
      child: InkWell(
        onTap: _showNoteDialog,
        child: Row(
          children: [
            const Icon(Icons.edit_note, size: 20, color: AppColors.textHint),
            const SizedBox(width: 12),
            Text('备注', style: AppTypography.bodyLarge),
            const Spacer(),
            Flexible(
              child: Text(
                hasNote ? _noteController.text : '选填，点我输入...',
                style: AppTypography.bodyLarge.copyWith(
                  color: hasNote ? AppColors.textPrimary : AppColors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }

  /// V3.0 N3：底部抽屉弹窗，承载备注 TextField
  Future<void> _showNoteDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('备注（选填）', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 100,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '请输入备注...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('确定',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    // M3a：最近使用分类（按当前收支类型近 30 天频次 Top 3）
    final recentAsync = ref.watch(recentCategoriesProvider(_recordType));

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

              // M3a：最近使用分类 pill 行
              recentAsync.when(
                data: (recents) {
                  if (recents.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近使用',
                          style: TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recents.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final c = recents[i];
                              final isSelected = _selectedCategoryId == c.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategoryId = c.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.line,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c.icon, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // 常规分类网格
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
        // M1 修复：编辑模式下使用 _selectedDate（原写死 widget.recordToEdit!.recordDate，改日期不生效）
        recordDate: drift.Value(_selectedDate),
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
        type: drift.Value(_recordType),
        createdAt: drift.Value(widget.recordToEdit!.createdAt),
        updatedAt: drift.Value(DateTime.now()),
      ));
    } else {
      await database.insertRecord(RecordsCompanion.insert(
        amount: amount,
        categoryId: _selectedCategoryId!,
        recordDate: _selectedDate,
        note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
        type: drift.Value(_recordType),
      ));
    }

    if (mounted) {
      // D3: 保存成功后，首页自动切到对应收支类型视图（原型 A6 / 6.1）
      ref.read(selectedTypeProvider.notifier).state = _recordType;
      Navigator.of(context).pop();
      // V3.0 N4: Toast 文案更新为「已保存 {type} ¥{amount}，首页已同步切换」
      final typeLabel = _recordType == 'expense' ? '支出' : '收入';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已保存 $typeLabel ¥${_amountInput}，首页已同步切换'),
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
