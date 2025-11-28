import 'package:equatable/equatable.dart';
import '../../../data/models/help_model.dart';

class HelpState extends Equatable {
  final bool isLoading;
  final bool offlineMode;
  final bool fromCache;
  final List<FaqItem> faqs;
  final List<TutorialItem> tutorials;
  final String? error;

  const HelpState({
    this.isLoading = false,
    this.offlineMode = false,
    this.fromCache = false,
    this.faqs = const [],
    this.tutorials = const [],
    this.error,
  });

  HelpState copyWith({
    bool? isLoading,
    bool? offlineMode,
    bool? fromCache,
    List<FaqItem>? faqs,
    List<TutorialItem>? tutorials,
    String? error,
  }) {
    return HelpState(
      isLoading: isLoading ?? this.isLoading,
      offlineMode: offlineMode ?? this.offlineMode,
      fromCache: fromCache ?? this.fromCache,
      faqs: faqs ?? this.faqs,
      tutorials: tutorials ?? this.tutorials,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, offlineMode, fromCache, faqs, tutorials, error];
}
