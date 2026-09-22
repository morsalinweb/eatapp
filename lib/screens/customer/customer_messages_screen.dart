// path: lib/screens/customer/customer_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/alien_avatar.dart';
import '../chat/chat_thread_screen.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadThreads(viewerIsVendor: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final threads = chatProvider.threads;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatProvider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : chatProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chatProvider.error!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => chatProvider.loadThreads(viewerIsVendor: false),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : threads.isEmpty
                  ? const Center(
                      child: Text('No conversations yet', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => const Divider(indent: 82, height: 1),
                      itemBuilder: (context, i) {
                        final thread = threads[i];
                        final last = thread.lastMessage;
                        return ListTile(
                          leading: AlienAvatar(size: 48, imageUrl: thread.otherPartyAvatarUrl),
                          title: Text(thread.otherPartyName,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            last?.text ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: thread.unreadCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: thread.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                last != null ? _timeLabel(last.sentAt) : '',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              if (thread.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(color: AppColors.neon, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '${thread.unreadCount}',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ChatThreadScreen(threadTitle: thread.otherPartyName, thread: thread),
                            ));
                          },
                        );
                      },
                    ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}