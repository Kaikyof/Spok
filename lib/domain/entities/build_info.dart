class BuildInfo {
  final String versionName;
  final String? channel; // TestFlight / QA APK в Nextcloud
  final DateTime? publishedAt;

  const BuildInfo({required this.versionName, this.channel, this.publishedAt});
}
