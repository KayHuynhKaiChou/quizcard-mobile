import 'package:go_router/go_router.dart';

// Screens
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/features_screen.dart';
import '../screens/onboarding/progress_tracking_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/global_stats_screen.dart';
import '../screens/home/leaderboard_screen.dart';
import '../screens/decks/deck_terms_list_screen.dart';
import '../screens/decks/create_term_screen.dart';
import '../screens/decks/flashcard_study_screen.dart';
import '../screens/quiz/quiz_challenge_screen.dart';
import '../screens/quiz/quiz_results_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../widgets/bottom_nav_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/features', builder: (c, s) => const FeaturesScreen()),
      GoRoute(path: '/progress', builder: (c, s) => const ProgressTrackingScreen()),

      // Full-screen flows (no bottom nav)
      GoRoute(path: '/decks', builder: (c, s) => const DeckTermsListScreen()),
      GoRoute(path: '/create_term', builder: (c, s) => const CreateTermScreen()),
      GoRoute(path: '/study', builder: (c, s) => const FlashcardStudyScreen()),
      GoRoute(path: '/quiz_challenge', builder: (c, s) => const QuizChallengeScreen()),
      GoRoute(path: '/quiz_results', builder: (c, s) => const QuizResultsScreen()),
      GoRoute(path: '/public_profile', builder: (c, s) => const PublicProfileScreen()),

      // Main Application Shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/explore', builder: (c, s) => const GlobalStatsScreen()),
          GoRoute(path: '/leaderboard', builder: (c, s) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const UserProfileScreen()),
        ],
      ),
    ],
  );
}
