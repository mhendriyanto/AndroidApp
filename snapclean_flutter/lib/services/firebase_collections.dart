class FirebaseCollections {
  static const users = 'users';
  static const usernames = 'usernames';
  static const screenshots = 'screenshots';
  static const folders = 'folders';
  static const settings = 'settings';
  static const timerPresets = 'timerPresets';
  static const activity = 'activity';

  static const appSettingsDocument = 'app';
}

class FirestorePaths {
  static String username(String username) =>
      '${FirebaseCollections.usernames}/$username';

  static String user(String uid) => '${FirebaseCollections.users}/$uid';

  static String screenshots(String uid) =>
      '${user(uid)}/${FirebaseCollections.screenshots}';

  static String screenshot(String uid, String screenshotId) =>
      '${screenshots(uid)}/$screenshotId';

  static String folders(String uid) =>
      '${user(uid)}/${FirebaseCollections.folders}';

  static String folder(String uid, String folderId) =>
      '${folders(uid)}/$folderId';

  static String settings(String uid) =>
      '${user(uid)}/${FirebaseCollections.settings}';

  static String appSettings(String uid) =>
      '${settings(uid)}/${FirebaseCollections.appSettingsDocument}';

  static String timerPresets(String uid) =>
      '${user(uid)}/${FirebaseCollections.timerPresets}';

  static String timerPreset(String uid, String presetId) =>
      '${timerPresets(uid)}/$presetId';

  static String activity(String uid) =>
      '${user(uid)}/${FirebaseCollections.activity}';

  static String activityEvent(String uid, String eventId) =>
      '${activity(uid)}/$eventId';
}
