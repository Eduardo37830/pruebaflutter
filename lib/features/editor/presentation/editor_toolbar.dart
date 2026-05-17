import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditorToolbar extends StatelessWidget {
  final quill.QuillController controller;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onInsertImage;
  final VoidCallback onTogglePreview;
  final VoidCallback? onHideKeyboard;
  final bool previewMode;
  final bool hasUndo;
  final bool hasRedo;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onUndo,
    required this.onRedo,
    required this.onInsertImage,
    required this.onTogglePreview,
    this.onHideKeyboard,
    required this.previewMode,
    required this.hasUndo,
    required this.hasRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(Icons.undo_rounded, onPressed: hasUndo ? onUndo : null),
            _icon(Icons.redo_rounded, onPressed: hasRedo ? onRedo : null),
            _separator(),
            _icon(Icons.format_bold, onPressed: () => _toggleAttr(quill.Attribute.bold)),
            _icon(Icons.format_italic, onPressed: () => _toggleAttr(quill.Attribute.italic)),
            _textAction('H1', onPressed: () => _setHeading(quill.Attribute.h1)),
            _textAction('H2', onPressed: () => _setHeading(quill.Attribute.h2)),
            _separator(),
            _icon(Icons.format_list_bulleted, onPressed: () => _toggleAttr(quill.Attribute.ul)),
            _icon(Icons.format_quote, onPressed: () => _toggleAttr(quill.Attribute.blockQuote)),
            _separator(),
            _icon(Icons.image_outlined, onPressed: onInsertImage),
            _icon(
              previewMode ? Icons.edit_note : Icons.visibility_outlined,
              onPressed: onTogglePreview,
              iconColor: previewMode ? const Color(0xFFFFD9A3) : Colors.white,
            ),
            _icon(Icons.keyboard_hide_rounded, onPressed: onHideKeyboard),
          ],
        ),
      ),
    );
  }

  Widget _separator() {
    return const Text('  •  ', style: TextStyle(color: Colors.white54));
  }

  Widget _icon(IconData icon, {VoidCallback? onPressed, Color? iconColor}) {
    final isActive = switch (icon) {
      Icons.format_bold => _isAttrActive(quill.Attribute.bold),
      Icons.format_italic => _isAttrActive(quill.Attribute.italic),
      Icons.format_list_bulleted => _isAttrActive(quill.Attribute.ul),
      Icons.format_quote => _isAttrActive(quill.Attribute.blockQuote),
      _ => false,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        splashRadius: 20,
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null
              ? Colors.white38
              : iconColor ??
                    (isActive ? const Color(0xFFFFE0B2) : Colors.white),
        ),
      ),
    );
  }

  Widget _textAction(String label, {required VoidCallback onPressed}) {
    final isActive = switch (label) {
      'H1' => _isAttrActive(quill.Attribute.h1),
      'H2' => _isAttrActive(quill.Attribute.h2),
      _ => false,
    };

    final textColor = isActive ? const Color(0xFFFFE0B2) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(38, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: textColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }

  bool _isAttrActive(quill.Attribute attribute) {
    final attrs = controller.getSelectionStyle().attributes;
    final current = attrs[attribute.key];
    if (current == null) return false;
    if (attribute.value == null) return true;
    return current.value == attribute.value;
  }

  void _toggleAttr(quill.Attribute attribute) {
    final active = _isAttrActive(attribute);
    controller.formatSelection(
      active ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  void _setHeading(quill.Attribute<int?> heading) {
    final active = _isAttrActive(heading);
    controller.formatSelection(
      active ? quill.Attribute.clone(heading, null) : heading,
    );
  }
}
