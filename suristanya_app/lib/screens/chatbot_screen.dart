import 'package:flutter/material.dart';

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

class _SymptomQuestion {
  final String text;
  const _SymptomQuestion(this.text);
}

const List<_SymptomQuestion> _questions = [
  _SymptomQuestion("Have you been feeling unusually tired or fatigued lately?"),
  _SymptomQuestion(
    "Have you noticed paleness in your skin, palms, or lower eyelids?",
  ),
  _SymptomQuestion(
    "Do you get short of breath easily, even with light activity?",
  ),
  _SymptomQuestion("Do you feel dizzy or lightheaded often?"),
  _SymptomQuestion("Are your hands and feet often cold?"),
  _SymptomQuestion("Do you get frequent headaches?"),
  _SymptomQuestion("Have you noticed your heartbeat racing or pounding?"),
  _SymptomQuestion(
    "Are your nails brittle, spoon-shaped, or unusually ridged?",
  ),
  _SymptomQuestion("Does your tongue feel sore, smooth, or unusually pale?"),
];

enum _Stage { questionnaire, completed }

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      "Hi! I'm Ava 🌿 your health assistant.\n\nI'll ask you a few quick questions about common anemia symptoms, then guide you to a body scan.",
      ChatRole.bot,
    ),
  ];

  final List<String> _answers = [];
  int _currentQuestion = 0;
  _Stage _stage = _Stage.questionnaire;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askCurrentQuestion();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  void _askCurrentQuestion() {
    if (_currentQuestion >= _questions.length) {
      _completeQuestionnaire();
      return;
    }

    setState(() => _isTyping = true);
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(_questions[_currentQuestion].text, ChatRole.bot),
        );
      });
      _scrollToBottom();
    });
  }

  void _answer(String value) {
    if (_stage != _Stage.questionnaire) return;

    setState(() {
      _answers.add(value);
      _messages.add(_ChatMessage(value, ChatRole.user));
      _currentQuestion++;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _askCurrentQuestion();
    });
  }

  void _completeQuestionnaire() {
    final yesCount = _answers.where((a) => a.toLowerCase() == 'yes').length;
    final total = _questions.length;

    String summary;
    if (yesCount == 0) {
      summary = "Great — you didn't report any symptoms. A quick scan can still give you a baseline.";
    } else if (yesCount <= 2) {
      summary =
          "You reported $yesCount symptom${yesCount == 1 ? '' : 's'}. It's worth a scan to look for subtle signs.";
    } else if (yesCount <= 5) {
      summary =
          "You reported $yesCount symptoms — several overlap with anemia. I recommend doing a scan now.";
    } else {
      summary =
          "You reported $yesCount symptoms. That's a lot — please do a scan, and consider seeing a doctor soon.";
    }

    setState(() {
      _stage = _Stage.completed;
      _messages.add(
        _ChatMessage(
          "Thanks for answering all $total questions! 🌿\n\n$summary",
          ChatRole.bot,
        ),
      );
      _messages.add(
        _ChatMessage(
          "Tap Start Scan below to capture your tongue, palm, nail, and eye. It takes about a minute.",
          ChatRole.bot,
        ),
      );
    });
    _scrollToBottom();
  }

  void _restart() {
    setState(() {
      _answers.clear();
      _currentQuestion = 0;
      _stage = _Stage.questionnaire;
      _messages.clear();
      _messages.add(
        _ChatMessage(
          "Hi! I'm Ava 🌿 your health assistant.\n\nI'll ask you a few quick questions about common anemia symptoms, then guide you to a body scan.",
          ChatRole.bot,
        ),
      );
    });
    _askCurrentQuestion();
  }

  List<String> get _quickReplies {
    if (_stage == _Stage.questionnaire) {
      return const ['Yes', 'No', 'Unsure'];
    }
    return const ['Start Scan', 'Restart questions'];
  }

  void _handleQuickReply(String value) {
    if (value == 'Start Scan') {
      Navigator.pushNamed(context, '/scan');
      return;
    }
    if (value == 'Restart questions') {
      _restart();
      return;
    }
    _answer(value);
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final progress = (_currentQuestion / total).clamp(0.0, 1.0);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ava',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar (questionnaire only) ────────────
            if (_stage == _Stage.questionnaire)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Anemia symptom check',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_currentQuestion.clamp(0, total)} / $total',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        color: AppColors.accent,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Messages ─────────────────────────────────────
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

            // ── Quick replies ────────────────────────────────
            if (!_isTyping && _quickReplies.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final label = _quickReplies[i];
                    final isPrimary = label == 'Start Scan';
                    return ActionChip(
                      label: Text(label),
                      onPressed: () => _handleQuickReply(label),
                      backgroundColor: isPrimary
                          ? AppColors.primary
                          : Colors.white,
                      side: BorderSide(
                        color: isPrimary ? AppColors.primary : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  },
                ),
              ),

            // ── Status hint bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _stage == _Stage.questionnaire
                        ? Icons.touch_app_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                    color: _stage == _Stage.questionnaire
                        ? AppColors.accentDark
                        : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stage == _Stage.questionnaire
                          ? 'Tap Yes / No / Unsure above to answer'
                          : 'All done — tap Start Scan above to continue',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
