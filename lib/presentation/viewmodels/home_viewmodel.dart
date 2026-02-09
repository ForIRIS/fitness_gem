import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_curriculum.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/featured_program.dart';
import '../../domain/usecases/workout/get_today_curriculum.dart';
import '../../domain/usecases/workout/generate_curriculum.dart';
import '../../domain/usecases/workout/save_curriculum.dart';
import '../../domain/usecases/workout/get_daily_hot_categories.dart';
import '../../domain/usecases/workout/get_featured_program.dart';
import '../../domain/usecases/user/get_user_profile.dart';
import '../../core/di/injection.dart';

/// Riverpod providers for Home feature

// Provider for HomeViewModel
final homeViewModelProvider = ChangeNotifierProvider.autoDispose((ref) {
  return HomeViewModel(
    getTodayCurriculum: getIt<GetTodayCurriculumUseCase>(),
    generateCurriculum: getIt<GenerateCurriculumUseCase>(),
    saveCurriculum: getIt<SaveCurriculumUseCase>(),
    getDailyHotCategories: getIt<GetDailyHotCategoriesUseCase>(),
    getFeaturedProgram: getIt<GetFeaturedProgramUseCase>(),
    getUserProfile: getIt<GetUserProfileUseCase>(),
  );
});

/// ViewModel for Home screen
/// Manages state and business logic for the home view
class HomeViewModel extends ChangeNotifier {
  final GetTodayCurriculumUseCase getTodayCurriculum;
  final GenerateCurriculumUseCase generateCurriculum;
  final SaveCurriculumUseCase saveCurriculum;
  final GetDailyHotCategoriesUseCase getDailyHotCategories;
  final GetFeaturedProgramUseCase getFeaturedProgram;
  final GetUserProfileUseCase getUserProfile;

  HomeViewModel({
    required this.getTodayCurriculum,
    required this.generateCurriculum,
    required this.saveCurriculum,
    required this.getDailyHotCategories,
    required this.getFeaturedProgram,
    required this.getUserProfile,
  });

  // State
  WorkoutCurriculum? _todayCurriculum;
  UserProfile? _userProfile;
  List<String> _hotCategories = [];
  FeaturedProgram? _featuredProgram;

  // Granular Loading States
  bool _isProfileLoading = true;
  bool _isCurriculumLoading = true;
  bool _isHotCategoriesLoading = true;
  bool _isFeaturedLoading = true;

  bool _isGenerating = false;
  String? _errorMessage;
  WorkoutCurriculum? _tomorrowCurriculum;

  // Initialize with a default category if needed, or null
  // Based on user request, 'Build Strength' seems to be the default A case
  String _selectedCategory = 'Build Strength';

  // Getters
  WorkoutCurriculum? get todayCurriculum => _todayCurriculum;
  UserProfile? get userProfile => _userProfile;
  List<String> get hotCategories => _hotCategories;
  FeaturedProgram? get featuredProgram => _featuredProgram;

  // Expose granular states
  bool get isProfileLoading => _isProfileLoading;
  bool get isCurriculumLoading => _isCurriculumLoading;
  bool get isHotCategoriesLoading => _isHotCategoriesLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;

  // Composite loading state for backward compatibility if needed,
  // but UI should use granular getters.
  bool get isLoading => _isProfileLoading && _isCurriculumLoading;

  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  WorkoutCurriculum? get tomorrowCurriculum => _tomorrowCurriculum;

  // Notification State
  bool _areNotificationsEnabled =
      false; // Default to off as per user description
  int _unreadNotificationCount = 0;

  bool get areNotificationsEnabled => _areNotificationsEnabled;
  int get unreadNotificationCount => _unreadNotificationCount;
  bool get hasUnreadNotifications => _unreadNotificationCount > 0;

  bool get isTodayCompleted => _todayCurriculum?.isCompleted ?? false;

  bool get isInProgress {
    if (_todayCurriculum == null) return false;
    if (isTodayCompleted) return false;
    return _todayCurriculum!.currentTaskIndex > 0 ||
        _todayCurriculum!.currentSetIndex > 0;
  }

  /// Select a category and update featured program
  Future<void> selectCategory(String category) async {
    debugPrint('HomeViewModel: User selected category: $category');
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    notifyListeners();

    // Reload featured program for the new category
    await _loadFeaturedProgram();
  }

