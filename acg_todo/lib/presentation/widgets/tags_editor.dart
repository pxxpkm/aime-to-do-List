import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/utils/tag_utils.dart';

class TagsEditor extends StatefulWidget {
  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  const TagsEditor({
    super.key,
    required this.tags,
    this.suggestions = const [],
    required this.onChanged,
  });

  @override
  State<TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<TagsEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final next = normalizeTags([...widget.tags, raw]);
    if (next.length == widget.tags.length &&
        next.every(widget.tags.contains)) {
      _controller.clear();
      return;
    }
    widget.onChanged(next);
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final unusedSuggestions = widget.suggestions
        .where((s) => !widget.tags.contains(s))
        .take(12)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in widget.tags)
              InputChip(
                label: Text(t, style: TextStyle(fontSize: 12)),
                onDeleted: () => _remove(t),
                deleteIconColor: context.palette.inkMuted,
                backgroundColor: context.palette.surface,
              ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '新增標籤後按 Enter',
            isDense: true,
            filled: true,
            fillColor: context.palette.elevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _add(_controller.text),
            ),
          ),
          onSubmitted: _add,
          textInputAction: TextInputAction.done,
        ),
        if (unusedSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in unusedSuggestions)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _add(s),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
