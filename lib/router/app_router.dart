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
import '../screens/home/leaderboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/study_set/study_sets_screen.dart';

// Study Set screens
import '../screens/study_set/study_set_detail_screen.dart';
import '../screens/study_set/create_study_set_screen.dart';
import '../screens/decks/create_term_screen.dart';
import '../screens/decks/flashcard_study_screen.dart';
import '../data/models/study_set_models.dart';

// Quiz screens
import '../screens/quiz/quiz_challenge_screen.dart';
import '../screens/quiz/quiz_results_screen.dart';
import '../screens/quiz/quiz_history_screen.dart';
import '../screens/quiz/quiz_result_detail_screen.dart';

// Profile screens
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';

// Search screen
import '../screens/search/search_screen.dart';

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
        GoRoute(
          path: '/study-set/:id',
          builder: (c, s) => StudySetDetailScreen(
            studySetId: s.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/study-set/:id/term-edit',
          builder: (c, s) => CreateTermScreen(
            studySetId: s.pathParameters['id']!,
            term: s.extra as Term?,
          ),
        ),
        GoRoute(
          path: '/create-set',
          builder: (c, s) => const CreateStudySetScreen(),
        ),
        GoRoute(
          path: '/study',
          builder: (c, s) => const FlashcardStudyScreen(),
        ),
        GoRoute(
          path: '/quiz/:studySetId',
          builder: (c, s) => QuizChallengeScreen(
            studySetId: s.pathParameters['studySetId']!,
          ),
        ),
        GoRoute(
          path: '/quiz_results',
          builder: (c, s) => QuizResultsScreen(
            result: s.extra as LocalQuizResult,
          ),
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
          path: '/public_profile/:userId',
          builder: (c, s) => PublicProfileScreen(
            userId: s.pathParameters['userId']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (c, s) => const SearchScreen(),
        ),

        // Main Application Shell with bottom nav
        ShellRoute(
          builder: (context, state, child) => BottomNavShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
            GoRoute(
              path: '/studyset',
              builder: (c, s) => const StudySetsScreen(),
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (c, s) => const LeaderboardScreen(),
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
