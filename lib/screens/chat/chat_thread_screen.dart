// path: lib/screens/chat/chat_thread_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/alien_avatar.dart';

class ChatThreadScreen extends StatefulWidget {
  final String threadTitle;
  final ChatThread thread;

  const ChatThreadScreen({super.key, required this.threadTitle, required this.thread});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.setActiveThread(widget.thread.id);
    await chatProvider.loadMessages(widget.thread);
    chatProvider.startListening(widget.thread);
    _lastMessageCount = widget.thread.messages.length;
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(widget.thread, text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.stopListening(widget.thread);
    chatProvider.setActiveThread(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ChatProvider>(); // rebuild on new messages
    final messages = widget.thread.messages;

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AlienAvatar(size: 34, imageUrl: widget.thread.otherPartyAvatarUrl),
            const SizedBox(width: 10),
            Text(widget.threadTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
                : messages.isEmpty
                    ? const Center(
                        child: Text('Say hello 👋', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.neon,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.neonGlow(opacity: 0.3),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.neon : AppColors.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text,
                style: TextStyle(color: isMine ? Colors.black : AppColors.textPrimary, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.black.withOpacity(0.6) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}