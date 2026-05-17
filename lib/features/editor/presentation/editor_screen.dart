import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/upload_service.dart';
import '../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../core/utils/app_radius.dart';
import '../application/editor_notifier.dart';
import 'editor_embed_builders.dart';
import 'editor_toolbar.dart';
import 'editor_utils.dart';

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
        if (didPop) return;
        await _saveBeforeExit();
        if (!mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: EditorToolbar(
          controller: _quillController,
          onUndo: _undoLastChange,
          onRedo: _redoLastChange,
          onInsertImage: _insertImage,
          onTogglePreview: _togglePreviewMode,
          onHideKeyboard: _editorFocusNode.hasFocus
              ? _editorFocusNode.unfocus
              : null,
          previewMode: _previewMode,
          hasUndo: _quillController.hasUndo,
          hasRedo: _quillController.hasRedo,
        ),
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
                  _buildAppBar(theme),
                  if (_hasExternalConflict)
                    MaterialBanner(
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleField(theme),
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
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: ShimmerLoading(
              child: Column(
                children: [
                  SizedBox(height: 60),
                  ShimmerList(itemCount: 3),
                ],
              ),
            ),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () async {
              await _saveBeforeExit();
              if (!mounted) return;
                            Navigator.of(context).pop();
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
                  'Words: ${getWordCount(_quillController)}',
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
                onPressed: _isSaving
                    ? null
                    : () => _saveChapter(showFeedback: true),
                icon: const Icon(Icons.save_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.newsreader(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E1E1E),
      ),
      decoration: const InputDecoration(
        filled: false,
        hintText: 'The title...',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
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
        ButtonSegment(value: false, icon: Icon(Icons.edit_note_rounded), label: Text('Escribir')),
        ButtonSegment(value: true, icon: Icon(Icons.visibility_outlined), label: Text('Vista previa')),
      ],
      selected: {_previewMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        _setPreviewMode(selection.first);
      },
    );
  }

  Widget _buildEditorStatsWrap(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statChip(theme, icon: Icons.short_text_rounded, label: '${getWordCount(_quillController)} palabras'),
        _statChip(theme, icon: Icons.text_fields_rounded, label: '${getCharacterCount(_quillController)} caracteres'),
        _statChip(theme, icon: Icons.schedule_rounded, label: '${estimateReadingMinutes(_quillController)} min lectura'),
      ],
    );
  }

  Widget _statChip(ThemeData theme, {required IconData icon, required String label}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.pill,
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

  Widget _buildMarkdownPreview(ThemeData theme) {
    return Container(
      key: const ValueKey('markdown-preview'),
      width: double.infinity,
      alignment: Alignment.topLeft,
      child: Markdown(
        data: markdownForPreview(_quillController),
        selectable: true,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.newsreader(fontSize: 20, height: 1.6, color: const Color(0xFF1E1E1E)),
          h1: GoogleFonts.newsreader(fontSize: 30, fontWeight: FontWeight.w500, height: 1.15, color: const Color(0xFF1E1E1E)),
          h2: GoogleFonts.newsreader(fontSize: 24, fontWeight: FontWeight.w500, height: 1.2, color: const Color(0xFF1E1E1E)),
          blockquote: GoogleFonts.newsreader(fontSize: 20, height: 1.6, fontStyle: FontStyle.italic, color: const Color(0xFF1E1E1E).withValues(alpha: 0.88)),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.45), width: 3)),
          ),
          listBullet: GoogleFonts.newsreader(fontSize: 20, color: const Color(0xFF1E1E1E)),
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
          customLeadingBlockBuilder: (node, config) => const SizedBox.shrink(),
          embedBuilders: [
            ImageEmbedBuilder(),
          ],
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(fontSize: 20, height: 1.6, color: const Color(0xFF1E1E1E)),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 14),
              const quill.VerticalSpacing(0, 0), null,
            ),
            h1: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(fontSize: 30, height: 1.2, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E1E)),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 16),
              const quill.VerticalSpacing(0, 0), null,
            ),
            h2: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(fontSize: 24, height: 1.2, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E1E)),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 14),
              const quill.VerticalSpacing(0, 0), null,
            ),
            quote: quill.DefaultTextBlockStyle(
              GoogleFonts.newsreader(fontSize: 20, height: 1.6, fontStyle: FontStyle.italic, color: const Color(0xFF1E1E1E).withValues(alpha: 0.88)),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 12),
              const quill.VerticalSpacing(0, 0),
              const BoxDecoration(border: Border(left: BorderSide(color: Color(0x667F7F78), width: 3))),
            ),
          ),
        ),
      ),
    );
  }

  void _loadChapter(dynamic chapter) {
    _initialized = true;
    _titleController.text = chapter.tituloCapitulo;
    _setEditorMarkdown(chapter.contenido, moveCursorToEnd: false);
    _baseLastModified = chapter.lastModified;
    _lastSavedFingerprint = fingerprintFor(_titleController.text.trim(), markdownFromDocument(_quillController.document));
    _lastObservedFingerprint = _lastSavedFingerprint;
    _isDirty = false;
  }

  void _setEditorMarkdown(String markdown, {required bool moveCursorToEnd}) {
    final doc = documentFromMarkdown(markdown);
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

  Future<void> _saveBeforeExit() async {
    _autosaveDebounce?.cancel();
    await _saveChapter(showFeedback: false);
  }

  void _onEditorChanged() {
    if (!_initialized || _isApplyingSnapshot) return;

    final fingerprint = fingerprintFor(_titleController.text.trim(), markdownFromDocument(_quillController.document));
    if (fingerprint == _lastObservedFingerprint) return;

    _lastObservedFingerprint = fingerprint;

    setState(() { _isDirty = true; });

    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(_autosaveDelay, () {
      _saveChapter(showFeedback: false);
    });
  }

  Future<void> _saveChapter({required bool showFeedback}) async {
    final markdown = markdownFromDocument(_quillController.document);
    final fingerprint = fingerprintFor(_titleController.text.trim(), markdown);

    if (!_isDirty && fingerprint == _lastSavedFingerprint) return;
    if (_isSaving) return;

    setState(() { _isSaving = true; });

    try {
      await ref
          .read(editorNotifierProvider(widget.chapterLocalId).notifier)
          .saveChapter(title: _titleController.text.trim(), markdownContent: markdown);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
      return;
    }

    if (!mounted) return;

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

    final updatedChapter = ref.read(editorNotifierProvider(widget.chapterLocalId)).valueOrNull;
    if (updatedChapter != null) _baseLastModified = updatedChapter.lastModified;

    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capitulo guardado')),
      );
    }
  }

  void _checkExternalUpdate(dynamic chapter) {
    if (_baseLastModified == null || chapter.lastModified == _baseLastModified) return;

    final incoming = fingerprintFor(chapter.tituloCapitulo, chapter.contenido);
    if (incoming == _lastSavedFingerprint) {
      _baseLastModified = chapter.lastModified;
      return;
    }

    if (_externalLastModified == chapter.lastModified) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    if (_externalTitle == null || _externalContent == null) return;

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

  Future<void> _copyMarkdownToClipboard() async {
    final markdown = markdownFromDocument(_quillController.document);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown copiado al portapapeles')),
    );
  }

  String _saveStatusText() {
    if (_isSaving) return 'Guardando...';
    if (_isDirty) return 'Cambios sin guardar';
    if (_lastSavedAt != null) {
      final hour = _lastSavedAt!.hour.toString().padLeft(2, '0');
      final minute = _lastSavedAt!.minute.toString().padLeft(2, '0');
      return 'Guardado a las $hour:$minute';
    }
    return 'Sin cambios';
  }

  void _setPreviewMode(bool next) {
    setState(() { _previewMode = next; });
    if (next) { _editorFocusNode.unfocus(); }
    else { _editorFocusNode.requestFocus(); }
  }

  void _togglePreviewMode() => _setPreviewMode(!_previewMode);

  void _undoLastChange() {
    if (_previewMode) _setPreviewMode(false);
    _quillController.undo();
    _editorFocusNode.requestFocus();
  }

  void _redoLastChange() {
    if (_previewMode) _setPreviewMode(false);
    _quillController.redo();
    _editorFocusNode.requestFocus();
  }

  Future<void> _insertImage() async {
    if (_previewMode) setState(() { _previewMode = false; });

    final source = await showModalBottomSheet<_ImageInsertSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
      ),
    );

    if (!mounted || source == null) return;

    if (source == _ImageInsertSource.url) {
      await _insertImageFromUrl();
    } else {
      await _insertImageFromGallery();
    }
  }

  Future<void> _insertImageFromUrl() async {
    final controller = TextEditingController(text: 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL de la imagen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://ejemplo.com/imagen.jpg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Insertar')),
        ],
      ),
    );

    if (!mounted || url == null || url.isEmpty) return;

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

    if (!mounted || pickedFile == null) return;

    String imageSource;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'escritor_images'));
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      final ext = p.extension(pickedFile.path).isNotEmpty
          ? p.extension(pickedFile.path) : '.jpg';
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(imagesDir.path, fileName);
      await pickedFile.saveTo(destPath);
      imageSource = Uri.file(destPath).toString();

      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.uploadImage(destPath);
      if (result != null) imageSource = result.url;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la imagen')),
      );
      return;
    }

    if (!mounted) return;
    _insertImageEmbed(imageSource);
  }

  void _insertImageEmbed(String imageSource) {
    var index = _quillController.selection.baseOffset;
    final maxIndex = _quillController.document.length - 1;
    if (index < 0 || index > maxIndex) index = maxIndex;

    final selection = _quillController.selection;
    final replaceLength = selection.isValid ? selection.end - selection.start : 0;

    _quillController.replaceText(index, replaceLength, quill.BlockEmbed.image(imageSource), null);
    _quillController.replaceText(index + 1, 0, '\n', null);

    _editorFocusNode.requestFocus();
  }
}
