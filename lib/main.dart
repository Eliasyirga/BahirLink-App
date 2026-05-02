import 'package:flutter/material.dart';

import 'presentation/home/home_page.dart';
import 'presentation/call/call_page.dart';
import 'services/call_services.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _callRouteOpen = false;
  CallInvite? _activeInvite;

  @override
  void initState() {
    super.initState();

    CallService.I.onIncomingCall = (invite) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;

      // Don't stack duplicates
      if (_callRouteOpen &&
          _activeInvite != null &&
          _activeInvite!.emergencyId == invite.emergencyId &&
          _activeInvite!.fromSocketId == invite.fromSocketId) {
        return;
      }
      if (_callRouteOpen) return;

      _callRouteOpen = true;
      _activeInvite = invite;

      nav
          .push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CallPage(invite: invite),
        ),
      )
          .whenComplete(() {
        _callRouteOpen = false;
        _activeInvite = null;
        CallService.I.pendingInvite = null;
      });
    };
  }

  @override
  void dispose() {
    CallService.I.onIncomingCall = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BahirLink',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}