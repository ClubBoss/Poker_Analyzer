# Changelog

## [Unreleased]
- Add DecayHeatmapUISurface widget for visualizing memory decay.
- Remind to resume stale user goals via GoalReengagementBanner on main menu.
- Add DecayHeatmapScreen to review tag decay as a heatmap.
- Fix training resume dialog to load packs before showing confirmation.
- Remove unused spot storage field from app state.
- Add "Select All" toggle in the My Packs selection toolbar.
- Export Markdown summary from pack template preview.
- Add Import Starter Packs button to Template Library.
- Suggest next built-in pack from the same category when one is completed.
- Add hand analysis history with EV/ICM stats and filters.
- Track XP goal streaks via new GoalStreakTrackerService.
- Introduce XPLevelEngine for computing user level progression.
- Add TheoryPackPreviewScreen for theory-only training packs.
- Track consecutive days of theory reinforcement via TheoryStreakService.
- Expose recordToday method on TheoryStreakService and update MiniLessonScreen.
- Introduce TheoryBoosterSuggestionEngine for recommending lessons when recap tags underperform.
- Add TheoryReinforcementBannerController for soft theory reminders after recap failures.
- Persist full decay reinforcement history and expose TagDecayForecastService for spaced repetition analytics.
- Add DecayForecastEngine to predict future decay levels by tag.
- Introduce DecayForecastAlertService for upcoming critical decay warnings.
- Add DecayDashboardScreen to visualize memory health.
- Track days without critical decay via DecayStreakTrackerService.
- Show humanized goal labels on pack cards for quick tactical focus.

- Celebrate decay streak milestones with DecayMilestoneCelebrationService.
- Display theory cluster completion summary in TheoryPackPreviewScreen.
