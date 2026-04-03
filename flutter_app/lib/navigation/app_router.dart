import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/trip_details_screen.dart';
import '../screens/authority_home_screen.dart';
import '../widgets/movement_detector.dart';
import 'main_tab_navigator.dart';
import '../screens/safe_route_map_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            email: extra?['email'] ?? '',
            isSignUp: extra?['isSignUp'] ?? false,
            name: extra?['name'],
            phone: extra?['phone'],
            password: extra?['password'],
          );
        },
      ),
      GoRoute(
        path: '/trip-details',
        builder: (context, state) => const TripDetailsScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MovementDetector(
          child: MainTabNavigator(),
        ),
      ),
      GoRoute(
        path: '/authority-home',
        builder: (context, state) => const AuthorityHomeScreen(),
      ),
      GoRoute(
        path: '/safe-route',
        builder: (context, state) => const SafeRouteMapScreen(),
      ),
    ],
    redirect: (context, state) {
      final userProvider = context.read<UserProvider>();
      final loggingIn = state.uri.path == '/login' || state.uri.path == '/signup' || state.uri.path == '/' || state.uri.path == '/otp';

      if (userProvider.loading) return null;

      if (!userProvider.isAuthenticated && !loggingIn) {
        return '/';
      }

      return null;
    },
  );
}
