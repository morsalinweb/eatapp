// path: lib/services/socket_service.dart
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';

/// Thin singleton wrapper around socket_io_client, matching the events
/// defined in eat_backend/src/sockets/index.js:
///   emits:   map:subscribe, map:unsubscribe, thread:join, thread:leave,
///            message:send, typing
///   listens: vendor:live, vendor:location_update, vendor:offline,
///            message:new, typing
///
/// IMPORTANT — reconnection handling: Socket.IO room membership
/// (`socket.join('thread:...')`) lives on the server's connection object.
/// If the underlying WebSocket ever drops and reconnects (a network blip,
/// the OS suspending the connection in the background, anything), the
/// server sees a brand new connection with zero rooms joined — even
/// though the client's event listeners are still attached and look fine.
/// Without re-joining on reconnect, messages silently stop arriving until
/// the app is restarted. This class tracks which rooms are "supposed to"
/// be joined and re-joins all of them automatically every time the socket
/// (re)connects.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  bool _wantsMapSubscription = false;
  final Set<String> _activeThreadIds = {};

  /// Connects using the current Supabase session's access token. Call after
  /// login/signup; call [disconnect] on logout.
  void connect() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return;
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[socket] connected — resuming ${_activeThreadIds.length} thread room(s)'
          '${_wantsMapSubscription ? ' + map subscription' : ''}');
      if (_wantsMapSubscription) {
        _socket?.emit('map:subscribe');
      }
      for (final threadId in _activeThreadIds) {
        _emitJoinThread(threadId);
      }
    });

    _socket!.onConnectError((err) => debugPrint('[socket] connect_error: $err'));
    _socket!.onDisconnect((reason) => debugPrint('[socket] disconnected: $reason'));
    _socket!.onError((err) => debugPrint('[socket] error: $err'));

    _socket!.connect();
  }

  void disconnect() {
    _wantsMapSubscription = false;
    _activeThreadIds.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ---- Live map ----
  void subscribeToMap() {
    _wantsMapSubscription = true;
    _socket?.emit('map:subscribe');
  }

  void unsubscribeFromMap() {
    _wantsMapSubscription = false;
    _socket?.emit('map:unsubscribe');
  }

  void onVendorLive(void Function(dynamic data) handler) => _socket?.on('vendor:live', handler);
  void onVendorLocationUpdate(void Function(dynamic data) handler) =>
      _socket?.on('vendor:location_update', handler);
  void onVendorOffline(void Function(dynamic data) handler) => _socket?.on('vendor:offline', handler);

  /// Clears a previously-registered handler for each event. Call these
  /// right before re-registering (see VendorProvider.loadAllVendorsWorldwide)
  /// so re-loading the map screen never ends up with the same event firing
  /// a handler twice — the same defensive re-arming pattern ChatProvider
  /// uses for 'message:new'.
  void offVendorLive() => _socket?.off('vendor:live');
  void offVendorLocationUpdate() => _socket?.off('vendor:location_update');
  void offVendorOffline() => _socket?.off('vendor:offline');

  // ---- Chat ----

  void joinThread(String threadId) {
    _activeThreadIds.add(threadId);
    _emitJoinThread(threadId);
  }

  void _emitJoinThread(String threadId) {
    _socket?.emitWithAck('thread:join', threadId, ack: (response) {
      if (response is Map && response['ok'] != true) {
        debugPrint('[socket] failed to join thread $threadId: ${response['error']}');
      }
    });
  }

  void leaveThread(String threadId) {
    _activeThreadIds.remove(threadId);
    _socket?.emit('thread:leave', threadId);
  }

  void sendMessage(String threadId, String body, {void Function(dynamic)? ack}) {
    _socket?.emitWithAck('message:send', {'thread_id': threadId, 'body': body},
        ack: ack ?? (_) {});
  }

  void onNewMessage(void Function(dynamic data) handler) => _socket?.on('message:new', handler);
  void offNewMessage() => _socket?.off('message:new');

  void sendTyping(String threadId, bool isTyping) =>
      _socket?.emit('typing', {'thread_id': threadId, 'isTyping': isTyping});
  void onTyping(void Function(dynamic data) handler) => _socket?.on('typing', handler);
}