import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import '../application/editor_notifier.dart';

enum _ImageInsertSource { url, gallery }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.projectLocalId,
    required this.chapterLocalId,
  });

  final String projectLocalId;
  final String chapterLocalId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _autosaveDelay = Duration(seconds: 2);
  static const _markdownRenderDelay = Duration(milliseconds: 420);
  static const _editorTextColor = Color(0xFF1E1E1E);

  final _titleController = TextEditingController();
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  final _imagePicker = ImagePicker();
  late quill.QuillController _quillController;

  bool _initialized = false;
  bool _previewMode = true;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isApplyingSnapshot = false;
  DateTime? _lastSavedAt;
  String _lastSavedFingerprint = '';
  String _lastObservedFingerprint = '';
  int? _baseLastModified;
  bool _hasExternalConflict = false;
  String? _externalTitle;
  String? _externalContent;
  int? _externalLastModified;
  Timer? _autosaveDebounce;
  Timer? _markdownRenderDebounce;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _quillController.addListener(_onEditorChanged);
    _titleController.addListener(_onEditorChanged);
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _markdownRenderDebounce?.cancel();
    _titleController.removeListener(_onEditorChanged);
    _quillController.removeListener(_onEditorChanged);
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chapterAsync = ref.watch(
      editorNotifierProvider(widget.chapterLocalId),
    );

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _saveBeforeExit();
        if (!mounted) {
          return;
        }

        Navigator.of(this.context).pop(result);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildToolbar(),
        body: chapterAsync.when(
          data: (chapter) {
            if (chapter == null) {
              return const Center(child: Text('Capitulo no encontrado'));
            }

            if (!_initialized) {
              _loadChapter(chapter);
            } else {
              _checkExternalUpdate(chapter);
            }

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Volver',
                          onPressed: () async {
                            await _saveBeforeExit();
                            if (!mounted) {
                              return;
                            }
                            Navigator.of(this.context).pop();
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _isDirty ? 'UNSAVED DRAFT' : 'DRAFT SYNCED',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.4,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _saveStatusText(),
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Words: ${_getWordCount()}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Copiar Markdown',
                              onPressed: _copyMarkdownToClipboard,
                              icon: const Icon(Icons.content_copy_rounded),
                            ),
                            IconButton(
                              tooltip: 'Guardar',
                              onPressed: chapterAsync.isLoading || _isSaving
                                  ? null
                                  : () => _saveChapter(showFeedback: true),
                              icon: const Icon(Icons.save_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_hasExternalConflict)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: MaterialBanner(
                        backgroundColor: scheme.errorContainer,
                        content: const Text(
                          'Este capitulo fue actualizado en otra fuente. Elige que version conservar.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: _dismissExternalConflict,
                            child: const Text('Mantener mi version'),
                          ),
                          TextButton(
                            onPressed: _applyExternalVersion,
                            child: const Text('Cargar version externa'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: GoogleFonts.newsreader(
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: _editorTextColor,
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              hintText: 'The title...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildEditorModeSwitcher(theme),
                          const SizedBox(height: 10),
                          _buildEditorStatsWrap(theme),
                          const SizedBox(height: 14),
                          Expanded(
                            child: IndexedStack(
                              index: _previewMode ? 1 : 0,
                              children: [
                                _buildQuillCanvas(),
                                _buildMarkdownPreview(theme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 86),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildMarkdownPreview(ThemeData theme) {
    return Container(
      key: const ValueKey('markdown-preview'),
      width: double.infinity,
      alignment: Alignment.topLeft,
      child: Markdown(
        data: _markdownForPreview(),
        selectable: true,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.newsreader(
            fontSize: 20,
            height: 1.6,
            color: _editorTextColor,
          ),
          h1: GoogleFonts.newsreader(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: _editorTextColor,
          ),
          h2: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: _editorTextColor,
          ),
          blockquote: GoogleFonts.newsreader(
            fontSize: 20,
            height: 1.6,
            fontStyle: FontStyle.italic,
            color: _editorTextColor.withValues(alpha: 0.88),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.45),
                width: 3,
              ),
            ),
          ),
          listBullet: GoogleFonts.newsreader(
            fontSize: 20,
            color: _editorTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildQuillCanvas() {
    return Container(
      key: const ValueKey('quill-canvas'),
      width: double.infinity,
      alignment: Alignment.topLeft,
      child: quill.QuillEditor.basic(
        controller: _quillController,
        focusNode: _editorFocusNode,
        scrollController: _editorScrollController,
        config: quill.QuillEditorConfig(
          autoFocus: true,
          expands: true,
          scrollBottomInset: 120,
          padding: EdgeInsets.zero,
          placeholder: 'Start writing...',
          // ignore: experimental_member_use
          customLeadingBlockBuilder: (node, config) => const SizedBox.shrink(),
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(
                fontSize: 20,
                height: 1.6,
                color: _editorTextColor,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 14),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h1: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: _editorTextColor,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 16),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h2: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: _editorTextColor,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 14),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            quote: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(
                fontSize: 20,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: _editorTextColor.withValues(alpha: 0.88),
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 12),
              const quill.VerticalSpacing(0, 0),
              const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0x667F7F78), width: 3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorModeSwitcher(ThemeData theme) {
    return SegmentedButton<bool>(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
      ),
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<bool>(
          value: false,
          icon: Icon(Icons.edit_note_rounded),
          label: Text('Escribir'),
        ),
        ButtonSegment<bool>(
          value: true,
          icon: Icon(Icons.visibility_outlined),
          label: Text('Vista previa'),
        ),
      ],
      selected: {_previewMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        _setPreviewMode(selection.first);
      },
    );
  }

  Widget _buildEditorStatsWrap(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatChip(
          theme,
          icon: Icons.short_text_rounded,
          label: '${_getWordCount()} palabras',
        ),
        _buildStatChip(
          theme,
          icon: Icons.text_fields_rounded,
          label: '${_getCharacterCount()} caracteres',
        ),
        _buildStatChip(
          theme,
          icon: Icons.schedule_rounded,
          label: '${_estimateReadingMinutes()} min lectura',
        ),
      ],
    );
  }

  Widget _buildStatChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  void _loadChapter(dynamic chapter) {
    _initialized = true;
    _titleController.text = chapter.tituloCapitulo;
    _setEditorMarkdown(chapter.contenido, moveCursorToEnd: false);
    _baseLastModified = chapter.lastModified;
    _lastSavedFingerprint = _currentFingerprint();
    _lastObservedFingerprint = _lastSavedFingerprint;
    _isDirty = false;
  }

  Future<void> _saveBeforeExit() async {
    _autosaveDebounce?.cancel();
    await _saveChapter(showFeedback: false);
  }

  void _onEditorChanged() {
    if (!_initialized || _isApplyingSnapshot) {
      return;
    }

    final fingerprint = _currentFingerprint();
    if (fingerprint == _lastObservedFingerprint) {
      return;
    }

    _lastObservedFingerprint = fingerprint;

    setState(() {
      _isDirty = true;
    });

    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(_autosaveDelay, () {
      _saveChapter(showFeedback: false);
    });

    _scheduleLiveMarkdownRendering();
  }

  void _scheduleLiveMarkdownRendering() {
    if (_previewMode) {
      return;
    }

    _markdownRenderDebounce?.cancel();
    _markdownRenderDebounce = Timer(_markdownRenderDelay, () {
      _tryRenderMarkdownSyntaxInPlace();
    });
  }

  void _tryRenderMarkdownSyntaxInPlace() {
    if (!mounted || _isApplyingSnapshot || _previewMode) {
      return;
    }

    if (_documentHasRichFormatting()) {
      return;
    }

    final rawText = _quillController.document.toPlainText();
    if (!_looksLikeMarkdown(rawText)) {
      return;
    }

    final parsedDoc = _documentFromMarkdown(rawText);
    if (_deltaSignature(parsedDoc) ==
        _deltaSignature(_quillController.document)) {
      return;
    }

    final selection = _quillController.selection;
    var nextOffset = selection.extentOffset;
    final maxOffset = parsedDoc.length - 1;
    if (nextOffset < 0 || nextOffset > maxOffset) {
      nextOffset = maxOffset;
    }

    _isApplyingSnapshot = true;
    _quillController
      ..document = parsedDoc
      ..updateSelection(
        TextSelection.collapsed(offset: nextOffset),
        quill.ChangeSource.local,
      );
    _isApplyingSnapshot = false;
  }

  Future<void> _saveChapter({required bool showFeedback}) async {
    final markdown = _currentMarkdown();
    final fingerprint = _fingerprintFor(_titleController.text.trim(), markdown);

    if (!_isDirty && fingerprint == _lastSavedFingerprint) {
      return;
    }
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref
        .read(editorNotifierProvider(widget.chapterLocalId).notifier)
        .saveChapter(
          title: _titleController.text.trim(),
          markdownContent: markdown,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isDirty = false;
      _lastSavedAt = DateTime.now();
      _lastSavedFingerprint = fingerprint;
      _lastObservedFingerprint = fingerprint;
      _hasExternalConflict = false;
      _externalTitle = null;
      _externalContent = null;
      _externalLastModified = null;
    });

    final updatedChapter = ref
        .read(editorNotifierProvider(widget.chapterLocalId))
        .valueOrNull;
    if (updatedChapter != null) {
      _baseLastModified = updatedChapter.lastModified;
    }

    if (showFeedback) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Capitulo guardado')));
    }
  }

  void _checkExternalUpdate(dynamic chapter) {
    if (_baseLastModified == null ||
        chapter.lastModified == _baseLastModified) {
      return;
    }

    final incomingFingerprint = _fingerprintFor(
      chapter.tituloCapitulo,
      chapter.contenido,
    );

    if (incomingFingerprint == _lastSavedFingerprint) {
      _baseLastModified = chapter.lastModified;
      return;
    }

    if (_externalLastModified == chapter.lastModified) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasExternalConflict = true;
        _externalTitle = chapter.tituloCapitulo;
        _externalContent = chapter.contenido;
        _externalLastModified = chapter.lastModified;
      });
    });
  }

  void _dismissExternalConflict() {
    setState(() {
      _hasExternalConflict = false;
      _externalTitle = null;
      _externalContent = null;
      _externalLastModified = null;
    });
  }

  void _applyExternalVersion() {
    if (_externalTitle == null || _externalContent == null) {
      return;
    }

    _titleController.text = _externalTitle!;
    _setEditorMarkdown(_externalContent!, moveCursorToEnd: true);

    setState(() {
      _baseLastModified = _externalLastModified;
      _hasExternalConflict = false;
      _externalTitle = null;
      _externalContent = null;
      _externalLastModified = null;
      _isDirty = true;
    });

    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(
      const Duration(milliseconds: 100),
      () => _saveChapter(showFeedback: false),
    );
  }

  void _setEditorMarkdown(String markdown, {required bool moveCursorToEnd}) {
    final doc = _documentFromMarkdown(markdown);
    final endOffset = moveCursorToEnd ? doc.toPlainText().length : 0;

    _isApplyingSnapshot = true;
    _quillController
      ..document = doc
      ..updateSelection(
        TextSelection.collapsed(offset: endOffset),
        quill.ChangeSource.local,
      );
    _isApplyingSnapshot = false;
  }

  quill.Document _documentFromMarkdown(String markdown) {
    if (markdown.trim().isEmpty) {
      return quill.Document();
    }

    try {
      final delta = MarkdownToDelta(
        markdownDocument: md.Document(),
      ).convert(markdown);
      return quill.Document.fromDelta(delta);
    } catch (_) {
      final doc = quill.Document();
      doc.insert(0, markdown);
      return doc;
    }
  }

  String _currentMarkdown() {
    return _markdownFromDocument(_quillController.document);
  }

  String _markdownFromDocument(quill.Document document) {
    final plain = document.toPlainText().trim();
    if (plain.isEmpty) {
      return '';
    }

    try {
      return DeltaToMarkdown().convert(document.toDelta()).trimRight();
    } catch (_) {
      return document.toPlainText().trimRight();
    }
  }

  String _markdownForPreview() {
    final plain = _quillController.document.toPlainText().trimRight();
    if (plain.isEmpty) {
      return '*Start writing...*';
    }

    if (!_documentHasRichFormatting()) {
      return plain;
    }

    final serialized = _currentMarkdown();
    return serialized.isEmpty ? plain : serialized;
  }

  bool _documentHasRichFormatting() {
    final ops = _quillController.document.toDelta().toJson();

    for (final op in ops) {
      final attrs = op['attributes'];
      final insert = op['insert'];

      if (attrs is Map && attrs.isNotEmpty) {
        return true;
      }

      if (insert is! String) {
        return true;
      }
    }

    return false;
  }

  String _deltaSignature(quill.Document document) {
    return jsonEncode(document.toDelta().toJson());
  }

  bool _looksLikeMarkdown(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    const markdownPattern =
        r'(^|\n)\s{0,3}(#{1,3})\s+|\*\*[^*]+\*\*|\*[^*\n]+\*|(^|\n)\s*[-*]\s+|(^|\n)\s*>\s+|!\[[^\]]*\]\([^)]+\)|\[[^\]]+\]\([^)]+\)';

    return RegExp(markdownPattern, multiLine: true).hasMatch(value);
  }

  String _currentFingerprint() {
    return _fingerprintFor(_titleController.text.trim(), _currentMarkdown());
  }

  String _fingerprintFor(String title, String content) {
    return '$title::$content';
  }

  Future<void> _copyMarkdownToClipboard() async {
    final markdown = _currentMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown copiado al portapapeles')),
    );
  }

  int _getWordCount() {
    final text = _quillController.document.toPlainText();
    return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
  }

  int _getCharacterCount() {
    return _quillController.document.toPlainText().trim().length;
  }

  int _estimateReadingMinutes() {
    final words = _getWordCount();
    if (words == 0) {
      return 0;
    }
    return ((words - 1) ~/ 220) + 1;
  }

  String _saveStatusText() {
    if (_isSaving) {
      return 'Guardando...';
    }
    if (_isDirty) {
      return 'Cambios sin guardar';
    }
    if (_lastSavedAt != null) {
      final hour = _lastSavedAt!.hour.toString().padLeft(2, '0');
      final minute = _lastSavedAt!.minute.toString().padLeft(2, '0');
      return 'Guardado a las $hour:$minute';
    }
    return 'Sin cambios';
  }

  Widget _buildToolbar() {
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
            _toolbarIcon(
              icon: Icons.undo_rounded,
              onPressed: _quillController.hasUndo ? _undoLastChange : null,
            ),
            _toolbarIcon(
              icon: Icons.redo_rounded,
              onPressed: _quillController.hasRedo ? _redoLastChange : null,
            ),
            _toolbarSeparator(),
            _toolbarIcon(
              icon: Icons.format_bold,
              onPressed: () => _toggleAttribute(quill.Attribute.bold),
              isActive: _isAttributeActive(quill.Attribute.bold),
            ),
            _toolbarIcon(
              icon: Icons.format_italic,
              onPressed: () => _toggleAttribute(quill.Attribute.italic),
              isActive: _isAttributeActive(quill.Attribute.italic),
            ),
            _toolbarTextAction(
              label: 'H1',
              onPressed: () => _setHeading(quill.Attribute.h1),
              isActive: _isAttributeActive(quill.Attribute.h1),
            ),
            _toolbarTextAction(
              label: 'H2',
              onPressed: () => _setHeading(quill.Attribute.h2),
              isActive: _isAttributeActive(quill.Attribute.h2),
            ),
            _toolbarSeparator(),
            _toolbarIcon(
              icon: Icons.format_list_bulleted,
              onPressed: () => _toggleAttribute(quill.Attribute.ul),
              isActive: _isAttributeActive(quill.Attribute.ul),
            ),
            _toolbarIcon(
              icon: Icons.format_quote,
              onPressed: () => _toggleAttribute(quill.Attribute.blockQuote),
              isActive: _isAttributeActive(quill.Attribute.blockQuote),
            ),
            _toolbarSeparator(),
            _toolbarIcon(icon: Icons.image_outlined, onPressed: _insertImage),
            _toolbarIcon(
              icon: _previewMode ? Icons.edit_note : Icons.visibility_outlined,
              onPressed: _togglePreviewMode,
              iconColor: _previewMode ? const Color(0xFFFFD9A3) : Colors.white,
            ),
            _toolbarIcon(
              icon: Icons.keyboard_hide_rounded,
              onPressed: _editorFocusNode.hasFocus
                  ? _editorFocusNode.unfocus
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarSeparator() {
    return const Text('  •  ', style: TextStyle(color: Colors.white54));
  }

  Widget _toolbarIcon({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    Color? iconColor,
  }) {
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

  Widget _toolbarTextAction({
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
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

  bool _isAttributeActive(quill.Attribute attribute) {
    final activeAttributes = _quillController.getSelectionStyle().attributes;
    final current = activeAttributes[attribute.key];
    if (current == null) {
      return false;
    }

    if (attribute.value == null) {
      return true;
    }

    return current.value == attribute.value;
  }

  void _toggleAttribute(quill.Attribute attribute) {
    if (_previewMode) {
      _setPreviewMode(false);
    }

    final isActive = _isAttributeActive(attribute);
    _quillController.formatSelection(
      isActive ? quill.Attribute.clone(attribute, null) : attribute,
    );
    _editorFocusNode.requestFocus();
  }

  void _setHeading(quill.Attribute<int?> headingAttribute) {
    if (_previewMode) {
      _setPreviewMode(false);
    }

    final isActive = _isAttributeActive(headingAttribute);
    _quillController.formatSelection(
      isActive
          ? quill.Attribute.clone(headingAttribute, null)
          : headingAttribute,
    );
    _editorFocusNode.requestFocus();
  }

  void _undoLastChange() {
    if (_previewMode) {
      _setPreviewMode(false);
    }
    _quillController.undo();
    _editorFocusNode.requestFocus();
  }

  void _redoLastChange() {
    if (_previewMode) {
      _setPreviewMode(false);
    }
    _quillController.redo();
    _editorFocusNode.requestFocus();
  }

  void _togglePreviewMode() {
    _setPreviewMode(!_previewMode);
  }

  void _setPreviewMode(bool nextPreviewMode) {
    setState(() {
      _previewMode = nextPreviewMode;
    });

    if (nextPreviewMode) {
      _editorFocusNode.unfocus();
    } else {
      _editorFocusNode.requestFocus();
    }
  }

  Future<void> _insertImage() async {
    if (_previewMode) {
      setState(() {
        _previewMode = false;
      });
    }

    final source = await showModalBottomSheet<_ImageInsertSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Insertar por URL'),
                onTap: () => Navigator.pop(context, _ImageInsertSource.url),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Insertar desde galeria'),
                onTap: () => Navigator.pop(context, _ImageInsertSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) {
      return;
    }

    if (source == _ImageInsertSource.url) {
      await _insertImageFromUrl();
      return;
    }

    await _insertImageFromGallery();
  }

  Future<void> _insertImageFromUrl() async {
    final controller = TextEditingController(text: 'https://');

    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URL de la imagen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://ejemplo.com/imagen.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Insertar'),
            ),
          ],
        );
      },
    );

    if (!mounted || url == null || url.isEmpty) {
      return;
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL de imagen no es valida.')),
      );
      return;
    }

    _insertImageEmbed(parsed.toString());
  }

  Future<void> _insertImageFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    _insertImageEmbed(Uri.file(pickedFile.path).toString());
  }

  void _insertImageEmbed(String imageSource) {
    var index = _quillController.selection.baseOffset;
    final maxIndex = _quillController.document.length - 1;
    if (index < 0 || index > maxIndex) {
      index = maxIndex;
    }

    final selection = _quillController.selection;
    final replaceLength = selection.isValid
        ? selection.end - selection.start
        : 0;

    _quillController.replaceText(
      index,
      replaceLength,
      quill.BlockEmbed.image(imageSource),
      null,
    );
    _quillController.replaceText(index + 1, 0, '\n', null);

    _editorFocusNode.requestFocus();
  }
}
