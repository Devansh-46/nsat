import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/note_box.dart';
import '../../widgets/niu_button.dart';
import '../../services/question_management_service.dart';
import '../../services/admin_service.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  final _adminService = AdminService();
  final _questionMgmtService = QuestionManagementService();

  List<String> _allowedCourses = [];
  String? _selectedCourse;
  bool _isLoadingCourses = true;
  bool _isLoadingQuestions = false;
  String? _error;
  String? _success;

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _adminService.getMyAllowedCourses();
      setState(() {
        _allowedCourses = courses.contains('*') ? _allCourses : courses;
        if (_allowedCourses.isNotEmpty) {
          _selectedCourse = _allowedCourses.first;
          _fetchQuestions();
        }
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load courses';
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _fetchQuestions() async {
    if (_selectedCourse == null) return;
    setState(() {
      _isLoadingQuestions = true;
      _error = null;
      _success = null;
    });

    try {
      final qs = await _questionMgmtService.fetchForCourse(_selectedCourse!);
      setState(() {
        _questions = qs;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load questions';
        _isLoadingQuestions = false;
      });
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.clay)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _questionMgmtService.deleteQuestion(id);
      setState(() => _success = 'Question deleted successfully');
      _fetchQuestions();
    } catch (e) {
      setState(() => _error = 'Failed to delete question');
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? q]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuestionEditorDialog(
        course: _selectedCourse!,
        existingQuestion: q,
      ),
    );

    if (result == true) {
      setState(() => _success = 'Question saved successfully');
      _fetchQuestions();
    }
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      final csvString = utf8.decode(result.files.single.bytes!);
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty || rows.length == 1) {
        setState(() => _error = 'CSV is empty or only has a header.');
        return;
      }

      int created = 0;
      int skipped = 0;
      List<String> errors = [];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 11) {
          errors.add('Row $i: Missing columns');
          skipped++;
          continue;
        }

        final course = row[0].toString().trim();
        final sequence = int.tryParse(row[1].toString()) ?? 9999;
        final type = row[2].toString().trim();
        final text = row[3].toString().trim();
        final opt1 = row[4].toString().trim();
        final opt2 = row[5].toString().trim();
        final opt3 = row[6].toString().trim();
        final opt4 = row[7].toString().trim();
        final correctIdx = int.tryParse(row[8].toString());
        final correctTextsRaw = row[9].toString().trim();
        final category = row[10].toString().trim();
        final topic = row.length > 11 ? row[11].toString().trim() : '';
        final minWords = row.length > 12 ? int.tryParse(row[12].toString()) ?? 0 : 0;
        final maxWords = row.length > 13 ? int.tryParse(row[13].toString()) ?? 0 : 0;

        if (!_allowedCourses.contains(course) && !_allowedCourses.contains('*')) {
          errors.add('Row $i: Invalid or unauthorized course "$course"');
          skipped++;
          continue;
        }

        if (text.isEmpty) {
          errors.add('Row $i: Missing question text');
          skipped++;
          continue;
        }

        final isMcq = type == 'multipleChoice';

        if (isMcq) {
          if (opt1.isEmpty || opt2.isEmpty || opt3.isEmpty || opt4.isEmpty) {
            errors.add('Row $i: MCQ must have 4 options');
            skipped++;
            continue;
          }
          if (correctIdx == null || correctIdx < 0 || correctIdx > 3) {
            errors.add('Row $i: Invalid correctAnswerIndex for MCQ');
            skipped++;
            continue;
          }
        } else {
          if (correctTextsRaw.isEmpty) {
            errors.add('Row $i: Short answer requires correctAnswerTexts');
            skipped++;
            continue;
          }
        }

        try {
          await _questionMgmtService.createQuestion({
            'course': course,
            'sequence': sequence,
            'type': type,
            'text': text,
            'options': isMcq ? [opt1, opt2, opt3, opt4] : [],
            'correctAnswerIndex': isMcq ? correctIdx : -1,
            'correctAnswerTexts': !isMcq ? correctTextsRaw.split('|').map((e) => e.trim()).toList() : [],
            'category': category,
            'topic': topic,
            'minWords': minWords,
            'maxWords': maxWords,
          });
          created++;
        } catch (e) {
          errors.add('Row $i: Failed to save to DB');
          skipped++;
        }
      }

      setState(() {
        if (errors.isEmpty) {
          _success = 'Imported $created questions.';
        } else {
          _error = 'Imported $created. Skipped $skipped.\\nErrors:\\n${errors.take(3).join("\\n")}${errors.length > 3 ? "\\n..." : ""}';
        }
      });
      _fetchQuestions();

    } catch (e) {
      setState(() => _error = 'Failed to parse CSV file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 24, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink3),
                ),
              ),
              const SizedBox(height: 16),
              const Eyebrow('authoring'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Manage ',
                  style: AppTheme.display(size: 26),
                  children: [AppTheme.italicSpan('questions.')],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoteBox.clay(icon: Icons.error_outline, body: _error!),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoteBox.green(icon: Icons.check_circle, body: _success!),
                ),

              const NoteBox.gold(
                icon: Icons.info_outline,
                body: 'Publish a test only when authored question count for its course == test.questionCount.',
              ),
              const SizedBox(height: 24),

              if (_isLoadingCourses)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCourse,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: AppTheme.body(size: 14, color: AppColors.ink),
                            items: _allowedCourses.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(_courseDisplayLabels[c] ?? c),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCourse = val);
                                _fetchQuestions();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    NiuButton(
                      label: 'Import CSV',
                      variant: NiuButtonVariant.outline,
                      fullWidth: false,
                      onTap: _importCSV,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                NiuButton(
                  label: 'Add Question',
                  variant: NiuButtonVariant.primary,
                  fullWidth: true,
                  onTap: () => _openEditor(),
                ),
                const SizedBox(height: 24),

                if (_isLoadingQuestions)
                  const Center(child: CircularProgressIndicator())
                else if (_questions.isEmpty)
                  Center(
                    child: Text('No questions found for this course.',
                        style: AppTheme.body(color: AppColors.ink4)),
                  )
                else
                  ..._questions.map((q) => _QuestionCard(
                        question: q,
                        onEdit: () => _openEditor(q),
                        onDelete: () => _deleteQuestion(q['id']),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = question['text'] as String? ?? 'Untitled';
    final type = question['type'] as String? ?? 'multipleChoice';
    final seq = question['sequence']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.forestTint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Q$seq',
                style: AppTheme.body(size: 11, color: AppColors.forest, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTheme.body(size: 13.5, color: AppColors.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type == 'multipleChoice' ? 'MCQ' : 'Short Answer',
                    style: AppTheme.body(size: 11.5, color: AppColors.ink4),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.ink3),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.clay),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionEditorDialog extends StatefulWidget {
  final String course;
  final Map<String, dynamic>? existingQuestion;

  const _QuestionEditorDialog({required this.course, this.existingQuestion});

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  final _questionMgmtService = QuestionManagementService();
  
  bool _isSaving = false;
  String? _error;

  late bool _isMcq;
  final _textController = TextEditingController();
  final _seqController = TextEditingController(text: '9999');
  final _categoryController = TextEditingController();
  final _topicController = TextEditingController();

  final List<TextEditingController> _mcqControllers = [];
  int _correctIndex = 0;

  final _correctTextsController = TextEditingController();
  final _minWordsController = TextEditingController(text: '0');
  final _maxWordsController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _isMcq = (q?['type'] ?? 'multipleChoice') == 'multipleChoice';

    if (q != null) {
      _textController.text = q['text'] ?? '';
      _seqController.text = q['sequence']?.toString() ?? '9999';
      _categoryController.text = q['category'] ?? '';
      _topicController.text = q['topic'] ?? '';

      if (_isMcq) {
        final opts = (q['options'] as List?)?.cast<String>() ?? [];
        for (var o in opts) {
          _mcqControllers.add(TextEditingController(text: o));
        }
        _correctIndex = q['correctAnswerIndex'] ?? 0;
      } else {
        final texts = (q['correctAnswerTexts'] as List?)?.cast<String>() ?? [];
        _correctTextsController.text = texts.join(' | ');
        _minWordsController.text = q['minWords']?.toString() ?? '0';
        _maxWordsController.text = q['maxWords']?.toString() ?? '0';
      }
    }

    if (_mcqControllers.isEmpty && _isMcq) {
      for (int i = 0; i < 4; i++) {
        _mcqControllers.add(TextEditingController());
      }
    }
  }

  Future<void> _save() async {
    if (_textController.text.trim().isEmpty) {
      setState(() => _error = 'Question text cannot be empty');
      return;
    }

    final data = <String, dynamic>{
      'course': widget.course,
      'text': _textController.text.trim(),
      'type': _isMcq ? 'multipleChoice' : 'shortAnswer',
      'sequence': int.tryParse(_seqController.text) ?? 9999,
      'category': _categoryController.text.trim(),
      'topic': _topicController.text.trim(),
    };

    if (_isMcq) {
      final opts = _mcqControllers.map((c) => c.text.trim()).toList();
      if (opts.any((o) => o.isEmpty)) {
        setState(() => _error = 'All MCQ options must be filled');
        return;
      }
      data['options'] = opts;
      data['correctAnswerIndex'] = _correctIndex;
    } else {
      final textsStr = _correctTextsController.text.trim();
      if (textsStr.isEmpty) {
        setState(() => _error = 'Short answer requires at least one correct text variant');
        return;
      }
      data['correctAnswerTexts'] = textsStr.split('|').map((e) => e.trim()).toList();
      data['minWords'] = int.tryParse(_minWordsController.text) ?? 0;
      data['maxWords'] = int.tryParse(_maxWordsController.text) ?? 0;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (widget.existingQuestion != null) {
        await _questionMgmtService.updateQuestion(widget.existingQuestion!['id'], data);
      } else {
        await _questionMgmtService.createQuestion(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save question';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgBase,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingQuestion == null ? 'Add Question' : 'Edit Question',
                style: AppTheme.displaySm(size: 20),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoteBox.clay(icon: Icons.error_outline, body: _error!),
                ),

              Row(
                children: [
                  Expanded(
                    child: _buildField('Sequence', _seqController, isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: _isMcq,
                          isExpanded: true,
                          dropdownColor: AppColors.bgBase,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Multiple Choice')),
                            DropdownMenuItem(value: false, child: Text('Short Answer')),
                          ],
                          onChanged: widget.existingQuestion == null ? (val) {
                            if (val != null) {
                              setState(() {
                                _isMcq = val;
                                if (_isMcq && _mcqControllers.isEmpty) {
                                  for (int i = 0; i < 4; i++) {
                                    _mcqControllers.add(TextEditingController());
                                  }
                                }
                              });
                            }
                          } : null, // Disable changing type for existing questions
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildField('Question Text', _textController, maxLines: 3),
              const SizedBox(height: 16),

              if (_isMcq) ...[
                Text('Options', style: AppTheme.body(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _correctIndex,
                        activeColor: AppColors.forest,
                        onChanged: (val) {
                          if (val != null) setState(() => _correctIndex = val);
                        },
                      ),
                      Expanded(
                        child: _buildField('', _mcqControllers[i]),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ] else ...[
                _buildField('Correct Answers (pipe "|" separated)', _correctTextsController, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Min Words', _minWordsController, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Max Words', _maxWordsController, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(child: _buildField('Category', _categoryController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Topic', _topicController)),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTheme.body(color: AppColors.ink4)),
                  ),
                  const SizedBox(width: 16),
                  _isSaving
                      ? const CircularProgressIndicator()
                      : NiuButton(
                          label: 'Save',
                          fullWidth: false,
                          onTap: _save,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTheme.body(size: 12.5, color: AppColors.ink, weight: FontWeight.w500)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: AppTheme.body(size: 14, color: AppColors.ink),
          cursorColor: AppColors.forest,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.forest)),
          ),
        ),
      ],
    );
  }
}

const _allCourses = [
  'soahs_ug', 'soahs_pg', 'son_bsc', 'son_gnm', 'set_ug', 'set_pg',
  'sbm_ug', 'sbm_pg', 'solla_ug', 'solla_pg', 'sjmc', 'sos_ug',
  'sos_pg', 'sola', 'sofad', 'soe', 'sop'
];

const _courseDisplayLabels = {
  'soahs_ug': 'SOAHS UG',
  'soahs_pg': 'SOAHS PG',
  'son': 'Nursing',
  'son_bsc': 'Nursing B.Sc',
  'son_gnm': 'Nursing GNM',
  'set_ug': 'Engineering UG',
  'set_pg': 'Engineering PG',
  'sbm_ug': 'Business UG',
  'sbm_pg': 'Business PG',
  'solla_ug': 'Law UG',
  'solla_pg': 'Law PG',
  'sjmc': 'Journalism',
  'sos_ug': 'Science UG',
  'sos_pg': 'Science PG',
  'sola': 'Liberal Arts',
  'soe': 'Education',
  'sop': 'Pharmacy',
};
