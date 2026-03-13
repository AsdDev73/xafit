import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import 'notification_service.dart';

class ProgressOverview {
  final List<BodyProgressEntry> entries;
  final BodyProfile profile;
  final WeeklyReminderSettings reminderSettings;

  const ProgressOverview({
    required this.entries,
    required this.profile,
    required this.reminderSettings,
  });

  const ProgressOverview.empty()
    : entries = const [],
      profile = BodyProfile.empty,
      reminderSettings = const WeeklyReminderSettings.defaultValue();
}

class ProgressService {
  final BodyProfileRepository bodyProfileRepository;
  final BodyProgressRepository bodyProgressRepository;

  const ProgressService({
    required this.bodyProfileRepository,
    required this.bodyProgressRepository,
  });

  Future<ProgressOverview> loadOverview() async {
    final entries = await bodyProgressRepository.getEntries();
    final profile = await bodyProfileRepository.getProfile();
    final reminderSettings =
        await NotificationService.loadWeeklyReminderSettings();

    return ProgressOverview(
      entries: entries,
      profile: profile,
      reminderSettings: reminderSettings,
    );
  }

  Future<void> saveProfile(BodyProfile profile) async {
    await bodyProfileRepository.saveProfile(profile);
  }

  Future<void> saveEntry(BodyProgressEntry entry) async {
    await bodyProgressRepository.saveEntry(entry);
  }

  Future<void> deleteEntry(String entryId) async {
    await bodyProgressRepository.deleteEntry(entryId);
  }

  Future<void> clearAllEntries() async {
    await bodyProgressRepository.clearAllEntries();
  }
}
