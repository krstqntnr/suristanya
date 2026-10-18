import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/screening_session.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final ChatRole role;
  _ChatMessage(this.text, this.role);
}

enum _Stage { sex, pregnancy, age, symptoms, riskFactors, complete }

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _freeText = TextEditingController();
  final List<_ChatMessage> _messages = [];
  _Stage _stage = _Stage.sex;
  bool _isTyping = false;

  ScreeningSession get _session => ScreeningSession.instance;

  static const _symptomLabels = {
    'fatigue': 'Fatigue or tiredness',
    'pallor': 'Pale skin, palms, or eyelids',
    'shortness_of_breath': 'Shortness of breath',
    'pica': 'Craving non-food items',
    'restless_legs': 'Restless legs at night',
    'hair_loss': 'Hair thinning or loss',
    'dizziness': 'Dizziness or lightheadedness',
    'cold_extremities': 'Cold hands and feet',
    'headache': 'Frequent headaches',
    'palpitations': 'Racing or pounding heartbeat',
    'smooth_tongue': 'Smooth or sore tongue',
    'brittle_nails': 'Brittle or ridged nails',
  };

  static const _riskLabels = {
    'heavy_menstruation': 'Heavy menstrual bleeding',
    'pregnancy': 'Currently pregnant',
    'gi_bleeding_history': 'History of GI bleeding',
    'nsaid_use': 'Regular NSAID use',
    'celiac': 'Celiac disease',
    'ibd': 'Inflammatory bowel disease',
    'bariatric_surgery': 'Bariatric surgery',
    'vegan_vegetarian': 'Vegan or vegetarian diet',
    'frequent_blood_donation': 'Frequent blood donation',
    'ckd': 'Chronic kidney disease',
    'heart_failure': 'Heart failure',
  };

  @override
  void initState() {
    super.initState();
    _session.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _freeText.dispose();
    super.dispose();
  }

  // ─── Scrolling ──────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Bot messages ───────────────────────────────────────────

  Future<void> _botSay(String text, {int delayMs = 500}) async {
    setState(() => _isTyping = true);
    _scrollToBottom();
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text, ChatRole.bot));
    });
    _scrollToBottom();
  }

  Future<void> _bootstrap() async {
    await _botSay(
      "Hi! I'm Ava 🌿 your screening assistant.\n\n"
      "I'll ask a few questions about your health and risk factors, then guide you to a body scan. "
      "You can also type any question at any time — I'm here to help.",
      delayMs: 300,
    );
    await _botSay("First, what is your biological sex?");
  }

  // ─── Questionnaire actions ──────────────────────────────────

  void _pickSex(String value) {
    _session.sex = value == 'Male'
        ? 'male'
        : value == 'Female'
        ? 'female'
        : null;
    setState(() => _messages.add(_ChatMessage(value, ChatRole.user)));
    _scrollToBottom();

    if (value == 'Female') {
      _stage = _Stage.pregnancy;
      _botSay("Are you currently pregnant?");
    } else {
      _stage = _Stage.age;
      _botSay("What is your age range?");
    }
  }

  void _pickPregnancy(String value) {
    _session.pregnant = value == 'Yes';
    setState(() => _messages.add(_ChatMessage(value, ChatRole.user)));
    _scrollToBottom();
    _stage = _Stage.age;
    _botSay("What is your age range?");
  }

  void _pickAge(String label, int? ageValue) {
    _session.age = ageValue;
    setState(() => _messages.add(_ChatMessage(label, ChatRole.user)));
    _scrollToBottom();
    _stage = _Stage.symptoms;
    _botSay(
      "Do you have any of these symptoms? Select all that apply, then tap Continue.",
    );
  }

  void _submitSymptoms() {
    final picked = _session.symptoms;
    setState(() {
      _messages.add(
        _ChatMessage(
          picked.isEmpty
              ? 'None of these'
              : picked.map((k) => _symptomLabels[k] ?? k).join(', '),
          ChatRole.user,
        ),
      );
    });
    _scrollToBottom();
    _stage = _Stage.riskFactors;
    _botSay("Do you have any of these risk factors? Select all that apply.");
  }

  void _submitRiskFactors() {
    final picked = _session.riskFactors;
    setState(() {
      _messages.add(
        _ChatMessage(
          picked.isEmpty
              ? 'None of these'
              : picked.map((k) => _riskLabels[k] ?? k).join(', '),
          ChatRole.user,
        ),
      );
    });
    _scrollToBottom();
    _stage = _Stage.complete;
    _botSay(
      "Thanks! I have enough to run your screening. 🌿\n\n"
      "You can add lab values if you have them, or skip straight to the body scan.",
    );
  }

  // ─── Free-text chatbot ──────────────────────────────────────

  List<Map<String, String>> _buildHistory() {
    return _messages
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'bot',
            'text': m.text,
          },
        )
        .toList();
  }

  /// Whether to re-ask the current question after a free-form
  /// question. Only for chip-based stages — the multi-select panels
  /// are self-explanatory.
  bool get _shouldReAsk {
    switch (_stage) {
      case _Stage.sex:
      case _Stage.pregnancy:
      case _Stage.age:
        return true;
      case _Stage.symptoms:
      case _Stage.riskFactors:
      case _Stage.complete:
        return false;
    }
  }

  String _currentQuestionPrompt() {
    switch (_stage) {
      case _Stage.sex:
        return "What is your biological sex?";
      case _Stage.pregnancy:
        return "Are you currently pregnant?";
      case _Stage.age:
        return "What is your age range?";
      case _Stage.symptoms:
        return "Do you have any of these symptoms?";
      case _Stage.riskFactors:
        return "Do you have any of these risk factors?";
      case _Stage.complete:
        return "";
    }
  }

  Future<void> _handleFreeText() async {
    final text = _freeText.text.trim();
    if (text.isEmpty) return;

    _freeText.clear();
    setState(() {
      _messages.add(_ChatMessage(text, ChatRole.user));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await ApiService.instance.chat(
        message: text,
        history: _buildHistory(),
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(reply.text, ChatRole.bot));
      });
      _scrollToBottom();

      // Re-ask the current question after a short pause
      if (_shouldReAsk) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              "Now, back to our screening — ${_currentQuestionPrompt()}",
              ChatRole.bot,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            "Sorry, I couldn't reach the server. Try asking again?",
            ChatRole.bot,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ava',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Screening assistant',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Messages ──────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return const ChatBubble(
                      message: '',
                      role: ChatRole.bot,
                      isTyping: true,
                    );
                  }
                  final msg = _messages[index];
                  return ChatBubble(message: msg.text, role: msg.role);
                },
              ),
            ),

            // ── Interactive panel (chips or multi-select) ─
            if (!_isTyping) _buildInteractivePanel(),

            // ── Text input (always visible) ───────────────
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePanel() {
    switch (_stage) {
      case _Stage.sex:
        return _chipRow([
          ('Male', () => _pickSex('Male')),
          ('Female', () => _pickSex('Female')),
          ('Prefer not to say', () => _pickSex('Prefer not to say')),
        ]);
      case _Stage.pregnancy:
        return _chipRow([
          ('Yes', () => _pickPregnancy('Yes')),
          ('No', () => _pickPregnancy('No')),
        ]);
      case _Stage.age:
        return _chipRow([
          ('Under 18', () => _pickAge('Under 18', 16)),
          ('18–30', () => _pickAge('18–30', 25)),
          ('31–50', () => _pickAge('31–50', 40)),
          ('51–65', () => _pickAge('51–65', 58)),
          ('65+', () => _pickAge('65+', 70)),
        ]);
      case _Stage.symptoms:
        return _MultiSelectPanel(
          title: 'Symptoms',
          options: _symptomLabels,
          selected: _session.symptoms,
          onToggle: (key) => setState(() {
            if (_session.symptoms.contains(key)) {
              _session.symptoms.remove(key);
            } else {
              _session.symptoms.add(key);
            }
          }),
          onContinue: _submitSymptoms,
        );
      case _Stage.riskFactors:
        return _MultiSelectPanel(
          title: 'Risk factors',
          options: _riskLabels,
          selected: _session.riskFactors,
          onToggle: (key) => setState(() {
            if (_session.riskFactors.contains(key)) {
              _session.riskFactors.remove(key);
            } else {
              _session.riskFactors.add(key);
            }
          }),
          onContinue: _submitRiskFactors,
        );
      case _Stage.complete:
        return _completePanel();
    }
  }

  Widget _chipRow(List<(String, VoidCallback)> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((entry) {
          return ActionChip(
            label: Text(entry.$1),
            onPressed: entry.$2,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _completePanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/labs'),
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Add lab values (optional)'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/scan'),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Continue to Body Scan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _freeText,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleFreeText(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask Ava anything...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _isTyping ? null : _handleFreeText,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

// ─── MULTI-SELECT PANEL ────────────────────────────────────────

class _MultiSelectPanel extends StatelessWidget {
  final String title;
  final Map<String, String> options;
  final Set<String> selected;
  final void Function(String key) onToggle;
  final VoidCallback onContinue;

  const _MultiSelectPanel({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selected.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shrinkWrap: true,
              children: options.entries.map((entry) {
                final isOn = selected.contains(entry.key);
                return CheckboxListTile(
                  dense: true,
                  value: isOn,
                  onChanged: (_) => onToggle(entry.key),
                  title: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
