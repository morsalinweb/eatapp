// path: lib/screens/vendor/vendor_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/alien_avatar.dart';
import '../chat/chat_thread_screen.dart';

class VendorMessagesScreen extends StatefulWidget {
  const VendorMessagesScreen({super.key});

  @override
  State<VendorMessagesScreen> createState() => _VendorMessagesScreenState();
}

class _VendorMessagesScreenState extends State<VendorMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadThreads(viewerIsVendor: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final threads = chatProvider.threads;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          bottom: const TabBar(
            indicatorColor: AppColors.neon,
            labelColor: AppColors.neon,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'Inbox'), Tab(text: 'Archive')],
          ),
        ),
        body: TabBarView(
          children: [
            chatProvider.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
                : threads.isEmpty
                    ? const Center(
                        child: Text('No messages yet', style: TextStyle(color: AppColors.textSecondary)))
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
                                color:
                                    thread.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: thread.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            trailing: thread.unreadCount > 0
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration:
                                        const BoxDecoration(color: AppColors.neon, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text('${thread.unreadCount}',
                                          style: const TextStyle(
                                              color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    ChatThreadScreen(threadTitle: thread.otherPartyName, thread: thread),
                              ));
                            },
                          );
                        },
                      ),
            const Center(
              child: Text('No archived conversations', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}