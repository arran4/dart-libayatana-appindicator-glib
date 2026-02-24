/// The category of the indicator.
enum AppIndicatorCategory {
  applicationStatus,
  communications,
  systemServices,
  hardware,
  other,
}

/// The status of the indicator.
enum AppIndicatorStatus {
  passive,
  active,
  attention,
}

extension AppIndicatorCategoryExtension on AppIndicatorCategory {
  String get name {
    switch (this) {
      case AppIndicatorCategory.applicationStatus: return 'ApplicationStatus';
      case AppIndicatorCategory.communications: return 'Communications';
      case AppIndicatorCategory.systemServices: return 'SystemServices';
      case AppIndicatorCategory.hardware: return 'Hardware';
      case AppIndicatorCategory.other: return 'Other';
    }
  }
}

extension AppIndicatorStatusExtension on AppIndicatorStatus {
  String get name {
    switch (this) {
      case AppIndicatorStatus.passive: return 'Passive';
      case AppIndicatorStatus.active: return 'Active';
      case AppIndicatorStatus.attention: return 'Attention';
    }
  }
}
