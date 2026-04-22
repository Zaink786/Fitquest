import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() =>
      _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState
    extends State<SecurityQuestionsSetupScreen> {
  static const _accent = Color(0xFF8896CC);
  static const _numQuestions = 3;

  late List<String?> _selectedQuestions;
  late List<TextEditingController> _answerControllers;

  bool _isLoading = false;
  String? _errorMessage;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _selectedQuestions = List.filled(_numQuestions, null);
    _answerControllers =
        List.generate(_numQuestions, (_) => TextEditingController());
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final email = AuthService.getCurrentUser();
    if (email == null) return;
    final questions = await AuthService.getSecurityQuestions(email);
    if (!mounted || questions == null) return;
    setState(() {
      for (int i = 0; i < questions.length && i < _numQuestions; i++) {
        _selectedQuestions[i] = questions[i];
      }
      _saved = true;
    });
  }

  List<String> _availableFor(int index) {
    final chosen = _selectedQuestions
        .asMap()
        .entries
        .where((e) => e.key != index && e.value != null)
        .map((e) => e.value!)
        .toSet();
    return AuthService.allSecurityQuestions
        .where((q) => !chosen.contains(q))
        .toList();
  }

  Future<void> _save() async {
    // Validate all questions chosen
    for (int i = 0; i < _numQuestions; i++) {
      if (_selectedQuestions[i] == null) {
        setState(() => _errorMessage = 'Please select all $_numQuestions security questions');
        return;
      }
      if (_answerControllers[i].text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please answer all security questions');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = AuthService.getCurrentUser();
    if (email == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Not logged in';
      });
      return;
    }

    final pairs = List.generate(
      _numQuestions,
      (i) => MapEntry(_selectedQuestions[i]!, _answerControllers[i].text),
    );

    await AuthService.setSecurityQuestions(email, pairs);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _saved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security questions saved'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Questions'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _saved
                            ? 'Your security questions are set up. Update them below.'
                            : 'Set up 3 security questions so you can recover your account if you forget your password.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              for (int i = 0; i < _numQuestions; i++) ...[
                Text(
                  'Question ${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedQuestions[i],
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select a question'),
                  items: _availableFor(i).map((q) {
                    return DropdownMenuItem(
                      value: q,
                      child: Text(q, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList()
                    ..addAll(
                      _selectedQuestions[i] != null &&
                              !_availableFor(i).contains(_selectedQuestions[i])
                          ? [
                              DropdownMenuItem(
                                value: _selectedQuestions[i],
                                child: Text(
                                  _selectedQuestions[i]!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ]
                          : [],
                    ),
                  onChanged: (val) {
                    setState(() {
                      _selectedQuestions[i] = val;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _answerControllers[i],
                  textInputAction: i < _numQuestions - 1
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Your answer',
                    prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _saved ? 'Update Questions' : 'Save Questions',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
