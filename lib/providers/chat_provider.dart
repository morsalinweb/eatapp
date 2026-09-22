// path: lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';

/// Thread history loads over REST (GET /threads, GET /threads/:id/messages);
/// sending + receiving happens over the socket for instant delivery, with
/// a REST fallback if the socket isn't connected for some reason.
///
/// Real-time delivery is handled by ONE global 'message:new' listener,
/// re-armed every time [loadThreads] runs, rather than a per-thread
/// listener that only exists while that specific chat screen is open.
class ChatProvider extends ChangeNotifier {
  List<ChatThread> threads = [];
  bool loading = false;
  String? error;
  bool _viewerIsVendor = false;

  String? _activeThreadId;

  String get _myUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  int get unreadTotal => threads.fold(0, (sum, t) => sum + t.unreadCount);

  void setActiveThread(String? threadId) {
    _activeThreadId = threadId;
    if (threadId != null) {
      final idx = threads.indexWhere((t) => t.id == threadId);
      if (idx != -1 && threads[idx].unreadCount != 0) {
        threads[idx].unreadCount = 0;
        notifyListeners();
      }
    }
  }

  Future<void> loadThreads({required bool viewerIsVendor}) async {
    _viewerIsVendor = viewerIsVendor;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/threads');
      threads = (json['threads'] as List)
          .map((t) => ChatThread.fromJson(t, viewerIsVendor: viewerIsVendor))
          .toList();

      SocketService.instance.offNewMessage();
      SocketService.instance.onNewMessage(_handleIncomingMessage);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not load conversations.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _handleIncomingMessage(dynamic data) {
    final threadId = data['thread_id'];
    final idx = threads.indexWhere((t) => t.id == threadId);

    if (idx == -1) {
      loadThreads(viewerIsVendor: _viewerIsVendor);
      return;
    }

    final incoming = ChatMessage.fromJson(data, _myUserId);
    final thread = threads[idx];
    final alreadyPresent = thread.messages.any((m) => m.id == incoming.id);
    if (!alreadyPresent) {
      thread.messages.add(incoming);
    }

    if (_activeThreadId == thread.id) {
      thread.unreadCount = 0;
    } else if (!incoming.isMine) {
      thread.unreadCount += 1;
    }

    threads
      ..removeAt(idx)
      ..insert(0, thread);

    notifyListeners();
  }

  /// Starts (or reopens) a conversation with a vendor from the customer
  /// side, returning the thread so the UI can navigate straight into it.
  ///
  /// [vendorAvatarUrl] is optional and only used when this is a genuinely
  /// NEW thread (not already in [threads]) — it lets the chat screen show
  /// the vendor's real photo immediately, instead of the painted alien
  /// placeholder until the next full inbox reload pulls it from the server.
  Future<ChatThread?> startThreadWithVendor(
    String vendorId,
    String vendorName, {
    String? vendorAvatarUrl,
  }) async {
    try {
      final json = await ApiClient.instance.post('/threads', body: {'vendor_id': vendorId});
      final threadId = json['thread']['id'];
      final existingIndex = threads.indexWhere((t) => t.id == threadId);
      ChatThread thread;
      if (existingIndex != -1) {
        thread = threads[existingIndex];
      } else {
        thread = ChatThread(
          id: threadId,
          vendorId: vendorId,
          otherPartyName: vendorName,
          otherPartyAvatarUrl: vendorAvatarUrl ?? '',
        );
        threads.insert(0, thread);
      }
      notifyListeners();
      return thread;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(ChatThread thread) async {
    try {
      final json = await ApiClient.instance.get('/threads/${thread.id}/messages');
      thread.messages = (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m, _myUserId))
          .toList();
      thread.unreadCount = 0;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  void startListening(ChatThread thread) {
    SocketService.instance.joinThread(thread.id);
  }

  void stopListening(ChatThread thread) {
    SocketService.instance.leaveThread(thread.id);
  }

  Future<void> sendMessage(ChatThread thread, String text) async {
    if (SocketService.instance.isConnected) {
      SocketService.instance.sendMessage(thread.id, text, ack: (response) {
        if (response is Map && response['ok'] == true && response['message'] != null) {
          final msg = ChatMessage.fromJson(response['message'], _myUserId);
          final alreadyPresent = thread.messages.any((m) => m.id == msg.id);
          if (!alreadyPresent) {
            thread.messages.add(msg);
            notifyListeners();
          }
        }
      });
    } else {
      try {
        final json = await ApiClient.instance.post('/threads/${thread.id}/messages', body: {'body': text});
        thread.messages.add(ChatMessage.fromJson(json['message'], _myUserId));
        notifyListeners();
      } catch (_) {
        // surfaced to the user via the chat screen's own error handling
      }
    }
  }
}