import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/qa_provider.dart';
import '../utils/prompt_templates.dart';
import '../widgets/qa_message_bubble.dart';

/// Full chat interface for the Gemma 4 farming Q&A.
///
/// Shows conversation history, an input field, suggested questions, and
/// loading / error states.
class QaScreen extends StatefulWidget {
  /// Optional initial question to send immediately (e.g. from the home text
  /// field routed via TaskRouter).
  final String? initialQuestion;

  const QaScreen({super.key, this.initialQuestion});

  @override
  State<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends State<QaScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sentInitial = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Send the initial question once (routed from home text field).
    if (!_sentInitial &&
        widget.initialQuestion != null &&
        widget.initialQuestion!.trim().isNotEmpty) {
      _sentInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<QaProvider>().ask(widget.initialQuestion!);
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<QaProvider>().ask(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask the Expert'),
        actions: [
          Consumer<QaProvider>(
            builder: (_, qa, _) {
              if (qa.scanContext != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: Icon(Icons.linked_camera,
                        size: 14, color: Colors.orange[800]),
                    label: Text(
                      qa.scanContext!.disease,
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => qa.clearScanContext(),
                    backgroundColor: Colors.orange[50],
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClear();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear history'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────
          Expanded(
            child: Consumer<QaProvider>(
              builder: (_, qa, _) {
                final msgs = qa.messages;
                if (qa.isLoading || msgs.isNotEmpty) {
                  _scrollToBottom();
                }

                if (msgs.isEmpty && !qa.isLoading) {
                  return _EmptyState(onSuggestionTap: _sendSuggestion);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: msgs.length + (qa.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < msgs.length) {
                      return QaMessageBubble(message: msgs[index]);
                    }
                    // Loading indicator at the bottom
                    return const _TypingIndicator();
                  },
                );
              },
            ),
          ),

          // ── Error banner ──────────────────────────────────────────
          Consumer<QaProvider>(
            builder: (_, qa, _) {
              if (qa.error == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.red[50],
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        qa.error!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => qa.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Input bar ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ask about cocoa farming...',
                        filled: true,
                        fillColor: Colors.brown[50],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<QaProvider>(
                    builder: (_, qa, _) {
                      return IconButton.filled(
                        onPressed: qa.isLoading ? null : _submit,
                        icon: qa.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          disabledBackgroundColor: Colors.green[300],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendSuggestion(String question) {
    context.read<QaProvider>().ask(question);
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This will delete all Q&A conversations. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<QaProvider>().clearHistory();
            },
            child:
                const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state with suggested questions ─────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const _EmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.smart_toy_outlined,
              size: 64, color: Colors.green[300]),
          const SizedBox(height: 16),
          Text(
            'Gemma 4 Farming Expert',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask any question about cocoa farming, diseases, treatments, '
            'or best practices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),
          Text(
            'Try asking:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: PromptTemplates.suggestedQuestions
                .map(
                  (q) => ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.chat_bubble_outline,
                        size: 14),
                    onPressed: () => onSuggestionTap(q),
                    backgroundColor: Colors.brown[50],
                    side: BorderSide(
                      color: Colors.brown.withValues(alpha: 0.15),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final qa = context.watch<QaProvider>();
    final label = qa.isTranslating ? 'Translating...' : 'Thinking...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.brown.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
