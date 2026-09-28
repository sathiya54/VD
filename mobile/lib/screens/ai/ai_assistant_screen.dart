import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/result.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _service = AiService();
  final _contentController = TextEditingController();
  bool _isBusy = false;
  String? _resultLabel;
  String? _resultText;
  List<String>? _resultTags;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Result<dynamic>> Function() action, String label) async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _resultText = null;
      _resultTags = null;
      _resultLabel = label;
    });

    final result = await action();
    result.when(
      success: (data) {
        setState(() {
          if (data is List) {
            _resultTags = data.map((e) => e.toString()).toList();
          } else {
            _resultText = data.toString();
          }
        });
      },
      failure: (error) {
        setState(() {
          _errorMessage = error.isAiNotConfigured
              ? 'AI assistant is not available right now. Please try again later.'
              : error.message;
        });
      },
    );
    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final aiEnabled = auth.user?.aiEnabled ?? false;

    if (!aiEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Assistant')),
        body: const EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'AI Assistant is turned off',
          message:
              'Enable AI features from Settings > AI Settings to summarize, improve, or tag your entries automatically.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Paste or write an entry below, then choose an action.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste your diary entry text here...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Generate Title',
                icon: Icons.title,
                onTap: () => _run(
                  () => _service.generateTitle(_contentController.text.trim()),
                  'Suggested Title',
                ),
              ),
              _ActionButton(
                label: 'Summarize',
                icon: Icons.summarize_outlined,
                onTap: () => _run(
                  () => _service.summarize(_contentController.text.trim()),
                  'Summary',
                ),
              ),
              _ActionButton(
                label: 'Improve Writing',
                icon: Icons.auto_fix_high_outlined,
                onTap: () => _run(
                  () => _service.improve(_contentController.text.trim()),
                  'Improved Version',
                ),
              ),
              _ActionButton(
                label: 'Generate Tags',
                icon: Icons.sell_outlined,
                onTap: () => _run(
                  () => _service.generateTags(_contentController.text.trim()),
                  'Suggested Tags',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isBusy) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          if (_resultText != null || _resultTags != null) ...[
            Text(_resultLabel ?? 'Result', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _resultTags != null
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _resultTags!.map((t) => Chip(label: Text(t))).toList(),
                      )
                    : Text(_resultText ?? ''),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
