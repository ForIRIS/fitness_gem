import 'package:equatable/equatable.dart';

/// Domain Entity: PostWorkoutSummary
/// Represents the Storyteller agent's analysis comparing session vs baseline.
class PostWorkoutSummary extends Equatable {
  final HeadlineCard headlineCard;
  final List<String> insightBulletPoints;
  final VisualizationMeta visualizationMeta;
  final String ttsScript;

  const PostWorkoutSummary({
    required this.headlineCard,
    required this.insightBulletPoints,
    required this.visualizationMeta,
    required this.ttsScript,
  });

  /// Parse from Gemini JSON response
  factory PostWorkoutSummary.fromJson(Map<String, dynamic> json) {
    final uiComponents = json['ui_components'] as Map<String, dynamic>;
    final vizMeta = json['visualization_meta'] as Map<String, dynamic>;

    return PostWorkoutSummary(
      headlineCard: HeadlineCard.fromJson(
        uiComponents['headline_card'] as Map<String, dynamic>,
      ),
      insightBulletPoints: (uiComponents['insight_bullet_points'] as List)
          .map((e) => e.toString())
          .toList(),
      visualizationMeta: VisualizationMeta.fromJson(vizMeta),
      ttsScript: json['tts_script'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'ui_components': {
      'headline_card': headlineCard.toJson(),
      'insight_bullet_points': insightBulletPoints,
    },
    'visualization_meta': visualizationMeta.toJson(),
    'tts_script': ttsScript,
  };

  @override
  List<Object?> get props => [
    headlineCard,
    insightBulletPoints,
    visualizationMeta,
    ttsScript,
  ];
}

/// Headline card for the insight display
class HeadlineCard extends Equatable {
  final String title;
  final String subtitle;
  final ThemeColor themeColor;

  const HeadlineCard({
    required this.title,
    required this.subtitle,
    required this.themeColor,
  });

  factory HeadlineCard.fromJson(Map<String, dynamic> json) {
    return HeadlineCard(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      themeColor: ThemeColor.fromString(json['theme_color'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'theme_color': themeColor.name.toUpperCase(),
  };

  @override
  List<Object?> get props => [title, subtitle, themeColor];
}

/// Visualization metadata for charts
class VisualizationMeta extends Equatable {
  final int deltaPercentage;
  final String comparisonText;

  const VisualizationMeta({
    required this.deltaPercentage,
    required this.comparisonText,
  });

  factory VisualizationMeta.fromJson(Map<String, dynamic> json) {
    return VisualizationMeta(
      deltaPercentage: json['delta_percentage'] as int,
      comparisonText: json['comparison_text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'delta_percentage': deltaPercentage,
    'comparison_text': comparisonText,
  };

  @override
  List<Object?> get props => [deltaPercentage, comparisonText];
}

/// Theme color enum for dynamic UI coloring
enum ThemeColor {
  green, // Growth: current > baseline + 5
  blue, // Maintenance: current ≈ baseline
  amber; // Needs Focus: current < baseline - 10

  static ThemeColor fromString(String value) {
    switch (value.toUpperCase()) {
      case 'GREEN':
        return ThemeColor.green;
      case 'AMBER':
        return ThemeColor.amber;
      case 'BLUE':
      default:
        return ThemeColor.blue;
    }
  }
}
