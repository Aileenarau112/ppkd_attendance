import 'package:flutter/material.dart';

import '../../presentation/splash/splash_page.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/auth/register_page.dart';
import '../../presentation/dashboard/dashboard_page.dart';
import '../../presentation/history/history_page.dart';
import '../../presentation/profile/profile_page.dart';

class AppRoutes {
  static const String splash = "/";

  static const String login = "/login";

  static const String register = "/register";

  static const String dashboard = "/dashboard";

  static const String history = "/history";

  static const String profile = "/profile";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),

    login: (context) => const LoginPage(),

    register: (context) => const RegisterPage(),

    dashboard: (context) => DashboardPage(user: {}),

    history: (context) => const HistoryPage(),

    profile: (context) => ProfilePage(user: {}),
  };
}
