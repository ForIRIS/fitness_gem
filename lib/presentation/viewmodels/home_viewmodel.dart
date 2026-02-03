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
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isHotCategoriesLoading = false;
  bool _isFeaturedLoading = false;
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
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isHotCategoriesLoading => _isHotCategoriesLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  WorkoutCurriculum? get tomorrowCurriculum => _tomorrowCurriculum;

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

  /// Load all data for home screen
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('HomeViewModel: Loading dashboard data...');

    try {
      // Load user profile
      final profileResult = await getUserProfile.execute();
      profileResult.fold(
        (failure) {
          debugPrint(
            'HomeViewModel: Failed to load profile: ${failure.message}',
          );
          _errorMessage = failure.message;
        },
        (profile) {
          if (profile != null) {
            debugPrint('HomeViewModel: Loaded profile for ${profile.nickname}');
            _userProfile = profile;
          } else {
            debugPrint('HomeViewModel: Loaded profile is null.');
            _userProfile = null;
          }
        },
      );

      // Load today's curriculum
      final curriculumResult = await getTodayCurriculum.execute();
      curriculumResult.fold(
        (failure) {
          debugPrint(
            'HomeViewModel: Failed to load curriculum: ${failure.message}',
          );
        },
        (curriculum) {
          if (curriculum != null) {
            debugPrint(
              'HomeViewModel: Loaded existing curriculum: ${curriculum.title}',
            );
          } else {
            debugPrint('HomeViewModel: No existing curriculum found.');
          }
          _todayCurriculum = curriculum;
        },
      );

      // Load hot categories
      await _loadHotCategories();

      // Load featured program
      await _loadFeaturedProgram();

      // If no curriculum exists and we have a profile, generate one
      if (_todayCurriculum == null && _userProfile != null) {
        debugPrint('HomeViewModel: Generating new curriculum...');
        await generateNewCurriculum();
      }

      // Load tomorrow's curriculum (mock for now or based on some schedule)
      await _loadTomorrowCurriculum();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load hot categories
  Future<void> _loadHotCategories() async {
    _isHotCategoriesLoading = true;
    notifyListeners();

    final result = await getDailyHotCategories.execute();
    result.fold(
      (failure) {
        debugPrint(
          'HomeViewModel: Failed to load hot categories: ${failure.message}',
        );
        _isHotCategoriesLoading = false;
      },
      (categories) {
        _hotCategories = categories;

        // Ensure selected category is valid if categories loaded
        if (categories.isNotEmpty && !categories.contains(_selectedCategory)) {
          _selectedCategory = categories.first;
        }

        _isHotCategoriesLoading = false;
      },
    );
    notifyListeners();
  }

  /// Load featured program
  Future<void> _loadFeaturedProgram() async {
    debugPrint(
      'HomeViewModel: Loading featured program for category: $_selectedCategory',
    );

    _isFeaturedLoading = true;
    notifyListeners();

    // Pass the selected category to the use case
    final result = await getFeaturedProgram.execute(_selectedCategory);
    result.fold(
      (failure) {
        debugPrint(
          'HomeViewModel: Failed to load featured program, using mock: ${failure.message}',
        );
        _setMockFeaturedProgram(); // Fallback
      },
      (program) {
        if (program != null) {
          debugPrint('HomeViewModel: Loaded program: ${program.title}');
          _featuredProgram = program;
        } else {
          debugPrint('HomeViewModel: Loaded program is NULL');
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
      imageUrl: 'assets/images/workouts/squat_01.png',
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
    } finally {
      _isGenerating = false;
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
}
