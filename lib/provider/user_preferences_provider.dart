import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/settings/color_scheme_picker_dialog.dart';
import 'package:spotube/models/source_match.dart';
import 'package:spotube/provider/palette_provider.dart';
import 'package:spotube/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/services/sourced_track/enums.dart';

import 'package:spotube/utils/persisted_change_notifier.dart';
import 'package:spotube/utils/platform.dart';
import 'package:path/path.dart' as path;

enum LayoutMode {
  compact,
  extended,
  adaptive,
}

enum CloseBehavior {
  minimizeToTray,
  close,
}

enum AudioSource {
  youtube,
  piped,
  jiosaavn;

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum SearchMode {
  youtube,
  youtubeMusic;

  String get label => name[0].toUpperCase() + name.substring(1);

  static SearchMode fromString(String? string) {
    switch (string) {
      case "youtube":
        return SearchMode.youtube;
      case "youtubeMusic":
        return SearchMode.youtubeMusic;
      default:
        return SearchMode.youtube;
    }
  }

  toSourceType() {
    switch (this) {
      case SearchMode.youtube:
        return SourceType.youtube;
      case SearchMode.youtubeMusic:
        return SourceType.youtubeMusic;
    }
  }
}

class UserPreferences extends PersistedChangeNotifier {
  SourceQualities audioQuality;
  bool albumColorSync;
  bool amoledDarkTheme;
  bool checkUpdate;
  bool normalizeAudio;
  bool showSystemTrayIcon;
  bool skipNonMusic;
  bool systemTitleBar;
  CloseBehavior closeBehavior;
  late SpotubeColor accentColorScheme;
  LayoutMode layoutMode;
  Locale locale;
  Market recommendationMarket;
  SearchMode searchMode;
  String downloadLocation;
  String pipedInstance;
  ThemeMode themeMode;
  AudioSource audioSource;
  SourceCodecs streamMusicCodec;
  SourceCodecs downloadMusicCodec;

  final Ref ref;

  UserPreferences(
    this.ref, {
    this.recommendationMarket = Market.US,
    this.themeMode = ThemeMode.system,
    this.layoutMode = LayoutMode.adaptive,
    this.albumColorSync = true,
    this.checkUpdate = true,
    this.audioQuality = SourceQualities.high,
    this.downloadLocation = "",
    this.closeBehavior = CloseBehavior.close,
    this.showSystemTrayIcon = true,
    this.locale = const Locale("system", "system"),
    this.pipedInstance = "https://pipedapi.kavin.rocks",
    this.searchMode = SearchMode.youtube,
    this.skipNonMusic = true,
    this.audioSource = AudioSource.youtube,
    this.systemTitleBar = false,
    this.amoledDarkTheme = false,
    this.normalizeAudio = true,
    this.streamMusicCodec = SourceCodecs.weba,
    this.downloadMusicCodec = SourceCodecs.m4a,
    SpotubeColor? accentColorScheme,
  }) : super() {
    this.accentColorScheme =
        accentColorScheme ?? SpotubeColor(Colors.blue.value, name: "Blue");
    if (downloadLocation.isEmpty && !kIsWeb) {
      _getDefaultDownloadDirectory().then(
        (value) {
          downloadLocation = value;
        },
      );
    }
  }

  void reset() {
    setRecommendationMarket(Market.US);
    setThemeMode(ThemeMode.system);
    setLayoutMode(LayoutMode.adaptive);
    setAlbumColorSync(true);
    setCheckUpdate(true);
    setAudioQuality(SourceQualities.high);
    setDownloadLocation("");
    setCloseBehavior(CloseBehavior.close);
    setShowSystemTrayIcon(true);
    setLocale(const Locale("system", "system"));
    setPipedInstance("https://pipedapi.kavin.rocks");
    setSearchMode(SearchMode.youtube);
    setSkipNonMusic(true);
    setAudioSource(AudioSource.youtube);
    setSystemTitleBar(false);
    setAmoledDarkTheme(false);
    setNormalizeAudio(true);
    setAccentColorScheme(SpotubeColor(Colors.blue.value, name: "Blue"));
    setStreamMusicCodec(SourceCodecs.weba);
    setDownloadMusicCodec(SourceCodecs.m4a);
  }

  void setStreamMusicCodec(SourceCodecs codec) {
    streamMusicCodec = codec;
    notifyListeners();
    updatePersistence();
  }

