import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({required this.state, super.key});
  final AppState state;

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<ChatMessage> _messages;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        id: 'opening',
        fromUser: false,
        text: widget.state.likedOffers.isEmpty
            ? 'Я Островок. Подберу вариант, помогу с заявкой или позову менеджера.'
            : 'У вас уже ${widget.state.likedOffers.length} понравившихся вариантов. Могу их сравнить.',
        quickReplies: const [
          'Подобрать',
          'Забронировать',
          'Отложить бронь',
          'Менеджер',
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickReplies = _messages.last.fromUser
        ? const <String>[]
        : _messages.last.quickReplies;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _MessageBubble(message: _messages[index]),
          ),
        ),
        if (_sending) const LinearProgressIndicator(minHeight: 2),
        if (quickReplies.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              scrollDirection: Axis.horizontal,
              itemCount: quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ActionChip(
                label: Text(quickReplies[index]),
                onPressed: _sending ? null : () => _send(quickReplies[index]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sending ? null : _send,
                      decoration: InputDecoration(
                        hintText: 'Напишите агенту',
                        filled: true,
                        fillColor: AppColors.mint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : () => _send(_input.text),
                    icon: const Icon(Icons.arrow_circle_up_rounded),
                    color: AppColors.leaf,
                    iconSize: 36,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _input.clear();
      _messages.add(
        ChatMessage(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          fromUser: true,
          text: text,
        ),
      );
    });
    _scrollDown();

    final reply = await widget.state.chat(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add(
        ChatMessage(
          id: 'agent-${DateTime.now().microsecondsSinceEpoch}',
          fromUser: false,
          text: reply.text,
          quickReplies: reply.quickReplies,
        ),
      );
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          message.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!message.fromUser) ...[
          const Mascot(size: 38),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: message.fromUser ? AppColors.leaf : Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.fromUser ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
        if (message.fromUser) const SizedBox(width: 44),
      ],
    );
  }
}