  /// Load all data for home screen with granular updates
  Future<void> loadData() async {
    _isProfileLoading = true;
    _isCurriculumLoading = true;
    _isHotCategoriesLoading = true;
    _isFeaturedLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('HomeViewModel: Loading dashboard data...');

    // 1. Load User Profile First (Critical for Header)
    await _loadUserProfile();

    // 2. Load Curriculum (Critical for Daily Stats & FAB)
    // We start this immediately after profile to ensure fastest TTI for main action
    await _loadTodayCurriculum();

    // 3. Load Secondary Content Concurrently
    // These can load in parallel as they are lower on the page
    Future.wait([
      _loadHotCategories(),
      _loadFeaturedProgram(),
      _loadTomorrowCurriculum(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileResult = await getUserProfile.execute();
      profileResult.fold(
        (failure) {
          debugPrint(
            'HomeViewModel: Failed to load profile: ${failure.message}',
          );
          _errorMessage = failure.message;
        },
        (profile) {
          _userProfile = profile;
          debugPrint('HomeViewModel: Loaded profile for ${profile?.nickname}');
        },
      );
    } finally {
      _isProfileLoading = false;
      notifyListeners(); // Update UI immediately
    }
  }

  Future<void> _loadTodayCurriculum() async {
    try {
      final curriculumResult = await getTodayCurriculum.execute();

      await curriculumResult.fold(
        (failure) async {
          debugPrint(
            'HomeViewModel: Failed to load curriculum: ${failure.message}',
          );
        },
        (curriculum) async {
          _todayCurriculum = curriculum;

          // If no curriculum exists and we have a profile, generate one
          if (_todayCurriculum == null && _userProfile != null) {
            debugPrint('HomeViewModel: No curriculum found. Generating new...');
            await generateNewCurriculum();
          } else {
            debugPrint(
              'HomeViewModel: Loaded curriculum: ${curriculum?.title}',
            );
          }
        },
      );
    } finally {
      if (!_isGenerating) {
        _isCurriculumLoading = false;
        notifyListeners(); // Update UI immediately
      }
    }
  }

  /// Load hot categories
  Future<void> _loadHotCategories() async {
    try {
      final result = await getDailyHotCategories.execute();
      result.fold(
        (failure) {
          debugPrint(
            'HomeViewModel: Failed to hot categories: ${failure.message}',
          );
        },
        (categories) {
          // Force limit to 3 items as per user request (UI Hotfix)
          final limitedCategories = categories.take(3).toList();
          _hotCategories = limitedCategories;
          if (limitedCategories.isNotEmpty &&
              !limitedCategories.contains(_selectedCategory)) {
            _selectedCategory = limitedCategories.first;
          }
        },
      );
    } finally {
      _isHotCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Load featured program
  Future<void> _loadFeaturedProgram() async {
    // Only set loading if not already loading (to avoid flicker on initial load)
    if (!_isFeaturedLoading) {
      _isFeaturedLoading = true;
      notifyListeners();
    }

    debugPrint('HomeViewModel: Loading featured: $_selectedCategory');

    final result = await getFeaturedProgram.execute(_selectedCategory);
    result.fold(
      (failure) {
        debugPrint(
          'HomeViewModel: Failed to featured program: ${failure.message}',
        );
        _setMockFeaturedProgram();
      },
      (program) {
        if (program != null) {
          _featuredProgram = program;
        } else {
          _setMockFeaturedProgram();
        }
      },
    );

    _isFeaturedLoading = false;
    notifyListeners();
  }

  void _setMockFeaturedProgram() {
    // If the repository fails, we still need a visual program to show
    _featuredProgram = FeaturedProgram(
      id: 'mock_fallback',
      title: 'Workout Program',
      slogan: 'Get Set, Stay Ignite.',
      description: 'Choose a category to see featured challenges.',
      imageUrl: 'assets/images/workouts/air_squat_ready.png',
      membersCount: '0',
      rating: 5.0,
      difficulty: '1',
      userAvatars: [],
      workoutCurriculum: null,
    );
  }

  /// Generate a new curriculum
  Future<void> generateNewCurriculum() async {
    if (_userProfile == null) {
      _errorMessage = 'User profile not found';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('HomeViewModel: Generating curriculum for profile...');
      final result = await generateCurriculum.execute(_userProfile!);

      result.fold(
        (failure) {
          _errorMessage = 'Failed to generate curriculum: ${failure.message}';
          debugPrint('HomeViewModel: $_errorMessage');
        },
        (curriculum) async {
          _todayCurriculum = curriculum;
          _errorMessage = null;
          debugPrint(
            'HomeViewModel: Generated curriculum: ${curriculum.title}',
          );

          // Save to local storage
          debugPrint('HomeViewModel: Saving generated curriculum...');
          final saveResult = await saveCurriculum.execute(curriculum);
          saveResult.fold(
            (failure) => debugPrint(
              'HomeViewModel: Failed to save generated curriculum: ${failure.message}',
            ),
            (_) => debugPrint(
              'HomeViewModel: Generated curriculum saved successfully',
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('HomeViewModel: Error generating curriculum: $e');
      _errorMessage = e.toString();
    } finally {
      _isGenerating = false;
      _isCurriculumLoading = false; // Ensure this is cleared
      notifyListeners();
    }
  }

  /// Set featured program as today's curriculum
  Future<void> setFeaturedAsToday() async {
    if (_featuredProgram == null ||
        _featuredProgram!.workoutCurriculum == null) {
      // If we have a featured program but no curriculum (e.g. presentation only),
      // we might want to fetch it or handle error. For now, just return.
      debugPrint('HomeViewModel: No curriculum available in featured program');
      return;
    }

    final curriculum = _featuredProgram!.workoutCurriculum!;
    _todayCurriculum = curriculum;

    // Save to local storage
    debugPrint(
      'HomeViewModel: Saving featured program as today\'s curriculum...',
    );
    final result = await saveCurriculum.execute(curriculum);
    result.fold(
      (failure) {
        debugPrint(
          'HomeViewModel: Failed to save curriculum: ${failure.message}',
        );
      },
      (_) {
        debugPrint(
          'HomeViewModel: Featured program set as today\'s curriculum',
        );
      },
    );

    notifyListeners();
  }

  /// Update today's curriculum with a new one (e.g. from AI)
  Future<void> updateTodayCurriculum(WorkoutCurriculum curriculum) async {
    _todayCurriculum = curriculum;
    debugPrint(
      'HomeViewModel: Updating today\'s curriculum: ${curriculum.title}',
    );

    // Save to local storage
    final result = await saveCurriculum.execute(curriculum);
    result.fold(
      (failure) {
        debugPrint(
          'HomeViewModel: Failed to save updated curriculum: ${failure.message}',
        );
      },
      (_) {
        debugPrint('HomeViewModel: Updated today\'s curriculum successfully');
      },
    );

    notifyListeners();
  }

  /// Update user profile (in-memory only for now)
  /// TODO: Implement persistence via SaveUserProfileUseCase
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset progress of today's curriculum
  Future<void> resetWorkoutProgress() async {
    if (_todayCurriculum == null) return;

    final resetCurriculum = _todayCurriculum!.resetProgress();
    await updateTodayCurriculum(resetCurriculum);
  }

  /// Load tomorrow's curriculum (Mock implementation)
  Future<void> _loadTomorrowCurriculum() async {
    // In a real app, this might fetch from a pre-planned schedule
    // or generate a preview. For now, we'll provide a mock tomorrow curriculum.
    _tomorrowCurriculum = WorkoutCurriculum(
      id: 'tomorrow_1',
      title: 'Active Recovery',
      description: 'Light stretching and mobility to recover from today.',
      createdAt: DateTime.now().add(const Duration(days: 1)),
      workoutTasks: [], // Empty for preview
    );
    notifyListeners();
  }

  /// Toggle notification enabled state (Mock)
  void toggleNotifications() {
    _areNotificationsEnabled = !_areNotificationsEnabled;
    // Reset unread count if disabled? Or keep it?
    // Usually if you disable notifications, you might not see badges, but existing ones might stay or clear.
    // Let's just toggle the setting for now.
    notifyListeners();
  }

  /// Update unread notification count (Mock)
  void setUnreadCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }
}