  void setDownloadMusicCodec(SourceCodecs codec) {
    downloadMusicCodec = codec;
    notifyListeners();
    updatePersistence();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    updatePersistence();
  }

  void setRecommendationMarket(Market country) {
    recommendationMarket = country;
    notifyListeners();
    updatePersistence();
  }

  void setAccentColorScheme(SpotubeColor color) {
    accentColorScheme = color;
    notifyListeners();
    updatePersistence();
  }

  void setAlbumColorSync(bool sync) {
    albumColorSync = sync;
    if (!sync) {
      ref.read(paletteProvider.notifier).state = null;
    } else {
      ref.read(ProxyPlaylistNotifier.notifier).updatePalette();
    }
    notifyListeners();
    updatePersistence();
  }

  void setCheckUpdate(bool check) {
    checkUpdate = check;
    notifyListeners();
    updatePersistence();
  }

  void setAudioQuality(SourceQualities quality) {
    audioQuality = quality;
    notifyListeners();
    updatePersistence();
  }

  void setDownloadLocation(String downloadDir) {
    if (downloadDir.isEmpty) return;
    downloadLocation = downloadDir;
    notifyListeners();
    updatePersistence();
  }

  void setLayoutMode(LayoutMode mode) {
    layoutMode = mode;
    notifyListeners();
    updatePersistence();
  }

  void setCloseBehavior(CloseBehavior behavior) {
    closeBehavior = behavior;
    notifyListeners();
    updatePersistence();
  }

  void setShowSystemTrayIcon(bool show) {
    showSystemTrayIcon = show;
    notifyListeners();
    updatePersistence();
  }

  void setLocale(Locale locale) {
    this.locale = locale;
    notifyListeners();
    updatePersistence();
  }

  void setPipedInstance(String instance) {
    pipedInstance = instance;
    notifyListeners();
    updatePersistence();
  }

  void setSearchMode(SearchMode mode) {
    searchMode = mode;
    notifyListeners();
    updatePersistence();
  }

  void setSkipNonMusic(bool skip) {
    skipNonMusic = skip;
    notifyListeners();
    updatePersistence();
  }

  void setAudioSource(AudioSource type) {
    audioSource = type;
    notifyListeners();
    updatePersistence();
  }

  void setSystemTitleBar(bool isSystemTitleBar) {
    systemTitleBar = isSystemTitleBar;
    if (DesktopTools.platform.isDesktop) {
      DesktopTools.window.setTitleBarStyle(
        systemTitleBar ? TitleBarStyle.normal : TitleBarStyle.hidden,
      );
    }
    notifyListeners();
    updatePersistence();
  }

  void setAmoledDarkTheme(bool isAmoled) {
    amoledDarkTheme = isAmoled;
    notifyListeners();
    updatePersistence();
  }

  void setNormalizeAudio(bool normalize) {
    normalizeAudio = normalize;
    audioPlayer.setAudioNormalization(normalize);
    notifyListeners();
    updatePersistence();
  }

  Future<String> _getDefaultDownloadDirectory() async {
    if (kIsAndroid) return "/storage/emulated/0/Download/Spotube";

    if (kIsMacOS) {
      return path.join((await getLibraryDirectory()).path, "Caches");
    }

    return getDownloadsDirectory().then((dir) {
      return path.join(dir!.path, "Spotube");
    });
  }

