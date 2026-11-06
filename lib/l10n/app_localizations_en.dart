// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get genericSuccess => 'Success';

  @override
  String get noName => 'No name';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count hr';
  }

  @override
  String hoursMinutesShort(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navOrders => 'Orders';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPending => 'Pending';

  @override
  String get errTimeout =>
      'The connection to the server timed out. Please try again.';

  @override
  String get errOffline =>
      'No connection to the server. Check your internet connection.';

  @override
  String get errCancelled => 'Request cancelled.';

  @override
  String get errInsecure => 'Insecure connection to the server.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errTooManyRequests =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errInvalidData => 'The submitted data is invalid.';

  @override
  String get errSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errForbidden => 'You do not have access to this action.';

  @override
  String get errNotFound => 'This item could not be found.';

  @override
  String get errEmailTaken =>
      'An account with this email address already exists.';

  @override
  String get errServer =>
      'Something went wrong on the server. Please try again later.';

  @override
  String get errInvalidCredentials => 'Signing in failed. Please try again.';

  @override
  String get errUserNotFound => 'User not found.';

  @override
  String get errOrderNotFound => 'Order not found.';

  @override
  String get errLessonNotFound => 'Lesson not found.';

  @override
  String get errPaymentFailed => 'Starting the payment failed.';

  @override
  String get errEmptyInvoice => 'The invoice is empty.';

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardHello => 'Hello';

  @override
  String get dashboardUpcomingLessons => 'Upcoming lessons';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardBuyLessons => 'Buy lessons';

  @override
  String get dashboardTopUpBalance => 'Top up balance';

  @override
  String get dashboardRecentNotifications => 'Recent notifications';

  @override
  String get dashboardAllNotifications => 'All notifications';

  @override
  String get dashboardNotificationFallback => 'Notification';

  @override
  String get dashboardBalanceLabel => 'Balance';

  @override
  String get dashboardNoLessonsTitle => 'No lessons scheduled yet';

  @override
  String get dashboardNoLessonsSubtitle =>
      'Buy a lesson package to schedule your first lesson.';

  @override
  String get dashboardLessonFallback => 'Lesson';

  @override
  String get studentsTitle => 'My students';

  @override
  String get studentsSearchHint => 'Search student';

  @override
  String get studentsEmptyTitle => 'No students';

  @override
  String get studentsEmptySubtitle => 'No students are linked to you yet.';

  @override
  String get studentsEmailLabel => 'Email';

  @override
  String get studentsPhoneLabel => 'Phone';

  @override
  String get studentsAddressLabel => 'Address';

  @override
  String get studentsPickupLabel => 'Pickup location';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to manage your lessons';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginEmailRequired => 'Enter your email address';

  @override
  String get loginEmailInvalid => 'Enter a valid email address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginNoAccount => 'Don\'t have an account yet?';

  @override
  String get loginRegister => 'Sign up';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerAccountType => 'Account type';

  @override
  String get registerStudent => 'Student';

  @override
  String get registerInstructor => 'Instructor';

  @override
  String get registerPersonalDetails => 'Personal details';

  @override
  String get registerFirstName => 'First name';

  @override
  String get registerLastName => 'Last name';

  @override
  String get registerPhone => 'Phone number';

  @override
  String get registerBirthdate => 'Date of birth';

  @override
  String get registerBirthdateHint => 'yyyy-mm-dd';

  @override
  String get registerAddress => 'Address';

  @override
  String get registerStreet => 'Street';

  @override
  String get registerHouseNumber => 'House no.';

  @override
  String get registerZipCode => 'Postcode';

  @override
  String get registerCity => 'City';

  @override
  String get registerLessonDetails => 'Lesson details (optional)';

  @override
  String get registerPickupLocation => 'Pickup location';

  @override
  String get registerLicensePlate => 'Licence plate (own vehicle)';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordRules =>
      'At least 8 characters with a lowercase letter, an uppercase letter and a digit';

  @override
  String get registerPasswordMin8 => 'At least 8 characters';

  @override
  String get registerPasswordNeedsMix =>
      'Use a lowercase letter, an uppercase letter and a digit';

  @override
  String get registerPasswordRepeat => 'Repeat password';

  @override
  String get registerPasswordMismatch => 'Passwords do not match';

  @override
  String get registerRequired => 'Required field';

  @override
  String get registerOtpTitle => 'Confirmation code';

  @override
  String get registerOtpFallback =>
      'We have sent a code to your email address.';

  @override
  String get registerOtpLabel => 'Code from email';

  @override
  String get registerOtpRequired => 'Enter the 4-digit code';

  @override
  String get registerSubmitCreate => 'Create account';

  @override
  String get registerSubmitCode => 'Request code';

  @override
  String get registerHaveAccount => 'I already have an account';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotEnterCode => 'Enter the code';

  @override
  String get forgotResetTitle => 'Reset your password';

  @override
  String forgotCodeSentTo(String email) {
    return 'We have sent a code to $email.';
  }

  @override
  String get forgotEmailHint =>
      'Enter your email address and we will send you a recovery code.';

  @override
  String get forgotCodeLabel => 'Recovery code';

  @override
  String get forgotCodeRequired => 'Enter the code';

  @override
  String get forgotNewPassword => 'New password (optional)';

  @override
  String get forgotSubmitReset => 'Reset password';

  @override
  String get forgotSubmitSend => 'Send code';

  @override
  String get forgotResend => 'Resend code';

  @override
  String get forgotBackToLogin => 'Back to sign in';

  @override
  String get forgotCodeSent => 'We have sent a code to your email.';

  @override
  String get forgotPasswordChanged => 'Password changed. You can now sign in.';

  @override
  String get planningTitle => 'Planning';

  @override
  String get planningTabUpcoming => 'Upcoming';

  @override
  String get planningTabCompleted => 'Completed';

  @override
  String get planningTabCancelled => 'Cancelled';

  @override
  String get planningEmptyTitle => 'Nothing here yet';

  @override
  String get planningEmptySubtitle =>
      'There are no lessons in this category yet.';

  @override
  String get planningUnknownDate => 'Date unknown';

  @override
  String get planningLesson => 'Lesson';

  @override
  String get planningLessonScheduled => 'Lesson scheduled';

  @override
  String get planningLessonConfirmed => 'Lesson confirmed';

  @override
  String get planningLessonCancelled => 'Lesson cancelled';

  @override
  String get planningLessonCompleted => 'Lesson completed';

  @override
  String get planningLessonRescheduled => 'Lesson rescheduled';

  @override
  String get planningLogChange => 'Change';

  @override
  String get planningDetailTitle => 'Lesson details';

  @override
  String get planningDateNotSet => 'Date not set';

  @override
  String get planningSectionDetails => 'Details';

  @override
  String get planningInfoLessonType => 'Lesson type';

  @override
  String get planningTypeTrial => 'Trial lesson';

  @override
  String get planningTypeBase => 'Standard lesson';

  @override
  String get planningTypePack => 'Lesson package';

  @override
  String get planningTypeExam => 'Exam';

  @override
  String get planningInfoInstructor => 'Instructor';

  @override
  String get planningInfoStudent => 'Student';

  @override
  String get planningInfoPhone => 'Phone';

  @override
  String get planningInfoOrder => 'Order';

  @override
  String get planningInfoPaid => 'Paid';

  @override
  String get planningNotes => 'Notes';

  @override
  String get planningNotesSaved => 'Notes saved';

  @override
  String get planningCancelReasonTitle => 'Cancellation reason';

  @override
  String get planningCancelReasonLabel => 'Reason (optional)';

  @override
  String get planningSectionActions => 'Actions';

  @override
  String get planningSectionHistory => 'History';

  @override
  String get planningConfirmLesson => 'Confirm lesson';

  @override
  String get planningCancelLesson => 'Cancel lesson';

  @override
  String get planningRescheduleLesson => 'Reschedule lesson';

  @override
  String get planningCompleteLesson => 'Complete lesson';

  @override
  String get planningCompleteConfirmMessage =>
      'Are you sure you want to complete this lesson?';

  @override
  String get planningCompleteAction => 'Complete';

  @override
  String get planningEditNotes => 'Edit notes';

  @override
  String get planningWasPresent => 'I attended';

  @override
  String get planningWasAbsent => 'I was absent';

  @override
  String get planningReportAbsenceTitle => 'Report absence';

  @override
  String get planningConfirmAttendedMessage =>
      'Confirm that this lesson took place.';

  @override
  String get planningReportAbsentMessage =>
      'Report your absence. Your instructor and the office will be notified.';

  @override
  String get planningAttendanceConfirmed => 'Attendance confirmed';

  @override
  String get planningAbsenceReported => 'Absence reported';

  @override
  String get reschedulePickDateTime => 'Pick a date and start time.';

  @override
  String get rescheduleFutureDate => 'The new date must be in the future.';

  @override
  String get reschedulePickMoment => 'Pick a new time';

  @override
  String rescheduleDurationHint(String duration) {
    return 'The lesson lasts $duration and must be rescheduled at least 24 hours in advance.';
  }

  @override
  String get rescheduleDateLabel => 'Date';

  @override
  String get rescheduleStartTimeLabel => 'Start time';

  @override
  String get rescheduleNotChosen => 'Not chosen yet';

  @override
  String get lessonCardTitle => 'Lesson card';

  @override
  String get lessonCardView => 'View lesson card';

  @override
  String get lessonCardRefresh => 'Refresh';

  @override
  String get lessonCardEmptyTitle => 'No questions';

  @override
  String get lessonCardEmptySubtitle =>
      'No questions have been set up for this lesson yet.';

  @override
  String get lessonCardInstructorIntro => 'Rate your student for each section.';

  @override
  String get lessonCardStudentIntro => 'Fill in how your lesson went.';

  @override
  String get lessonCardSave => 'Save lesson card';

  @override
  String get lessonCardSaved => 'Lesson card saved';

  @override
  String get lessonCardFillFirst => 'Answer at least one question first.';

  @override
  String get lessonCardAnswerLabel => 'Answer / comment';

  @override
  String get lessonCardScoreLabel => 'Rating';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String get profileDeactivate => 'Deactivate account';

  @override
  String get profileDeactivateMessage =>
      'Your account will be deactivated and you will no longer be able to sign in. This cannot be undone.';

  @override
  String get profileDeactivateConfirm => 'Deactivate';

  @override
  String get profileAccountDeactivated => 'Account deactivated';

  @override
  String get profileTopUp => 'Top up';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileLicensePlate => 'Licence plate';

  @override
  String get profileNotificationSettings => 'Notification settings';

  @override
  String get editProfileTitle => 'Edit details';

  @override
  String get editProfileUpdated => 'Profile updated';

  @override
  String get editProfileGender => 'Gender';

  @override
  String get editProfileGenderMale => 'Male';

  @override
  String get editProfileGenderFemale => 'Female';

  @override
  String get editProfileGenderUnknown => 'Unknown';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordSuccess => 'Password changed';

  @override
  String get changePasswordSubmit => 'Save password';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsOpenSettings => 'Settings';

  @override
  String get notificationsRefreshFailed => 'Refreshing failed.';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle =>
      'Updates about your lessons and payments will show up here.';

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get notifSettingsQuietSection => 'Do not disturb';

  @override
  String get notifSettingsQuietHours => 'Quiet hours';

  @override
  String notifSettingsQuietRange(String start, String end) {
    return 'No notifications between $start and $end';
  }

  @override
  String get notifSettingsQuietStart => 'Start';

  @override
  String get notifSettingsQuietEnd => 'End';

  @override
  String get notifSettingsTypesSection => 'Notification types';

  @override
  String get notifSettingsSaved => 'Settings saved';

  @override
  String get topUpCurrentBalance => 'Current balance';

  @override
  String get topUpChooseAmount => 'Choose an amount';

  @override
  String get topUpCustomAmount => 'Custom amount';

  @override
  String topUpPayButton(String amount) {
    return 'Pay $amount';
  }

  @override
  String get topUpMollieNote =>
      'Payment via Mollie. Your balance is credited once the payment is confirmed.';

  @override
  String get topUpInvalidAmount => 'Enter a valid amount.';

  @override
  String get topUpCompletePayment =>
      'Complete the payment to top up your balance.';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get ordersBuyButton => 'Buy';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptySubtitle =>
      'Buy your first lesson package to schedule lessons.';

  @override
  String ordersOrderNumber(int id) {
    return 'Order #$id';
  }

  @override
  String get ordersPaymentPaid => 'Paid';

  @override
  String get ordersPaymentOpen => 'Open';

  @override
  String get ordersPaymentPending => 'Pending';

  @override
  String get ordersPaymentFailed => 'Failed';

  @override
  String get ordersPaymentCanceled => 'Cancelled';

  @override
  String get ordersPaymentExpired => 'Expired';

  @override
  String get ordersPaymentUnpaid => 'Not paid yet';

  @override
  String ordersTotalDuration(String duration) {
    return '$duration lesson';
  }

  @override
  String orderDetailTitle(int id) {
    return 'Order #$id';
  }

  @override
  String orderDetailPlacedOn(String date) {
    return 'Placed on $date';
  }

  @override
  String get orderDetailSectionDetails => 'Details';

  @override
  String get orderDetailStudent => 'Student';

  @override
  String get orderDetailInstructor => 'Instructor';

  @override
  String get orderDetailTotal => 'Total';

  @override
  String get orderDetailScheduled => 'Scheduled';

  @override
  String get orderDetailAvailable => 'Available';

  @override
  String get orderDetailPaymentMethod => 'Payment method';

  @override
  String get orderDetailPaymentDigital => 'Online';

  @override
  String get orderDetailPaymentCash => 'Cash';

  @override
  String get orderDetailPaymentBalance => 'Balance';

  @override
  String get orderDetailSectionLessons => 'Lessons';

  @override
  String get orderDetailNoLessons => 'No lesson items found.';

  @override
  String get orderDetailLesson => 'Lesson';

  @override
  String orderDetailLessonCount(int count) {
    return '$count lessons';
  }

  @override
  String orderDetailMinutesAvailable(String duration) {
    return '$duration available';
  }

  @override
  String get orderDetailScheduleButton => 'Schedule';

  @override
  String get orderDetailSectionActions => 'Actions';

  @override
  String get orderDetailPayNow => 'Pay now';

  @override
  String get orderDetailMarkPaid => 'Mark as paid';

  @override
  String get orderDetailRequestPayment => 'Request payment';

  @override
  String get orderDetailPaymentRequested => 'Payment request sent';

  @override
  String get orderDetailOpenInvoice => 'Open invoice';

  @override
  String get orderDetailPaymentPageFailed => 'Could not open the payment page.';

  @override
  String get buyLessonsTitle => 'Buy lessons';

  @override
  String get buyLessonsChoosePackage => 'Choose a lesson package';

  @override
  String buyLessonsPayButton(String amount) {
    return 'Pay — $amount';
  }

  @override
  String get buyLessonsStepVehicle => '1. Vehicle';

  @override
  String buyLessonsVehicleFallback(int id) {
    return 'Vehicle $id';
  }

  @override
  String get buyLessonsStepLesson => '2. Lesson';

  @override
  String get buyLessonsChooseVehicleFirst => 'Choose a vehicle type first.';

  @override
  String get buyLessonsNoPackages => 'No lesson packages available.';

  @override
  String get buyLessonsStepQuantity => '3. Quantity';

  @override
  String get buyLessonsStepStudent => '4. Student';

  @override
  String get buyLessonsStepPaymentInstructor => '5. Payment method';

  @override
  String get buyLessonsStepPaymentStudent => '4. Payment method';

  @override
  String get buyLessonsPaymentOnline => 'Online';

  @override
  String get buyLessonsPaymentBalance => 'Balance';

  @override
  String buyLessonsBalanceNote(String balance) {
    return 'The amount will be deducted from your balance. Your balance: $balance';
  }

  @override
  String get buyLessonsMollieNote =>
      'You will be redirected to Mollie\'s secure payment page.';

  @override
  String get buyLessonsAfterPurchase =>
      'After purchase you schedule your lessons from the order.';

  @override
  String get buyLessonsOrderPlaced => 'Order placed';

  @override
  String get buyLessonsCompletePayment => 'Complete the payment';

  @override
  String get buyLessonsNoStudents => 'You have no students assigned yet.';

  @override
  String get buyLessonsChooseStudent => 'Choose a student';

  @override
  String get buyLessonsLessonTypeTrial => 'Trial lesson';

  @override
  String get buyLessonsLessonTypeBase => 'Basic lesson';

  @override
  String get buyLessonsLessonTypePack => 'Lesson package';

  @override
  String get buyLessonsLessonTypeExam => 'Exam';

  @override
  String buyLessonsTotalLine(String duration, String amount) {
    return '$duration lesson — $amount';
  }

  @override
  String get scheduleLessonTitle => 'Schedule lesson';

  @override
  String get scheduleLessonChooseDateTime => 'Choose a date and start time.';

  @override
  String get scheduleLessonFutureDate => 'The lesson must be in the future.';

  @override
  String get scheduleLessonScheduled => 'Lesson scheduled';

  @override
  String scheduleLessonAvailable(String duration) {
    return '$duration available in this package.';
  }

  @override
  String get scheduleLessonNoTimeLeft => 'No lesson time left in this package.';

  @override
  String get scheduleLessonDate => 'Date';

  @override
  String get scheduleLessonNotChosen => 'Not chosen yet';

  @override
  String get scheduleLessonStartTime => 'Start time';

  @override
  String get scheduleLessonDuration => 'Duration';

  @override
  String get scheduleLessonScheduleButton => 'Schedule';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System (automatic)';

  @override
  String get languageDutch => 'Dutch';

  @override
  String get languageEnglish => 'English';

  @override
  String get notifPrefLessonBooked => 'Lesson booked';

  @override
  String get notifPrefLessonReminder24h => 'Lesson reminder (24 hours)';

  @override
  String get notifPrefLessonReminder1h => 'Lesson reminder (1 hour)';

  @override
  String get notifPrefLessonCancelled => 'Lesson cancelled';

  @override
  String get notifPrefLessonChanged => 'Lesson changed';

  @override
  String get notifPrefLessonCompleted => 'Lesson completed';

  @override
  String get notifPrefPaymentSuccessful => 'Payment successful';

  @override
  String get notifPrefPaymentFailed => 'Payment failed';

  @override
  String get notifPrefPaymentRefunded => 'Payment refunded';

  @override
  String get notifPrefPaymentRequested => 'Payment request';

  @override
  String get notifPrefLowLessonCredit => 'Low lesson credit';

  @override
  String get notifPrefExamBooked => 'Exam booked';

  @override
  String get notifPrefExamReminder7d => 'Exam reminder (7 days)';

  @override
  String get notifPrefExamReminder24h => 'Exam reminder (24 hours)';

  @override
  String get notifPrefExamChanged => 'Exam changed';

  @override
  String get notifPrefExamCancelled => 'Exam cancelled';

  @override
  String get notifPrefLessonCardUpdated => 'Lesson card updated';

  @override
  String get notifPrefInstructorFeedback => 'Instructor feedback';

  @override
  String get notifPrefAccountSecurity => 'Account security';

  @override
  String get notifPrefLessons => 'Lessons';

  @override
  String get notifPrefPayments => 'Payments';

  @override
  String get notifPrefExams => 'Exams';

  @override
  String get notifPrefLessonCards => 'Lesson cards';

  @override
  String get notifPrefAccount => 'Account';

  @override
  String get notifPrefLocked => 'Always on (cannot be turned off)';

  @override
  String get paymentReturnProcessing => 'Processing payment…';

  @override
  String get paymentReturnSuccess => 'Payment received';
}
