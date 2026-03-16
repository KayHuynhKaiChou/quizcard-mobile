import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/auth_service.dart';

// Auth screens
import '../screens/auth/signin_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_sent_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';

// Onboarding screens
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/features_screen.dart';
import '../screens/onboarding/progress_tracking_screen.dart';

// Main screens
import '../screens/home/home_screen.dart';
import '../screens/home/global_stats_screen.dart';
import '../screens/home/leaderboard_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/notifications/notifications_screen.dart';

// Deck screens
import '../screens/decks/deck_terms_list_screen.dart';
import '../screens/decks/create_term_screen.dart';
import '../screens/decks/flashcard_study_screen.dart';

// Quiz screens
import '../screens/quiz/quiz_challenge_screen.dart';
import '../screens/quiz/quiz_results_screen.dart';
import '../screens/quiz/quiz_history_screen.dart';
import '../screens/quiz/quiz_result_detail_screen.dart';

// Profile screens
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';

import '../widgets/bottom_nav_shell.dart';

class AppRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/signin',
      redirect: (context, state) {
        final isAuthenticated = authService.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/signin' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation == '/reset-password' ||
            state.matchedLocation == '/verify-email-sent' ||
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/features' ||
            state.matchedLocation == '/progress';

        // If not authenticated and trying to access protected route → signin
        if (!isAuthenticated && !isAuthRoute) return '/signin';

        // If authenticated and on auth route → home
        if (isAuthenticated && isAuthRoute) return '/home';

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(path: '/signin', builder: (c, s) => const SigninScreen()),
        GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
        GoRoute(
          path: '/verify-email-sent',
          builder: (c, s) => VerifyEmailSentScreen(
            email: s.uri.queryParameters['email'],
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (c, s) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (c, s) => ResetPasswordScreen(
            token: s.uri.queryParameters['token'],
          ),
        ),

        // Onboarding (accessible without auth)
        GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
        GoRoute(path: '/features', builder: (c, s) => const FeaturesScreen()),
        GoRoute(
          path: '/progress',
          builder: (c, s) => const ProgressTrackingScreen(),
        ),

        // Full-screen flows (no bottom nav)
        GoRoute(path: '/decks', builder: (c, s) => const DeckTermsListScreen()),
        GoRoute(
          path: '/create_term',
          builder: (c, s) => const CreateTermScreen(),
        ),
        GoRoute(
          path: '/study',
          builder: (c, s) => const FlashcardStudyScreen(),
        ),
        GoRoute(
          path: '/quiz_challenge',
          builder: (c, s) => const QuizChallengeScreen(),
        ),
        GoRoute(
          path: '/quiz_results',
          builder: (c, s) => const QuizResultsScreen(),
        ),
        GoRoute(
          path: '/quiz-history',
          builder: (c, s) => const QuizHistoryScreen(),
        ),
        GoRoute(
          path: '/quiz-history/:id',
          builder: (c, s) => QuizResultDetailScreen(
            resultId: s.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/public_profile',
          builder: (c, s) => const PublicProfileScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),

        // Main Application Shell with bottom nav
        ShellRoute(
          builder: (context, state, child) => BottomNavShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
            GoRoute(
              path: '/explore',
              builder: (c, s) => const GlobalStatsScreen(),
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (c, s) => const LeaderboardScreen(),
            ),
            GoRoute(
              path: '/library',
              builder: (c, s) => const LibraryScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (c, s) => const UserProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