  @override
  FutureOr<void> loadFromLocal(Map<String, dynamic> map) async {
    recommendationMarket = Market.values.firstWhere(
      (market) =>
          market.name == (map["recommendationMarket"] ?? recommendationMarket),
      orElse: () => Market.US,
    );
    checkUpdate = map["checkUpdate"] ?? checkUpdate;

    themeMode = ThemeMode.values[map["themeMode"] ?? 0];
    accentColorScheme = map["accentColorScheme"] != null
        ? SpotubeColor.fromString(map["accentColorScheme"])
        : accentColorScheme;
    albumColorSync = map["albumColorSync"] ?? albumColorSync;
    audioQuality = map["audioQuality"] != null
        ? SourceQualities.values[map["audioQuality"]]
        : audioQuality;

    if (!kIsWeb) {
      downloadLocation =
          map["downloadLocation"] ?? await _getDefaultDownloadDirectory();
    }

    layoutMode = LayoutMode.values.firstWhere(
      (mode) => mode.name == map["layoutMode"],
      orElse: () => kIsDesktop ? LayoutMode.extended : LayoutMode.compact,
    );

    closeBehavior = map["closeBehavior"] != null
        ? CloseBehavior.values[map["closeBehavior"]]
        : closeBehavior;

    showSystemTrayIcon = map["showSystemTrayIcon"] ?? showSystemTrayIcon;

    final localeMap = map["locale"] != null ? jsonDecode(map["locale"]) : null;
    locale =
        localeMap != null ? Locale(localeMap?["lc"], localeMap?["cc"]) : locale;

    pipedInstance = map["pipedInstance"] ?? pipedInstance;

    searchMode = SearchMode.values.firstWhere(
      (mode) => mode.name == map["searchMode"],
      orElse: () => SearchMode.youtube,
    );

    skipNonMusic = map["skipNonMusic"] ?? skipNonMusic;

    audioSource = AudioSource.values.firstWhere(
      (type) => type.name == map["youtubeApiType"],
      orElse: () => AudioSource.youtube,
    );

    systemTitleBar = map["systemTitleBar"] ?? systemTitleBar;
    // updates the title bar
    setSystemTitleBar(systemTitleBar);

    amoledDarkTheme = map["amoledDarkTheme"] ?? amoledDarkTheme;

    normalizeAudio = map["normalizeAudio"] ?? normalizeAudio;
    audioPlayer.setAudioNormalization(normalizeAudio);

    streamMusicCodec = SourceCodecs.values.firstWhere(
      (codec) => codec.name == map["streamMusicCodec"],
      orElse: () => SourceCodecs.weba,
    );

    downloadMusicCodec = SourceCodecs.values.firstWhere(
      (codec) => codec.name == map["downloadMusicCodec"],
      orElse: () => SourceCodecs.m4a,
    );
  }

  @override
  FutureOr<Map<String, dynamic>> toMap() {
    return {
      "recommendationMarket": recommendationMarket.name,
      "themeMode": themeMode.index,
      "accentColorScheme": accentColorScheme.toString(),
      "albumColorSync": albumColorSync,
      "checkUpdate": checkUpdate,
      "audioQuality": audioQuality.index,
      "downloadLocation": downloadLocation,
      "layoutMode": layoutMode.name,
      "closeBehavior": closeBehavior.index,
      "showSystemTrayIcon": showSystemTrayIcon,
      "locale":
          jsonEncode({"lc": locale.languageCode, "cc": locale.countryCode}),
      "pipedInstance": pipedInstance,
      "searchMode": searchMode.name,
      "skipNonMusic": skipNonMusic,
      "youtubeApiType": audioSource.name,
      'systemTitleBar': systemTitleBar,
      "amoledDarkTheme": amoledDarkTheme,
      "normalizeAudio": normalizeAudio,
      "streamMusicCodec": streamMusicCodec.name,
      "downloadMusicCodec": downloadMusicCodec.name,
    };
  }

  UserPreferences copyWith({
    ThemeMode? themeMode,
    SpotubeColor? accentColorScheme,
    bool? albumColorSync,
    bool? checkUpdate,
    SourceQualities? audioQuality,
    String? downloadLocation,
    LayoutMode? layoutMode,
    CloseBehavior? closeBehavior,
    bool? showSystemTrayIcon,
    Locale? locale,
    String? pipedInstance,
    SearchMode? searchMode,
    bool? skipNonMusic,
    AudioSource? youtubeApiType,
    Market? recommendationMarket,
    bool? saveTrackLyrics,
  }) {
    return UserPreferences(
      ref,
      themeMode: themeMode ?? this.themeMode,
      accentColorScheme: accentColorScheme ?? this.accentColorScheme,
      albumColorSync: albumColorSync ?? this.albumColorSync,
      checkUpdate: checkUpdate ?? this.checkUpdate,
      audioQuality: audioQuality ?? this.audioQuality,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      layoutMode: layoutMode ?? this.layoutMode,
      closeBehavior: closeBehavior ?? this.closeBehavior,
      showSystemTrayIcon: showSystemTrayIcon ?? this.showSystemTrayIcon,
      locale: locale ?? this.locale,
      pipedInstance: pipedInstance ?? this.pipedInstance,
      searchMode: searchMode ?? this.searchMode,
      skipNonMusic: skipNonMusic ?? this.skipNonMusic,
      audioSource: youtubeApiType ?? this.audioSource,
      recommendationMarket: recommendationMarket ?? this.recommendationMarket,
    );
  }
}

final userPreferencesProvider = ChangeNotifierProvider(
  (ref) => UserPreferences(ref),
);
