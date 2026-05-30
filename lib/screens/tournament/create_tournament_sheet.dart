import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CreateTournamentSheet extends StatefulWidget {
  const CreateTournamentSheet({super.key});

  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _maxPlayers = 8;
  int _topCutSize = 8;

  final _maxPlayersOptions = [4, 8, 16, 32];
  final _topCutOptions = [4, 8, 16];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: AppTheme.surfaceBg,
        child: Column(
          children: [
            Container(
              color: AppTheme.cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Date',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          fontSize: 16)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Done',
                        style: TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                            fontSize: 16)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (dt) => setState(() => _selectedDate = dt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Name Required'),
          content: const Text('Please enter a tournament name.'),
          actions: [
            CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context))
          ],
        ),
      );
      return;
    }
    Navigator.pop(context, {
      'name': name,
      'date': _selectedDate.toIso8601String(),
      'maxPlayers': _maxPlayers,
      'topCutSize': _topCutSize,
    });
  }

  Widget _buildSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChoiceRow<T>(List<T> options, T selected, ValueChanged<T> onSelect) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => onSelect(opt)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGold.withOpacity(0.15)
                    : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentGold
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                opt.toString(),
                style: TextStyle(
                  color: isSelected ? AppTheme.accentGold : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.flag_fill,
                      color: AppTheme.accentGold, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Create Tournament',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 24),
          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'TOURNAMENT NAME',
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'e.g. Grand Line Championship',
                      placeholderStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  _buildSection(
                    'DATE',
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.calendar,
                                color: AppTheme.accentGold, size: 18),
                            const SizedBox(width: 12),
                            Text(_formatDate(_selectedDate),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            const Spacer(),
                            const Icon(CupertinoIcons.chevron_down,
                                color: AppTheme.textSecondary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildSection(
                    'MAX PLAYERS',
                    _buildChoiceRow<int>(
                        _maxPlayersOptions,
                        _maxPlayers,
                        (v) => _maxPlayers = v),
                  ),
                  _buildSection(
                    'TOP CUT SIZE',
                    _buildChoiceRow<int>(
                        _topCutOptions,
                        _topCutSize,
                        (v) => _topCutSize = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: _submit,
                      child: const Text(
                        'Create Event',
                        style: TextStyle(
                            color: AppTheme.obsidianBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
