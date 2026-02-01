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
  String? _errorMessage;

  // Getters
  WorkoutCurriculum? get todayCurriculum => _todayCurriculum;
  UserProfile? get userProfile => _userProfile;
  List<String> get hotCategories => _hotCategories;
  FeaturedProgram? get featuredProgram => _featuredProgram;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isHotCategoriesLoading => _isHotCategoriesLoading;
  String? get errorMessage => _errorMessage;

  /// Load all data for home screen
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load user profile
      final profileResult = await getUserProfile.execute();
      profileResult.fold((failure) {
        debugPrint('Failed to load profile: ${failure.message}');
        _errorMessage = failure.message;
      }, (profile) => _userProfile = profile);

      // Load today's curriculum
      final curriculumResult = await getTodayCurriculum.execute();
      curriculumResult.fold((failure) {
        debugPrint('Failed to load curriculum: ${failure.message}');
      }, (curriculum) => _todayCurriculum = curriculum);

      // Load hot categories
      await _loadHotCategories();

      // Load featured program
      await _loadFeaturedProgram();

      // If no curriculum exists and we have a profile, generate one
      if (_todayCurriculum == null && _userProfile != null) {
        await generateNewCurriculum();
      }
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
        debugPrint('Failed to load hot categories: ${failure.message}');
        _isHotCategoriesLoading = false;
      },
      (categories) {
        _hotCategories = categories;
        _isHotCategoriesLoading = false;
      },
    );
    notifyListeners();
  }

  /// Load featured program
  Future<void> _loadFeaturedProgram() async {
    final result = await getFeaturedProgram.execute();
    result.fold(
      (failure) {
        debugPrint(
          'Failed to load featured program, using mock: ${failure.message}',
        );
        _setMockFeaturedProgram(); // Fallback
      },
      (program) {
        if (program != null) {
          _featuredProgram = program;
        } else {
          _setMockFeaturedProgram();
        }
      },
    );
    notifyListeners();
  }

  void _setMockFeaturedProgram() {
    // Create a mock program if none exists
    // This is a minimal mock, ideally it should match the full mock structure
    _featuredProgram = const FeaturedProgram(
      id: 'featured-mock',
      title: 'Ignite Flow',
      slogan: 'Get Set, Stay Ignite.',
      description: 'Get Set, Stay Ignite.',
      imageUrl: 'assets/images/workouts/squat_04.png',
      membersCount: '5.8k+',
      rating: 5.0,
      difficulty: '3',
      userAvatars: [
        'https://i.pravatar.cc/150?img=12',
        'https://i.pravatar.cc/150?img=24',
        'https://i.pravatar.cc/150?img=33',
      ],
      workoutCurriculum:
          null, // Mock curriculum if needed, but null handles error gracefully
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
      final result = await generateCurriculum.execute(_userProfile!);

      result.fold(
        (failure) {
          _errorMessage = 'Failed to generate curriculum: ${failure.message}';
          debugPrint(_errorMessage);
        },
        (curriculum) {
          _todayCurriculum = curriculum;
          _errorMessage = null;
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
      debugPrint('No curriculum available in featured program');
      return;
    }

    final curriculum = _featuredProgram!.workoutCurriculum!;
    _todayCurriculum = curriculum;

    // Save to local storage
    final result = await saveCurriculum.execute(curriculum);
    result.fold(
      (failure) {
        debugPrint('Failed to save curriculum: ${failure.message}');
      },
      (_) {
        debugPrint('Featured program set as today\'s curriculum');
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
}
