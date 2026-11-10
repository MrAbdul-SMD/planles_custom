import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('nl'),
  ];

  /// No description provided for @retry.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw proberen'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In nl, this message translates to:
  /// **'Bevestigen'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get save;

  /// No description provided for @close.
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get close;

  /// No description provided for @back.
  ///
  /// In nl, this message translates to:
  /// **'Terug'**
  String get back;

  /// No description provided for @next.
  ///
  /// In nl, this message translates to:
  /// **'Volgende'**
  String get next;

  /// No description provided for @delete.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In nl, this message translates to:
  /// **'Bewerken'**
  String get edit;

  /// No description provided for @genericSuccess.
  ///
  /// In nl, this message translates to:
  /// **'Gelukt'**
  String get genericSuccess;

  /// No description provided for @noName.
  ///
  /// In nl, this message translates to:
  /// **'Geen naam'**
  String get noName;

  /// No description provided for @today.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In nl, this message translates to:
  /// **'Morgen'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In nl, this message translates to:
  /// **'Gisteren'**
  String get yesterday;

  /// Duration in minutes, e.g. '45 min'
  ///
  /// In nl, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// Duration in whole hours, e.g. '2 uur'
  ///
  /// In nl, this message translates to:
  /// **'{count} uur'**
  String hoursShort(int count);

  /// Duration in hours and minutes, e.g. '1 uur 30 min'
  ///
  /// In nl, this message translates to:
  /// **'{hours} uur {minutes} min'**
  String hoursMinutesShort(int hours, int minutes);

  /// No description provided for @navHome.
  ///
  /// In nl, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPlanning.
  ///
  /// In nl, this message translates to:
  /// **'Planning'**
  String get navPlanning;

  /// No description provided for @navOrders.
  ///
  /// In nl, this message translates to:
  /// **'Bestellingen'**
  String get navOrders;

  /// No description provided for @navNotifications.
  ///
  /// In nl, this message translates to:
  /// **'Meldingen'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In nl, this message translates to:
  /// **'Profiel'**
  String get navProfile;

  /// No description provided for @statusConfirmed.
  ///
  /// In nl, this message translates to:
  /// **'Bevestigd'**
  String get statusConfirmed;

  /// No description provided for @statusCompleted.
  ///
  /// In nl, this message translates to:
  /// **'Afgerond'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In nl, this message translates to:
  /// **'Geannuleerd'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In nl, this message translates to:
  /// **'In afwachting'**
  String get statusPending;

  /// No description provided for @errTimeout.
  ///
  /// In nl, this message translates to:
  /// **'De verbinding met de server duurde te lang. Probeer het opnieuw.'**
  String get errTimeout;

  /// No description provided for @errOffline.
  ///
  /// In nl, this message translates to:
  /// **'Geen verbinding met de server. Controleer je internetverbinding.'**
  String get errOffline;

  /// No description provided for @errCancelled.
  ///
  /// In nl, this message translates to:
  /// **'Aanvraag geannuleerd.'**
  String get errCancelled;

  /// No description provided for @errInsecure.
  ///
  /// In nl, this message translates to:
  /// **'Onveilige verbinding met de server.'**
  String get errInsecure;

  /// No description provided for @errGeneric.
  ///
  /// In nl, this message translates to:
  /// **'Er is iets misgegaan. Probeer het opnieuw.'**
  String get errGeneric;

  /// No description provided for @errTooManyRequests.
  ///
  /// In nl, this message translates to:
  /// **'Te veel aanvragen. Wacht even en probeer het opnieuw.'**
  String get errTooManyRequests;

  /// No description provided for @errInvalidData.
  ///
  /// In nl, this message translates to:
  /// **'De ingevulde gegevens zijn ongeldig.'**
  String get errInvalidData;

  /// No description provided for @errSessionExpired.
  ///
  /// In nl, this message translates to:
  /// **'Je sessie is verlopen. Log opnieuw in.'**
  String get errSessionExpired;

  /// No description provided for @errForbidden.
  ///
  /// In nl, this message translates to:
  /// **'Je hebt geen toegang tot deze actie.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In nl, this message translates to:
  /// **'Dit item is niet gevonden.'**
  String get errNotFound;

  /// No description provided for @errEmailTaken.
  ///
  /// In nl, this message translates to:
  /// **'Er bestaat al een account met dit e-mailadres.'**
  String get errEmailTaken;

  /// No description provided for @errServer.
  ///
  /// In nl, this message translates to:
  /// **'Er is iets misgegaan op de server. Probeer het later opnieuw.'**
  String get errServer;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In nl, this message translates to:
  /// **'Inloggen is mislukt. Probeer het opnieuw.'**
  String get errInvalidCredentials;

  /// No description provided for @errUserNotFound.
  ///
  /// In nl, this message translates to:
  /// **'Gebruiker niet gevonden.'**
  String get errUserNotFound;

  /// No description provided for @errOrderNotFound.
  ///
  /// In nl, this message translates to:
  /// **'Bestelling niet gevonden.'**
  String get errOrderNotFound;

  /// No description provided for @errLessonNotFound.
  ///
  /// In nl, this message translates to:
  /// **'Les niet gevonden.'**
  String get errLessonNotFound;

  /// No description provided for @errPaymentFailed.
  ///
  /// In nl, this message translates to:
  /// **'Het openen van de betaling is mislukt.'**
  String get errPaymentFailed;

  /// No description provided for @errEmptyInvoice.
  ///
  /// In nl, this message translates to:
  /// **'De factuur is leeg.'**
  String get errEmptyInvoice;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In nl, this message translates to:
  /// **'Goedemorgen'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In nl, this message translates to:
  /// **'Goedemiddag'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In nl, this message translates to:
  /// **'Goedenavond'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardHello.
  ///
  /// In nl, this message translates to:
  /// **'Hallo'**
  String get dashboardHello;

  /// No description provided for @dashboardUpcomingLessons.
  ///
  /// In nl, this message translates to:
  /// **'Eerstvolgende lessen'**
  String get dashboardUpcomingLessons;

  /// No description provided for @dashboardViewAll.
  ///
  /// In nl, this message translates to:
  /// **'Alles bekijken'**
  String get dashboardViewAll;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In nl, this message translates to:
  /// **'Snel regelen'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardBuyLessons.
  ///
  /// In nl, this message translates to:
  /// **'Lessen kopen'**
  String get dashboardBuyLessons;

  /// No description provided for @dashboardTopUpBalance.
  ///
  /// In nl, this message translates to:
  /// **'Saldo opwaarderen'**
  String get dashboardTopUpBalance;

  /// No description provided for @dashboardRecentNotifications.
  ///
  /// In nl, this message translates to:
  /// **'Recente meldingen'**
  String get dashboardRecentNotifications;

  /// No description provided for @dashboardAllNotifications.
  ///
  /// In nl, this message translates to:
  /// **'Alle meldingen'**
  String get dashboardAllNotifications;

  /// No description provided for @dashboardNotificationFallback.
  ///
  /// In nl, this message translates to:
  /// **'Melding'**
  String get dashboardNotificationFallback;

  /// No description provided for @dashboardBalanceLabel.
  ///
  /// In nl, this message translates to:
  /// **'Saldo'**
  String get dashboardBalanceLabel;

  /// No description provided for @dashboardNoLessonsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen lessen gepland'**
  String get dashboardNoLessonsTitle;

  /// No description provided for @dashboardNoLessonsSubtitle.
  ///
  /// In nl, this message translates to:
  /// **'Koop een lespakket om je eerste les in te plannen.'**
  String get dashboardNoLessonsSubtitle;

  /// No description provided for @dashboardLessonFallback.
  ///
  /// In nl, this message translates to:
  /// **'Les'**
  String get dashboardLessonFallback;

  /// No description provided for @studentsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Mijn leerlingen'**
  String get studentsTitle;

  /// No description provided for @studentsSearchHint.
  ///
  /// In nl, this message translates to:
  /// **'Zoek leerling'**
  String get studentsSearchHint;

  /// No description provided for @studentsEmptyTitle.
  ///
  /// In nl, this message translates to:
  /// **'Geen leerlingen'**
  String get studentsEmptyTitle;

  /// No description provided for @studentsEmptySubtitle.
  ///
  /// In nl, this message translates to:
  /// **'Er zijn nog geen leerlingen aan je gekoppeld.'**
  String get studentsEmptySubtitle;

  /// No description provided for @studentsEmailLabel.
  ///
  /// In nl, this message translates to:
  /// **'E-mail'**
  String get studentsEmailLabel;

  /// No description provided for @studentsPhoneLabel.
  ///
  /// In nl, this message translates to:
  /// **'Telefoon'**
  String get studentsPhoneLabel;

  /// No description provided for @studentsAddressLabel.
  ///
  /// In nl, this message translates to:
  /// **'Adres'**
  String get studentsAddressLabel;

  /// No description provided for @studentsPickupLabel.
  ///
  /// In nl, this message translates to:
  /// **'Ophaallocatie'**
  String get studentsPickupLabel;

  /// No description provided for @loginTitle.
  ///
  /// In nl, this message translates to:
  /// **'Welkom terug'**
  String get loginTitle;

  /// Subtitle under the login screen heading
  ///
  /// In nl, this message translates to:
  /// **'Log in om je lessen te beheren'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres'**
  String get loginEmailLabel;

  /// Validator + snack shown when the email field is empty
  ///
  /// In nl, this message translates to:
  /// **'Vul je e-mailadres in'**
  String get loginEmailRequired;

  /// Validator for an email address without @
  ///
  /// In nl, this message translates to:
  /// **'Vul een geldig e-mailadres in'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In nl, this message translates to:
  /// **'Vul je wachtwoord in'**
  String get loginPasswordRequired;

  /// Link from the login screen to the reset flow
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord vergeten?'**
  String get loginForgotPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In nl, this message translates to:
  /// **'Inloggen'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In nl, this message translates to:
  /// **'Registreren'**
  String get loginRegister;

  /// No description provided for @registerTitle.
  ///
  /// In nl, this message translates to:
  /// **'Registreren'**
  String get registerTitle;

  /// No description provided for @registerAccountType.
  ///
  /// In nl, this message translates to:
  /// **'Accounttype'**
  String get registerAccountType;

  /// No description provided for @registerStudent.
  ///
  /// In nl, this message translates to:
  /// **'Leerling'**
  String get registerStudent;

  /// No description provided for @registerInstructor.
  ///
  /// In nl, this message translates to:
  /// **'Instructeur'**
  String get registerInstructor;

  /// No description provided for @registerPersonalDetails.
  ///
  /// In nl, this message translates to:
  /// **'Persoonlijke gegevens'**
  String get registerPersonalDetails;

  /// No description provided for @registerFirstName.
  ///
  /// In nl, this message translates to:
  /// **'Voornaam'**
  String get registerFirstName;

  /// No description provided for @registerLastName.
  ///
  /// In nl, this message translates to:
  /// **'Achternaam'**
  String get registerLastName;

  /// No description provided for @registerPhone.
  ///
  /// In nl, this message translates to:
  /// **'Telefoonnummer'**
  String get registerPhone;

  /// No description provided for @registerBirthdate.
  ///
  /// In nl, this message translates to:
  /// **'Geboortedatum'**
  String get registerBirthdate;

  /// No description provided for @registerBirthdateHint.
  ///
  /// In nl, this message translates to:
  /// **'jjjj-mm-dd'**
  String get registerBirthdateHint;

  /// No description provided for @registerAddress.
  ///
  /// In nl, this message translates to:
  /// **'Adres'**
  String get registerAddress;

  /// No description provided for @registerStreet.
  ///
  /// In nl, this message translates to:
  /// **'Straat'**
  String get registerStreet;

  /// No description provided for @registerHouseNumber.
  ///
  /// In nl, this message translates to:
  /// **'Huisnr.'**
  String get registerHouseNumber;

  /// No description provided for @registerZipCode.
  ///
  /// In nl, this message translates to:
  /// **'Postcode'**
  String get registerZipCode;

  /// No description provided for @registerCity.
  ///
  /// In nl, this message translates to:
  /// **'Plaats'**
  String get registerCity;

  /// No description provided for @registerLessonDetails.
  ///
  /// In nl, this message translates to:
  /// **'Lesdetails (optioneel)'**
  String get registerLessonDetails;

  /// No description provided for @registerPickupLocation.
  ///
  /// In nl, this message translates to:
  /// **'Ophaallocatie'**
  String get registerPickupLocation;

  /// No description provided for @registerLicensePlate.
  ///
  /// In nl, this message translates to:
  /// **'Kenteken (bij eigen voertuig)'**
  String get registerLicensePlate;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord'**
  String get registerPasswordLabel;

  /// Helper text under the password fields
  ///
  /// In nl, this message translates to:
  /// **'Minimaal 8 tekens met een kleine letter, hoofdletter en cijfer'**
  String get registerPasswordRules;

  /// No description provided for @registerPasswordMin8.
  ///
  /// In nl, this message translates to:
  /// **'Minimaal 8 tekens'**
  String get registerPasswordMin8;

  /// No description provided for @registerPasswordNeedsMix.
  ///
  /// In nl, this message translates to:
  /// **'Gebruik een kleine letter, hoofdletter en cijfer'**
  String get registerPasswordNeedsMix;

  /// No description provided for @registerPasswordRepeat.
  ///
  /// In nl, this message translates to:
  /// **'Herhaal wachtwoord'**
  String get registerPasswordRepeat;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoorden komen niet overeen'**
  String get registerPasswordMismatch;

  /// No description provided for @registerRequired.
  ///
  /// In nl, this message translates to:
  /// **'Verplicht veld'**
  String get registerRequired;

  /// No description provided for @registerOtpTitle.
  ///
  /// In nl, this message translates to:
  /// **'Bevestigingscode'**
  String get registerOtpTitle;

  /// Shown when the API gives no message after requesting an OTP
  ///
  /// In nl, this message translates to:
  /// **'We hebben een code naar je e-mailadres gestuurd.'**
  String get registerOtpFallback;

  /// No description provided for @registerOtpLabel.
  ///
  /// In nl, this message translates to:
  /// **'Code uit e-mail'**
  String get registerOtpLabel;

  /// No description provided for @registerOtpRequired.
  ///
  /// In nl, this message translates to:
  /// **'Vul de 4-cijferige code in'**
  String get registerOtpRequired;

  /// No description provided for @registerSubmitCreate.
  ///
  /// In nl, this message translates to:
  /// **'Account aanmaken'**
  String get registerSubmitCreate;

  /// No description provided for @registerSubmitCode.
  ///
  /// In nl, this message translates to:
  /// **'Code aanvragen'**
  String get registerSubmitCode;

  /// No description provided for @registerHaveAccount.
  ///
  /// In nl, this message translates to:
  /// **'Ik heb al een account'**
  String get registerHaveAccount;

  /// No description provided for @registerCarImage.
  ///
  /// In nl, this message translates to:
  /// **'Autobeeld'**
  String get registerCarImage;

  /// No description provided for @registerCarImageSelect.
  ///
  /// In nl, this message translates to:
  /// **'Autobeeld selecteren'**
  String get registerCarImageSelect;

  /// No description provided for @forgotTitle.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord vergeten'**
  String get forgotTitle;

  /// No description provided for @forgotEnterCode.
  ///
  /// In nl, this message translates to:
  /// **'Voer de code in'**
  String get forgotEnterCode;

  /// No description provided for @forgotResetTitle.
  ///
  /// In nl, this message translates to:
  /// **'Herstel je wachtwoord'**
  String get forgotResetTitle;

  /// Heading text once a reset code has been sent
  ///
  /// In nl, this message translates to:
  /// **'We hebben een code gestuurd naar {email}.'**
  String forgotCodeSentTo(String email);

  /// No description provided for @forgotEmailHint.
  ///
  /// In nl, this message translates to:
  /// **'Vul je e-mailadres in en we sturen je een herstelcode.'**
  String get forgotEmailHint;

  /// No description provided for @forgotCodeLabel.
  ///
  /// In nl, this message translates to:
  /// **'Herstelcode'**
  String get forgotCodeLabel;

  /// No description provided for @forgotCodeRequired.
  ///
  /// In nl, this message translates to:
  /// **'Vul de code in'**
  String get forgotCodeRequired;

  /// No description provided for @forgotNewPassword.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw wachtwoord (optioneel)'**
  String get forgotNewPassword;

  /// No description provided for @forgotSubmitReset.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord resetten'**
  String get forgotSubmitReset;

  /// No description provided for @forgotSubmitSend.
  ///
  /// In nl, this message translates to:
  /// **'Code versturen'**
  String get forgotSubmitSend;

  /// No description provided for @forgotResend.
  ///
  /// In nl, this message translates to:
  /// **'Code opnieuw versturen'**
  String get forgotResend;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In nl, this message translates to:
  /// **'Terug naar inloggen'**
  String get forgotBackToLogin;

  /// No description provided for @forgotCodeSent.
  ///
  /// In nl, this message translates to:
  /// **'We hebben een code naar je e-mail gestuurd.'**
  String get forgotCodeSent;

  /// No description provided for @forgotPasswordChanged.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord gewijzigd. Je kunt nu inloggen.'**
  String get forgotPasswordChanged;

  /// No description provided for @planningTitle.
  ///
  /// In nl, this message translates to:
  /// **'Planning'**
  String get planningTitle;

  /// Planning list tab: upcoming lessons
  ///
  /// In nl, this message translates to:
  /// **'Aankomend'**
  String get planningTabUpcoming;

  /// Planning list tab: past/completed lessons
  ///
  /// In nl, this message translates to:
  /// **'Afgerond'**
  String get planningTabCompleted;

  /// Planning list tab: cancelled lessons
  ///
  /// In nl, this message translates to:
  /// **'Geannuleerd'**
  String get planningTabCancelled;

  /// Empty-state title on the planning list
  ///
  /// In nl, this message translates to:
  /// **'Niets te vinden'**
  String get planningEmptyTitle;

  /// Empty-state subtitle on the planning list
  ///
  /// In nl, this message translates to:
  /// **'Er staan nog geen lessen in deze categorie.'**
  String get planningEmptySubtitle;

  /// Day-group header when a lesson has no start date
  ///
  /// In nl, this message translates to:
  /// **'Datum onbekend'**
  String get planningUnknownDate;

  /// Generic 'lesson' word: detail-row label and fallback title when the lesson has no driving-class name
  ///
  /// In nl, this message translates to:
  /// **'Les'**
  String get planningLesson;

  /// History log entry for a newly created lesson, also a success snack
  ///
  /// In nl, this message translates to:
  /// **'Les ingepland'**
  String get planningLessonScheduled;

  /// History log entry and success snack after confirming a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les bevestigd'**
  String get planningLessonConfirmed;

  /// History log entry and success snack after cancelling a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les geannuleerd'**
  String get planningLessonCancelled;

  /// History log entry and success snack after completing a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les afgerond'**
  String get planningLessonCompleted;

  /// History log entry and success snack after moving a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les verplaatst'**
  String get planningLessonRescheduled;

  /// Fallback label for an unknown history log action
  ///
  /// In nl, this message translates to:
  /// **'Wijziging'**
  String get planningLogChange;

  /// AppBar title of the lesson detail screen
  ///
  /// In nl, this message translates to:
  /// **'Lesdetails'**
  String get planningDetailTitle;

  /// Shown instead of the date when the lesson has no start date
  ///
  /// In nl, this message translates to:
  /// **'Datum niet ingesteld'**
  String get planningDateNotSet;

  /// Section header with the lesson details
  ///
  /// In nl, this message translates to:
  /// **'Gegevens'**
  String get planningSectionDetails;

  /// Info-row label for the kind of lesson
  ///
  /// In nl, this message translates to:
  /// **'Lesvorm'**
  String get planningInfoLessonType;

  /// Lesson type: trial
  ///
  /// In nl, this message translates to:
  /// **'Proefles'**
  String get planningTypeTrial;

  /// Lesson type: regular/base lesson
  ///
  /// In nl, this message translates to:
  /// **'Basisles'**
  String get planningTypeBase;

  /// Lesson type: package of lessons
  ///
  /// In nl, this message translates to:
  /// **'Lespakket'**
  String get planningTypePack;

  /// Lesson type: exam
  ///
  /// In nl, this message translates to:
  /// **'Examen'**
  String get planningTypeExam;

  /// Info-row label for the instructor
  ///
  /// In nl, this message translates to:
  /// **'Instructeur'**
  String get planningInfoInstructor;

  /// Info-row label for the student
  ///
  /// In nl, this message translates to:
  /// **'Leerling'**
  String get planningInfoStudent;

  /// Info-row label for the phone number
  ///
  /// In nl, this message translates to:
  /// **'Telefoon'**
  String get planningInfoPhone;

  /// Info-row label for the related order
  ///
  /// In nl, this message translates to:
  /// **'Bestelling'**
  String get planningInfoOrder;

  /// Info-row label for the amount paid
  ///
  /// In nl, this message translates to:
  /// **'Betaald'**
  String get planningInfoPaid;

  /// Section header and text-field label for the lesson notes
  ///
  /// In nl, this message translates to:
  /// **'Notities'**
  String get planningNotes;

  /// Success snack after saving notes
  ///
  /// In nl, this message translates to:
  /// **'Notities opgeslagen'**
  String get planningNotesSaved;

  /// Section header with the reason the lesson was cancelled
  ///
  /// In nl, this message translates to:
  /// **'Annuleringsreden'**
  String get planningCancelReasonTitle;

  /// Text-field label in the cancel-lesson dialog
  ///
  /// In nl, this message translates to:
  /// **'Reden (optioneel)'**
  String get planningCancelReasonLabel;

  /// Section header with the available actions
  ///
  /// In nl, this message translates to:
  /// **'Acties'**
  String get planningSectionActions;

  /// Section header with the lesson history
  ///
  /// In nl, this message translates to:
  /// **'Geschiedenis'**
  String get planningSectionHistory;

  /// Button for a student to confirm a pending lesson
  ///
  /// In nl, this message translates to:
  /// **'Les bevestigen'**
  String get planningConfirmLesson;

  /// Button and dialog title for cancelling a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les annuleren'**
  String get planningCancelLesson;

  /// Button and AppBar title for moving a lesson to a new slot
  ///
  /// In nl, this message translates to:
  /// **'Les verplaatsen'**
  String get planningRescheduleLesson;

  /// Button and confirm-dialog title for finishing a lesson
  ///
  /// In nl, this message translates to:
  /// **'Les afronden'**
  String get planningCompleteLesson;

  /// Confirm-dialog message before completing a lesson
  ///
  /// In nl, this message translates to:
  /// **'Weet je zeker dat je deze les wilt afronden?'**
  String get planningCompleteConfirmMessage;

  /// Confirm button label of the complete-lesson dialog
  ///
  /// In nl, this message translates to:
  /// **'Afronden'**
  String get planningCompleteAction;

  /// Button and dialog title for editing the lesson notes
  ///
  /// In nl, this message translates to:
  /// **'Notities bijwerken'**
  String get planningEditNotes;

  /// Button for a student to confirm they attended the lesson
  ///
  /// In nl, this message translates to:
  /// **'Ik was aanwezig'**
  String get planningWasPresent;

  /// Button for a student to report they missed the lesson
  ///
  /// In nl, this message translates to:
  /// **'Ik was afwezig'**
  String get planningWasAbsent;

  /// Confirm-dialog title when reporting an absence
  ///
  /// In nl, this message translates to:
  /// **'Afwezigheid melden'**
  String get planningReportAbsenceTitle;

  /// Confirm-dialog message when confirming attendance
  ///
  /// In nl, this message translates to:
  /// **'Bevestig dat deze les heeft plaatsgevonden.'**
  String get planningConfirmAttendedMessage;

  /// Confirm-dialog message when reporting an absence
  ///
  /// In nl, this message translates to:
  /// **'Meld je afwezigheid. Je instructeur en de administratie worden op de hoogte gebracht.'**
  String get planningReportAbsentMessage;

  /// Status line shown after the student confirmed attendance
  ///
  /// In nl, this message translates to:
  /// **'Aanwezigheid bevestigd'**
  String get planningAttendanceConfirmed;

  /// Status line shown after the student reported an absence
  ///
  /// In nl, this message translates to:
  /// **'Afwezigheid gemeld'**
  String get planningAbsenceReported;

  /// Error snack when no date or start time was chosen yet
  ///
  /// In nl, this message translates to:
  /// **'Kies een datum en starttijd.'**
  String get reschedulePickDateTime;

  /// Error snack when the chosen slot is in the past
  ///
  /// In nl, this message translates to:
  /// **'De nieuwe datum moet in de toekomst liggen.'**
  String get rescheduleFutureDate;

  /// Heading of the reschedule screen
  ///
  /// In nl, this message translates to:
  /// **'Kies een nieuw moment'**
  String get reschedulePickMoment;

  /// Hint under the reschedule heading, {duration} is the lesson length
  ///
  /// In nl, this message translates to:
  /// **'De les duurt {duration} en moet minstens 24 uur vooruit worden verplaatst.'**
  String rescheduleDurationHint(String duration);

  /// List-tile label for the new date
  ///
  /// In nl, this message translates to:
  /// **'Datum'**
  String get rescheduleDateLabel;

  /// List-tile label for the new start time
  ///
  /// In nl, this message translates to:
  /// **'Starttijd'**
  String get rescheduleStartTimeLabel;

  /// Subtitle while date or time has not been picked
  ///
  /// In nl, this message translates to:
  /// **'Nog niet gekozen'**
  String get rescheduleNotChosen;

  /// AppBar title of the lesson card screen
  ///
  /// In nl, this message translates to:
  /// **'Leskaart'**
  String get lessonCardTitle;

  /// Button on the lesson detail screen opening the lesson card
  ///
  /// In nl, this message translates to:
  /// **'Leskaart bekijken'**
  String get lessonCardView;

  /// Tooltip of the refresh button
  ///
  /// In nl, this message translates to:
  /// **'Vernieuwen'**
  String get lessonCardRefresh;

  /// Empty-state title when the lesson card has no questions
  ///
  /// In nl, this message translates to:
  /// **'Geen vragen'**
  String get lessonCardEmptyTitle;

  /// Empty-state subtitle when the lesson card has no questions
  ///
  /// In nl, this message translates to:
  /// **'Voor deze les zijn nog geen vragen ingesteld.'**
  String get lessonCardEmptySubtitle;

  /// Intro line shown to instructors on the lesson card
  ///
  /// In nl, this message translates to:
  /// **'Beoordeel je leerling per onderdeel.'**
  String get lessonCardInstructorIntro;

  /// Intro line shown to students on the lesson card
  ///
  /// In nl, this message translates to:
  /// **'Vul in hoe het ging tijdens je les.'**
  String get lessonCardStudentIntro;

  /// Save button of the lesson card
  ///
  /// In nl, this message translates to:
  /// **'Leskaart opslaan'**
  String get lessonCardSave;

  /// Success snack after saving the lesson card
  ///
  /// In nl, this message translates to:
  /// **'Leskaart opgeslagen'**
  String get lessonCardSaved;

  /// Error snack when saving an empty lesson card
  ///
  /// In nl, this message translates to:
  /// **'Vul eerst minstens één vraag in.'**
  String get lessonCardFillFirst;

  /// Text-field label for a question answer
  ///
  /// In nl, this message translates to:
  /// **'Antwoord / commentaar'**
  String get lessonCardAnswerLabel;

  /// Label above the score choice chips
  ///
  /// In nl, this message translates to:
  /// **'Beoordeling'**
  String get lessonCardScoreLabel;

  /// No description provided for @profileTitle.
  ///
  /// In nl, this message translates to:
  /// **'Profiel'**
  String get profileTitle;

  /// No description provided for @profileSignOut.
  ///
  /// In nl, this message translates to:
  /// **'Uitloggen'**
  String get profileSignOut;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In nl, this message translates to:
  /// **'Weet je zeker dat je wilt uitloggen?'**
  String get profileSignOutMessage;

  /// No description provided for @profileDeactivate.
  ///
  /// In nl, this message translates to:
  /// **'Account deactiveren'**
  String get profileDeactivate;

  /// No description provided for @profileDeactivateMessage.
  ///
  /// In nl, this message translates to:
  /// **'Je account wordt gedeactiveerd en je kunt niet meer inloggen. Dit kan niet ongedaan worden gemaakt.'**
  String get profileDeactivateMessage;

  /// No description provided for @profileDeactivateConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Deactiveren'**
  String get profileDeactivateConfirm;

  /// No description provided for @profileAccountDeactivated.
  ///
  /// In nl, this message translates to:
  /// **'Account gedeactiveerd'**
  String get profileAccountDeactivated;

  /// No description provided for @profileTopUp.
  ///
  /// In nl, this message translates to:
  /// **'Opwaarderen'**
  String get profileTopUp;

  /// No description provided for @profileSectionAccount.
  ///
  /// In nl, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileLicensePlate.
  ///
  /// In nl, this message translates to:
  /// **'Kenteken'**
  String get profileLicensePlate;

  /// No description provided for @profileNotificationSettings.
  ///
  /// In nl, this message translates to:
  /// **'Meldingsinstellingen'**
  String get profileNotificationSettings;

  /// No description provided for @editProfileTitle.
  ///
  /// In nl, this message translates to:
  /// **'Gegevens bewerken'**
  String get editProfileTitle;

  /// No description provided for @editProfileUpdated.
  ///
  /// In nl, this message translates to:
  /// **'Profiel bijgewerkt'**
  String get editProfileUpdated;

  /// No description provided for @editProfileGender.
  ///
  /// In nl, this message translates to:
  /// **'Geslacht'**
  String get editProfileGender;

  /// No description provided for @editProfileGenderMale.
  ///
  /// In nl, this message translates to:
  /// **'Man'**
  String get editProfileGenderMale;

  /// No description provided for @editProfileGenderFemale.
  ///
  /// In nl, this message translates to:
  /// **'Vrouw'**
  String get editProfileGenderFemale;

  /// No description provided for @editProfileGenderUnknown.
  ///
  /// In nl, this message translates to:
  /// **'Onbekend'**
  String get editProfileGenderUnknown;

  /// No description provided for @changePasswordTitle.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord wijzigen'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In nl, this message translates to:
  /// **'Huidig wachtwoord'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw wachtwoord'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord gewijzigd'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoord opslaan'**
  String get changePasswordSubmit;

  /// AppBar title of the notifications screen
  ///
  /// In nl, this message translates to:
  /// **'Meldingen'**
  String get notificationsTitle;

  /// Tooltip of the mark-all-read button
  ///
  /// In nl, this message translates to:
  /// **'Alles gelezen'**
  String get notificationsMarkAllRead;

  /// Tooltip of the button opening the notification settings
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get notificationsOpenSettings;

  /// Error snack when refreshing the notification list fails
  ///
  /// In nl, this message translates to:
  /// **'Vernieuwen is mislukt.'**
  String get notificationsRefreshFailed;

  /// Empty-state title on the notifications screen
  ///
  /// In nl, this message translates to:
  /// **'Geen meldingen'**
  String get notificationsEmptyTitle;

  /// Empty-state subtitle on the notifications screen
  ///
  /// In nl, this message translates to:
  /// **'Updates over je lessen en betalingen komen hier.'**
  String get notificationsEmptySubtitle;

  /// AppBar title of the notification settings screen
  ///
  /// In nl, this message translates to:
  /// **'Meldingsinstellingen'**
  String get notifSettingsTitle;

  /// Section header with the quiet-hours settings
  ///
  /// In nl, this message translates to:
  /// **'Niet storen'**
  String get notifSettingsQuietSection;

  /// Switch title for the quiet hours
  ///
  /// In nl, this message translates to:
  /// **'Stille uren'**
  String get notifSettingsQuietHours;

  /// Subtitle of the quiet-hours switch, {start} and {end} are times
  ///
  /// In nl, this message translates to:
  /// **'Geen meldingen tussen {start} en {end}'**
  String notifSettingsQuietRange(String start, String end);

  /// List-tile label for the quiet-hours start time
  ///
  /// In nl, this message translates to:
  /// **'Begin'**
  String get notifSettingsQuietStart;

  /// List-tile label for the quiet-hours end time
  ///
  /// In nl, this message translates to:
  /// **'Einde'**
  String get notifSettingsQuietEnd;

  /// Section header with the notification-type switches
  ///
  /// In nl, this message translates to:
  /// **'Soorten meldingen'**
  String get notifSettingsTypesSection;

  /// Success snack after saving the notification settings
  ///
  /// In nl, this message translates to:
  /// **'Instellingen opgeslagen'**
  String get notifSettingsSaved;

  /// Label above the current balance on the top-up screen
  ///
  /// In nl, this message translates to:
  /// **'Huidig saldo'**
  String get topUpCurrentBalance;

  /// Section header above the amount presets, also the pay button while no amount is chosen
  ///
  /// In nl, this message translates to:
  /// **'Kies een bedrag'**
  String get topUpChooseAmount;

  /// Label of the free-form amount field
  ///
  /// In nl, this message translates to:
  /// **'Eigen bedrag'**
  String get topUpCustomAmount;

  /// Pay button with the chosen amount, {amount} is formatted as currency
  ///
  /// In nl, this message translates to:
  /// **'Betalen — {amount}'**
  String topUpPayButton(String amount);

  /// Footer note on the top-up screen
  ///
  /// In nl, this message translates to:
  /// **'Betaling via Mollie. Je saldo wordt bijgeschreven zodra de betaling is bevestigd.'**
  String get topUpMollieNote;

  /// Error snack when the chosen amount is missing or invalid
  ///
  /// In nl, this message translates to:
  /// **'Vul een geldig bedrag in.'**
  String get topUpInvalidAmount;

  /// Snack shown after the payment page has been opened
  ///
  /// In nl, this message translates to:
  /// **'Rond de betaling af om je saldo te verhogen.'**
  String get topUpCompletePayment;

  /// No description provided for @ordersTitle.
  ///
  /// In nl, this message translates to:
  /// **'Bestellingen'**
  String get ordersTitle;

  /// No description provided for @ordersBuyButton.
  ///
  /// In nl, this message translates to:
  /// **'Kopen'**
  String get ordersBuyButton;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen bestellingen'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptySubtitle.
  ///
  /// In nl, this message translates to:
  /// **'Koop je eerste lespakket om lessen in te plannen.'**
  String get ordersEmptySubtitle;

  /// No description provided for @ordersOrderNumber.
  ///
  /// In nl, this message translates to:
  /// **'Bestelling #{id}'**
  String ordersOrderNumber(int id);

  /// No description provided for @ordersPaymentPaid.
  ///
  /// In nl, this message translates to:
  /// **'Betaald'**
  String get ordersPaymentPaid;

  /// No description provided for @ordersPaymentOpen.
  ///
  /// In nl, this message translates to:
  /// **'Open'**
  String get ordersPaymentOpen;

  /// No description provided for @ordersPaymentPending.
  ///
  /// In nl, this message translates to:
  /// **'In behandeling'**
  String get ordersPaymentPending;

  /// No description provided for @ordersPaymentFailed.
  ///
  /// In nl, this message translates to:
  /// **'Mislukt'**
  String get ordersPaymentFailed;

  /// No description provided for @ordersPaymentCanceled.
  ///
  /// In nl, this message translates to:
  /// **'Geannuleerd'**
  String get ordersPaymentCanceled;

  /// No description provided for @ordersPaymentExpired.
  ///
  /// In nl, this message translates to:
  /// **'Verlopen'**
  String get ordersPaymentExpired;

  /// No description provided for @ordersPaymentUnpaid.
  ///
  /// In nl, this message translates to:
  /// **'Nog niet betaald'**
  String get ordersPaymentUnpaid;

  /// No description provided for @ordersTotalDuration.
  ///
  /// In nl, this message translates to:
  /// **'{duration} les'**
  String ordersTotalDuration(String duration);

  /// No description provided for @orderDetailTitle.
  ///
  /// In nl, this message translates to:
  /// **'Bestelling #{id}'**
  String orderDetailTitle(int id);

  /// No description provided for @orderDetailPlacedOn.
  ///
  /// In nl, this message translates to:
  /// **'Geplaatst op {date}'**
  String orderDetailPlacedOn(String date);

  /// No description provided for @orderDetailSectionDetails.
  ///
  /// In nl, this message translates to:
  /// **'Gegevens'**
  String get orderDetailSectionDetails;

  /// No description provided for @orderDetailStudent.
  ///
  /// In nl, this message translates to:
  /// **'Leerling'**
  String get orderDetailStudent;

  /// No description provided for @orderDetailInstructor.
  ///
  /// In nl, this message translates to:
  /// **'Instructeur'**
  String get orderDetailInstructor;

  /// No description provided for @orderDetailTotal.
  ///
  /// In nl, this message translates to:
  /// **'Totaal'**
  String get orderDetailTotal;

  /// No description provided for @orderDetailScheduled.
  ///
  /// In nl, this message translates to:
  /// **'Gepland'**
  String get orderDetailScheduled;

  /// No description provided for @orderDetailAvailable.
  ///
  /// In nl, this message translates to:
  /// **'Beschikbaar'**
  String get orderDetailAvailable;

  /// No description provided for @orderDetailPaymentMethod.
  ///
  /// In nl, this message translates to:
  /// **'Betaalwijze'**
  String get orderDetailPaymentMethod;

  /// No description provided for @orderDetailPaymentDigital.
  ///
  /// In nl, this message translates to:
  /// **'Online'**
  String get orderDetailPaymentDigital;

  /// No description provided for @orderDetailPaymentCash.
  ///
  /// In nl, this message translates to:
  /// **'Contant'**
  String get orderDetailPaymentCash;

  /// No description provided for @orderDetailPaymentBalance.
  ///
  /// In nl, this message translates to:
  /// **'Saldo'**
  String get orderDetailPaymentBalance;

  /// No description provided for @orderDetailSectionLessons.
  ///
  /// In nl, this message translates to:
  /// **'Lessen'**
  String get orderDetailSectionLessons;

  /// No description provided for @orderDetailNoLessons.
  ///
  /// In nl, this message translates to:
  /// **'Geen lesonderdelen gevonden.'**
  String get orderDetailNoLessons;

  /// No description provided for @orderDetailLesson.
  ///
  /// In nl, this message translates to:
  /// **'Les'**
  String get orderDetailLesson;

  /// No description provided for @orderDetailLessonCount.
  ///
  /// In nl, this message translates to:
  /// **'{count} lessen'**
  String orderDetailLessonCount(int count);

  /// No description provided for @orderDetailMinutesAvailable.
  ///
  /// In nl, this message translates to:
  /// **'{duration} vrij'**
  String orderDetailMinutesAvailable(String duration);

  /// No description provided for @orderDetailScheduleButton.
  ///
  /// In nl, this message translates to:
  /// **'Inplannen'**
  String get orderDetailScheduleButton;

  /// No description provided for @orderDetailSectionActions.
  ///
  /// In nl, this message translates to:
  /// **'Acties'**
  String get orderDetailSectionActions;

  /// No description provided for @orderDetailPayNow.
  ///
  /// In nl, this message translates to:
  /// **'Nu betalen'**
  String get orderDetailPayNow;

  /// No description provided for @orderDetailMarkPaid.
  ///
  /// In nl, this message translates to:
  /// **'Markeer als betaald'**
  String get orderDetailMarkPaid;

  /// No description provided for @orderDetailRequestPayment.
  ///
  /// In nl, this message translates to:
  /// **'Betaling aanvragen'**
  String get orderDetailRequestPayment;

  /// No description provided for @orderDetailPaymentRequested.
  ///
  /// In nl, this message translates to:
  /// **'Betalingsverzoek verstuurd'**
  String get orderDetailPaymentRequested;

  /// No description provided for @orderDetailOpenInvoice.
  ///
  /// In nl, this message translates to:
  /// **'Factuur openen'**
  String get orderDetailOpenInvoice;

  /// No description provided for @orderDetailPaymentPageFailed.
  ///
  /// In nl, this message translates to:
  /// **'De betalingspagina kon niet worden geopend.'**
  String get orderDetailPaymentPageFailed;

  /// No description provided for @buyLessonsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Lessen kopen'**
  String get buyLessonsTitle;

  /// No description provided for @buyLessonsChoosePackage.
  ///
  /// In nl, this message translates to:
  /// **'Kies een lespakket'**
  String get buyLessonsChoosePackage;

  /// No description provided for @buyLessonsPayButton.
  ///
  /// In nl, this message translates to:
  /// **'Betalen — {amount}'**
  String buyLessonsPayButton(String amount);

  /// No description provided for @buyLessonsStepVehicle.
  ///
  /// In nl, this message translates to:
  /// **'1. Voertuig'**
  String get buyLessonsStepVehicle;

  /// No description provided for @buyLessonsVehicleFallback.
  ///
  /// In nl, this message translates to:
  /// **'Voertuig {id}'**
  String buyLessonsVehicleFallback(int id);

  /// No description provided for @buyLessonsStepLesson.
  ///
  /// In nl, this message translates to:
  /// **'2. Les'**
  String get buyLessonsStepLesson;

  /// No description provided for @buyLessonsChooseVehicleFirst.
  ///
  /// In nl, this message translates to:
  /// **'Kies eerst een voertuigtype.'**
  String get buyLessonsChooseVehicleFirst;

  /// No description provided for @buyLessonsNoPackages.
  ///
  /// In nl, this message translates to:
  /// **'Geen lespakketten beschikbaar.'**
  String get buyLessonsNoPackages;

  /// No description provided for @buyLessonsStepQuantity.
  ///
  /// In nl, this message translates to:
  /// **'3. Aantal'**
  String get buyLessonsStepQuantity;

  /// No description provided for @buyLessonsStepStudent.
  ///
  /// In nl, this message translates to:
  /// **'4. Leerling'**
  String get buyLessonsStepStudent;

  /// No description provided for @buyLessonsStepPaymentInstructor.
  ///
  /// In nl, this message translates to:
  /// **'5. Betaalwijze'**
  String get buyLessonsStepPaymentInstructor;

  /// No description provided for @buyLessonsStepPaymentStudent.
  ///
  /// In nl, this message translates to:
  /// **'4. Betaalwijze'**
  String get buyLessonsStepPaymentStudent;

  /// No description provided for @buyLessonsPaymentOnline.
  ///
  /// In nl, this message translates to:
  /// **'Online'**
  String get buyLessonsPaymentOnline;

  /// No description provided for @buyLessonsPaymentBalance.
  ///
  /// In nl, this message translates to:
  /// **'Saldo'**
  String get buyLessonsPaymentBalance;

  /// No description provided for @buyLessonsBalanceNote.
  ///
  /// In nl, this message translates to:
  /// **'Het bedrag wordt van je saldo afgeschreven. Je saldo: {balance}'**
  String buyLessonsBalanceNote(String balance);

  /// No description provided for @buyLessonsMollieNote.
  ///
  /// In nl, this message translates to:
  /// **'Je doorgestuurd naar de veilige betaalpagina van Mollie.'**
  String get buyLessonsMollieNote;

  /// No description provided for @buyLessonsAfterPurchase.
  ///
  /// In nl, this message translates to:
  /// **'Na de aankoop plan je je lessen in vanuit de bestelling.'**
  String get buyLessonsAfterPurchase;

  /// No description provided for @buyLessonsOrderPlaced.
  ///
  /// In nl, this message translates to:
  /// **'Bestelling geplaatst'**
  String get buyLessonsOrderPlaced;

  /// No description provided for @buyLessonsCompletePayment.
  ///
  /// In nl, this message translates to:
  /// **'Rond de betaling af'**
  String get buyLessonsCompletePayment;

  /// No description provided for @buyLessonsNoStudents.
  ///
  /// In nl, this message translates to:
  /// **'Je hebt nog geen leerlingen toegewezen.'**
  String get buyLessonsNoStudents;

  /// No description provided for @buyLessonsChooseStudent.
  ///
  /// In nl, this message translates to:
  /// **'Kies een leerling'**
  String get buyLessonsChooseStudent;

  /// No description provided for @buyLessonsLessonTypeTrial.
  ///
  /// In nl, this message translates to:
  /// **'Proefles'**
  String get buyLessonsLessonTypeTrial;

  /// No description provided for @buyLessonsLessonTypeBase.
  ///
  /// In nl, this message translates to:
  /// **'Basisles'**
  String get buyLessonsLessonTypeBase;

  /// No description provided for @buyLessonsLessonTypePack.
  ///
  /// In nl, this message translates to:
  /// **'Lespakket'**
  String get buyLessonsLessonTypePack;

  /// No description provided for @buyLessonsLessonTypeExam.
  ///
  /// In nl, this message translates to:
  /// **'Examen'**
  String get buyLessonsLessonTypeExam;

  /// No description provided for @buyLessonsTotalLine.
  ///
  /// In nl, this message translates to:
  /// **'{duration} les — {amount}'**
  String buyLessonsTotalLine(String duration, String amount);

  /// No description provided for @buyLessonsAddItem.
  ///
  /// In nl, this message translates to:
  /// **'Toevoegen aan bestelling'**
  String get buyLessonsAddItem;

  /// No description provided for @scheduleLessonTitle.
  ///
  /// In nl, this message translates to:
  /// **'Les inplannen'**
  String get scheduleLessonTitle;

  /// No description provided for @scheduleLessonChooseDateTime.
  ///
  /// In nl, this message translates to:
  /// **'Kies een datum en starttijd.'**
  String get scheduleLessonChooseDateTime;

  /// No description provided for @scheduleLessonFutureDate.
  ///
  /// In nl, this message translates to:
  /// **'De les moet in de toekomst liggen.'**
  String get scheduleLessonFutureDate;

  /// No description provided for @scheduleLessonScheduled.
  ///
  /// In nl, this message translates to:
  /// **'Les ingepland'**
  String get scheduleLessonScheduled;

  /// No description provided for @scheduleLessonAvailable.
  ///
  /// In nl, this message translates to:
  /// **'Nog {duration} beschikbaar in dit pakket.'**
  String scheduleLessonAvailable(String duration);

  /// No description provided for @scheduleLessonNoTimeLeft.
  ///
  /// In nl, this message translates to:
  /// **'Er is geen beschikbare lestijd meer in dit pakket.'**
  String get scheduleLessonNoTimeLeft;

  /// No description provided for @scheduleLessonDate.
  ///
  /// In nl, this message translates to:
  /// **'Datum'**
  String get scheduleLessonDate;

  /// No description provided for @scheduleLessonNotChosen.
  ///
  /// In nl, this message translates to:
  /// **'Nog niet gekozen'**
  String get scheduleLessonNotChosen;

  /// No description provided for @scheduleLessonStartTime.
  ///
  /// In nl, this message translates to:
  /// **'Starttijd'**
  String get scheduleLessonStartTime;

  /// No description provided for @scheduleLessonDuration.
  ///
  /// In nl, this message translates to:
  /// **'Duur'**
  String get scheduleLessonDuration;

  /// No description provided for @scheduleLessonScheduleButton.
  ///
  /// In nl, this message translates to:
  /// **'Inplannen'**
  String get scheduleLessonScheduleButton;

  /// No description provided for @languageLabel.
  ///
  /// In nl, this message translates to:
  /// **'Taal'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In nl, this message translates to:
  /// **'Systeem (automatisch)'**
  String get languageSystem;

  /// No description provided for @languageDutch.
  ///
  /// In nl, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @languageEnglish.
  ///
  /// In nl, this message translates to:
  /// **'Engels'**
  String get languageEnglish;

  /// No description provided for @notifPrefLessonBooked.
  ///
  /// In nl, this message translates to:
  /// **'Les geboekt'**
  String get notifPrefLessonBooked;

  /// No description provided for @notifPrefLessonReminder24h.
  ///
  /// In nl, this message translates to:
  /// **'Herinnering les (24 uur)'**
  String get notifPrefLessonReminder24h;

  /// No description provided for @notifPrefLessonReminder1h.
  ///
  /// In nl, this message translates to:
  /// **'Herinnering les (1 uur)'**
  String get notifPrefLessonReminder1h;

  /// No description provided for @notifPrefLessonCancelled.
  ///
  /// In nl, this message translates to:
  /// **'Les geannuleerd'**
  String get notifPrefLessonCancelled;

  /// No description provided for @notifPrefLessonChanged.
  ///
  /// In nl, this message translates to:
  /// **'Les gewijzigd'**
  String get notifPrefLessonChanged;

  /// No description provided for @notifPrefLessonCompleted.
  ///
  /// In nl, this message translates to:
  /// **'Les afgerond'**
  String get notifPrefLessonCompleted;

  /// No description provided for @notifPrefPaymentSuccessful.
  ///
  /// In nl, this message translates to:
  /// **'Betaling geslaagd'**
  String get notifPrefPaymentSuccessful;

  /// No description provided for @notifPrefPaymentFailed.
  ///
  /// In nl, this message translates to:
  /// **'Betaling mislukt'**
  String get notifPrefPaymentFailed;

  /// No description provided for @notifPrefPaymentRefunded.
  ///
  /// In nl, this message translates to:
  /// **'Betaling terugbetaald'**
  String get notifPrefPaymentRefunded;

  /// No description provided for @notifPrefPaymentRequested.
  ///
  /// In nl, this message translates to:
  /// **'Betalingsverzoek'**
  String get notifPrefPaymentRequested;

  /// No description provided for @notifPrefLowLessonCredit.
  ///
  /// In nl, this message translates to:
  /// **'Weinig lesuren over'**
  String get notifPrefLowLessonCredit;

  /// No description provided for @notifPrefExamBooked.
  ///
  /// In nl, this message translates to:
  /// **'Examen geboekt'**
  String get notifPrefExamBooked;

  /// No description provided for @notifPrefExamReminder7d.
  ///
  /// In nl, this message translates to:
  /// **'Herinnering examen (7 dagen)'**
  String get notifPrefExamReminder7d;

  /// No description provided for @notifPrefExamReminder24h.
  ///
  /// In nl, this message translates to:
  /// **'Herinnering examen (24 uur)'**
  String get notifPrefExamReminder24h;

  /// No description provided for @notifPrefExamChanged.
  ///
  /// In nl, this message translates to:
  /// **'Examen gewijzigd'**
  String get notifPrefExamChanged;

  /// No description provided for @notifPrefExamCancelled.
  ///
  /// In nl, this message translates to:
  /// **'Examen geannuleerd'**
  String get notifPrefExamCancelled;

  /// No description provided for @notifPrefLessonCardUpdated.
  ///
  /// In nl, this message translates to:
  /// **'Leskaart bijgewerkt'**
  String get notifPrefLessonCardUpdated;

  /// No description provided for @notifPrefInstructorFeedback.
  ///
  /// In nl, this message translates to:
  /// **'Instructeur feedback'**
  String get notifPrefInstructorFeedback;

  /// No description provided for @notifPrefAccountSecurity.
  ///
  /// In nl, this message translates to:
  /// **'Accountbeveiliging'**
  String get notifPrefAccountSecurity;

  /// No description provided for @notifPrefLessons.
  ///
  /// In nl, this message translates to:
  /// **'Lessen'**
  String get notifPrefLessons;

  /// No description provided for @notifPrefPayments.
  ///
  /// In nl, this message translates to:
  /// **'Betalingen'**
  String get notifPrefPayments;

  /// No description provided for @notifPrefExams.
  ///
  /// In nl, this message translates to:
  /// **'Examens'**
  String get notifPrefExams;

  /// No description provided for @notifPrefLessonCards.
  ///
  /// In nl, this message translates to:
  /// **'Leskaarten'**
  String get notifPrefLessonCards;

  /// No description provided for @notifPrefAccount.
  ///
  /// In nl, this message translates to:
  /// **'Account'**
  String get notifPrefAccount;

  /// No description provided for @notifPrefLocked.
  ///
  /// In nl, this message translates to:
  /// **'Altijd aan (kan niet worden uitgezet)'**
  String get notifPrefLocked;

  /// No description provided for @paymentReturnProcessing.
  ///
  /// In nl, this message translates to:
  /// **'Betaling verwerken…'**
  String get paymentReturnProcessing;

  /// No description provided for @paymentReturnSuccess.
  ///
  /// In nl, this message translates to:
  /// **'Betaling ontvangen'**
  String get paymentReturnSuccess;

  /// No description provided for @orderDetailOpenInvoiceFailed.
  ///
  /// In nl, this message translates to:
  /// **'De factuur kon niet worden geopend.'**
  String get orderDetailOpenInvoiceFailed;

  /// No description provided for @orderDetailDownloadInvoice.
  ///
  /// In nl, this message translates to:
  /// **'Downloaden'**
  String get orderDetailDownloadInvoice;

  /// No description provided for @themeModeLabel.
  ///
  /// In nl, this message translates to:
  /// **'Thema'**
  String get themeModeLabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In nl, this message translates to:
  /// **'Systeem'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In nl, this message translates to:
  /// **'Donker'**
  String get themeModeDark;

  /// No description provided for @planningAwaitingConfirmation.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op bevestiging van de andere partij.'**
  String get planningAwaitingConfirmation;

  /// No description provided for @planningNumber.
  ///
  /// In nl, this message translates to:
  /// **'Les #{id}'**
  String planningNumber(int id);

  /// No description provided for @planningOrderId.
  ///
  /// In nl, this message translates to:
  /// **'Bestelling #{id}'**
  String planningOrderId(int id);
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
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
