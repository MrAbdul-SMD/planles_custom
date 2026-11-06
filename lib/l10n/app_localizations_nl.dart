// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get save => 'Opslaan';

  @override
  String get close => 'Sluiten';

  @override
  String get back => 'Terug';

  @override
  String get next => 'Volgende';

  @override
  String get delete => 'Verwijderen';

  @override
  String get edit => 'Bewerken';

  @override
  String get genericSuccess => 'Gelukt';

  @override
  String get noName => 'Geen naam';

  @override
  String get today => 'Vandaag';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get yesterday => 'Gisteren';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count uur';
  }

  @override
  String hoursMinutesShort(int hours, int minutes) {
    return '$hours uur $minutes min';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navOrders => 'Bestellingen';

  @override
  String get navNotifications => 'Meldingen';

  @override
  String get navProfile => 'Profiel';

  @override
  String get statusConfirmed => 'Bevestigd';

  @override
  String get statusCompleted => 'Afgerond';

  @override
  String get statusCancelled => 'Geannuleerd';

  @override
  String get statusPending => 'In afwachting';

  @override
  String get errTimeout =>
      'De verbinding met de server duurde te lang. Probeer het opnieuw.';

  @override
  String get errOffline =>
      'Geen verbinding met de server. Controleer je internetverbinding.';

  @override
  String get errCancelled => 'Aanvraag geannuleerd.';

  @override
  String get errInsecure => 'Onveilige verbinding met de server.';

  @override
  String get errGeneric => 'Er is iets misgegaan. Probeer het opnieuw.';

  @override
  String get errTooManyRequests =>
      'Te veel aanvragen. Wacht even en probeer het opnieuw.';

  @override
  String get errInvalidData => 'De ingevulde gegevens zijn ongeldig.';

  @override
  String get errSessionExpired => 'Je sessie is verlopen. Log opnieuw in.';

  @override
  String get errForbidden => 'Je hebt geen toegang tot deze actie.';

  @override
  String get errNotFound => 'Dit item is niet gevonden.';

  @override
  String get errEmailTaken => 'Er bestaat al een account met dit e-mailadres.';

  @override
  String get errServer =>
      'Er is iets misgegaan op de server. Probeer het later opnieuw.';

  @override
  String get errInvalidCredentials =>
      'Inloggen is mislukt. Probeer het opnieuw.';

  @override
  String get errUserNotFound => 'Gebruiker niet gevonden.';

  @override
  String get errOrderNotFound => 'Bestelling niet gevonden.';

  @override
  String get errLessonNotFound => 'Les niet gevonden.';

  @override
  String get errPaymentFailed => 'Het openen van de betaling is mislukt.';

  @override
  String get errEmptyInvoice => 'De factuur is leeg.';

  @override
  String get dashboardGreetingMorning => 'Goedemorgen';

  @override
  String get dashboardGreetingAfternoon => 'Goedemiddag';

  @override
  String get dashboardGreetingEvening => 'Goedenavond';

  @override
  String get dashboardHello => 'Hallo';

  @override
  String get dashboardUpcomingLessons => 'Eerstvolgende lessen';

  @override
  String get dashboardViewAll => 'Alles bekijken';

  @override
  String get dashboardQuickActions => 'Snel regelen';

  @override
  String get dashboardBuyLessons => 'Lessen kopen';

  @override
  String get dashboardTopUpBalance => 'Saldo opwaarderen';

  @override
  String get dashboardRecentNotifications => 'Recente meldingen';

  @override
  String get dashboardAllNotifications => 'Alle meldingen';

  @override
  String get dashboardNotificationFallback => 'Melding';

  @override
  String get dashboardBalanceLabel => 'Saldo';

  @override
  String get dashboardNoLessonsTitle => 'Nog geen lessen gepland';

  @override
  String get dashboardNoLessonsSubtitle =>
      'Koop een lespakket om je eerste les in te plannen.';

  @override
  String get dashboardLessonFallback => 'Les';

  @override
  String get studentsTitle => 'Mijn leerlingen';

  @override
  String get studentsSearchHint => 'Zoek leerling';

  @override
  String get studentsEmptyTitle => 'Geen leerlingen';

  @override
  String get studentsEmptySubtitle =>
      'Er zijn nog geen leerlingen aan je gekoppeld.';

  @override
  String get studentsEmailLabel => 'E-mail';

  @override
  String get studentsPhoneLabel => 'Telefoon';

  @override
  String get studentsAddressLabel => 'Adres';

  @override
  String get studentsPickupLabel => 'Ophaallocatie';

  @override
  String get loginTitle => 'Welkom terug';

  @override
  String get loginSubtitle => 'Log in om je lessen te beheren';

  @override
  String get loginEmailLabel => 'E-mailadres';

  @override
  String get loginEmailRequired => 'Vul je e-mailadres in';

  @override
  String get loginEmailInvalid => 'Vul een geldig e-mailadres in';

  @override
  String get loginPasswordLabel => 'Wachtwoord';

  @override
  String get loginPasswordRequired => 'Vul je wachtwoord in';

  @override
  String get loginForgotPassword => 'Wachtwoord vergeten?';

  @override
  String get loginSubmit => 'Inloggen';

  @override
  String get loginNoAccount => 'Nog geen account?';

  @override
  String get loginRegister => 'Registreren';

  @override
  String get registerTitle => 'Registreren';

  @override
  String get registerAccountType => 'Accounttype';

  @override
  String get registerStudent => 'Leerling';

  @override
  String get registerInstructor => 'Instructeur';

  @override
  String get registerPersonalDetails => 'Persoonlijke gegevens';

  @override
  String get registerFirstName => 'Voornaam';

  @override
  String get registerLastName => 'Achternaam';

  @override
  String get registerPhone => 'Telefoonnummer';

  @override
  String get registerBirthdate => 'Geboortedatum';

  @override
  String get registerBirthdateHint => 'jjjj-mm-dd';

  @override
  String get registerAddress => 'Adres';

  @override
  String get registerStreet => 'Straat';

  @override
  String get registerHouseNumber => 'Huisnr.';

  @override
  String get registerZipCode => 'Postcode';

  @override
  String get registerCity => 'Plaats';

  @override
  String get registerLessonDetails => 'Lesdetails (optioneel)';

  @override
  String get registerPickupLocation => 'Ophaallocatie';

  @override
  String get registerLicensePlate => 'Kenteken (bij eigen voertuig)';

  @override
  String get registerPasswordLabel => 'Wachtwoord';

  @override
  String get registerPasswordRules =>
      'Minimaal 8 tekens met een kleine letter, hoofdletter en cijfer';

  @override
  String get registerPasswordMin8 => 'Minimaal 8 tekens';

  @override
  String get registerPasswordNeedsMix =>
      'Gebruik een kleine letter, hoofdletter en cijfer';

  @override
  String get registerPasswordRepeat => 'Herhaal wachtwoord';

  @override
  String get registerPasswordMismatch => 'Wachtwoorden komen niet overeen';

  @override
  String get registerRequired => 'Verplicht veld';

  @override
  String get registerOtpTitle => 'Bevestigingscode';

  @override
  String get registerOtpFallback =>
      'We hebben een code naar je e-mailadres gestuurd.';

  @override
  String get registerOtpLabel => 'Code uit e-mail';

  @override
  String get registerOtpRequired => 'Vul de 4-cijferige code in';

  @override
  String get registerSubmitCreate => 'Account aanmaken';

  @override
  String get registerSubmitCode => 'Code aanvragen';

  @override
  String get registerHaveAccount => 'Ik heb al een account';

  @override
  String get forgotTitle => 'Wachtwoord vergeten';

  @override
  String get forgotEnterCode => 'Voer de code in';

  @override
  String get forgotResetTitle => 'Herstel je wachtwoord';

  @override
  String forgotCodeSentTo(String email) {
    return 'We hebben een code gestuurd naar $email.';
  }

  @override
  String get forgotEmailHint =>
      'Vul je e-mailadres in en we sturen je een herstelcode.';

  @override
  String get forgotCodeLabel => 'Herstelcode';

  @override
  String get forgotCodeRequired => 'Vul de code in';

  @override
  String get forgotNewPassword => 'Nieuw wachtwoord (optioneel)';

  @override
  String get forgotSubmitReset => 'Wachtwoord resetten';

  @override
  String get forgotSubmitSend => 'Code versturen';

  @override
  String get forgotResend => 'Code opnieuw versturen';

  @override
  String get forgotBackToLogin => 'Terug naar inloggen';

  @override
  String get forgotCodeSent => 'We hebben een code naar je e-mail gestuurd.';

  @override
  String get forgotPasswordChanged =>
      'Wachtwoord gewijzigd. Je kunt nu inloggen.';

  @override
  String get planningTitle => 'Planning';

  @override
  String get planningTabUpcoming => 'Aankomend';

  @override
  String get planningTabCompleted => 'Afgerond';

  @override
  String get planningTabCancelled => 'Geannuleerd';

  @override
  String get planningEmptyTitle => 'Niets te vinden';

  @override
  String get planningEmptySubtitle =>
      'Er staan nog geen lessen in deze categorie.';

  @override
  String get planningUnknownDate => 'Datum onbekend';

  @override
  String get planningLesson => 'Les';

  @override
  String get planningLessonScheduled => 'Les ingepland';

  @override
  String get planningLessonConfirmed => 'Les bevestigd';

  @override
  String get planningLessonCancelled => 'Les geannuleerd';

  @override
  String get planningLessonCompleted => 'Les afgerond';

  @override
  String get planningLessonRescheduled => 'Les verplaatst';

  @override
  String get planningLogChange => 'Wijziging';

  @override
  String get planningDetailTitle => 'Lesdetails';

  @override
  String get planningDateNotSet => 'Datum niet ingesteld';

  @override
  String get planningSectionDetails => 'Gegevens';

  @override
  String get planningInfoLessonType => 'Lesvorm';

  @override
  String get planningTypeTrial => 'Proefles';

  @override
  String get planningTypeBase => 'Basisles';

  @override
  String get planningTypePack => 'Lespakket';

  @override
  String get planningTypeExam => 'Examen';

  @override
  String get planningInfoInstructor => 'Instructeur';

  @override
  String get planningInfoStudent => 'Leerling';

  @override
  String get planningInfoPhone => 'Telefoon';

  @override
  String get planningInfoOrder => 'Bestelling';

  @override
  String get planningInfoPaid => 'Betaald';

  @override
  String get planningNotes => 'Notities';

  @override
  String get planningNotesSaved => 'Notities opgeslagen';

  @override
  String get planningCancelReasonTitle => 'Annuleringsreden';

  @override
  String get planningCancelReasonLabel => 'Reden (optioneel)';

  @override
  String get planningSectionActions => 'Acties';

  @override
  String get planningSectionHistory => 'Geschiedenis';

  @override
  String get planningConfirmLesson => 'Les bevestigen';

  @override
  String get planningCancelLesson => 'Les annuleren';

  @override
  String get planningRescheduleLesson => 'Les verplaatsen';

  @override
  String get planningCompleteLesson => 'Les afronden';

  @override
  String get planningCompleteConfirmMessage =>
      'Weet je zeker dat je deze les wilt afronden?';

  @override
  String get planningCompleteAction => 'Afronden';

  @override
  String get planningEditNotes => 'Notities bijwerken';

  @override
  String get planningWasPresent => 'Ik was aanwezig';

  @override
  String get planningWasAbsent => 'Ik was afwezig';

  @override
  String get planningReportAbsenceTitle => 'Afwezigheid melden';

  @override
  String get planningConfirmAttendedMessage =>
      'Bevestig dat deze les heeft plaatsgevonden.';

  @override
  String get planningReportAbsentMessage =>
      'Meld je afwezigheid. Je instructeur en de administratie worden op de hoogte gebracht.';

  @override
  String get planningAttendanceConfirmed => 'Aanwezigheid bevestigd';

  @override
  String get planningAbsenceReported => 'Afwezigheid gemeld';

  @override
  String get reschedulePickDateTime => 'Kies een datum en starttijd.';

  @override
  String get rescheduleFutureDate =>
      'De nieuwe datum moet in de toekomst liggen.';

  @override
  String get reschedulePickMoment => 'Kies een nieuw moment';

  @override
  String rescheduleDurationHint(String duration) {
    return 'De les duurt $duration en moet minstens 24 uur vooruit worden verplaatst.';
  }

  @override
  String get rescheduleDateLabel => 'Datum';

  @override
  String get rescheduleStartTimeLabel => 'Starttijd';

  @override
  String get rescheduleNotChosen => 'Nog niet gekozen';

  @override
  String get lessonCardTitle => 'Leskaart';

  @override
  String get lessonCardView => 'Leskaart bekijken';

  @override
  String get lessonCardRefresh => 'Vernieuwen';

  @override
  String get lessonCardEmptyTitle => 'Geen vragen';

  @override
  String get lessonCardEmptySubtitle =>
      'Voor deze les zijn nog geen vragen ingesteld.';

  @override
  String get lessonCardInstructorIntro =>
      'Beoordeel je leerling per onderdeel.';

  @override
  String get lessonCardStudentIntro => 'Vul in hoe het ging tijdens je les.';

  @override
  String get lessonCardSave => 'Leskaart opslaan';

  @override
  String get lessonCardSaved => 'Leskaart opgeslagen';

  @override
  String get lessonCardFillFirst => 'Vul eerst minstens één vraag in.';

  @override
  String get lessonCardAnswerLabel => 'Antwoord / commentaar';

  @override
  String get lessonCardScoreLabel => 'Beoordeling';

  @override
  String get profileTitle => 'Profiel';

  @override
  String get profileSignOut => 'Uitloggen';

  @override
  String get profileSignOutMessage => 'Weet je zeker dat je wilt uitloggen?';

  @override
  String get profileDeactivate => 'Account deactiveren';

  @override
  String get profileDeactivateMessage =>
      'Je account wordt gedeactiveerd en je kunt niet meer inloggen. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get profileDeactivateConfirm => 'Deactiveren';

  @override
  String get profileAccountDeactivated => 'Account gedeactiveerd';

  @override
  String get profileTopUp => 'Opwaarderen';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileLicensePlate => 'Kenteken';

  @override
  String get profileNotificationSettings => 'Meldingsinstellingen';

  @override
  String get editProfileTitle => 'Gegevens bewerken';

  @override
  String get editProfileUpdated => 'Profiel bijgewerkt';

  @override
  String get editProfileGender => 'Geslacht';

  @override
  String get editProfileGenderMale => 'Man';

  @override
  String get editProfileGenderFemale => 'Vrouw';

  @override
  String get editProfileGenderUnknown => 'Onbekend';

  @override
  String get changePasswordTitle => 'Wachtwoord wijzigen';

  @override
  String get changePasswordCurrentLabel => 'Huidig wachtwoord';

  @override
  String get changePasswordNewLabel => 'Nieuw wachtwoord';

  @override
  String get changePasswordSuccess => 'Wachtwoord gewijzigd';

  @override
  String get changePasswordSubmit => 'Wachtwoord opslaan';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsMarkAllRead => 'Alles gelezen';

  @override
  String get notificationsOpenSettings => 'Instellingen';

  @override
  String get notificationsRefreshFailed => 'Vernieuwen is mislukt.';

  @override
  String get notificationsEmptyTitle => 'Geen meldingen';

  @override
  String get notificationsEmptySubtitle =>
      'Updates over je lessen en betalingen komen hier.';

  @override
  String get notifSettingsTitle => 'Meldingsinstellingen';

  @override
  String get notifSettingsQuietSection => 'Niet storen';

  @override
  String get notifSettingsQuietHours => 'Stille uren';

  @override
  String notifSettingsQuietRange(String start, String end) {
    return 'Geen meldingen tussen $start en $end';
  }

  @override
  String get notifSettingsQuietStart => 'Begin';

  @override
  String get notifSettingsQuietEnd => 'Einde';

  @override
  String get notifSettingsTypesSection => 'Soorten meldingen';

  @override
  String get notifSettingsSaved => 'Instellingen opgeslagen';

  @override
  String get topUpCurrentBalance => 'Huidig saldo';

  @override
  String get topUpChooseAmount => 'Kies een bedrag';

  @override
  String get topUpCustomAmount => 'Eigen bedrag';

  @override
  String topUpPayButton(String amount) {
    return 'Betalen — $amount';
  }

  @override
  String get topUpMollieNote =>
      'Betaling via Mollie. Je saldo wordt bijgeschreven zodra de betaling is bevestigd.';

  @override
  String get topUpInvalidAmount => 'Vul een geldig bedrag in.';

  @override
  String get topUpCompletePayment =>
      'Rond de betaling af om je saldo te verhogen.';

  @override
  String get ordersTitle => 'Bestellingen';

  @override
  String get ordersBuyButton => 'Kopen';

  @override
  String get ordersEmptyTitle => 'Nog geen bestellingen';

  @override
  String get ordersEmptySubtitle =>
      'Koop je eerste lespakket om lessen in te plannen.';

  @override
  String ordersOrderNumber(int id) {
    return 'Bestelling #$id';
  }

  @override
  String get ordersPaymentPaid => 'Betaald';

  @override
  String get ordersPaymentOpen => 'Open';

  @override
  String get ordersPaymentPending => 'In behandeling';

  @override
  String get ordersPaymentFailed => 'Mislukt';

  @override
  String get ordersPaymentCanceled => 'Geannuleerd';

  @override
  String get ordersPaymentExpired => 'Verlopen';

  @override
  String get ordersPaymentUnpaid => 'Nog niet betaald';

  @override
  String ordersTotalDuration(String duration) {
    return '$duration les';
  }

  @override
  String orderDetailTitle(int id) {
    return 'Bestelling #$id';
  }

  @override
  String orderDetailPlacedOn(String date) {
    return 'Geplaatst op $date';
  }

  @override
  String get orderDetailSectionDetails => 'Gegevens';

  @override
  String get orderDetailStudent => 'Leerling';

  @override
  String get orderDetailInstructor => 'Instructeur';

  @override
  String get orderDetailTotal => 'Totaal';

  @override
  String get orderDetailScheduled => 'Gepland';

  @override
  String get orderDetailAvailable => 'Beschikbaar';

  @override
  String get orderDetailPaymentMethod => 'Betaalwijze';

  @override
  String get orderDetailPaymentDigital => 'Online';

  @override
  String get orderDetailPaymentCash => 'Contant';

  @override
  String get orderDetailPaymentBalance => 'Saldo';

  @override
  String get orderDetailSectionLessons => 'Lessen';

  @override
  String get orderDetailNoLessons => 'Geen lesonderdelen gevonden.';

  @override
  String get orderDetailLesson => 'Les';

  @override
  String orderDetailLessonCount(int count) {
    return '$count lessen';
  }

  @override
  String orderDetailMinutesAvailable(String duration) {
    return '$duration vrij';
  }

  @override
  String get orderDetailScheduleButton => 'Inplannen';

  @override
  String get orderDetailSectionActions => 'Acties';

  @override
  String get orderDetailPayNow => 'Nu betalen';

  @override
  String get orderDetailMarkPaid => 'Markeer als betaald';

  @override
  String get orderDetailRequestPayment => 'Betaling aanvragen';

  @override
  String get orderDetailPaymentRequested => 'Betalingsverzoek verstuurd';

  @override
  String get orderDetailOpenInvoice => 'Factuur openen';

  @override
  String get orderDetailPaymentPageFailed =>
      'De betalingspagina kon niet worden geopend.';

  @override
  String get buyLessonsTitle => 'Lessen kopen';

  @override
  String get buyLessonsChoosePackage => 'Kies een lespakket';

  @override
  String buyLessonsPayButton(String amount) {
    return 'Betalen — $amount';
  }

  @override
  String get buyLessonsStepVehicle => '1. Voertuig';

  @override
  String buyLessonsVehicleFallback(int id) {
    return 'Voertuig $id';
  }

  @override
  String get buyLessonsStepLesson => '2. Les';

  @override
  String get buyLessonsChooseVehicleFirst => 'Kies eerst een voertuigtype.';

  @override
  String get buyLessonsNoPackages => 'Geen lespakketten beschikbaar.';

  @override
  String get buyLessonsStepQuantity => '3. Aantal';

  @override
  String get buyLessonsStepStudent => '4. Leerling';

  @override
  String get buyLessonsStepPaymentInstructor => '5. Betaalwijze';

  @override
  String get buyLessonsStepPaymentStudent => '4. Betaalwijze';

  @override
  String get buyLessonsPaymentOnline => 'Online';

  @override
  String get buyLessonsPaymentBalance => 'Saldo';

  @override
  String buyLessonsBalanceNote(String balance) {
    return 'Het bedrag wordt van je saldo afgeschreven. Je saldo: $balance';
  }

  @override
  String get buyLessonsMollieNote =>
      'Je doorgestuurd naar de veilige betaalpagina van Mollie.';

  @override
  String get buyLessonsAfterPurchase =>
      'Na de aankoop plan je je lessen in vanuit de bestelling.';

  @override
  String get buyLessonsOrderPlaced => 'Bestelling geplaatst';

  @override
  String get buyLessonsCompletePayment => 'Rond de betaling af';

  @override
  String get buyLessonsNoStudents => 'Je hebt nog geen leerlingen toegewezen.';

  @override
  String get buyLessonsChooseStudent => 'Kies een leerling';

  @override
  String get buyLessonsLessonTypeTrial => 'Proefles';

  @override
  String get buyLessonsLessonTypeBase => 'Basisles';

  @override
  String get buyLessonsLessonTypePack => 'Lespakket';

  @override
  String get buyLessonsLessonTypeExam => 'Examen';

  @override
  String buyLessonsTotalLine(String duration, String amount) {
    return '$duration les — $amount';
  }

  @override
  String get scheduleLessonTitle => 'Les inplannen';

  @override
  String get scheduleLessonChooseDateTime => 'Kies een datum en starttijd.';

  @override
  String get scheduleLessonFutureDate => 'De les moet in de toekomst liggen.';

  @override
  String get scheduleLessonScheduled => 'Les ingepland';

  @override
  String scheduleLessonAvailable(String duration) {
    return 'Nog $duration beschikbaar in dit pakket.';
  }

  @override
  String get scheduleLessonNoTimeLeft =>
      'Er is geen beschikbare lestijd meer in dit pakket.';

  @override
  String get scheduleLessonDate => 'Datum';

  @override
  String get scheduleLessonNotChosen => 'Nog niet gekozen';

  @override
  String get scheduleLessonStartTime => 'Starttijd';

  @override
  String get scheduleLessonDuration => 'Duur';

  @override
  String get scheduleLessonScheduleButton => 'Inplannen';

  @override
  String get languageLabel => 'Taal';

  @override
  String get languageSystem => 'Systeem (automatisch)';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get notifPrefLessonBooked => 'Les geboekt';

  @override
  String get notifPrefLessonReminder24h => 'Herinnering les (24 uur)';

  @override
  String get notifPrefLessonReminder1h => 'Herinnering les (1 uur)';

  @override
  String get notifPrefLessonCancelled => 'Les geannuleerd';

  @override
  String get notifPrefLessonChanged => 'Les gewijzigd';

  @override
  String get notifPrefLessonCompleted => 'Les afgerond';

  @override
  String get notifPrefPaymentSuccessful => 'Betaling geslaagd';

  @override
  String get notifPrefPaymentFailed => 'Betaling mislukt';

  @override
  String get notifPrefPaymentRefunded => 'Betaling terugbetaald';

  @override
  String get notifPrefPaymentRequested => 'Betalingsverzoek';

  @override
  String get notifPrefLowLessonCredit => 'Weinig lesuren over';

  @override
  String get notifPrefExamBooked => 'Examen geboekt';

  @override
  String get notifPrefExamReminder7d => 'Herinnering examen (7 dagen)';

  @override
  String get notifPrefExamReminder24h => 'Herinnering examen (24 uur)';

  @override
  String get notifPrefExamChanged => 'Examen gewijzigd';

  @override
  String get notifPrefExamCancelled => 'Examen geannuleerd';

  @override
  String get notifPrefLessonCardUpdated => 'Leskaart bijgewerkt';

  @override
  String get notifPrefInstructorFeedback => 'Instructeur feedback';

  @override
  String get notifPrefAccountSecurity => 'Accountbeveiliging';

  @override
  String get notifPrefLessons => 'Lessen';

  @override
  String get notifPrefPayments => 'Betalingen';

  @override
  String get notifPrefExams => 'Examens';

  @override
  String get notifPrefLessonCards => 'Leskaarten';

  @override
  String get notifPrefAccount => 'Account';

  @override
  String get notifPrefLocked => 'Altijd aan (kan niet worden uitgezet)';

  @override
  String get paymentReturnProcessing => 'Betaling verwerken…';

  @override
  String get paymentReturnSuccess => 'Betaling ontvangen';

  @override
  String get orderDetailOpenInvoiceFailed =>
      'De factuur kon niet worden geopend.';

  @override
  String get orderDetailDownloadInvoice => 'Downloaden';
}
