# Changelog

## [Unreleased]
- Fix training resume dialog to load packs before showing confirmation.
- Remove unused spot storage field from app state.
- Add "Select All" toggle in the My Packs selection toolbar.
- Export Markdown summary from pack template preview.
- Add Import Starter Packs button to Template Library.
- Suggest next built-in pack from the same category when one is completed.
- Add hand analysis history with EV/ICM stats and filters.
- Introduce XPLevelEngine for computing user level progression.
- Add TheoryPackPreviewScreen for theory-only training packs.
- Track consecutive days of theory reinforcement via TheoryStreakService.
- Expose recordToday method on TheoryStreakService and update MiniLessonScreen.
- Introduce TheoryBoosterSuggestionEngine for recommending lessons when recap tags underperform.
- Add TheoryReinforcementBannerController for soft theory reminders after recap failures.
