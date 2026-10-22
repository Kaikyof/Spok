import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import 'redmine_status_names.dart';

/// Палитра статусов Redmine по их именам — знание адаптера, а не ядра:
/// красит только ярлык трекера рядом со стадией. Цвет точки стадии даёт
/// `AppColors.forStage`, и он один для любой спеки.
Color redmineStatusColor(String status) => switch (status) {
  RedmineStatusNames.newIssue => AppColors.statusNew,
  RedmineStatusNames.inProgress => AppColors.statusInProgress,
  RedmineStatusNames.inReview => AppColors.statusInReview,
  RedmineStatusNames.reviewDone => AppColors.statusReviewDone,
  RedmineStatusNames.waitingTest => AppColors.statusWaitingTest,
  RedmineStatusNames.testing => AppColors.statusTesting,
  RedmineStatusNames.readyToRelease => AppColors.statusReadyToRelease,
  RedmineStatusNames.returnedFromReview || RedmineStatusNames.returned => AppColors.statusReturned,
  _ => AppColors.statusNew,
};
