// path: lib/core/navigation.dart
import 'package:flutter/material.dart';

/// Lets code outside the widget tree (specifically, AuthProvider's
/// deep-link sign-in handler) push a new route without needing a
/// BuildContext — the email-confirmation link can arrive while any screen
/// happens to be visible, not just one we control.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();