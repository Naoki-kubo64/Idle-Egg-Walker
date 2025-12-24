import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'Egg Walker'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @soundSettings.
  ///
  /// In ja, this message translates to:
  /// **'サウンド設定'**
  String get soundSettings;

  /// No description provided for @bgmVolume.
  ///
  /// In ja, this message translates to:
  /// **'BGM音量'**
  String get bgmVolume;

  /// No description provided for @seVolume.
  ///
  /// In ja, this message translates to:
  /// **'SE音量'**
  String get seVolume;

  /// No description provided for @tapPower.
  ///
  /// In ja, this message translates to:
  /// **'タップ力'**
  String get tapPower;

  /// No description provided for @atkPower.
  ///
  /// In ja, this message translates to:
  /// **'攻撃力'**
  String get atkPower;

  /// No description provided for @gold.
  ///
  /// In ja, this message translates to:
  /// **'所持金'**
  String get gold;

  /// No description provided for @eps.
  ///
  /// In ja, this message translates to:
  /// **'秒間EXP'**
  String get eps;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In ja, this message translates to:
  /// **'おかえりなさい！'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackMessage.
  ///
  /// In ja, this message translates to:
  /// **'留守のあいだに...'**
  String get welcomeBackMessage;

  /// No description provided for @welcomeBackGained.
  ///
  /// In ja, this message translates to:
  /// **'を獲得しました！'**
  String get welcomeBackGained;

  /// No description provided for @offlineReward.
  ///
  /// In ja, this message translates to:
  /// **'冒険の成果'**
  String get offlineReward;

  /// No description provided for @steps.
  ///
  /// In ja, this message translates to:
  /// **'歩数'**
  String get steps;

  /// No description provided for @stepsWalked.
  ///
  /// In ja, this message translates to:
  /// **'歩いた歩数'**
  String get stepsWalked;

  /// No description provided for @exp.
  ///
  /// In ja, this message translates to:
  /// **'経験値'**
  String get exp;

  /// No description provided for @expGained.
  ///
  /// In ja, this message translates to:
  /// **'獲得経験値'**
  String get expGained;

  /// No description provided for @shop.
  ///
  /// In ja, this message translates to:
  /// **'ショップ'**
  String get shop;

  /// No description provided for @collectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'モンスター図鑑'**
  String get collectionTitle;

  /// No description provided for @completionRate.
  ///
  /// In ja, this message translates to:
  /// **'コンプリート率'**
  String get completionRate;

  /// No description provided for @upgradeHeader.
  ///
  /// In ja, this message translates to:
  /// **'アップグレード'**
  String get upgradeHeader;

  /// No description provided for @upgradeAttack.
  ///
  /// In ja, this message translates to:
  /// **'おともだち攻撃力'**
  String get upgradeAttack;

  /// No description provided for @upgradeTap.
  ///
  /// In ja, this message translates to:
  /// **'タップ効率強化'**
  String get upgradeTap;

  /// No description provided for @upgradeStep.
  ///
  /// In ja, this message translates to:
  /// **'歩数ブースト'**
  String get upgradeStep;

  /// No description provided for @collection.
  ///
  /// In ja, this message translates to:
  /// **'図鑑'**
  String get collection;

  /// No description provided for @upgrade.
  ///
  /// In ja, this message translates to:
  /// **'強化'**
  String get upgrade;

  /// No description provided for @rare.
  ///
  /// In ja, this message translates to:
  /// **'レア'**
  String get rare;

  /// No description provided for @superRare.
  ///
  /// In ja, this message translates to:
  /// **'スーパーレア'**
  String get superRare;

  /// No description provided for @ultraRare.
  ///
  /// In ja, this message translates to:
  /// **'ウルトラレア'**
  String get ultraRare;

  /// No description provided for @legend.
  ///
  /// In ja, this message translates to:
  /// **'レジェンド'**
  String get legend;

  /// No description provided for @egg.
  ///
  /// In ja, this message translates to:
  /// **'卵'**
  String get egg;

  /// No description provided for @baby.
  ///
  /// In ja, this message translates to:
  /// **'幼体'**
  String get baby;

  /// No description provided for @teen.
  ///
  /// In ja, this message translates to:
  /// **'成長体'**
  String get teen;

  /// No description provided for @adult.
  ///
  /// In ja, this message translates to:
  /// **'成体'**
  String get adult;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
