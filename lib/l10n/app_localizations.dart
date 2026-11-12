import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @dashboard_greeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا، {name} 👋'**
  String dashboard_greeting(String name);

  /// No description provided for @dashboard_open.
  ///
  /// In ar, this message translates to:
  /// **'محادثات مفتوحة'**
  String get dashboard_open;

  /// No description provided for @dashboard_waiting_sla.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت وقت الانتظار'**
  String get dashboard_waiting_sla;

  /// No description provided for @dashboard_view_queue.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة الانتظار'**
  String get dashboard_view_queue;

  /// No description provided for @dashboard_first_response.
  ///
  /// In ar, this message translates to:
  /// **'متوسط أول رد'**
  String get dashboard_first_response;

  /// No description provided for @dashboard_resolved_today.
  ///
  /// In ar, this message translates to:
  /// **'محلولة اليوم'**
  String get dashboard_resolved_today;

  /// No description provided for @dashboard_ai_rate.
  ///
  /// In ar, this message translates to:
  /// **'حلّها الذكاء الاصطناعي'**
  String get dashboard_ai_rate;

  /// No description provided for @dashboard_csat.
  ///
  /// In ar, this message translates to:
  /// **'رضا العملاء'**
  String get dashboard_csat;

  /// No description provided for @dashboard_csat_scale.
  ///
  /// In ar, this message translates to:
  /// **'من 5'**
  String get dashboard_csat_scale;

  /// No description provided for @dashboard_vs_yesterday.
  ///
  /// In ar, this message translates to:
  /// **'{delta} عن أمس'**
  String dashboard_vs_yesterday(String delta);

  /// No description provided for @dashboard_volume_title.
  ///
  /// In ar, this message translates to:
  /// **'حجم المحادثات اليوم'**
  String get dashboard_volume_title;

  /// No description provided for @dashboard_volume_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{total} محادثة اليوم، الذروة {peak} عند الساعة {hour}'**
  String dashboard_volume_a11y(int total, int peak, String hour);

  /// No description provided for @dashboard_channels_title.
  ///
  /// In ar, this message translates to:
  /// **'حسب القناة'**
  String get dashboard_channels_title;

  /// No description provided for @dashboard_ai_usage_title.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الذكاء الاصطناعي'**
  String get dashboard_ai_usage_title;

  /// No description provided for @dashboard_ai_manage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة'**
  String get dashboard_ai_manage;

  /// No description provided for @dashboard_ai_usage_value.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {quota} ردًّا هذا الشهر'**
  String dashboard_ai_usage_value(int used, int quota);

  /// No description provided for @dashboard_team_title.
  ///
  /// In ar, this message translates to:
  /// **'الفريق الآن'**
  String get dashboard_team_title;

  /// No description provided for @dashboard_team_open.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا محادثات} =1{محادثة واحدة} =2{محادثتان} few{{count} محادثات} other{{count} محادثة}}'**
  String dashboard_team_open(int count);

  /// No description provided for @notifications_title.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications_title;

  /// No description provided for @notifications_mark_all.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get notifications_mark_all;

  /// No description provided for @notifications_earlier.
  ///
  /// In ar, this message translates to:
  /// **'سابقًا'**
  String get notifications_earlier;

  /// No description provided for @notifications_empty_title.
  ///
  /// In ar, this message translates to:
  /// **'لا إشعارات بعد'**
  String get notifications_empty_title;

  /// No description provided for @notifications_empty_body.
  ///
  /// In ar, this message translates to:
  /// **'سنخبرك عند إسناد محادثة إليك أو ذكرك في ملاحظة.'**
  String get notifications_empty_body;

  /// No description provided for @knowledge_search.
  ///
  /// In ar, this message translates to:
  /// **'بحث في المعرفة'**
  String get knowledge_search;

  /// No description provided for @knowledge_search_hint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الإجابات…'**
  String get knowledge_search_hint;

  /// No description provided for @knowledge_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إجابة'**
  String get knowledge_add;

  /// No description provided for @knowledge_filter_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get knowledge_filter_all;

  /// No description provided for @knowledge_type_faq.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة شائعة'**
  String get knowledge_type_faq;

  /// No description provided for @knowledge_type_policy.
  ///
  /// In ar, this message translates to:
  /// **'سياسات'**
  String get knowledge_type_policy;

  /// No description provided for @knowledge_type_product.
  ///
  /// In ar, this message translates to:
  /// **'منتجات'**
  String get knowledge_type_product;

  /// No description provided for @knowledge_type_snippet.
  ///
  /// In ar, this message translates to:
  /// **'ردود جاهزة'**
  String get knowledge_type_snippet;

  /// No description provided for @knowledge_type_website.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get knowledge_type_website;

  /// No description provided for @knowledge_coverage_title.
  ///
  /// In ar, this message translates to:
  /// **'ما يعرفه الذكاء الاصطناعي'**
  String get knowledge_coverage_title;

  /// No description provided for @knowledge_coverage_body.
  ///
  /// In ar, this message translates to:
  /// **'{total, plural, =1{إجابة واحدة} =2{إجابتان} few{{total} إجابات} other{{total} إجابة}}، منها {enabled} مفعّلة'**
  String knowledge_coverage_body(int total, int enabled);

  /// No description provided for @knowledge_coverage_top.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر استخدامًا: {title}'**
  String knowledge_coverage_top(String title);

  /// No description provided for @knowledge_used.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لم تُستخدم بعد} =1{استُخدمت مرة} =2{استُخدمت مرتين} few{استُخدمت {count} مرات} other{استُخدمت {count} مرة}}'**
  String knowledge_used(int count);

  /// No description provided for @knowledge_updated.
  ///
  /// In ar, this message translates to:
  /// **'حُدّثت {time}'**
  String knowledge_updated(String time);

  /// No description provided for @knowledge_disabled.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة'**
  String get knowledge_disabled;

  /// No description provided for @knowledge_enabled_a11y.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل «{title}»'**
  String knowledge_enabled_a11y(String title);

  /// No description provided for @knowledge_empty_title.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة المعرفة فارغة'**
  String get knowledge_empty_title;

  /// No description provided for @knowledge_empty_body.
  ///
  /// In ar, this message translates to:
  /// **'أضف إجابات وسياسات ليستخدمها الذكاء الاصطناعي في اقتراح الردود.'**
  String get knowledge_empty_body;

  /// No description provided for @knowledge_empty_filtered.
  ///
  /// In ar, this message translates to:
  /// **'لا إجابات من هذا النوع'**
  String get knowledge_empty_filtered;

  /// No description provided for @knowledge_no_results.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج لـ «{query}»'**
  String knowledge_no_results(String query);

  /// No description provided for @knowledge_edit_title_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إجابة'**
  String get knowledge_edit_title_add;

  /// No description provided for @knowledge_edit_title_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإجابة'**
  String get knowledge_edit_title_edit;

  /// No description provided for @knowledge_edit_type.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get knowledge_edit_type;

  /// No description provided for @knowledge_edit_question.
  ///
  /// In ar, this message translates to:
  /// **'السؤال'**
  String get knowledge_edit_question;

  /// No description provided for @knowledge_edit_title_label.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get knowledge_edit_title_label;

  /// No description provided for @knowledge_edit_title_hint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: كم مدة التوصيل؟'**
  String get knowledge_edit_title_hint;

  /// No description provided for @knowledge_edit_body_label.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة'**
  String get knowledge_edit_body_label;

  /// No description provided for @knowledge_edit_body_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الإجابة كما تريد أن يقولها الذكاء الاصطناعي…'**
  String get knowledge_edit_body_hint;

  /// No description provided for @knowledge_edit_counter.
  ///
  /// In ar, this message translates to:
  /// **'{count} / {max}'**
  String knowledge_edit_counter(int count, int max);

  /// No description provided for @knowledge_edit_keywords.
  ///
  /// In ar, this message translates to:
  /// **'كلمات مفتاحية'**
  String get knowledge_edit_keywords;

  /// No description provided for @knowledge_edit_keywords_hint.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلمة واضغط إدخال'**
  String get knowledge_edit_keywords_hint;

  /// No description provided for @knowledge_edit_keyword_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كلمة مفتاحية'**
  String get knowledge_edit_keyword_add;

  /// No description provided for @knowledge_edit_enabled.
  ///
  /// In ar, this message translates to:
  /// **'متاحة للذكاء الاصطناعي'**
  String get knowledge_edit_enabled;

  /// No description provided for @knowledge_edit_enabled_sub.
  ///
  /// In ar, this message translates to:
  /// **'عند الإيقاف لن تُستخدم في الاقتراحات'**
  String get knowledge_edit_enabled_sub;

  /// No description provided for @knowledge_edit_preview_title.
  ///
  /// In ar, this message translates to:
  /// **'كيف سيستخدمها الذكاء الاصطناعي'**
  String get knowledge_edit_preview_title;

  /// No description provided for @knowledge_edit_preview_q.
  ///
  /// In ar, this message translates to:
  /// **'سؤال العميل يظهر هنا'**
  String get knowledge_edit_preview_q;

  /// No description provided for @knowledge_edit_preview_a.
  ///
  /// In ar, this message translates to:
  /// **'وهنا الرد المقترح بناءً على إجابتك'**
  String get knowledge_edit_preview_a;

  /// No description provided for @knowledge_edit_error_title.
  ///
  /// In ar, this message translates to:
  /// **'العنوان مطلوب'**
  String get knowledge_edit_error_title;

  /// No description provided for @knowledge_edit_error_body.
  ///
  /// In ar, this message translates to:
  /// **'اكتب إجابة من 10 أحرف على الأقل'**
  String get knowledge_edit_error_body;

  /// No description provided for @knowledge_edit_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإجابة'**
  String get knowledge_edit_saved;

  /// No description provided for @knowledge_edit_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإجابة'**
  String get knowledge_edit_delete;

  /// No description provided for @knowledge_edit_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه الإجابة؟'**
  String get knowledge_edit_delete_title;

  /// No description provided for @knowledge_edit_delete_body.
  ///
  /// In ar, this message translates to:
  /// **'لن يستخدمها الذكاء الاصطناعي بعد الآن في اقتراح الردود.'**
  String get knowledge_edit_delete_body;

  /// No description provided for @knowledge_edit_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الإجابة'**
  String get knowledge_edit_deleted;

  /// No description provided for @knowledge_edit_discard_title.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التغييرات؟'**
  String get knowledge_edit_discard_title;

  /// No description provided for @knowledge_edit_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لديك تعديلات غير محفوظة ستضيع إذا خرجت الآن.'**
  String get knowledge_edit_discard_body;

  /// No description provided for @knowledge_edit_discard_confirm.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل والخروج'**
  String get knowledge_edit_discard_confirm;

  /// No description provided for @account_section_admin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get account_section_admin;

  /// No description provided for @account_section_app.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get account_section_app;

  /// No description provided for @account_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب الخاص بك'**
  String get account_whatsapp;

  /// No description provided for @account_whatsapp_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get account_whatsapp_connected;

  /// No description provided for @account_whatsapp_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get account_whatsapp_disconnected;

  /// No description provided for @account_channels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get account_channels;

  /// No description provided for @account_ai_agent.
  ///
  /// In ar, this message translates to:
  /// **'وكيل الذكاء الاصطناعي'**
  String get account_ai_agent;

  /// No description provided for @account_team.
  ///
  /// In ar, this message translates to:
  /// **'الفريق والمستخدمون'**
  String get account_team;

  /// No description provided for @account_subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get account_subscription;

  /// No description provided for @account_notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get account_notifications;

  /// No description provided for @account_language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get account_language;

  /// No description provided for @account_appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get account_appearance;

  /// No description provided for @account_theme_light.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get account_theme_light;

  /// No description provided for @account_theme_dark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get account_theme_dark;

  /// No description provided for @account_theme_system.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get account_theme_system;

  /// No description provided for @account_theme_system_sub.
  ///
  /// In ar, this message translates to:
  /// **'يتبع إعدادات الجهاز'**
  String get account_theme_system_sub;

  /// No description provided for @account_help.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والشروحات'**
  String get account_help;

  /// No description provided for @account_logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get account_logout;

  /// No description provided for @account_logout_title.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get account_logout_title;

  /// No description provided for @account_logout_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك إشعارات المحادثات على هذا الجهاز حتى تسجّل الدخول مجددًا.'**
  String get account_logout_body;

  /// No description provided for @account_version.
  ///
  /// In ar, this message translates to:
  /// **'Wavadesk {version}'**
  String account_version(String version);

  /// No description provided for @account_network_online.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get account_network_online;

  /// No description provided for @ai_settings_title.
  ///
  /// In ar, this message translates to:
  /// **'وكيل الذكاء الاصطناعي'**
  String get ai_settings_title;

  /// No description provided for @ai_settings_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل وكيل الذكاء الاصطناعي'**
  String get ai_settings_enable;

  /// No description provided for @ai_settings_status_on.
  ///
  /// In ar, this message translates to:
  /// **'يعمل ويقترح الردود'**
  String get ai_settings_status_on;

  /// No description provided for @ai_settings_status_off.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get ai_settings_status_off;

  /// No description provided for @ai_settings_usage.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {quota} ردًّا هذا الشهر'**
  String ai_settings_usage(int used, int quota);

  /// No description provided for @ai_settings_section_behavior.
  ///
  /// In ar, this message translates to:
  /// **'السلوك'**
  String get ai_settings_section_behavior;

  /// No description provided for @ai_settings_suggest.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح الردود'**
  String get ai_settings_suggest;

  /// No description provided for @ai_settings_suggest_sub.
  ///
  /// In ar, this message translates to:
  /// **'مسودة جاهزة قبل أن تفتح المحادثة'**
  String get ai_settings_suggest_sub;

  /// No description provided for @ai_settings_auto.
  ///
  /// In ar, this message translates to:
  /// **'الرد التلقائي'**
  String get ai_settings_auto;

  /// No description provided for @ai_settings_auto_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرد على المحادثات غير المُسندة دون انتظار'**
  String get ai_settings_auto_sub;

  /// No description provided for @ai_settings_claimed.
  ///
  /// In ar, this message translates to:
  /// **'الرد حتى بعد الاستلام'**
  String get ai_settings_claimed;

  /// No description provided for @ai_settings_claimed_sub.
  ///
  /// In ar, this message translates to:
  /// **'يستمر في الرد بعد أن يستلم موظف المحادثة'**
  String get ai_settings_claimed_sub;

  /// No description provided for @ai_settings_handoff.
  ///
  /// In ar, this message translates to:
  /// **'التحويل عند الاستياء'**
  String get ai_settings_handoff;

  /// No description provided for @ai_settings_handoff_sub.
  ///
  /// In ar, this message translates to:
  /// **'يحوّل المحادثة للفريق إذا بدا العميل منزعجًا'**
  String get ai_settings_handoff_sub;

  /// No description provided for @ai_settings_section_tone.
  ///
  /// In ar, this message translates to:
  /// **'أسلوب الرد'**
  String get ai_settings_section_tone;

  /// No description provided for @ai_settings_tone_friendly.
  ///
  /// In ar, this message translates to:
  /// **'ودّي'**
  String get ai_settings_tone_friendly;

  /// No description provided for @ai_settings_tone_friendly_sub.
  ///
  /// In ar, this message translates to:
  /// **'دافئ وقريب من العميل'**
  String get ai_settings_tone_friendly_sub;

  /// No description provided for @ai_settings_tone_formal.
  ///
  /// In ar, this message translates to:
  /// **'رسمي'**
  String get ai_settings_tone_formal;

  /// No description provided for @ai_settings_tone_formal_sub.
  ///
  /// In ar, this message translates to:
  /// **'مهذب ومهني'**
  String get ai_settings_tone_formal_sub;

  /// No description provided for @ai_settings_tone_concise.
  ///
  /// In ar, this message translates to:
  /// **'مختصر'**
  String get ai_settings_tone_concise;

  /// No description provided for @ai_settings_tone_concise_sub.
  ///
  /// In ar, this message translates to:
  /// **'جمل قصيرة ومباشرة'**
  String get ai_settings_tone_concise_sub;

  /// No description provided for @ai_settings_section_knowledge.
  ///
  /// In ar, this message translates to:
  /// **'مصدر المعرفة'**
  String get ai_settings_section_knowledge;

  /// No description provided for @ai_settings_knowledge.
  ///
  /// In ar, this message translates to:
  /// **'الإجابات المفعّلة'**
  String get ai_settings_knowledge;

  /// No description provided for @ai_settings_knowledge_footer.
  ///
  /// In ar, this message translates to:
  /// **'يعتمد الذكاء الاصطناعي على قاعدة المعرفة فقط ولا يخترع معلومات.'**
  String get ai_settings_knowledge_footer;

  /// No description provided for @whatsapp_title.
  ///
  /// In ar, this message translates to:
  /// **'واتساب الخاص بك'**
  String get whatsapp_title;

  /// No description provided for @whatsapp_status_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get whatsapp_status_connected;

  /// No description provided for @whatsapp_status_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get whatsapp_status_disconnected;

  /// No description provided for @whatsapp_since.
  ///
  /// In ar, this message translates to:
  /// **'متصل منذ'**
  String get whatsapp_since;

  /// No description provided for @whatsapp_messages_today.
  ///
  /// In ar, this message translates to:
  /// **'رسائل اليوم'**
  String get whatsapp_messages_today;

  /// No description provided for @whatsapp_connected_tip.
  ///
  /// In ar, this message translates to:
  /// **'أبقِ هاتفك متصلًا بالإنترنت. إذا سجّلت الخروج من واتساب على الهاتف ستحتاج لمسح الرمز من جديد.'**
  String get whatsapp_connected_tip;

  /// No description provided for @whatsapp_disconnect.
  ///
  /// In ar, this message translates to:
  /// **'قطع الاتصال'**
  String get whatsapp_disconnect;

  /// No description provided for @whatsapp_disconnect_title.
  ///
  /// In ar, this message translates to:
  /// **'قطع اتصال واتساب؟'**
  String get whatsapp_disconnect_title;

  /// No description provided for @whatsapp_disconnect_body.
  ///
  /// In ar, this message translates to:
  /// **'ستتوقف رسائل العملاء عن الوصول إلى المحادثات حتى تعيد ربط الرقم.'**
  String get whatsapp_disconnect_body;

  /// No description provided for @whatsapp_qr_a11y.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR لربط واتساب'**
  String get whatsapp_qr_a11y;

  /// No description provided for @whatsapp_qr_expires.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي الرمز خلال دقيقة'**
  String get whatsapp_qr_expires;

  /// No description provided for @whatsapp_waiting_scan.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المسح من هاتفك…'**
  String get whatsapp_waiting_scan;

  /// No description provided for @whatsapp_steps_title.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الربط'**
  String get whatsapp_steps_title;

  /// No description provided for @whatsapp_step1.
  ///
  /// In ar, this message translates to:
  /// **'افتح واتساب على هاتف العمل'**
  String get whatsapp_step1;

  /// No description provided for @whatsapp_step2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط ⋮ ثم «الأجهزة المرتبطة»'**
  String get whatsapp_step2;

  /// No description provided for @whatsapp_step3.
  ///
  /// In ar, this message translates to:
  /// **'اختر «ربط جهاز»'**
  String get whatsapp_step3;

  /// No description provided for @whatsapp_step4.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا نحو هذا الرمز'**
  String get whatsapp_step4;

  /// No description provided for @whatsapp_simulate_scan.
  ///
  /// In ar, this message translates to:
  /// **'مسح الرمز (تجريبي)'**
  String get whatsapp_simulate_scan;

  /// No description provided for @whatsapp_new_code.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رمز جديد'**
  String get whatsapp_new_code;

  /// No description provided for @whatsapp_connected_toast.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط واتساب بنجاح'**
  String get whatsapp_connected_toast;

  /// No description provided for @channels_title.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get channels_title;

  /// No description provided for @channels_section_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصلة'**
  String get channels_section_connected;

  /// No description provided for @channels_section_available.
  ///
  /// In ar, this message translates to:
  /// **'متاحة للربط'**
  String get channels_section_available;

  /// No description provided for @channels_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصلة وتستقبل الرسائل'**
  String get channels_connected;

  /// No description provided for @channels_not_connected.
  ///
  /// In ar, this message translates to:
  /// **'غير مربوطة'**
  String get channels_not_connected;

  /// No description provided for @channels_manage_on_web.
  ///
  /// In ar, this message translates to:
  /// **'إدارة هذه القناة متاحة من لوحة الويب'**
  String get channels_manage_on_web;

  /// No description provided for @channels_footer.
  ///
  /// In ar, this message translates to:
  /// **'تصل رسائل كل القنوات المربوطة إلى صندوق واحد.'**
  String get channels_footer;

  /// No description provided for @team_title.
  ///
  /// In ar, this message translates to:
  /// **'الفريق والمستخدمون'**
  String get team_title;

  /// No description provided for @team_invite.
  ///
  /// In ar, this message translates to:
  /// **'دعوة زميل'**
  String get team_invite;

  /// No description provided for @team_invite_sent.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رابط الدعوة'**
  String get team_invite_sent;

  /// No description provided for @team_section_members.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{عضو واحد} =2{عضوان} few{{count} أعضاء} other{{count} عضوًا}}'**
  String team_section_members(int count);

  /// No description provided for @team_section_teams.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get team_section_teams;

  /// No description provided for @team_you.
  ///
  /// In ar, this message translates to:
  /// **'{name} (أنت)'**
  String team_you(String name);

  /// No description provided for @team_members.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{عضو واحد} =2{عضوان} few{{count} أعضاء} other{{count} عضوًا}}'**
  String team_members(int count);

  /// No description provided for @subscription_title.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription_title;

  /// No description provided for @subscription_current.
  ///
  /// In ar, this message translates to:
  /// **'باقتك الحالية'**
  String get subscription_current;

  /// No description provided for @subscription_plan_name.
  ///
  /// In ar, this message translates to:
  /// **'الاحترافية'**
  String get subscription_plan_name;

  /// No description provided for @subscription_price.
  ///
  /// In ar, this message translates to:
  /// **'199 ر.س / شهريًا'**
  String get subscription_price;

  /// No description provided for @subscription_renews.
  ///
  /// In ar, this message translates to:
  /// **'تتجدد في {date}'**
  String subscription_renews(String date);

  /// No description provided for @subscription_section_usage.
  ///
  /// In ar, this message translates to:
  /// **'الاستخدام هذا الشهر'**
  String get subscription_section_usage;

  /// No description provided for @subscription_ai_replies.
  ///
  /// In ar, this message translates to:
  /// **'ردود الذكاء الاصطناعي'**
  String get subscription_ai_replies;

  /// No description provided for @subscription_agents.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get subscription_agents;

  /// No description provided for @subscription_channels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get subscription_channels;

  /// No description provided for @subscription_usage.
  ///
  /// In ar, this message translates to:
  /// **'{used} / {total}'**
  String subscription_usage(String used, String total);

  /// No description provided for @subscription_upgrade.
  ///
  /// In ar, this message translates to:
  /// **'ترقية الباقة'**
  String get subscription_upgrade;

  /// No description provided for @subscription_invoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get subscription_invoices;

  /// No description provided for @subscription_upgrade_web.
  ///
  /// In ar, this message translates to:
  /// **'سنفتح صفحة الفوترة على الويب'**
  String get subscription_upgrade_web;

  /// No description provided for @notif_settings_title.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notif_settings_title;

  /// No description provided for @notif_settings_section_push.
  ///
  /// In ar, this message translates to:
  /// **'أبلغني عند'**
  String get notif_settings_section_push;

  /// No description provided for @notif_settings_assigned.
  ///
  /// In ar, this message translates to:
  /// **'إسناد محادثة إليّ'**
  String get notif_settings_assigned;

  /// No description provided for @notif_settings_assigned_sub.
  ///
  /// In ar, this message translates to:
  /// **'عندما يسندها زميل أو قاعدة توزيع'**
  String get notif_settings_assigned_sub;

  /// No description provided for @notif_settings_mentions.
  ///
  /// In ar, this message translates to:
  /// **'ذكري في ملاحظة'**
  String get notif_settings_mentions;

  /// No description provided for @notif_settings_mentions_sub.
  ///
  /// In ar, this message translates to:
  /// **'عندما يكتب زميل ‎@اسمك'**
  String get notif_settings_mentions_sub;

  /// No description provided for @notif_settings_waiting.
  ///
  /// In ar, this message translates to:
  /// **'تجاوز وقت الانتظار'**
  String get notif_settings_waiting;

  /// No description provided for @notif_settings_waiting_sub.
  ///
  /// In ar, this message translates to:
  /// **'عميل ينتظر أكثر من الوقت المستهدف'**
  String get notif_settings_waiting_sub;

  /// No description provided for @notif_settings_section_sound.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get notif_settings_section_sound;

  /// No description provided for @notif_settings_sound.
  ///
  /// In ar, this message translates to:
  /// **'صوت الإشعار'**
  String get notif_settings_sound;

  /// No description provided for @notif_settings_sound_sub.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل صوت عند وصول رسالة جديدة'**
  String get notif_settings_sound_sub;

  /// No description provided for @notif_settings_footer.
  ///
  /// In ar, this message translates to:
  /// **'لا تصلك إشعارات عندما تكون حالتك «غير متاح».'**
  String get notif_settings_footer;

  /// No description provided for @help_title.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والشروحات'**
  String get help_title;

  /// No description provided for @help_section_guides.
  ///
  /// In ar, this message translates to:
  /// **'الشروحات'**
  String get help_section_guides;

  /// No description provided for @help_topic_claim.
  ///
  /// In ar, this message translates to:
  /// **'استلام المحادثات وإسنادها'**
  String get help_topic_claim;

  /// No description provided for @help_topic_ai.
  ///
  /// In ar, this message translates to:
  /// **'كيف تعمل اقتراحات الذكاء الاصطناعي'**
  String get help_topic_ai;

  /// No description provided for @help_topic_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'ربط رقم واتساب'**
  String get help_topic_whatsapp;

  /// No description provided for @help_topic_knowledge.
  ///
  /// In ar, this message translates to:
  /// **'بناء قاعدة المعرفة'**
  String get help_topic_knowledge;

  /// No description provided for @help_topic_snooze.
  ///
  /// In ar, this message translates to:
  /// **'التأجيل والإغلاق'**
  String get help_topic_snooze;

  /// No description provided for @help_section_contact.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get help_section_contact;

  /// No description provided for @help_contact_chat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة مع الدعم'**
  String get help_contact_chat;

  /// No description provided for @help_contact_chat_sub.
  ///
  /// In ar, this message translates to:
  /// **'نرد عادة خلال دقائق'**
  String get help_contact_chat_sub;

  /// No description provided for @help_contact_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get help_contact_email;

  /// No description provided for @help_opening.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الفتح…'**
  String get help_opening;

  /// No description provided for @account_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحميل'**
  String get account_load_error;

  /// No description provided for @subscription_ends.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي في {date}'**
  String subscription_ends(String date);

  /// No description provided for @subscription_trial_ends.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي الفترة التجريبية في {date}'**
  String subscription_trial_ends(String date);

  /// No description provided for @subscription_trial.
  ///
  /// In ar, this message translates to:
  /// **'فترة تجريبية'**
  String get subscription_trial;

  /// No description provided for @subscription_unlimited.
  ///
  /// In ar, this message translates to:
  /// **'غير محدود'**
  String get subscription_unlimited;

  /// No description provided for @subscription_no_plan.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد باقة'**
  String get subscription_no_plan;

  /// No description provided for @subscription_per_month.
  ///
  /// In ar, this message translates to:
  /// **'{price} / شهريًا'**
  String subscription_per_month(String price);

  /// No description provided for @channels_meta.
  ///
  /// In ar, this message translates to:
  /// **'واتساب للأعمال (ميتا)'**
  String get channels_meta;

  /// No description provided for @channels_open_on_web.
  ///
  /// In ar, this message translates to:
  /// **'يُفتح على الموقع'**
  String get channels_open_on_web;

  /// No description provided for @channels_open_web_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الموقع'**
  String get channels_open_web_failed;

  /// No description provided for @channels_meta_sub.
  ///
  /// In ar, this message translates to:
  /// **'الواجهة الرسمية · يُفتح على الموقع'**
  String get channels_meta_sub;

  /// No description provided for @acc_title.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get acc_title;

  /// No description provided for @acc_role_owner.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get acc_role_owner;

  /// No description provided for @acc_role_admin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول'**
  String get acc_role_admin;

  /// No description provided for @acc_role_lead.
  ///
  /// In ar, this message translates to:
  /// **'قائد فريق'**
  String get acc_role_lead;

  /// No description provided for @acc_role_agent.
  ///
  /// In ar, this message translates to:
  /// **'موظف دعم'**
  String get acc_role_agent;

  /// No description provided for @acc_menu.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الحساب'**
  String get acc_menu;

  /// No description provided for @acc_menu_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get acc_menu_edit;

  /// No description provided for @acc_menu_copy_id.
  ///
  /// In ar, this message translates to:
  /// **'نسخ معرّف المستخدم'**
  String get acc_menu_copy_id;

  /// No description provided for @acc_id_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ المعرّف'**
  String get acc_id_copied;

  /// No description provided for @acc_header_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {role}، {workspace}، الحالة: {status}'**
  String acc_header_a11y(
    String name,
    String role,
    String workspace,
    String status,
  );

  /// No description provided for @acc_my_status.
  ///
  /// In ar, this message translates to:
  /// **'حالتي'**
  String get acc_my_status;

  /// No description provided for @acc_away_open_title.
  ///
  /// In ar, this message translates to:
  /// **'لديك {n} محادثات مفتوحة'**
  String acc_away_open_title(int n);

  /// No description provided for @acc_away_open_body.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تفعل بها قبل أن تصبح غير متاح؟'**
  String get acc_away_open_body;

  /// No description provided for @acc_away_release.
  ///
  /// In ar, this message translates to:
  /// **'إعادتها لغير المُسندة'**
  String get acc_away_release;

  /// No description provided for @acc_away_keep.
  ///
  /// In ar, this message translates to:
  /// **'الإبقاء عليها'**
  String get acc_away_keep;

  /// No description provided for @acc_presence_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تغيير الحالة'**
  String get acc_presence_failed;

  /// No description provided for @acc_released.
  ///
  /// In ar, this message translates to:
  /// **'أُعيدت {n} محادثات لغير المُسندة'**
  String acc_released(int n);

  /// No description provided for @acc_sec_admin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get acc_sec_admin;

  /// No description provided for @acc_sec_app.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get acc_sec_app;

  /// No description provided for @acc_sec_about.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get acc_sec_about;

  /// No description provided for @acc_wa_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get acc_wa_connected;

  /// No description provided for @acc_wa_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get acc_wa_disconnected;

  /// No description provided for @acc_wa_phone_off.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف غير متصل'**
  String get acc_wa_phone_off;

  /// No description provided for @acc_wa_pending.
  ///
  /// In ar, this message translates to:
  /// **'غير مربوط'**
  String get acc_wa_pending;

  /// No description provided for @acc_wa_connecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال'**
  String get acc_wa_connecting;

  /// No description provided for @acc_ai_on.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get acc_ai_on;

  /// No description provided for @acc_ai_off.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get acc_ai_off;

  /// No description provided for @acc_ai_suggest.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح فقط'**
  String get acc_ai_suggest;

  /// No description provided for @acc_ai_hybrid.
  ///
  /// In ar, this message translates to:
  /// **'هجين'**
  String get acc_ai_hybrid;

  /// No description provided for @acc_plan_trial.
  ///
  /// In ar, this message translates to:
  /// **'{plan} · تجربة، متبقٍ {d} أيام'**
  String acc_plan_trial(String plan, int d);

  /// No description provided for @acc_plan_trial_ended.
  ///
  /// In ar, this message translates to:
  /// **'{plan} · انتهت التجربة'**
  String acc_plan_trial_ended(String plan);

  /// No description provided for @acc_plan_active.
  ///
  /// In ar, this message translates to:
  /// **'{plan} · نشط'**
  String acc_plan_active(String plan);

  /// No description provided for @acc_plan_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الدفع — حدّث البطاقة'**
  String get acc_plan_failed;

  /// No description provided for @acc_plan_badge_trial.
  ///
  /// In ar, this message translates to:
  /// **'تجربة'**
  String get acc_plan_badge_trial;

  /// No description provided for @acc_plan_badge_active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get acc_plan_badge_active;

  /// No description provided for @acc_plan_days_left.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {d} أيام من التجربة'**
  String acc_plan_days_left(int d);

  /// No description provided for @acc_plan_seats.
  ///
  /// In ar, this message translates to:
  /// **'المقاعد'**
  String get acc_plan_seats;

  /// No description provided for @acc_plan_ai.
  ///
  /// In ar, this message translates to:
  /// **'ردود الذكاء الاصطناعي'**
  String get acc_plan_ai;

  /// No description provided for @acc_plan_unlimited.
  ///
  /// In ar, this message translates to:
  /// **'غير محدود'**
  String get acc_plan_unlimited;

  /// No description provided for @acc_plan_manage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get acc_plan_manage;

  /// No description provided for @acc_plan_readonly.
  ///
  /// In ar, this message translates to:
  /// **'يديره مالك مساحة العمل'**
  String get acc_plan_readonly;

  /// No description provided for @acc_notif_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get acc_notif_all;

  /// No description provided for @acc_notif_assigned.
  ///
  /// In ar, this message translates to:
  /// **'المُسندة لي'**
  String get acc_notif_assigned;

  /// No description provided for @acc_notif_mentions.
  ///
  /// In ar, this message translates to:
  /// **'الإشارات فقط'**
  String get acc_notif_mentions;

  /// No description provided for @acc_notif_none.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة'**
  String get acc_notif_none;

  /// No description provided for @acc_notif_denied.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة من الجهاز'**
  String get acc_notif_denied;

  /// No description provided for @acc_security.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get acc_security;

  /// No description provided for @acc_terms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وسياسة الخصوصية'**
  String get acc_terms;

  /// No description provided for @acc_contact.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get acc_contact;

  /// No description provided for @acc_version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get acc_version;

  /// No description provided for @acc_debug_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ معلومات التشخيص'**
  String get acc_debug_copied;

  /// No description provided for @acc_logout_title.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get acc_logout_title;

  /// No description provided for @acc_logout_body.
  ///
  /// In ar, this message translates to:
  /// **'ستتوقف إشعارات المحادثات على هذا الجهاز.'**
  String get acc_logout_body;

  /// No description provided for @acc_logout_open.
  ///
  /// In ar, this message translates to:
  /// **'لديك {n} محادثات مفتوحة ستبقى مُسندة لك.'**
  String acc_logout_open(int n);

  /// No description provided for @acc_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get acc_offline;

  /// No description provided for @acc_offline_presence.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحالة يتطلب اتصالًا'**
  String get acc_offline_presence;

  /// No description provided for @acc_open_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصفحة'**
  String get acc_open_failed;

  /// No description provided for @prof_title.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get prof_title;

  /// No description provided for @prof_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get prof_name;

  /// No description provided for @prof_name_error.
  ///
  /// In ar, this message translates to:
  /// **'الاسم من 2 إلى 50 حرفًا'**
  String get prof_name_error;

  /// No description provided for @prof_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get prof_email;

  /// No description provided for @prof_email_locked.
  ///
  /// In ar, this message translates to:
  /// **'لتغيير البريد تواصل مع المسؤول'**
  String get prof_email_locked;

  /// No description provided for @prof_photo_web.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة متاح من لوحة الويب'**
  String get prof_photo_web;

  /// No description provided for @prof_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get prof_save;

  /// No description provided for @prof_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف الشخصي'**
  String get prof_saved;

  /// No description provided for @prof_save_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ'**
  String get prof_save_failed;

  /// No description provided for @prof_discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التغييرات؟'**
  String get prof_discard;

  /// No description provided for @prof_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ التعديلات التي أجريتها.'**
  String get prof_discard_body;

  /// No description provided for @prof_discard_ok.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get prof_discard_ok;

  /// No description provided for @sec_change_pw.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get sec_change_pw;

  /// No description provided for @sec_change_pw_sub.
  ///
  /// In ar, this message translates to:
  /// **'يُفتح على الموقع'**
  String get sec_change_pw_sub;

  /// No description provided for @sec_biometric.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بالبصمة'**
  String get sec_biometric;

  /// No description provided for @sec_biometric_reason.
  ///
  /// In ar, this message translates to:
  /// **'أكّد هويتك لتفعيل البصمة'**
  String get sec_biometric_reason;

  /// No description provided for @sec_biometric_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'البصمة غير متاحة على هذا الجهاز'**
  String get sec_biometric_unavailable;

  /// No description provided for @sec_devices.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة المسجّلة'**
  String get sec_devices;

  /// No description provided for @sec_this_device.
  ///
  /// In ar, this message translates to:
  /// **'هذا الجهاز'**
  String get sec_this_device;

  /// No description provided for @sec_device_logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get sec_device_logout;

  /// No description provided for @sec_logout_others.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من كل الأجهزة الأخرى'**
  String get sec_logout_others;

  /// No description provided for @sec_logout_others_body.
  ///
  /// In ar, this message translates to:
  /// **'سيُطلب تسجيل الدخول مجددًا على الأجهزة الأخرى.'**
  String get sec_logout_others_body;

  /// No description provided for @sec_logout_done.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج'**
  String get sec_logout_done;

  /// No description provided for @sec_last_active.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشاط {t}'**
  String sec_last_active(String t);

  /// No description provided for @sec_devices_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الأجهزة'**
  String get sec_devices_failed;

  /// No description provided for @common_locked.
  ///
  /// In ar, this message translates to:
  /// **'مقفل'**
  String get common_locked;

  /// No description provided for @ai_title.
  ///
  /// In ar, this message translates to:
  /// **'وكيل الذكاء الاصطناعي'**
  String get ai_title;

  /// No description provided for @ai_master_switch.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الذكاء الاصطناعي'**
  String get ai_master_switch;

  /// No description provided for @ai_state_on.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get ai_state_on;

  /// No description provided for @ai_state_off.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get ai_state_off;

  /// No description provided for @ai_readonly.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للمسؤول فقط تعديل إعدادات الذكاء الاصطناعي'**
  String get ai_readonly;

  /// No description provided for @ai_hero_answered.
  ///
  /// In ar, this message translates to:
  /// **'{n} سؤالًا'**
  String ai_hero_answered(String n);

  /// No description provided for @ai_hero_caption.
  ///
  /// In ar, this message translates to:
  /// **'أجاب عنها هذا الأسبوع · وفّر نحو {h} ساعات'**
  String ai_hero_caption(String h);

  /// No description provided for @ai_hero_off.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي متوقف'**
  String get ai_hero_off;

  /// No description provided for @ai_hero_off_body.
  ///
  /// In ar, this message translates to:
  /// **'فعّله ليجيب عن أسئلة عملائك من قاعدة المعرفة'**
  String get ai_hero_off_body;

  /// No description provided for @ai_hero_ready.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للعمل'**
  String get ai_hero_ready;

  /// No description provided for @ai_hero_ready_body.
  ///
  /// In ar, this message translates to:
  /// **'لم يجب عن أي سؤال بعد — جرّبه أولًا'**
  String get ai_hero_ready_body;

  /// No description provided for @ai_hero_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{n} سؤالًا أجاب عنها هذا الأسبوع، عرض الأداء'**
  String ai_hero_a11y(String n);

  /// No description provided for @ai_usage.
  ///
  /// In ar, this message translates to:
  /// **'استخدمت {p}% من ردود هذا الشهر'**
  String ai_usage(String p);

  /// No description provided for @ai_ready_title.
  ///
  /// In ar, this message translates to:
  /// **'قبل التفعيل الكامل'**
  String get ai_ready_title;

  /// No description provided for @ai_ready_kb.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة المعرفة تحتوي 10 إجابات على الأقل ({n}/10)'**
  String ai_ready_kb(String n);

  /// No description provided for @ai_ready_hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل محددة'**
  String get ai_ready_hours;

  /// No description provided for @ai_ready_handoff.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة تحويل للموظفين مفعّلة'**
  String get ai_ready_handoff;

  /// No description provided for @ai_ready_tested.
  ///
  /// In ar, this message translates to:
  /// **'تمت تجربة الوكيل'**
  String get ai_ready_tested;

  /// No description provided for @ai_ready_done.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get ai_ready_done;

  /// No description provided for @ai_ready_missing.
  ///
  /// In ar, this message translates to:
  /// **'غير مكتمل'**
  String get ai_ready_missing;

  /// No description provided for @ai_mode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة العمل'**
  String get ai_mode;

  /// No description provided for @ai_mode_suggest.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح'**
  String get ai_mode_suggest;

  /// No description provided for @ai_mode_suggest_sub.
  ///
  /// In ar, this message translates to:
  /// **'يقترح الردود مع إبقاء الوكيل في التحكم'**
  String get ai_mode_suggest_sub;

  /// No description provided for @ai_mode_auto.
  ///
  /// In ar, this message translates to:
  /// **'ذاتي'**
  String get ai_mode_auto;

  /// No description provided for @ai_mode_auto_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرد تلقائياً ضمن الحدود المسموح بها'**
  String get ai_mode_auto_sub;

  /// No description provided for @ai_mode_after.
  ///
  /// In ar, this message translates to:
  /// **'خارج الدوام فقط'**
  String get ai_mode_after;

  /// No description provided for @ai_mode_after_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرد تلقائيًا بعد ساعات العمل'**
  String get ai_mode_after_sub;

  /// No description provided for @ai_mode_after_sub2.
  ///
  /// In ar, this message translates to:
  /// **'واقتراحات خلال الدوام'**
  String get ai_mode_after_sub2;

  /// No description provided for @ai_mode_needs_hours.
  ///
  /// In ar, this message translates to:
  /// **'حدّد ساعات العمل أولًا'**
  String get ai_mode_needs_hours;

  /// No description provided for @ai_mode_needs_ready.
  ///
  /// In ar, this message translates to:
  /// **'أكمل قائمة الجاهزية أولًا'**
  String get ai_mode_needs_ready;

  /// No description provided for @ai_recommended.
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get ai_recommended;

  /// No description provided for @ai_mode_changed.
  ///
  /// In ar, this message translates to:
  /// **'تم التغيير إلى «{mode}»'**
  String ai_mode_changed(String mode);

  /// No description provided for @ai_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get ai_undo;

  /// No description provided for @ai_tone.
  ///
  /// In ar, this message translates to:
  /// **'نبرة الرد'**
  String get ai_tone;

  /// No description provided for @ai_tone_friendly.
  ///
  /// In ar, this message translates to:
  /// **'ودود'**
  String get ai_tone_friendly;

  /// No description provided for @ai_tone_formal.
  ///
  /// In ar, this message translates to:
  /// **'رسمي'**
  String get ai_tone_formal;

  /// No description provided for @ai_tone_concise.
  ///
  /// In ar, this message translates to:
  /// **'مختصر'**
  String get ai_tone_concise;

  /// No description provided for @ai_tone_sample_friendly.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا نورة، التوصيل للدمام 25 ريال، ومجاني فوق 300. يوصلك خلال 2–3 أيام!'**
  String get ai_tone_sample_friendly;

  /// No description provided for @ai_tone_sample_formal.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بك. رسوم التوصيل إلى الدمام 25 ريالًا، ويكون مجانيًا للطلبات التي تتجاوز 300 ريال، خلال 2–3 أيام عمل.'**
  String get ai_tone_sample_formal;

  /// No description provided for @ai_tone_sample_concise.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل للدمام 25 ريال (مجاني فوق 300) · 2–3 أيام.'**
  String get ai_tone_sample_concise;

  /// No description provided for @ai_use_name.
  ///
  /// In ar, this message translates to:
  /// **'استخدم اسم العميل في الرد'**
  String get ai_use_name;

  /// No description provided for @ai_rules.
  ///
  /// In ar, this message translates to:
  /// **'القواعد'**
  String get ai_rules;

  /// No description provided for @ai_hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل'**
  String get ai_hours;

  /// No description provided for @ai_hours_24.
  ///
  /// In ar, this message translates to:
  /// **'24 ساعة'**
  String get ai_hours_24;

  /// No description provided for @ai_hours_unset.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get ai_hours_unset;

  /// No description provided for @ai_handoff.
  ///
  /// In ar, this message translates to:
  /// **'التحويل لموظف'**
  String get ai_handoff;

  /// No description provided for @ai_handoff_sub.
  ///
  /// In ar, this message translates to:
  /// **'عند طلب إنسان، شكوى، أو دفع'**
  String get ai_handoff_sub;

  /// No description provided for @ai_language.
  ///
  /// In ar, this message translates to:
  /// **'لغة الرد'**
  String get ai_language;

  /// No description provided for @ai_lang_customer.
  ///
  /// In ar, this message translates to:
  /// **'لغة العميل'**
  String get ai_lang_customer;

  /// No description provided for @ai_lang_customer_sub.
  ///
  /// In ar, this message translates to:
  /// **'يكتشف اللغة في كل رسالة'**
  String get ai_lang_customer_sub;

  /// No description provided for @ai_lang_ar.
  ///
  /// In ar, this message translates to:
  /// **'العربية دائمًا'**
  String get ai_lang_ar;

  /// No description provided for @ai_lang_en.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية دائمًا'**
  String get ai_lang_en;

  /// No description provided for @ai_lang_style.
  ///
  /// In ar, this message translates to:
  /// **'الأسلوب'**
  String get ai_lang_style;

  /// No description provided for @ai_lang_msa.
  ///
  /// In ar, this message translates to:
  /// **'فصحى مبسطة'**
  String get ai_lang_msa;

  /// No description provided for @ai_lang_saudi.
  ///
  /// In ar, this message translates to:
  /// **'لهجة سعودية بيضاء'**
  String get ai_lang_saudi;

  /// No description provided for @ai_handoff_msg.
  ///
  /// In ar, this message translates to:
  /// **'رسالة التحويل'**
  String get ai_handoff_msg;

  /// No description provided for @ai_handoff_msg_default.
  ///
  /// In ar, this message translates to:
  /// **'سأحوّلك الآن لأحد زملائي ليساعدك، لحظات من فضلك.'**
  String get ai_handoff_msg_default;

  /// No description provided for @ai_var_customer.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get ai_var_customer;

  /// No description provided for @ai_var_return.
  ///
  /// In ar, this message translates to:
  /// **'وقت العودة'**
  String get ai_var_return;

  /// No description provided for @ai_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get ai_save;

  /// No description provided for @ai_delay.
  ///
  /// In ar, this message translates to:
  /// **'مهلة الرد التلقائي'**
  String get ai_delay;

  /// No description provided for @ai_delay_instant.
  ///
  /// In ar, this message translates to:
  /// **'فوري'**
  String get ai_delay_instant;

  /// No description provided for @ai_delay_30s.
  ///
  /// In ar, this message translates to:
  /// **'بعد 30 ث'**
  String get ai_delay_30s;

  /// No description provided for @ai_delay_1m.
  ///
  /// In ar, this message translates to:
  /// **'بعد دقيقة'**
  String get ai_delay_1m;

  /// No description provided for @ai_delay_2m.
  ///
  /// In ar, this message translates to:
  /// **'بعد دقيقتين'**
  String get ai_delay_2m;

  /// No description provided for @ai_delay_note.
  ///
  /// In ar, this message translates to:
  /// **'المهلة تتيح للموظفين الرد أولًا في وضع الرد التلقائي'**
  String get ai_delay_note;

  /// No description provided for @ai_perf.
  ///
  /// In ar, this message translates to:
  /// **'الأداء'**
  String get ai_perf;

  /// No description provided for @ai_perf_resolution.
  ///
  /// In ar, this message translates to:
  /// **'معدل الإجابة دون تحويل'**
  String get ai_perf_resolution;

  /// No description provided for @ai_perf_rating.
  ///
  /// In ar, this message translates to:
  /// **'التقييم الإيجابي'**
  String get ai_perf_rating;

  /// No description provided for @ai_perf_unanswered.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة بلا إجابة'**
  String get ai_perf_unanswered;

  /// No description provided for @ai_perf_detail.
  ///
  /// In ar, this message translates to:
  /// **'عرض الأداء التفصيلي'**
  String get ai_perf_detail;

  /// No description provided for @ai_perf_week.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get ai_perf_week;

  /// No description provided for @ai_perf_answered.
  ///
  /// In ar, this message translates to:
  /// **'أجاب'**
  String get ai_perf_answered;

  /// No description provided for @ai_perf_handoffs.
  ///
  /// In ar, this message translates to:
  /// **'تحويلات'**
  String get ai_perf_handoffs;

  /// No description provided for @ai_perf_reasons.
  ///
  /// In ar, this message translates to:
  /// **'أكثر أسباب التحويل'**
  String get ai_perf_reasons;

  /// No description provided for @ai_perf_sources.
  ///
  /// In ar, this message translates to:
  /// **'أكثر المصادر استخدامًا'**
  String get ai_perf_sources;

  /// No description provided for @ai_perf_none.
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات بعد'**
  String get ai_perf_none;

  /// No description provided for @ai_reason_human_request.
  ///
  /// In ar, this message translates to:
  /// **'طلب موظف'**
  String get ai_reason_human_request;

  /// No description provided for @ai_reason_complaint.
  ///
  /// In ar, this message translates to:
  /// **'شكوى'**
  String get ai_reason_complaint;

  /// No description provided for @ai_reason_payment.
  ///
  /// In ar, this message translates to:
  /// **'دفع أو استرجاع'**
  String get ai_reason_payment;

  /// No description provided for @ai_reason_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إجابة'**
  String get ai_reason_no_answer;

  /// No description provided for @ai_reason_low_confidence.
  ///
  /// In ar, this message translates to:
  /// **'ثقة منخفضة'**
  String get ai_reason_low_confidence;

  /// No description provided for @ai_reason_after_replies.
  ///
  /// In ar, this message translates to:
  /// **'ردود دون حل'**
  String get ai_reason_after_replies;

  /// No description provided for @ai_reason_keyword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة محددة: {word}'**
  String ai_reason_keyword(String word);

  /// No description provided for @ai_reason_other.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get ai_reason_other;

  /// No description provided for @ai_advanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get ai_advanced;

  /// No description provided for @ai_channels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات المفعّلة'**
  String get ai_channels;

  /// No description provided for @ai_channels_none.
  ///
  /// In ar, this message translates to:
  /// **'لا قنوات'**
  String get ai_channels_none;

  /// No description provided for @ai_channel_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get ai_channel_whatsapp;

  /// No description provided for @ai_channel_web.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get ai_channel_web;

  /// No description provided for @ai_channel_messenger.
  ///
  /// In ar, this message translates to:
  /// **'ماسنجر'**
  String get ai_channel_messenger;

  /// No description provided for @ai_instructions.
  ///
  /// In ar, this message translates to:
  /// **'تعليمات إضافية'**
  String get ai_instructions;

  /// No description provided for @ai_instructions_ph.
  ///
  /// In ar, this message translates to:
  /// **'مثال: لا تذكر أسعار الجملة، واطلب رقم الطلب دائمًا قبل الإجابة عن الشحن'**
  String get ai_instructions_ph;

  /// No description provided for @ai_instructions_empty.
  ///
  /// In ar, this message translates to:
  /// **'بدون'**
  String get ai_instructions_empty;

  /// No description provided for @ai_outside_kb.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة من خارج قاعدة المعرفة'**
  String get ai_outside_kb;

  /// No description provided for @ai_outside_kb_sub.
  ///
  /// In ar, this message translates to:
  /// **'غير مستحسن — قد يجيب بمعلومات غير دقيقة'**
  String get ai_outside_kb_sub;

  /// No description provided for @ai_confidence.
  ///
  /// In ar, this message translates to:
  /// **'حد الثقة للإرسال التلقائي'**
  String get ai_confidence;

  /// No description provided for @ai_conf_low.
  ///
  /// In ar, this message translates to:
  /// **'منخفض'**
  String get ai_conf_low;

  /// No description provided for @ai_conf_med.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get ai_conf_med;

  /// No description provided for @ai_conf_high.
  ///
  /// In ar, this message translates to:
  /// **'مرتفع'**
  String get ai_conf_high;

  /// No description provided for @ai_conf_low_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرسل أغلب الردود تلقائيًا'**
  String get ai_conf_low_sub;

  /// No description provided for @ai_conf_med_sub.
  ///
  /// In ar, this message translates to:
  /// **'توازن بين السرعة والدقة'**
  String get ai_conf_med_sub;

  /// No description provided for @ai_conf_high_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرسل فقط الردود المؤكدة، والباقي اقتراح أو تحويل'**
  String get ai_conf_high_sub;

  /// No description provided for @ai_team_styles.
  ///
  /// In ar, this message translates to:
  /// **'أساليب إعادة الصياغة للفريق'**
  String get ai_team_styles;

  /// No description provided for @ai_style_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أسلوب'**
  String get ai_style_add;

  /// No description provided for @ai_style_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأسلوب'**
  String get ai_style_name;

  /// No description provided for @ai_style_instruction.
  ///
  /// In ar, this message translates to:
  /// **'التعليمات'**
  String get ai_style_instruction;

  /// No description provided for @ai_style_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get ai_style_delete;

  /// No description provided for @ai_styles_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا أساليب بعد'**
  String get ai_styles_empty;

  /// No description provided for @ai_audit.
  ///
  /// In ar, this message translates to:
  /// **'سجل التغييرات'**
  String get ai_audit;

  /// No description provided for @ai_audit_row.
  ///
  /// In ar, this message translates to:
  /// **'غيّر {fields}'**
  String ai_audit_row(String fields);

  /// No description provided for @ai_audit_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا تغييرات بعد'**
  String get ai_audit_empty;

  /// No description provided for @ai_test.
  ///
  /// In ar, this message translates to:
  /// **'اختبر الوكيل بمحادثة تجريبية'**
  String get ai_test;

  /// No description provided for @ai_test_title.
  ///
  /// In ar, this message translates to:
  /// **'محادثة تجريبية'**
  String get ai_test_title;

  /// No description provided for @ai_test_sub.
  ///
  /// In ar, this message translates to:
  /// **'لن تُرسل لأي عميل'**
  String get ai_test_sub;

  /// No description provided for @ai_test_info.
  ///
  /// In ar, this message translates to:
  /// **'أنت تتحدث كعميل. جرّب أسئلة عملائك الحقيقية.'**
  String get ai_test_info;

  /// No description provided for @ai_test_why.
  ///
  /// In ar, this message translates to:
  /// **'لماذا هذا الرد؟'**
  String get ai_test_why;

  /// No description provided for @ai_test_handoff.
  ///
  /// In ar, this message translates to:
  /// **'في المحادثة الحقيقية سيتحوّل هنا للفريق: {reason}'**
  String ai_test_handoff(String reason);

  /// No description provided for @ai_test_reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة البدء'**
  String get ai_test_reset;

  /// No description provided for @ai_test_channel.
  ///
  /// In ar, this message translates to:
  /// **'تغيير القناة'**
  String get ai_test_channel;

  /// No description provided for @ai_test_p1.
  ///
  /// In ar, this message translates to:
  /// **'كم سعر التوصيل؟'**
  String get ai_test_p1;

  /// No description provided for @ai_test_p2.
  ///
  /// In ar, this message translates to:
  /// **'أبي أرجّع طلبي'**
  String get ai_test_p2;

  /// No description provided for @ai_test_p3.
  ///
  /// In ar, this message translates to:
  /// **'متى تفتحون؟'**
  String get ai_test_p3;

  /// No description provided for @ai_test_p4.
  ///
  /// In ar, this message translates to:
  /// **'أبي أكلم موظف'**
  String get ai_test_p4;

  /// No description provided for @ai_test_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالك كعميل…'**
  String get ai_test_hint;

  /// No description provided for @ai_test_label.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء'**
  String get ai_test_label;

  /// No description provided for @ai_test_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحصول على رد. حاول مرة أخرى.'**
  String get ai_test_error;

  /// No description provided for @ai_test_unsaved.
  ///
  /// In ar, this message translates to:
  /// **'لديك تعديلات غير محفوظة على ساعات العمل'**
  String get ai_test_unsaved;

  /// No description provided for @ai_why_sources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get ai_why_sources;

  /// No description provided for @ai_why_no_sources.
  ///
  /// In ar, this message translates to:
  /// **'لم يستخدم مصادر من قاعدة المعرفة'**
  String get ai_why_no_sources;

  /// No description provided for @ai_why_confidence.
  ///
  /// In ar, this message translates to:
  /// **'الثقة'**
  String get ai_why_confidence;

  /// No description provided for @ai_why_rule.
  ///
  /// In ar, this message translates to:
  /// **'القاعدة'**
  String get ai_why_rule;

  /// No description provided for @ai_why_tone.
  ///
  /// In ar, this message translates to:
  /// **'النبرة'**
  String get ai_why_tone;

  /// No description provided for @ai_off_title.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الذكاء الاصطناعي؟'**
  String get ai_off_title;

  /// No description provided for @ai_off_body.
  ///
  /// In ar, this message translates to:
  /// **'سيتوقف عن الرد والاقتراح في كل المحادثات. المحادثات التي يتولاها الآن ستتحوّل للفريق.'**
  String get ai_off_body;

  /// No description provided for @ai_off_handling.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات يتولاها الآن'**
  String ai_off_handling(String n);

  /// No description provided for @ai_off_confirm.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get ai_off_confirm;

  /// No description provided for @ai_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get ai_cancel;

  /// No description provided for @ai_kb_first_title.
  ///
  /// In ar, this message translates to:
  /// **'أضف قاعدة المعرفة أولًا'**
  String get ai_kb_first_title;

  /// No description provided for @ai_kb_first_body.
  ///
  /// In ar, this message translates to:
  /// **'يجيب الذكاء فقط من معلوماتك. أضف 10 إجابات على الأقل ليبدأ.'**
  String get ai_kb_first_body;

  /// No description provided for @ai_kb_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إجابات'**
  String get ai_kb_add;

  /// No description provided for @ai_enable_suggest.
  ///
  /// In ar, this message translates to:
  /// **'فعّله لوضع الاقتراح فقط'**
  String get ai_enable_suggest;

  /// No description provided for @ai_auto_title.
  ///
  /// In ar, this message translates to:
  /// **'سيرد الذكاء على عملائك مباشرة'**
  String get ai_auto_title;

  /// No description provided for @ai_auto_b1.
  ///
  /// In ar, this message translates to:
  /// **'يجيب فقط من قاعدة المعرفة'**
  String get ai_auto_b1;

  /// No description provided for @ai_auto_b2.
  ///
  /// In ar, this message translates to:
  /// **'يحوّل للفريق حسب قواعد التحويل'**
  String get ai_auto_b2;

  /// No description provided for @ai_auto_b3.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إيقافه في أي وقت'**
  String get ai_auto_b3;

  /// No description provided for @ai_auto_tested.
  ///
  /// In ar, this message translates to:
  /// **'جرّبت الوكيل بمحادثة تجريبية'**
  String get ai_auto_tested;

  /// No description provided for @ai_auto_try.
  ///
  /// In ar, this message translates to:
  /// **'جرّب الآن'**
  String get ai_auto_try;

  /// No description provided for @ai_auto_confirm.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الرد التلقائي'**
  String get ai_auto_confirm;

  /// No description provided for @ai_outside_title.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالإجابة من خارج قاعدة المعرفة؟'**
  String get ai_outside_title;

  /// No description provided for @ai_outside_body.
  ///
  /// In ar, this message translates to:
  /// **'قد يقدّم الذكاء معلومات غير صحيحة عن منتجاتك أو أسعارك.'**
  String get ai_outside_body;

  /// No description provided for @ai_allow.
  ///
  /// In ar, this message translates to:
  /// **'سماح'**
  String get ai_allow;

  /// No description provided for @ai_plan_off.
  ///
  /// In ar, this message translates to:
  /// **'ميزة الذكاء الاصطناعي غير متاحة في خطتك'**
  String get ai_plan_off;

  /// No description provided for @ai_view_plans.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخطط'**
  String get ai_view_plans;

  /// No description provided for @ai_quota_out.
  ///
  /// In ar, this message translates to:
  /// **'انتهت ردود هذا الشهر — يعمل كاقتراح فقط حتى {date}'**
  String ai_quota_out(String date);

  /// No description provided for @ai_save_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التغيير'**
  String get ai_save_failed;

  /// No description provided for @ai_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get ai_retry;

  /// No description provided for @ai_conflict.
  ///
  /// In ar, this message translates to:
  /// **'عدّل {name} الإعدادات للتو'**
  String ai_conflict(String name);

  /// No description provided for @ai_conflict_anon.
  ///
  /// In ar, this message translates to:
  /// **'عدّل شخص آخر الإعدادات للتو'**
  String get ai_conflict_anon;

  /// No description provided for @ai_offline.
  ///
  /// In ar, this message translates to:
  /// **'التعديل يتطلب اتصالًا بالإنترنت'**
  String get ai_offline;

  /// No description provided for @ai_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل إعدادات الذكاء الاصطناعي'**
  String get ai_load_error;

  /// No description provided for @ai_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get ai_saved;

  /// No description provided for @ai_hours_247.
  ///
  /// In ar, this message translates to:
  /// **'العمل على مدار الساعة'**
  String get ai_hours_247;

  /// No description provided for @ai_hours_closed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get ai_hours_closed;

  /// No description provided for @ai_hours_add_range.
  ///
  /// In ar, this message translates to:
  /// **'+ فترة'**
  String get ai_hours_add_range;

  /// No description provided for @ai_hours_copy_all.
  ///
  /// In ar, this message translates to:
  /// **'نسخ إلى كل الأيام'**
  String get ai_hours_copy_all;

  /// No description provided for @ai_hours_timezone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get ai_hours_timezone;

  /// No description provided for @ai_hours_holidays.
  ///
  /// In ar, this message translates to:
  /// **'العطل الرسمية'**
  String get ai_hours_holidays;

  /// No description provided for @ai_hours_err_order.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون وقت الانتهاء بعد البداية'**
  String get ai_hours_err_order;

  /// No description provided for @ai_hours_err_overlap.
  ///
  /// In ar, this message translates to:
  /// **'الفترات متداخلة'**
  String get ai_hours_err_overlap;

  /// No description provided for @ai_hours_err_max.
  ///
  /// In ar, this message translates to:
  /// **'فترتان كحد أقصى'**
  String get ai_hours_err_max;

  /// No description provided for @ai_hours_start.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get ai_hours_start;

  /// No description provided for @ai_hours_end.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get ai_hours_end;

  /// No description provided for @ai_hours_discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التعديلات؟'**
  String get ai_hours_discard;

  /// No description provided for @ai_hours_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لم تحفظ ساعات العمل بعد.'**
  String get ai_hours_discard_body;

  /// No description provided for @ai_hours_discard_confirm.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get ai_hours_discard_confirm;

  /// No description provided for @ai_day_sat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get ai_day_sat;

  /// No description provided for @ai_day_sun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get ai_day_sun;

  /// No description provided for @ai_day_mon.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get ai_day_mon;

  /// No description provided for @ai_day_tue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get ai_day_tue;

  /// No description provided for @ai_day_wed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get ai_day_wed;

  /// No description provided for @ai_day_thu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get ai_day_thu;

  /// No description provided for @ai_day_fri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get ai_day_fri;

  /// No description provided for @ai_ho_intro.
  ///
  /// In ar, this message translates to:
  /// **'يحوّل الذكاء المحادثة للفريق تلقائيًا في هذه الحالات:'**
  String get ai_ho_intro;

  /// No description provided for @ai_ho_human.
  ///
  /// In ar, this message translates to:
  /// **'العميل يطلب التحدث مع موظف'**
  String get ai_ho_human;

  /// No description provided for @ai_ho_always.
  ///
  /// In ar, this message translates to:
  /// **'دائمًا مفعّلة'**
  String get ai_ho_always;

  /// No description provided for @ai_ho_complaint.
  ///
  /// In ar, this message translates to:
  /// **'شكوى أو عميل غاضب'**
  String get ai_ho_complaint;

  /// No description provided for @ai_ho_payment.
  ///
  /// In ar, this message translates to:
  /// **'موضوع دفع أو استرجاع مبالغ'**
  String get ai_ho_payment;

  /// No description provided for @ai_ho_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'لم يجد إجابة في قاعدة المعرفة'**
  String get ai_ho_no_answer;

  /// No description provided for @ai_ho_low_conf.
  ///
  /// In ar, this message translates to:
  /// **'ثقة منخفضة في الإجابة'**
  String get ai_ho_low_conf;

  /// No description provided for @ai_ho_after_n.
  ///
  /// In ar, this message translates to:
  /// **'بعد {n} ردود دون حل'**
  String ai_ho_after_n(String n);

  /// No description provided for @ai_ho_keywords.
  ///
  /// In ar, this message translates to:
  /// **'كلمات محددة'**
  String get ai_ho_keywords;

  /// No description provided for @ai_ho_keyword_add.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلمة…'**
  String get ai_ho_keyword_add;

  /// No description provided for @ai_ho_target.
  ///
  /// In ar, this message translates to:
  /// **'إلى من يُحوّل؟'**
  String get ai_ho_target;

  /// No description provided for @ai_ho_target_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة (أول من يستلم)'**
  String get ai_ho_target_unassigned;

  /// No description provided for @ai_ho_target_team.
  ///
  /// In ar, this message translates to:
  /// **'فريق محدد'**
  String get ai_ho_target_team;

  /// No description provided for @ai_ho_target_last.
  ///
  /// In ar, this message translates to:
  /// **'آخر موظف تعامل مع العميل'**
  String get ai_ho_target_last;

  /// No description provided for @ai_ho_after_hours.
  ///
  /// In ar, this message translates to:
  /// **'خارج الدوام'**
  String get ai_ho_after_hours;

  /// No description provided for @ai_ho_tell_return.
  ///
  /// In ar, this message translates to:
  /// **'يخبر العميل بموعد العودة'**
  String get ai_ho_tell_return;

  /// No description provided for @ai_ho_notify.
  ///
  /// In ar, this message translates to:
  /// **'يحوّل ويرسل إشعارًا للفريق'**
  String get ai_ho_notify;

  /// No description provided for @ai_mode_hybrid.
  ///
  /// In ar, this message translates to:
  /// **'هجين'**
  String get ai_mode_hybrid;

  /// No description provided for @ai_mode_hybrid_sub.
  ///
  /// In ar, this message translates to:
  /// **'يمزج بين الاقتراح والرد التلقائي'**
  String get ai_mode_hybrid_sub;

  /// No description provided for @ai_replies.
  ///
  /// In ar, this message translates to:
  /// **'الردود'**
  String get ai_replies;

  /// No description provided for @ai_suggestions.
  ///
  /// In ar, this message translates to:
  /// **'عدد الاقتراحات لكل رسالة'**
  String get ai_suggestions;

  /// No description provided for @ai_suggestions_sub.
  ///
  /// In ar, this message translates to:
  /// **'كم اقتراح رد يقدّمه الذكاء الاصطناعي في كل مرة.'**
  String get ai_suggestions_sub;

  /// No description provided for @ai_reply_claimed.
  ///
  /// In ar, this message translates to:
  /// **'الرد عندما يستلم موظف المحادثة'**
  String get ai_reply_claimed;

  /// No description provided for @ai_reply_claimed_sub.
  ///
  /// In ar, this message translates to:
  /// **'عند الإيقاف: يتوقف الذكاء الاصطناعي بمجرد أن يستلم شخص المحادثة.'**
  String get ai_reply_claimed_sub;

  /// No description provided for @ai_keywords.
  ///
  /// In ar, this message translates to:
  /// **'كلمات التحويل'**
  String get ai_keywords;

  /// No description provided for @ai_keywords_sub.
  ///
  /// In ar, this message translates to:
  /// **'عندما يكتب العميل إحدى هذه الكلمات، تُحوَّل المحادثة إلى موظف.'**
  String get ai_keywords_sub;

  /// No description provided for @ai_keywords_none.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد'**
  String get ai_keywords_none;

  /// No description provided for @ai_keywords_count.
  ///
  /// In ar, this message translates to:
  /// **'{n} كلمات'**
  String ai_keywords_count(int n);

  /// No description provided for @ai_keywords_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كلمات بعد.'**
  String get ai_keywords_empty;

  /// No description provided for @ai_keywords_hint.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلمة، مثل: مدير'**
  String get ai_keywords_hint;

  /// No description provided for @ai_keywords_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get ai_keywords_add;

  /// No description provided for @ai_keywords_remove.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get ai_keywords_remove;

  /// No description provided for @ai_answer_source.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الإجابات'**
  String get ai_answer_source;

  /// No description provided for @ai_answer_source_kb.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة المعرفة'**
  String get ai_answer_source_kb;

  /// No description provided for @ai_answer_source_kb_sub.
  ///
  /// In ar, this message translates to:
  /// **'يجيب الذكاء الاصطناعي من قاعدة المعرفة.'**
  String get ai_answer_source_kb_sub;

  /// No description provided for @ai_answer_source_flow.
  ///
  /// In ar, this message translates to:
  /// **'تنظيم البوت'**
  String get ai_answer_source_flow;

  /// No description provided for @ai_answer_source_flow_sub.
  ///
  /// In ar, this message translates to:
  /// **'يتبع الذكاء الاصطناعي مسار البوت الذي أنشأته على الويب.'**
  String get ai_answer_source_flow_sub;

  /// No description provided for @ai_lang_fr.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get ai_lang_fr;

  /// No description provided for @ai_lang_es.
  ///
  /// In ar, this message translates to:
  /// **'الإسبانية'**
  String get ai_lang_es;

  /// No description provided for @ai_lang_pt.
  ///
  /// In ar, this message translates to:
  /// **'البرتغالية'**
  String get ai_lang_pt;

  /// No description provided for @ai_lang_de.
  ///
  /// In ar, this message translates to:
  /// **'الألمانية'**
  String get ai_lang_de;

  /// No description provided for @ai_lang_it.
  ///
  /// In ar, this message translates to:
  /// **'الإيطالية'**
  String get ai_lang_it;

  /// No description provided for @ai_mode_off.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get ai_mode_off;

  /// No description provided for @ai_mode_off_sub.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ردود آلية'**
  String get ai_mode_off_sub;

  /// No description provided for @ai_mode_auto_info.
  ///
  /// In ar, this message translates to:
  /// **'في الوضع الذاتي يرسل الذكاء الاصطناعي الردود مباشرة دون مراجعة الوكيل. كلمات التصعيد توقف الذكاء الاصطناعي وتنبّه الوكلاء.'**
  String get ai_mode_auto_info;

  /// No description provided for @ai_mode_set_on_web.
  ///
  /// In ar, this message translates to:
  /// **'يُضبط من الموقع حاليًا'**
  String get ai_mode_set_on_web;

  /// No description provided for @ai_mode_hybrid_on_web.
  ///
  /// In ar, this message translates to:
  /// **'اختر «هجين» على الموقع ثم عُد إلى التطبيق.'**
  String get ai_mode_hybrid_on_web;

  /// No description provided for @rw_title.
  ///
  /// In ar, this message translates to:
  /// **'حسّن الرد'**
  String get rw_title;

  /// No description provided for @rw_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر الأسلوب وسيعيد الذكاء الصياغة'**
  String get rw_subtitle;

  /// No description provided for @rw_original.
  ///
  /// In ar, this message translates to:
  /// **'ردّك الأصلي'**
  String get rw_original;

  /// No description provided for @rw_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get rw_edit;

  /// No description provided for @rw_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get rw_more;

  /// No description provided for @rw_selection_hint.
  ///
  /// In ar, this message translates to:
  /// **'سيتم استبدال الجزء المحدد فقط'**
  String get rw_selection_hint;

  /// No description provided for @rw_style_professional.
  ///
  /// In ar, this message translates to:
  /// **'أكثر احترافية'**
  String get rw_style_professional;

  /// No description provided for @rw_style_shorter.
  ///
  /// In ar, this message translates to:
  /// **'أقصر'**
  String get rw_style_shorter;

  /// No description provided for @rw_style_friendlier.
  ///
  /// In ar, this message translates to:
  /// **'أكثر ودًّا'**
  String get rw_style_friendlier;

  /// No description provided for @rw_style_apology.
  ///
  /// In ar, this message translates to:
  /// **'اعتذار'**
  String get rw_style_apology;

  /// No description provided for @rw_style_fix.
  ///
  /// In ar, this message translates to:
  /// **'صحّح الإملاء'**
  String get rw_style_fix;

  /// No description provided for @rw_style_to_en.
  ///
  /// In ar, this message translates to:
  /// **'ترجم للإنجليزية'**
  String get rw_style_to_en;

  /// No description provided for @rw_style_to_ar.
  ///
  /// In ar, this message translates to:
  /// **'ترجم للعربية'**
  String get rw_style_to_ar;

  /// No description provided for @rw_style_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get rw_style_more;

  /// No description provided for @rw_style_formal.
  ///
  /// In ar, this message translates to:
  /// **'رسمي جدًا'**
  String get rw_style_formal;

  /// No description provided for @rw_style_saudi.
  ///
  /// In ar, this message translates to:
  /// **'بلهجة سعودية'**
  String get rw_style_saudi;

  /// No description provided for @rw_style_msa.
  ///
  /// In ar, this message translates to:
  /// **'بالفصحى'**
  String get rw_style_msa;

  /// No description provided for @rw_style_greeting.
  ///
  /// In ar, this message translates to:
  /// **'أضف تحية وخاتمة'**
  String get rw_style_greeting;

  /// No description provided for @rw_style_bullets.
  ///
  /// In ar, this message translates to:
  /// **'حوّلها لنقاط'**
  String get rw_style_bullets;

  /// No description provided for @rw_style_sales.
  ///
  /// In ar, this message translates to:
  /// **'أكثر إقناعًا للبيع'**
  String get rw_style_sales;

  /// No description provided for @rw_style_simple.
  ///
  /// In ar, this message translates to:
  /// **'أبسط وأوضح'**
  String get rw_style_simple;

  /// No description provided for @rw_team_styles.
  ///
  /// In ar, this message translates to:
  /// **'أساليب فريقك'**
  String get rw_team_styles;

  /// No description provided for @rw_customer_prefers.
  ///
  /// In ar, this message translates to:
  /// **'العميل يفضّل {language}'**
  String rw_customer_prefers(String language);

  /// No description provided for @rw_result.
  ///
  /// In ar, this message translates to:
  /// **'الصياغة المقترحة'**
  String get rw_result;

  /// No description provided for @rw_writing.
  ///
  /// In ar, this message translates to:
  /// **'يعيد الصياغة…'**
  String get rw_writing;

  /// No description provided for @rw_streaming.
  ///
  /// In ar, this message translates to:
  /// **'يكتب…'**
  String get rw_streaming;

  /// No description provided for @rw_edited.
  ///
  /// In ar, this message translates to:
  /// **'معدّلة يدويًا'**
  String get rw_edited;

  /// No description provided for @rw_name_added.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف اسم العميل'**
  String get rw_name_added;

  /// No description provided for @rw_fact_warning.
  ///
  /// In ar, this message translates to:
  /// **'تحقق: أضاف الذكاء معلومة غير موجودة في ردّك'**
  String get rw_fact_warning;

  /// No description provided for @rw_chars.
  ///
  /// In ar, this message translates to:
  /// **'{n} حرف ({delta})'**
  String rw_chars(int n, String delta);

  /// No description provided for @rw_over_limit.
  ///
  /// In ar, this message translates to:
  /// **'أطول من الحد المسموح للقناة'**
  String get rw_over_limit;

  /// No description provided for @rw_show_diff.
  ///
  /// In ar, this message translates to:
  /// **'إظهار التغييرات'**
  String get rw_show_diff;

  /// No description provided for @rw_hide_diff.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التغييرات'**
  String get rw_hide_diff;

  /// No description provided for @rw_use.
  ///
  /// In ar, this message translates to:
  /// **'استخدم هذا الرد'**
  String get rw_use;

  /// No description provided for @rw_use_as_is.
  ///
  /// In ar, this message translates to:
  /// **'استخدم الرد كما هو'**
  String get rw_use_as_is;

  /// No description provided for @rw_rerun.
  ///
  /// In ar, this message translates to:
  /// **'أعد الصياغة'**
  String get rw_rerun;

  /// No description provided for @rw_regenerate.
  ///
  /// In ar, this message translates to:
  /// **'صياغة أخرى'**
  String get rw_regenerate;

  /// No description provided for @rw_max_versions.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد الأقصى من المحاولات'**
  String get rw_max_versions;

  /// No description provided for @rw_no_change.
  ///
  /// In ar, this message translates to:
  /// **'ردّك سليم، لا توجد تعديلات'**
  String get rw_no_change;

  /// No description provided for @rw_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت إعادة الصياغة'**
  String get rw_error;

  /// No description provided for @rw_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get rw_retry;

  /// No description provided for @rw_rate_limited.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لحد الاستخدام مؤقتًا، حاول بعد {n} ث'**
  String rw_rate_limited(int n);

  /// No description provided for @rw_plan_limit.
  ///
  /// In ar, this message translates to:
  /// **'ميزة إعادة الصياغة غير متاحة في خطتك'**
  String get rw_plan_limit;

  /// No description provided for @rw_view_plans.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخطط'**
  String get rw_view_plans;

  /// No description provided for @rw_blocked.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إعادة صياغة هذا النص'**
  String get rw_blocked;

  /// No description provided for @rw_offline.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج اتصالًا بالإنترنت'**
  String get rw_offline;

  /// No description provided for @rw_too_long.
  ///
  /// In ar, this message translates to:
  /// **'النص طويل جدًا لإعادة الصياغة (الحد 2,000 حرف)'**
  String get rw_too_long;

  /// No description provided for @rw_empty_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردًّا أولًا أو استخدم اقتراح الذكاء'**
  String get rw_empty_hint;

  /// No description provided for @rw_toolbar.
  ///
  /// In ar, this message translates to:
  /// **'حسّن بالذكاء'**
  String get rw_toolbar;

  /// No description provided for @rw_lang_ar.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get rw_lang_ar;

  /// No description provided for @rw_lang_en.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get rw_lang_en;

  /// No description provided for @rw_copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get rw_copy;

  /// No description provided for @rw_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get rw_copied;

  /// No description provided for @rw_a11y_ready.
  ///
  /// In ar, this message translates to:
  /// **'الصياغة المقترحة جاهزة: {text}'**
  String rw_a11y_ready(String text);

  /// No description provided for @rw_a11y_cached.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاؤها'**
  String get rw_a11y_cached;

  /// No description provided for @rw_a11y_version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {i} من {n}'**
  String rw_a11y_version(int i, int n);

  /// No description provided for @rw_a11y_prev.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get rw_a11y_prev;

  /// No description provided for @rw_a11y_next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get rw_a11y_next;

  /// No description provided for @rw_a11y_edit_result.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتعديل الصياغة، واضغط مطولًا للنسخ'**
  String get rw_a11y_edit_result;

  /// No description provided for @as_title.
  ///
  /// In ar, this message translates to:
  /// **'إسناد المحادثة'**
  String get as_title;

  /// No description provided for @as_title_bulk.
  ///
  /// In ar, this message translates to:
  /// **'إسناد {n} محادثات'**
  String as_title_bulk(int n);

  /// No description provided for @as_current.
  ///
  /// In ar, this message translates to:
  /// **'المسؤول الحالي: {name}'**
  String as_current(String name);

  /// No description provided for @as_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن زميل أو فريق'**
  String get as_search;

  /// No description provided for @as_no_results.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج لـ «{q}»'**
  String as_no_results(String q);

  /// No description provided for @as_filter_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get as_filter_all;

  /// No description provided for @as_filter_available.
  ///
  /// In ar, this message translates to:
  /// **'متاحون ({n})'**
  String as_filter_available(int n);

  /// No description provided for @as_filter_my_team.
  ///
  /// In ar, this message translates to:
  /// **'فريقي'**
  String get as_filter_my_team;

  /// No description provided for @as_suggested.
  ///
  /// In ar, this message translates to:
  /// **'مقترح'**
  String get as_suggested;

  /// No description provided for @as_teammates.
  ///
  /// In ar, this message translates to:
  /// **'الزملاء'**
  String get as_teammates;

  /// No description provided for @as_teams.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get as_teams;

  /// No description provided for @as_ai_section.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get as_ai_section;

  /// No description provided for @as_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get as_me;

  /// No description provided for @as_badge_current.
  ///
  /// In ar, this message translates to:
  /// **'الحالي'**
  String get as_badge_current;

  /// No description provided for @as_badge_capacity.
  ///
  /// In ar, this message translates to:
  /// **'عند الحد'**
  String get as_badge_capacity;

  /// No description provided for @as_online_m.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get as_online_m;

  /// No description provided for @as_online_f.
  ///
  /// In ar, this message translates to:
  /// **'متاحة'**
  String get as_online_f;

  /// No description provided for @as_busy_m.
  ///
  /// In ar, this message translates to:
  /// **'مشغول'**
  String get as_busy_m;

  /// No description provided for @as_busy_f.
  ///
  /// In ar, this message translates to:
  /// **'مشغولة'**
  String get as_busy_f;

  /// No description provided for @as_away.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get as_away;

  /// No description provided for @as_last_seen.
  ///
  /// In ar, this message translates to:
  /// **'آخر ظهور منذ {t}'**
  String as_last_seen(String t);

  /// No description provided for @as_open_count.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات مفتوحة'**
  String as_open_count(int n);

  /// No description provided for @as_members.
  ///
  /// In ar, this message translates to:
  /// **'{n} أعضاء'**
  String as_members(int n);

  /// No description provided for @as_available_count.
  ///
  /// In ar, this message translates to:
  /// **'{n} متاحون'**
  String as_available_count(int n);

  /// No description provided for @as_routing_least.
  ///
  /// In ar, this message translates to:
  /// **'يُسند لأقل زميل انشغالًا'**
  String get as_routing_least;

  /// No description provided for @as_routing_rr.
  ///
  /// In ar, this message translates to:
  /// **'يُسند بالتناوب'**
  String get as_routing_rr;

  /// No description provided for @as_routing_manual.
  ///
  /// In ar, this message translates to:
  /// **'يبقى في قائمة الفريق'**
  String get as_routing_manual;

  /// No description provided for @as_team_none_available.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أحد متاح الآن — ستنتظر في قائمة الفريق'**
  String get as_team_none_available;

  /// No description provided for @as_ai_name.
  ///
  /// In ar, this message translates to:
  /// **'وكيل الذكاء الاصطناعي'**
  String get as_ai_name;

  /// No description provided for @as_ai_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرد تلقائيًا ويحوّل للفريق عند الحاجة'**
  String get as_ai_sub;

  /// No description provided for @as_ai_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قاعدة معرفة كافية'**
  String get as_ai_unavailable;

  /// No description provided for @as_reason_handled.
  ///
  /// In ar, this message translates to:
  /// **'تعامل مع العميل سابقًا'**
  String get as_reason_handled;

  /// No description provided for @as_reason_handled_f.
  ///
  /// In ar, this message translates to:
  /// **'تعاملت مع العميل سابقًا'**
  String get as_reason_handled_f;

  /// No description provided for @as_reason_skill.
  ///
  /// In ar, this message translates to:
  /// **'خبير {skill}'**
  String as_reason_skill(String skill);

  /// No description provided for @as_reason_skill_f.
  ///
  /// In ar, this message translates to:
  /// **'خبيرة {skill}'**
  String as_reason_skill_f(String skill);

  /// No description provided for @as_reason_least.
  ///
  /// In ar, this message translates to:
  /// **'الأقل انشغالًا'**
  String get as_reason_least;

  /// No description provided for @as_note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة للزميل (اختياري)'**
  String get as_note;

  /// No description provided for @as_note_q1.
  ///
  /// In ar, this message translates to:
  /// **'العميل ينتظر ردًا عاجلًا'**
  String get as_note_q1;

  /// No description provided for @as_note_q2.
  ///
  /// In ar, this message translates to:
  /// **'موضوع دفع'**
  String get as_note_q2;

  /// No description provided for @as_note_q3.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج متابعة غدًا'**
  String get as_note_q3;

  /// No description provided for @as_pick.
  ///
  /// In ar, this message translates to:
  /// **'اختر زميلًا أو فريقًا'**
  String get as_pick;

  /// No description provided for @as_assign_to.
  ///
  /// In ar, this message translates to:
  /// **'إسناد إلى {name}'**
  String as_assign_to(String name);

  /// No description provided for @as_claim.
  ///
  /// In ar, this message translates to:
  /// **'استلم المحادثة'**
  String get as_claim;

  /// No description provided for @as_assign_ai.
  ///
  /// In ar, this message translates to:
  /// **'إسناد للذكاء الاصطناعي'**
  String get as_assign_ai;

  /// No description provided for @as_assign_bulk_to.
  ///
  /// In ar, this message translates to:
  /// **'إسناد {n} محادثات إلى {name}'**
  String as_assign_bulk_to(int n, String name);

  /// No description provided for @as_unassign.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإسناد (إرجاعها لغير المُسندة)'**
  String get as_unassign;

  /// No description provided for @as_busy_hint.
  ///
  /// In ar, this message translates to:
  /// **'مشغول الآن — قد يتأخر الرد'**
  String get as_busy_hint;

  /// No description provided for @as_busy_hint_f.
  ///
  /// In ar, this message translates to:
  /// **'مشغولة الآن — قد يتأخر الرد'**
  String get as_busy_hint_f;

  /// No description provided for @as_away_hint.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح — سيصله إشعار'**
  String get as_away_hint;

  /// No description provided for @as_away_hint_f.
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة — سيصلها إشعار'**
  String get as_away_hint_f;

  /// No description provided for @as_capacity_reached.
  ///
  /// In ar, this message translates to:
  /// **'وصل للحد الأقصى ({max})'**
  String as_capacity_reached(int max);

  /// No description provided for @as_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح للإسناد'**
  String get as_unavailable;

  /// No description provided for @as_taken_live.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name} للتو'**
  String as_taken_live(String name);

  /// No description provided for @as_reassign_to.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإسناد إلى {name}'**
  String as_reassign_to(String name);

  /// No description provided for @as_offline.
  ///
  /// In ar, this message translates to:
  /// **'الإسناد يتطلب اتصالًا بالإنترنت'**
  String get as_offline;

  /// No description provided for @as_none_available.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد زملاء متاحون الآن'**
  String get as_none_available;

  /// No description provided for @as_show_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get as_show_all;

  /// No description provided for @as_done.
  ///
  /// In ar, this message translates to:
  /// **'تم الإسناد إلى {name}'**
  String as_done(String name);

  /// No description provided for @as_done_bulk.
  ///
  /// In ar, this message translates to:
  /// **'تم إسناد {ok} من {n}'**
  String as_done_bulk(int ok, int n);

  /// No description provided for @as_show_errors.
  ///
  /// In ar, this message translates to:
  /// **'عرض الأخطاء'**
  String get as_show_errors;

  /// No description provided for @as_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get as_undo;

  /// No description provided for @as_forbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية الإسناد لهذا الزميل'**
  String get as_forbidden;

  /// No description provided for @as_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الإسناد. حاول مجددًا.'**
  String get as_error;

  /// No description provided for @as_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get as_retry;

  /// No description provided for @as_event_assigned.
  ///
  /// In ar, this message translates to:
  /// **'أسندت المحادثة إلى {name}'**
  String as_event_assigned(String name);

  /// No description provided for @as_event_undo.
  ///
  /// In ar, this message translates to:
  /// **'ألغى {actor} الإسناد'**
  String as_event_undo(String actor);

  /// No description provided for @as_resolved_live.
  ///
  /// In ar, this message translates to:
  /// **'تم حلّ المحادثة'**
  String get as_resolved_live;

  /// No description provided for @as_queued_team.
  ///
  /// In ar, this message translates to:
  /// **'في قائمة {team} بانتظار الاستلام'**
  String as_queued_team(String team);

  /// No description provided for @as_unassigned_done.
  ///
  /// In ar, this message translates to:
  /// **'أصبحت المحادثة غير مُسندة'**
  String get as_unassigned_done;

  /// No description provided for @as_errors_title.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إسناد {n}'**
  String as_errors_title(int n);

  /// No description provided for @as_err_same.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة له بالفعل'**
  String get as_err_same;

  /// No description provided for @as_err_resolved.
  ///
  /// In ar, this message translates to:
  /// **'المحادثة محلولة'**
  String get as_err_resolved;

  /// No description provided for @as_err_state.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر المسؤول'**
  String get as_err_state;

  /// No description provided for @as_err_generic.
  ///
  /// In ar, this message translates to:
  /// **'خطأ غير متوقع'**
  String get as_err_generic;

  /// No description provided for @as_expand_team.
  ///
  /// In ar, this message translates to:
  /// **'عرض أعضاء {team}'**
  String as_expand_team(String team);

  /// No description provided for @as_a11y_selected.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get as_a11y_selected;

  /// No description provided for @as_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الزملاء'**
  String get as_load_error;

  /// No description provided for @login_title.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بعودتك، سجّل دخولك للمتابعة'**
  String get login_subtitle;

  /// No description provided for @login_identifier_label.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو الجوال'**
  String get login_identifier_label;

  /// No description provided for @login_identifier_hint.
  ///
  /// In ar, this message translates to:
  /// **'name@company.com'**
  String get login_identifier_hint;

  /// No description provided for @login_password_label.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get login_password_label;

  /// No description provided for @login_password_show.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get login_password_show;

  /// No description provided for @login_password_hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get login_password_hide;

  /// No description provided for @login_forgot.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get login_forgot;

  /// No description provided for @login_submit.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login_submit;

  /// No description provided for @login_or.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get login_or;

  /// No description provided for @login_biometric_face.
  ///
  /// In ar, this message translates to:
  /// **'الدخول ببصمة الوجه'**
  String get login_biometric_face;

  /// No description provided for @login_biometric_finger.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالبصمة'**
  String get login_biometric_finger;

  /// No description provided for @login_biometric_reason.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول إلى Wavadesk'**
  String get login_biometric_reason;

  /// No description provided for @login_biometric_locked.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف البصمة مؤقتًا، استخدم كلمة المرور'**
  String get login_biometric_locked;

  /// No description provided for @login_no_account.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get login_no_account;

  /// No description provided for @login_start_trial.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ تجربة 7 أيام مجانًا'**
  String get login_start_trial;

  /// No description provided for @login_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل بالإنترنت'**
  String get login_offline;

  /// No description provided for @login_err_invalid.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get login_err_invalid;

  /// No description provided for @login_err_disabled.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف حسابك. تواصل مع مسؤول مساحة العمل'**
  String get login_err_disabled;

  /// No description provided for @login_err_suspended.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك مساحة العمل متوقف.'**
  String get login_err_suspended;

  /// No description provided for @login_manage_subscription.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get login_manage_subscription;

  /// No description provided for @login_err_locked.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. حاول مجددًا بعد {time}'**
  String login_err_locked(String time);

  /// No description provided for @login_err_network.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. تحقّق من الإنترنت وحاول مجددًا.'**
  String get login_err_network;

  /// No description provided for @login_err_server.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ، حاول مجددًا'**
  String get login_err_server;

  /// No description provided for @login_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get login_retry;

  /// No description provided for @login_val_identifier_required.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني أو رقم جوالك'**
  String get login_val_identifier_required;

  /// No description provided for @login_val_email_invalid.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد غير صحيحة'**
  String get login_val_email_invalid;

  /// No description provided for @login_val_phone_invalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال غير صحيح'**
  String get login_val_phone_invalid;

  /// No description provided for @login_val_password_required.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get login_val_password_required;

  /// No description provided for @login_val_password_short.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور 8 أحرف على الأقل'**
  String get login_val_password_short;

  /// No description provided for @login_bio_sheet_title.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك أسرع في المرة القادمة'**
  String get login_bio_sheet_title;

  /// No description provided for @login_bio_sheet_body.
  ///
  /// In ar, this message translates to:
  /// **'استخدم بصمة الوجه بدل كلمة المرور.'**
  String get login_bio_sheet_body;

  /// No description provided for @login_bio_sheet_body_finger.
  ///
  /// In ar, this message translates to:
  /// **'استخدم بصمة الإصبع بدل كلمة المرور.'**
  String get login_bio_sheet_body_finger;

  /// No description provided for @login_bio_sheet_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل بصمة الوجه'**
  String get login_bio_sheet_enable;

  /// No description provided for @login_bio_sheet_enable_finger.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل البصمة'**
  String get login_bio_sheet_enable_finger;

  /// No description provided for @login_bio_sheet_later.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get login_bio_sheet_later;

  /// No description provided for @auth_coming_soon_title.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get auth_coming_soon_title;

  /// No description provided for @auth_forgot_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور ستتوفر في تحديث قادم.'**
  String get auth_forgot_placeholder;

  /// No description provided for @auth_forgot_placeholder_for.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور لـ {identifier} ستتوفر في تحديث قادم.'**
  String auth_forgot_placeholder_for(String identifier);

  /// No description provided for @auth_2fa_title.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get auth_2fa_title;

  /// No description provided for @auth_2fa_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'إدخال رمز التحقق الثنائي سيتوفر في تحديث قادم.'**
  String get auth_2fa_placeholder;

  /// No description provided for @auth_workspace_title.
  ///
  /// In ar, this message translates to:
  /// **'اختر مساحة العمل'**
  String get auth_workspace_title;

  /// No description provided for @auth_workspace_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'حسابك مرتبط بأكثر من مساحة عمل. اختيار المساحة سيتوفر في تحديث قادم.'**
  String get auth_workspace_placeholder;

  /// No description provided for @login_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get login_email;

  /// No description provided for @login_register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get login_register;

  /// No description provided for @login_lang_title.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get login_lang_title;

  /// No description provided for @login_lang_a11y.
  ///
  /// In ar, this message translates to:
  /// **'اللغة: {lang}، تغيير'**
  String login_lang_a11y(String lang);

  /// No description provided for @login_err_email_empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني'**
  String get login_err_email_empty;

  /// No description provided for @login_err_email_format.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من صيغة البريد الإلكتروني'**
  String get login_err_email_format;

  /// No description provided for @login_err_pw_empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get login_err_pw_empty;

  /// No description provided for @login_err_offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get login_err_offline;

  /// No description provided for @login_session_expired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلستك، سجّل الدخول مجددًا'**
  String get login_session_expired;

  /// No description provided for @chat_ai_suggestion.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح الذكاء الاصطناعي'**
  String get chat_ai_suggestion;

  /// No description provided for @chat_ai_source.
  ///
  /// In ar, this message translates to:
  /// **'من: {title}'**
  String chat_ai_source(String title);

  /// No description provided for @chat_ai_send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get chat_ai_send;

  /// No description provided for @chat_ai_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get chat_ai_edit;

  /// No description provided for @chat_ai_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get chat_ai_more;

  /// No description provided for @chat_ai_low_conf.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من الرد قبل الإرسال'**
  String get chat_ai_low_conf;

  /// No description provided for @chat_ai_writing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب الاقتراح…'**
  String get chat_ai_writing;

  /// No description provided for @chat_ai_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'لم يجد الذكاء إجابة في قاعدة المعرفة'**
  String get chat_ai_no_answer;

  /// No description provided for @chat_ai_add_answer.
  ///
  /// In ar, this message translates to:
  /// **'أضف إجابة'**
  String get chat_ai_add_answer;

  /// No description provided for @chat_ai_ready_pill.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح جاهز'**
  String get chat_ai_ready_pill;

  /// No description provided for @chat_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردًّا…'**
  String get chat_placeholder;

  /// No description provided for @chat_note_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظة لفريقك — لن يراها العميل'**
  String get chat_note_placeholder;

  /// No description provided for @chat_mode_reply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get chat_mode_reply;

  /// No description provided for @chat_mode_note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية'**
  String get chat_mode_note;

  /// No description provided for @chat_attach_media.
  ///
  /// In ar, this message translates to:
  /// **'صورة/فيديو'**
  String get chat_attach_media;

  /// No description provided for @chat_attach_camera.
  ///
  /// In ar, this message translates to:
  /// **'كاميرا'**
  String get chat_attach_camera;

  /// No description provided for @chat_attach_file.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get chat_attach_file;

  /// No description provided for @chat_attach_location.
  ///
  /// In ar, this message translates to:
  /// **'موقع'**
  String get chat_attach_location;

  /// No description provided for @chat_attach_quick.
  ///
  /// In ar, this message translates to:
  /// **'ردود سريعة'**
  String get chat_attach_quick;

  /// No description provided for @chat_attach_template.
  ///
  /// In ar, this message translates to:
  /// **'قالب واتساب'**
  String get chat_attach_template;

  /// No description provided for @chat_attach_product.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get chat_attach_product;

  /// No description provided for @chat_record_cancel_hint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للإلغاء'**
  String get chat_record_cancel_hint;

  /// No description provided for @chat_claim.
  ///
  /// In ar, this message translates to:
  /// **'استلم المحادثة'**
  String get chat_claim;

  /// No description provided for @chat_assign_colleague.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لزميل'**
  String get chat_assign_colleague;

  /// No description provided for @chat_viewing_now.
  ///
  /// In ar, this message translates to:
  /// **'{name} تشاهد هذه المحادثة الآن'**
  String chat_viewing_now(String name);

  /// No description provided for @chat_waiting_claim.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الاستلام'**
  String get chat_waiting_claim;

  /// No description provided for @chat_claimed_before.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name} قبلك'**
  String chat_claimed_before(String name);

  /// No description provided for @chat_ro_colleague.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة إلى {name}'**
  String chat_ro_colleague(String name);

  /// No description provided for @chat_ro_request.
  ///
  /// In ar, this message translates to:
  /// **'اطلب التحويل'**
  String get chat_ro_request;

  /// No description provided for @chat_ro_resolved.
  ///
  /// In ar, this message translates to:
  /// **'المحادثة محلولة'**
  String get chat_ro_resolved;

  /// No description provided for @chat_reopen.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الفتح'**
  String get chat_reopen;

  /// No description provided for @chat_ro_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي يتولى هذه المحادثة'**
  String get chat_ro_ai;

  /// No description provided for @chat_take_over.
  ///
  /// In ar, this message translates to:
  /// **'تولَّ المحادثة'**
  String get chat_take_over;

  /// No description provided for @chat_ro_blocked.
  ///
  /// In ar, this message translates to:
  /// **'هذا العميل محظور'**
  String get chat_ro_blocked;

  /// No description provided for @chat_unblock.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحظر'**
  String get chat_unblock;

  /// No description provided for @chat_ro_past.
  ///
  /// In ar, this message translates to:
  /// **'محادثة سابقة — للقراءة فقط'**
  String get chat_ro_past;

  /// No description provided for @chat_banner_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل — ستُرسل رسائلك عند عودة الاتصال'**
  String get chat_banner_offline;

  /// No description provided for @chat_banner_window_closed.
  ///
  /// In ar, this message translates to:
  /// **'انتهت نافذة 24 ساعة — يمكنك إرسال قالب معتمد فقط'**
  String get chat_banner_window_closed;

  /// No description provided for @chat_choose_template.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالبًا'**
  String get chat_choose_template;

  /// No description provided for @chat_banner_window_soon.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي نافذة الرد خلال {t}'**
  String chat_banner_window_soon(String t);

  /// No description provided for @chat_banner_channel_down.
  ///
  /// In ar, this message translates to:
  /// **'واتساب غير متصل — لن تصل الرسائل'**
  String get chat_banner_channel_down;

  /// No description provided for @chat_reconnect.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الربط'**
  String get chat_reconnect;

  /// No description provided for @chat_snoozed_until.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة حتى {t}'**
  String chat_snoozed_until(String t);

  /// No description provided for @chat_unsnooze.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التأجيل'**
  String get chat_unsnooze;

  /// No description provided for @composer_attach.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق'**
  String get composer_attach;

  /// No description provided for @composer_send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get composer_send;

  /// No description provided for @composer_send_note.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الملاحظة'**
  String get composer_send_note;

  /// No description provided for @composer_record.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولًا لتسجيل رسالة صوتية'**
  String get composer_record;

  /// No description provided for @composer_recording.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التسجيل'**
  String get composer_recording;

  /// No description provided for @composer_record_stop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get composer_record_stop;

  /// No description provided for @composer_record_send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التسجيل'**
  String get composer_record_send;

  /// No description provided for @composer_record_cancelled.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي التسجيل'**
  String get composer_record_cancelled;

  /// No description provided for @composer_record_locked.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل مستمر بدون ضغط'**
  String get composer_record_locked;

  /// No description provided for @composer_record_slide_up.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأعلى للتثبيت'**
  String get composer_record_slide_up;

  /// No description provided for @composer_ai_rewrite.
  ///
  /// In ar, this message translates to:
  /// **'حسّن الرد بالذكاء الاصطناعي'**
  String get composer_ai_rewrite;

  /// No description provided for @composer_saved_replies.
  ///
  /// In ar, this message translates to:
  /// **'الردود المحفوظة'**
  String get composer_saved_replies;

  /// No description provided for @composer_field_label.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردًّا'**
  String get composer_field_label;

  /// No description provided for @composer_note_field_label.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظة داخلية'**
  String get composer_note_field_label;

  /// No description provided for @composer_template.
  ///
  /// In ar, this message translates to:
  /// **'قالب'**
  String get composer_template;

  /// No description provided for @composer_template_only.
  ///
  /// In ar, this message translates to:
  /// **'النافذة مغلقة — أرسل قالبًا معتمدًا'**
  String get composer_template_only;

  /// No description provided for @composer_colleague_typing_note.
  ///
  /// In ar, this message translates to:
  /// **'{name} يكتب ملاحظة…'**
  String composer_colleague_typing_note(String name);

  /// No description provided for @composer_colleague_viewing.
  ///
  /// In ar, this message translates to:
  /// **'{name} يشاهد أيضًا'**
  String composer_colleague_viewing(String name);

  /// No description provided for @composer_quick_title.
  ///
  /// In ar, this message translates to:
  /// **'ردود سريعة'**
  String get composer_quick_title;

  /// No description provided for @composer_quick_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ردود سريعة مطابقة'**
  String get composer_quick_empty;

  /// No description provided for @composer_mention_title.
  ///
  /// In ar, this message translates to:
  /// **'اذكر زميلًا'**
  String get composer_mention_title;

  /// No description provided for @composer_reply_to.
  ///
  /// In ar, this message translates to:
  /// **'رد على {name}'**
  String composer_reply_to(String name);

  /// No description provided for @composer_cancel_reply.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الرد'**
  String get composer_cancel_reply;

  /// No description provided for @composer_remove_attachment.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المرفق'**
  String get composer_remove_attachment;

  /// No description provided for @composer_uploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع {percent}٪'**
  String composer_uploading(int percent);

  /// No description provided for @composer_customer.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get composer_customer;

  /// No description provided for @composer_location_sample.
  ///
  /// In ar, this message translates to:
  /// **'حي الملقا، الرياض'**
  String get composer_location_sample;

  /// No description provided for @aicard_close.
  ///
  /// In ar, this message translates to:
  /// **'طي الاقتراح'**
  String get aicard_close;

  /// No description provided for @aicard_regenerate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إنشاء الاقتراح'**
  String get aicard_regenerate;

  /// No description provided for @aicard_less.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get aicard_less;

  /// No description provided for @aicard_open_pill.
  ///
  /// In ar, this message translates to:
  /// **'عرض اقتراح الذكاء الاصطناعي'**
  String get aicard_open_pill;

  /// No description provided for @claimbar_waiting_minutes.
  ///
  /// In ar, this message translates to:
  /// **'{n} د'**
  String claimbar_waiting_minutes(int n);

  /// No description provided for @claimbar_viewers_more.
  ///
  /// In ar, this message translates to:
  /// **'{name} و{count, plural, =1{زميل آخر} =2{زميلان آخران} few{{count} زملاء آخرين} other{{count} زميلًا آخر}} يشاهدون المحادثة'**
  String claimbar_viewers_more(String name, int count);

  /// No description provided for @readonly_take_instead.
  ///
  /// In ar, this message translates to:
  /// **'استلم بدلًا عنه'**
  String get readonly_take_instead;

  /// No description provided for @readonly_add_note.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة داخلية'**
  String get readonly_add_note;

  /// No description provided for @banner_connecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال…'**
  String get banner_connecting;

  /// No description provided for @composer_mic_denied.
  ///
  /// In ar, this message translates to:
  /// **'اسمح بالوصول إلى الميكروفون من الإعدادات لتسجيل الرسائل الصوتية.'**
  String get composer_mic_denied;

  /// No description provided for @composer_record_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التسجيل. حاول مرة أخرى.'**
  String get composer_record_failed;

  /// No description provided for @composer_record_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف التسجيل'**
  String get composer_record_delete;

  /// No description provided for @chat_ai_suggest_pill.
  ///
  /// In ar, this message translates to:
  /// **'اقترح ردًا'**
  String get chat_ai_suggest_pill;

  /// No description provided for @composer_file_too_big.
  ///
  /// In ar, this message translates to:
  /// **'حجم كبير لا يمكن إرساله: {names}. الصور حتى 5 ميجابايت، والفيديو والصوت 16، والمستندات 10.'**
  String composer_file_too_big(String names);

  /// No description provided for @composer_file_type.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إرسال هذا النوع من الملفات: {names}'**
  String composer_file_type(String names);

  /// No description provided for @composer_upload_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الرفع'**
  String get composer_upload_failed;

  /// No description provided for @composer_upload_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الرفع'**
  String get composer_upload_retry;

  /// No description provided for @sys_called.
  ///
  /// In ar, this message translates to:
  /// **'اتصل {actor} بالعميل'**
  String sys_called(String actor);

  /// No description provided for @sys_called_me.
  ///
  /// In ar, this message translates to:
  /// **'اتصلت بالعميل'**
  String get sys_called_me;

  /// No description provided for @snooze_title.
  ///
  /// In ar, this message translates to:
  /// **'تأجيل المحادثة'**
  String get snooze_title;

  /// No description provided for @snooze_one_hour.
  ///
  /// In ar, this message translates to:
  /// **'بعد ساعة'**
  String get snooze_one_hour;

  /// No description provided for @snooze_three_hours.
  ///
  /// In ar, this message translates to:
  /// **'بعد 3 ساعات'**
  String get snooze_three_hours;

  /// No description provided for @snooze_tomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا 9 ص'**
  String get snooze_tomorrow;

  /// No description provided for @snooze_next_week.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع القادم'**
  String get snooze_next_week;

  /// No description provided for @snooze_custom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get snooze_custom;

  /// No description provided for @sys_claimed.
  ///
  /// In ar, this message translates to:
  /// **'استلم {actor} المحادثة'**
  String sys_claimed(String actor);

  /// No description provided for @sys_claimed_me.
  ///
  /// In ar, this message translates to:
  /// **'استلمت المحادثة'**
  String get sys_claimed_me;

  /// No description provided for @sys_assigned.
  ///
  /// In ar, this message translates to:
  /// **'أسند {actor} المحادثة إلى {target}'**
  String sys_assigned(String actor, String target);

  /// No description provided for @sys_assigned_me.
  ///
  /// In ar, this message translates to:
  /// **'أسندت المحادثة إلى {target}'**
  String sys_assigned_me(String target);

  /// No description provided for @sys_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'حرّر {actor} المحادثة'**
  String sys_unassigned(String actor);

  /// No description provided for @sys_unassigned_me.
  ///
  /// In ar, this message translates to:
  /// **'حرّرت المحادثة'**
  String get sys_unassigned_me;

  /// No description provided for @sys_ai_handoff.
  ///
  /// In ar, this message translates to:
  /// **'حوّل الذكاء الاصطناعي المحادثة للفريق: {reason}'**
  String sys_ai_handoff(String reason);

  /// No description provided for @sys_ai_paused.
  ///
  /// In ar, this message translates to:
  /// **'أوقف {actor} الذكاء الاصطناعي لهذه المحادثة'**
  String sys_ai_paused(String actor);

  /// No description provided for @sys_ai_paused_me.
  ///
  /// In ar, this message translates to:
  /// **'أوقفت الذكاء الاصطناعي لهذه المحادثة'**
  String get sys_ai_paused_me;

  /// No description provided for @sys_ai_resumed.
  ///
  /// In ar, this message translates to:
  /// **'فعّل {actor} الذكاء الاصطناعي لهذه المحادثة'**
  String sys_ai_resumed(String actor);

  /// No description provided for @sys_ai_resumed_me.
  ///
  /// In ar, this message translates to:
  /// **'فعّلت الذكاء الاصطناعي لهذه المحادثة'**
  String get sys_ai_resumed_me;

  /// No description provided for @sys_resolved.
  ///
  /// In ar, this message translates to:
  /// **'حلّ {actor} المحادثة'**
  String sys_resolved(String actor);

  /// No description provided for @sys_resolved_me.
  ///
  /// In ar, this message translates to:
  /// **'حللت المحادثة'**
  String get sys_resolved_me;

  /// No description provided for @sys_reopened.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد فتح المحادثة'**
  String get sys_reopened;

  /// No description provided for @sys_snoozed.
  ///
  /// In ar, this message translates to:
  /// **'أجّل {actor} المحادثة حتى {time}'**
  String sys_snoozed(String actor, String time);

  /// No description provided for @sys_snoozed_me.
  ///
  /// In ar, this message translates to:
  /// **'أجّلت المحادثة حتى {time}'**
  String sys_snoozed_me(String time);

  /// No description provided for @sys_priority.
  ///
  /// In ar, this message translates to:
  /// **'غيّر {actor} الأولوية إلى {value}'**
  String sys_priority(String actor, String value);

  /// No description provided for @sys_priority_me.
  ///
  /// In ar, this message translates to:
  /// **'غيّرت الأولوية إلى {value}'**
  String sys_priority_me(String value);

  /// No description provided for @sys_tag_added.
  ///
  /// In ar, this message translates to:
  /// **'أضاف {actor} وسم «{tag}»'**
  String sys_tag_added(String actor, String tag);

  /// No description provided for @sys_tag_added_me.
  ///
  /// In ar, this message translates to:
  /// **'أضفت وسم «{tag}»'**
  String sys_tag_added_me(String tag);

  /// No description provided for @sys_window_closed.
  ///
  /// In ar, this message translates to:
  /// **'انتهت نافذة الرد 24 ساعة'**
  String get sys_window_closed;

  /// No description provided for @sys_blocked.
  ///
  /// In ar, this message translates to:
  /// **'حظر {actor} هذا العميل'**
  String sys_blocked(String actor);

  /// No description provided for @sys_blocked_me.
  ///
  /// In ar, this message translates to:
  /// **'حظرت هذا العميل'**
  String get sys_blocked_me;

  /// No description provided for @sys_unblocked.
  ///
  /// In ar, this message translates to:
  /// **'ألغى {actor} حظر هذا العميل'**
  String sys_unblocked(String actor);

  /// No description provided for @sys_unblocked_me.
  ///
  /// In ar, this message translates to:
  /// **'ألغيت حظر هذا العميل'**
  String get sys_unblocked_me;

  /// No description provided for @sys_started.
  ///
  /// In ar, this message translates to:
  /// **'بدأت المحادثة عبر {channel}'**
  String sys_started(String channel);

  /// No description provided for @msgaction_add_to_profile.
  ///
  /// In ar, this message translates to:
  /// **'إضافة لملف العميل'**
  String get msgaction_add_to_profile;

  /// No description provided for @msgaction_added_to_profile.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت الملاحظة إلى ملف العميل'**
  String get msgaction_added_to_profile;

  /// No description provided for @chat_new_messages.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{رسالة جديدة} =2{رسالتان جديدتان} few{{n} رسائل جديدة} other{{n} رسالة جديدة}}'**
  String chat_new_messages(int n);

  /// No description provided for @chat_ai_reply_label.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء الاصطناعي'**
  String get chat_ai_reply_label;

  /// No description provided for @chat_note_label.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية · {name}'**
  String chat_note_label(String name);

  /// No description provided for @chat_failed.
  ///
  /// In ar, this message translates to:
  /// **'لم تُرسل'**
  String get chat_failed;

  /// No description provided for @chat_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get chat_retry;

  /// No description provided for @chat_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get chat_delete;

  /// No description provided for @chat_edited.
  ///
  /// In ar, this message translates to:
  /// **'معدّلة'**
  String get chat_edited;

  /// No description provided for @chat_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف هذه الرسالة'**
  String get chat_deleted;

  /// No description provided for @chat_unsupported.
  ///
  /// In ar, this message translates to:
  /// **'نوع رسالة غير مدعوم — افتحها في واتساب'**
  String get chat_unsupported;

  /// No description provided for @chat_transcribe.
  ///
  /// In ar, this message translates to:
  /// **'تحويل لنص'**
  String get chat_transcribe;

  /// No description provided for @bubble_template_label.
  ///
  /// In ar, this message translates to:
  /// **'قالب: {name}'**
  String bubble_template_label(String name);

  /// No description provided for @bubble_show_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get bubble_show_all;

  /// No description provided for @bubble_show_less.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get bubble_show_less;

  /// No description provided for @bubble_save_contact.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get bubble_save_contact;

  /// No description provided for @bubble_contact_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ جهة الاتصال'**
  String get bubble_contact_saved;

  /// No description provided for @bubble_play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الرسالة الصوتية'**
  String get bubble_play;

  /// No description provided for @bubble_pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الرسالة الصوتية مؤقتًا'**
  String get bubble_pause;

  /// No description provided for @bubble_speed.
  ///
  /// In ar, this message translates to:
  /// **'سرعة التشغيل {speed}'**
  String bubble_speed(String speed);

  /// No description provided for @bubble_voice_summary.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{رسالة صوتية ثانية واحدة} =2{رسالة صوتية ثانيتان} few{رسالة صوتية {n} ثوانٍ} other{رسالة صوتية {n} ثانية}}'**
  String bubble_voice_summary(int n);

  /// No description provided for @bubble_image_from.
  ///
  /// In ar, this message translates to:
  /// **'صورة من {name}'**
  String bubble_image_from(String name);

  /// No description provided for @bubble_album_summary.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =2{صورتان} few{{n} صور} other{{n} صورة}}'**
  String bubble_album_summary(int n);

  /// No description provided for @bubble_video_summary.
  ///
  /// In ar, this message translates to:
  /// **'فيديو {duration}'**
  String bubble_video_summary(String duration);

  /// No description provided for @bubble_play_video.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الفيديو'**
  String get bubble_play_video;

  /// No description provided for @bubble_video_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الفيديو غير متاحة في البيانات التجريبية'**
  String get bubble_video_unavailable;

  /// No description provided for @bubble_download.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل الملف'**
  String get bubble_download;

  /// No description provided for @bubble_downloaded.
  ///
  /// In ar, this message translates to:
  /// **'تم تنزيل الملف'**
  String get bubble_downloaded;

  /// No description provided for @bubble_open_maps.
  ///
  /// In ar, this message translates to:
  /// **'فتح الموقع في الخرائط'**
  String get bubble_open_maps;

  /// No description provided for @bubble_transcribing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحويل إلى نص…'**
  String get bubble_transcribing;

  /// No description provided for @bubble_transcript.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get bubble_transcript;

  /// No description provided for @bubble_delivery_sending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الإرسال'**
  String get bubble_delivery_sending;

  /// No description provided for @bubble_delivery_sent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت'**
  String get bubble_delivery_sent;

  /// No description provided for @bubble_delivery_delivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get bubble_delivery_delivered;

  /// No description provided for @bubble_delivery_read.
  ///
  /// In ar, this message translates to:
  /// **'تمت القراءة'**
  String get bubble_delivery_read;

  /// No description provided for @bubble_reply_to.
  ///
  /// In ar, this message translates to:
  /// **'رد على {name}'**
  String bubble_reply_to(String name);

  /// No description provided for @bubble_viewer_share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get bubble_viewer_share;

  /// No description provided for @bubble_viewer_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get bubble_viewer_save;

  /// No description provided for @bubble_viewer_sample.
  ///
  /// In ar, this message translates to:
  /// **'هذه صورة تجريبية ولا يمكن مشاركتها أو حفظها'**
  String get bubble_viewer_sample;

  /// No description provided for @bubble_reactions.
  ///
  /// In ar, this message translates to:
  /// **'التفاعلات: {emojis}'**
  String bubble_reactions(String emojis);

  /// No description provided for @chatlist_jump_latest.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال إلى أحدث رسالة'**
  String get chatlist_jump_latest;

  /// No description provided for @chatlist_loading_older.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل الرسائل الأقدم'**
  String get chatlist_loading_older;

  /// No description provided for @chatlist_typing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب الآن…'**
  String get chatlist_typing;

  /// No description provided for @msgaction_reply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get msgaction_reply;

  /// No description provided for @msgaction_copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get msgaction_copy;

  /// No description provided for @msgaction_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرسالة'**
  String get msgaction_copied;

  /// No description provided for @msgaction_forward.
  ///
  /// In ar, this message translates to:
  /// **'إعادة توجيه'**
  String get msgaction_forward;

  /// No description provided for @msgaction_forward_soon.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التوجيه ستتوفر قريبًا'**
  String get msgaction_forward_soon;

  /// No description provided for @msgaction_save_kb.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في قاعدة المعرفة'**
  String get msgaction_save_kb;

  /// No description provided for @msgaction_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات'**
  String get msgaction_info;

  /// No description provided for @msgaction_info_title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الرسالة'**
  String get msgaction_info_title;

  /// No description provided for @msgaction_info_sent.
  ///
  /// In ar, this message translates to:
  /// **'وقت الإرسال'**
  String get msgaction_info_sent;

  /// No description provided for @msgaction_info_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get msgaction_info_status;

  /// No description provided for @msgaction_info_channel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get msgaction_info_channel;

  /// No description provided for @msgaction_info_via.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الإرسال'**
  String get msgaction_info_via;

  /// No description provided for @msgaction_via_manual.
  ///
  /// In ar, this message translates to:
  /// **'كتابة يدوية'**
  String get msgaction_via_manual;

  /// No description provided for @msgaction_via_ai_suggestion.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح الذكاء الاصطناعي'**
  String get msgaction_via_ai_suggestion;

  /// No description provided for @msgaction_via_ai_edited.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح معدّل'**
  String get msgaction_via_ai_edited;

  /// No description provided for @msgaction_via_quick_reply.
  ///
  /// In ar, this message translates to:
  /// **'رد سريع'**
  String get msgaction_via_quick_reply;

  /// No description provided for @msgaction_via_template.
  ///
  /// In ar, this message translates to:
  /// **'قالب معتمد'**
  String get msgaction_via_template;

  /// No description provided for @msgaction_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الرسالة؟'**
  String get msgaction_delete_title;

  /// No description provided for @msgaction_delete_body.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف الرسالة لدى الجميع إن كانت القناة تسمح بذلك. لا يمكن التراجع.'**
  String get msgaction_delete_body;

  /// No description provided for @msgaction_rate.
  ///
  /// In ar, this message translates to:
  /// **'تقييم الرد'**
  String get msgaction_rate;

  /// No description provided for @msgaction_rate_up.
  ///
  /// In ar, this message translates to:
  /// **'رد مفيد'**
  String get msgaction_rate_up;

  /// No description provided for @msgaction_rate_down.
  ///
  /// In ar, this message translates to:
  /// **'رد غير مفيد'**
  String get msgaction_rate_down;

  /// No description provided for @msgaction_rated.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا، سيتعلم الذكاء الاصطناعي من تقييمك'**
  String get msgaction_rated;

  /// No description provided for @msgaction_more_reactions.
  ///
  /// In ar, this message translates to:
  /// **'المزيد من التفاعلات'**
  String get msgaction_more_reactions;

  /// No description provided for @msgaction_pick_reaction.
  ///
  /// In ar, this message translates to:
  /// **'اختر تفاعلًا'**
  String get msgaction_pick_reaction;

  /// No description provided for @msgaction_react.
  ///
  /// In ar, this message translates to:
  /// **'تفاعل {emoji}'**
  String msgaction_react(String emoji);

  /// No description provided for @bubble_file_sending.
  ///
  /// In ar, this message translates to:
  /// **'ما زال قيد الإرسال، حاول بعد لحظات'**
  String get bubble_file_sending;

  /// No description provided for @bubble_file_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف غير متاح على الهاتف'**
  String get bubble_file_unavailable;

  /// No description provided for @bubble_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ: {name}'**
  String bubble_saved(String name);

  /// No description provided for @bubble_save_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنزيل الملف. حاول مرة أخرى.'**
  String get bubble_save_failed;

  /// No description provided for @bubble_open_file.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get bubble_open_file;

  /// No description provided for @bubble_tap_retry.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لإعادة المحاولة'**
  String get bubble_tap_retry;

  /// No description provided for @bubble_photo_fetching.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ جلب الصورة…'**
  String get bubble_photo_fetching;

  /// No description provided for @bubble_photo_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'الصورة غير متاحة'**
  String get bubble_photo_unavailable;

  /// No description provided for @chatscreen_load_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المحادثة'**
  String get chatscreen_load_failed;

  /// No description provided for @chatscreen_not_found.
  ///
  /// In ar, this message translates to:
  /// **'لم نعثر على هذه المحادثة'**
  String get chatscreen_not_found;

  /// No description provided for @chatscreen_action_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ الإجراء. حاول مجددًا.'**
  String get chatscreen_action_failed;

  /// No description provided for @chatscreen_taken_from_me.
  ///
  /// In ar, this message translates to:
  /// **'أُسندت المحادثة إلى {name}'**
  String chatscreen_taken_from_me(String name);

  /// No description provided for @chatscreen_claimed_by.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name}'**
  String chatscreen_claimed_by(String name);

  /// No description provided for @chatscreen_transfer_note.
  ///
  /// In ar, this message translates to:
  /// **'@{name} أرجو تحويل هذه المحادثة إليّ لأتابعها.'**
  String chatscreen_transfer_note(String name);

  /// No description provided for @chatscreen_transfer_sent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب التحويل إلى {name}'**
  String chatscreen_transfer_sent(String name);

  /// No description provided for @chatscreen_takeover_title.
  ///
  /// In ar, this message translates to:
  /// **'استلام المحادثة من زميل؟'**
  String get chatscreen_takeover_title;

  /// No description provided for @chatscreen_takeover_body.
  ///
  /// In ar, this message translates to:
  /// **'ستُسند المحادثة إليك بدلًا من {name} وسيصله إشعار بذلك.'**
  String chatscreen_takeover_body(String name);

  /// No description provided for @chatscreen_takeover_confirm.
  ///
  /// In ar, this message translates to:
  /// **'استلم بدلًا عنه'**
  String get chatscreen_takeover_confirm;

  /// No description provided for @chat_online.
  ///
  /// In ar, this message translates to:
  /// **'متصل الآن'**
  String get chat_online;

  /// No description provided for @chat_last_seen.
  ///
  /// In ar, this message translates to:
  /// **'آخر ظهور {time}'**
  String chat_last_seen(String time);

  /// No description provided for @chat_typing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب الآن…'**
  String get chat_typing;

  /// No description provided for @chat_assigned_you.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لك'**
  String get chat_assigned_you;

  /// No description provided for @chat_assigned_to.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لـ{name}'**
  String chat_assigned_to(String name);

  /// No description provided for @chat_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get chat_unassigned;

  /// No description provided for @chat_ai_handling.
  ///
  /// In ar, this message translates to:
  /// **'يتولاها الذكاء الاصطناعي'**
  String get chat_ai_handling;

  /// No description provided for @chat_resolve.
  ///
  /// In ar, this message translates to:
  /// **'حلّ المحادثة'**
  String get chat_resolve;

  /// No description provided for @chat_resolved_toast.
  ///
  /// In ar, this message translates to:
  /// **'تم حلّ المحادثة'**
  String get chat_resolved_toast;

  /// No description provided for @chat_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get chat_undo;

  /// No description provided for @chatbar_browsing.
  ///
  /// In ar, this message translates to:
  /// **'يتصفح: {page}'**
  String chatbar_browsing(String page);

  /// No description provided for @chatbar_back_unread.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{رجوع، محادثة أخرى غير مقروءة} =2{رجوع، محادثتان أخريان غير مقروءتين} few{رجوع، {n} محادثات أخرى غير مقروءة} other{رجوع، {n} محادثة أخرى غير مقروءة}}'**
  String chatbar_back_unread(int n);

  /// No description provided for @chatbar_open_profile.
  ///
  /// In ar, this message translates to:
  /// **'فتح ملف {name}'**
  String chatbar_open_profile(String name);

  /// No description provided for @chatbar_call.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get chatbar_call;

  /// No description provided for @chatbar_more.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات المحادثة'**
  String get chatbar_more;

  /// No description provided for @chatbar_call_phone.
  ///
  /// In ar, this message translates to:
  /// **'اتصال هاتفي'**
  String get chatbar_call_phone;

  /// No description provided for @chatbar_call_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'اتصال واتساب'**
  String get chatbar_call_whatsapp;

  /// No description provided for @chatbar_call_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء الاتصال على هذا الجهاز'**
  String get chatbar_call_failed;

  /// No description provided for @strip_snoozed_until.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة حتى {t}'**
  String strip_snoozed_until(String t);

  /// No description provided for @strip_order.
  ///
  /// In ar, this message translates to:
  /// **'طلب {ref}'**
  String strip_order(String ref);

  /// No description provided for @strip_no_store_integration.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تكامل مع المتجر بعد'**
  String get strip_no_store_integration;

  /// No description provided for @strip_add_tag.
  ///
  /// In ar, this message translates to:
  /// **'وسم'**
  String get strip_add_tag;

  /// No description provided for @snoozepick_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'ستعود المحادثة إلى قائمتك في الوقت المحدد'**
  String get snoozepick_subtitle;

  /// No description provided for @templates_title.
  ///
  /// In ar, this message translates to:
  /// **'القوالب المعتمدة'**
  String get templates_title;

  /// No description provided for @templates_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'قوالب واتساب الموافق عليها من Meta'**
  String get templates_subtitle;

  /// No description provided for @templates_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قوالب معتمدة بعد'**
  String get templates_empty;

  /// No description provided for @templates_sent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال القالب'**
  String get templates_sent;

  /// No description provided for @actions_assign.
  ///
  /// In ar, this message translates to:
  /// **'إسناد'**
  String get actions_assign;

  /// No description provided for @actions_change_owner.
  ///
  /// In ar, this message translates to:
  /// **'إسناد / تغيير المسؤول'**
  String get actions_change_owner;

  /// No description provided for @actions_unassign.
  ///
  /// In ar, this message translates to:
  /// **'تحرير من المسؤولية'**
  String get actions_unassign;

  /// No description provided for @actions_unassigned_toast.
  ///
  /// In ar, this message translates to:
  /// **'أُعيدت المحادثة إلى غير المُسندة'**
  String get actions_unassigned_toast;

  /// No description provided for @actions_snooze.
  ///
  /// In ar, this message translates to:
  /// **'تأجيل'**
  String get actions_snooze;

  /// No description provided for @actions_snoozed_toast.
  ///
  /// In ar, this message translates to:
  /// **'أُجّلت المحادثة'**
  String get actions_snoozed_toast;

  /// No description provided for @actions_priority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get actions_priority;

  /// No description provided for @actions_tag.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وسم'**
  String get actions_tag;

  /// No description provided for @actions_tag_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر الوسوم أو أضف وسمًا جديدًا'**
  String get actions_tag_subtitle;

  /// No description provided for @actions_tag_new_hint.
  ///
  /// In ar, this message translates to:
  /// **'وسم جديد'**
  String get actions_tag_new_hint;

  /// No description provided for @actions_tag_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الوسم'**
  String get actions_tag_add;

  /// No description provided for @actions_ai_pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الذكاء الاصطناعي لهذه المحادثة'**
  String get actions_ai_pause;

  /// No description provided for @actions_ai_resume.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الذكاء الاصطناعي لهذه المحادثة'**
  String get actions_ai_resume;

  /// No description provided for @actions_ai_paused_toast.
  ///
  /// In ar, this message translates to:
  /// **'أُوقف الذكاء الاصطناعي لهذه المحادثة'**
  String get actions_ai_paused_toast;

  /// No description provided for @actions_ai_resumed_toast.
  ///
  /// In ar, this message translates to:
  /// **'فُعّل الذكاء الاصطناعي لهذه المحادثة'**
  String get actions_ai_resumed_toast;

  /// No description provided for @actions_mark_unread.
  ///
  /// In ar, this message translates to:
  /// **'وضع علامة غير مقروءة'**
  String get actions_mark_unread;

  /// No description provided for @actions_export.
  ///
  /// In ar, this message translates to:
  /// **'تصدير المحادثة'**
  String get actions_export;

  /// No description provided for @actions_export_note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية'**
  String get actions_export_note;

  /// No description provided for @actions_exported_toast.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ نص المحادثة، الصقه حيث تريد'**
  String get actions_exported_toast;

  /// No description provided for @actions_block.
  ///
  /// In ar, this message translates to:
  /// **'حظر العميل'**
  String get actions_block;

  /// No description provided for @actions_unblock.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء حظر العميل'**
  String get actions_unblock;

  /// No description provided for @actions_block_title.
  ///
  /// In ar, this message translates to:
  /// **'حظر {name}؟'**
  String actions_block_title(String name);

  /// No description provided for @actions_block_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك رسائل هذا العميل وستُغلق المحادثة. يمكنك إلغاء الحظر لاحقًا.'**
  String get actions_block_body;

  /// No description provided for @actions_blocked_toast.
  ///
  /// In ar, this message translates to:
  /// **'تم حظر العميل'**
  String get actions_blocked_toast;

  /// No description provided for @actions_unblocked_toast.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الحظر'**
  String get actions_unblocked_toast;

  /// No description provided for @close_title.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق المحادثة'**
  String get close_title;

  /// No description provided for @close_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان قصير يساعد فريقك على العثور عليها لاحقًا.'**
  String get close_subtitle;

  /// No description provided for @close_field_label.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get close_field_label;

  /// No description provided for @close_field_hint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: استفسار عن التوصيل'**
  String get close_field_hint;

  /// No description provided for @close_ai_writing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ كتابة عنوان بالذكاء الاصطناعي…'**
  String get close_ai_writing;

  /// No description provided for @close_ai_suggest.
  ///
  /// In ar, this message translates to:
  /// **'اقترح عنوانًا'**
  String get close_ai_suggest;

  /// No description provided for @close_ai_again.
  ///
  /// In ar, this message translates to:
  /// **'اقترح عنوانًا آخر'**
  String get close_ai_again;

  /// No description provided for @close_ai_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر اقتراح عنوان الآن. يمكنك كتابته بنفسك.'**
  String get close_ai_unavailable;

  /// No description provided for @close_hint.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للعميل المراسلة مجددًا، وأي رسالة جديدة تعيد فتح المحادثة.'**
  String get close_hint;

  /// No description provided for @close_confirm.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق المحادثة'**
  String get close_confirm;

  /// No description provided for @claim_button.
  ///
  /// In ar, this message translates to:
  /// **'استلم المحادثة'**
  String get claim_button;

  /// No description provided for @claim_button_hint.
  ///
  /// In ar, this message translates to:
  /// **'ستُسند إليك ويمكنك الرد'**
  String get claim_button_hint;

  /// No description provided for @claim_region.
  ///
  /// In ar, this message translates to:
  /// **'استلام المحادثة'**
  String get claim_region;

  /// No description provided for @claim_assign_colleague.
  ///
  /// In ar, this message translates to:
  /// **'إسناد لزميل'**
  String get claim_assign_colleague;

  /// No description provided for @claim_ai_takeover.
  ///
  /// In ar, this message translates to:
  /// **'تولَّ الذكاء الاصطناعي الرد'**
  String get claim_ai_takeover;

  /// No description provided for @claim_ai_takeover_done.
  ///
  /// In ar, this message translates to:
  /// **'أُسندت المحادثة إلى الذكاء الاصطناعي'**
  String get claim_ai_takeover_done;

  /// No description provided for @claim_waiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الاستلام'**
  String get claim_waiting;

  /// No description provided for @claim_viewer_one_f.
  ///
  /// In ar, this message translates to:
  /// **'{name} تشاهد هذه المحادثة الآن'**
  String claim_viewer_one_f(String name);

  /// No description provided for @claim_viewer_one_m.
  ///
  /// In ar, this message translates to:
  /// **'{name} يشاهد هذه المحادثة الآن'**
  String claim_viewer_one_m(String name);

  /// No description provided for @claim_viewer_two.
  ///
  /// In ar, this message translates to:
  /// **'{a} و{b} يشاهدان المحادثة'**
  String claim_viewer_two(String a, String b);

  /// No description provided for @claim_viewer_many.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =2{{a} وآخران يشاهدون المحادثة} few{{a} و{n} آخرون يشاهدون المحادثة} other{{a} و{n} آخرون يشاهدون المحادثة}}'**
  String claim_viewer_many(String a, int n);

  /// No description provided for @claim_viewing_since_sec.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} ث'**
  String claim_viewing_since_sec(int n);

  /// No description provided for @claim_viewing_since_min.
  ///
  /// In ar, this message translates to:
  /// **'منذ {t}'**
  String claim_viewing_since_min(String t);

  /// No description provided for @claim_wait_sec.
  ///
  /// In ar, this message translates to:
  /// **'{n} ث'**
  String claim_wait_sec(int n);

  /// No description provided for @claim_wait_min.
  ///
  /// In ar, this message translates to:
  /// **'{n} د'**
  String claim_wait_min(int n);

  /// No description provided for @claim_wait_hm.
  ///
  /// In ar, this message translates to:
  /// **'{h} س {m} د'**
  String claim_wait_hm(int h, int m);

  /// No description provided for @claim_a11y_wait_sec.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{ينتظر منذ ثانية} =2{ينتظر منذ ثانيتين} few{ينتظر منذ {n} ثوانٍ} other{ينتظر منذ {n} ثانية}}'**
  String claim_a11y_wait_sec(int n);

  /// No description provided for @claim_a11y_wait_min.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{ينتظر منذ دقيقة} =2{ينتظر منذ دقيقتين} few{ينتظر منذ {n} دقائق} other{ينتظر منذ {n} دقيقة}}'**
  String claim_a11y_wait_min(int n);

  /// No description provided for @claim_a11y_wait_hm.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر منذ {h} ساعة و{m} دقيقة'**
  String claim_a11y_wait_hm(int h, int m);

  /// No description provided for @claim_success_event.
  ///
  /// In ar, this message translates to:
  /// **'استلمت المحادثة'**
  String get claim_success_event;

  /// No description provided for @claim_conflict.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name} قبلك'**
  String claim_conflict(String name);

  /// No description provided for @claim_taken_live.
  ///
  /// In ar, this message translates to:
  /// **'استلم {name} هذه المحادثة'**
  String claim_taken_live(String name);

  /// No description provided for @claim_assigned_to_you.
  ///
  /// In ar, this message translates to:
  /// **'أسند {name} المحادثة إليك'**
  String claim_assigned_to_you(String name);

  /// No description provided for @claim_resolved_live.
  ///
  /// In ar, this message translates to:
  /// **'حلّ {name} المحادثة'**
  String claim_resolved_live(String name);

  /// No description provided for @claim_network_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاستلام. تحقّق من الاتصال وحاول مجددًا.'**
  String get claim_network_error;

  /// No description provided for @claim_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get claim_retry;

  /// No description provided for @claim_forbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية استلام هذه المحادثة'**
  String get claim_forbidden;

  /// No description provided for @claim_team_only.
  ///
  /// In ar, this message translates to:
  /// **'هذه المحادثة لفريق {team}'**
  String claim_team_only(String team);

  /// No description provided for @claim_offline_hint.
  ///
  /// In ar, this message translates to:
  /// **'الاستلام يتطلب اتصالًا بالإنترنت'**
  String get claim_offline_hint;

  /// No description provided for @claim_capacity_hint.
  ///
  /// In ar, this message translates to:
  /// **'لديك {n} محادثات مفتوحة (الحد {max})'**
  String claim_capacity_hint(int n, int max);

  /// No description provided for @claim_capacity_reached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد الأقصى من المحادثات'**
  String get claim_capacity_reached;

  /// No description provided for @claim_away_title.
  ///
  /// In ar, this message translates to:
  /// **'حالتك الآن: غير متاح'**
  String get claim_away_title;

  /// No description provided for @claim_away_body.
  ///
  /// In ar, this message translates to:
  /// **'استلام المحادثة سيغيّر حالتك إلى «متاح».'**
  String get claim_away_body;

  /// No description provided for @claim_away_confirm.
  ///
  /// In ar, this message translates to:
  /// **'استلم وغيّر حالتي إلى متاح'**
  String get claim_away_confirm;

  /// No description provided for @claim_capacity_title.
  ///
  /// In ar, this message translates to:
  /// **'لديك {n} محادثات مفتوحة'**
  String claim_capacity_title(int n);

  /// No description provided for @claim_capacity_body.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد استلام محادثة إضافية؟'**
  String get claim_capacity_body;

  /// No description provided for @claim_capacity_confirm.
  ///
  /// In ar, this message translates to:
  /// **'استلم على أي حال'**
  String get claim_capacity_confirm;

  /// No description provided for @claim_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get claim_cancel;

  /// No description provided for @claim_assigned_toast.
  ///
  /// In ar, this message translates to:
  /// **'تم الإسناد إلى {name}'**
  String claim_assigned_toast(String name);

  /// No description provided for @claim_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get claim_undo;

  /// No description provided for @claim_reply_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب للاستلام والرد…'**
  String get claim_reply_placeholder;

  /// No description provided for @claim_short.
  ///
  /// In ar, this message translates to:
  /// **'استلم'**
  String get claim_short;

  /// No description provided for @claim_handoff_event.
  ///
  /// In ar, this message translates to:
  /// **'حوّل الذكاء الاصطناعي المحادثة للفريق: {reason}'**
  String claim_handoff_event(String reason);

  /// No description provided for @claim_reason_payment.
  ///
  /// In ar, this message translates to:
  /// **'موضوع دفع'**
  String get claim_reason_payment;

  /// No description provided for @claim_reason_human.
  ///
  /// In ar, this message translates to:
  /// **'طلب التحدث مع موظف'**
  String get claim_reason_human;

  /// No description provided for @claim_reason_complaint.
  ///
  /// In ar, this message translates to:
  /// **'شكوى'**
  String get claim_reason_complaint;

  /// No description provided for @claim_reason_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'سؤال بلا إجابة'**
  String get claim_reason_no_answer;

  /// No description provided for @claim_reason_refund.
  ///
  /// In ar, this message translates to:
  /// **'طلب استرجاع'**
  String get claim_reason_refund;

  /// No description provided for @claim_reason_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get claim_reason_other;

  /// No description provided for @claim_push_title.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة بانتظار الاستلام'**
  String get claim_push_title;

  /// No description provided for @claim_push_action.
  ///
  /// In ar, this message translates to:
  /// **'استلم'**
  String get claim_push_action;

  /// No description provided for @claim_push_success.
  ///
  /// In ar, this message translates to:
  /// **'استلمت المحادثة مع {customer}'**
  String claim_push_success(String customer);

  /// No description provided for @actions_add_note.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة داخلية'**
  String get actions_add_note;

  /// No description provided for @claim_a11y_wait_span.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر منذ {t}'**
  String claim_a11y_wait_span(String t);

  /// No description provided for @conversations_segment_mine.
  ///
  /// In ar, this message translates to:
  /// **'لي'**
  String get conversations_segment_mine;

  /// No description provided for @conversations_segment_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get conversations_segment_unassigned;

  /// No description provided for @conversations_segment_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get conversations_segment_all;

  /// No description provided for @conversations_filter_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get conversations_filter_all;

  /// No description provided for @conversations_filter_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروءة'**
  String get conversations_filter_unread;

  /// No description provided for @conversations_filter_awaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الرد'**
  String get conversations_filter_awaiting;

  /// No description provided for @conversations_filter_ai.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء'**
  String get conversations_filter_ai;

  /// No description provided for @conversations_filter_closed.
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get conversations_filter_closed;

  /// No description provided for @conversations_filter_more.
  ///
  /// In ar, this message translates to:
  /// **'فلاتر'**
  String get conversations_filter_more;

  /// No description provided for @conversations_channel_any.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get conversations_channel_any;

  /// No description provided for @conversations_priority_any.
  ///
  /// In ar, this message translates to:
  /// **'كل الأولويات'**
  String get conversations_priority_any;

  /// No description provided for @conversations_notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get conversations_notifications;

  /// No description provided for @conversations_new_message.
  ///
  /// In ar, this message translates to:
  /// **'رسالة جديدة'**
  String get conversations_new_message;

  /// No description provided for @conversations_exit_selection.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التحديد'**
  String get conversations_exit_selection;

  /// No description provided for @conversations_selected_count.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{محادثة واحدة محددة} =2{محادثتان محددتان} few{{count} محادثات محددة} other{{count} محادثة محددة}}'**
  String conversations_selected_count(int count);

  /// No description provided for @conversations_bulk_assign.
  ///
  /// In ar, this message translates to:
  /// **'إسناد المحدد'**
  String get conversations_bulk_assign;

  /// No description provided for @conversations_bulk_resolve.
  ///
  /// In ar, this message translates to:
  /// **'حلّ المحدد'**
  String get conversations_bulk_resolve;

  /// No description provided for @conversations_bulk_resolved.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تم حلّ محادثة واحدة} =2{تم حلّ محادثتين} few{تم حلّ {count} محادثات} other{تم حلّ {count} محادثة}}'**
  String conversations_bulk_resolved(int count);

  /// No description provided for @conversations_resolved_snack.
  ///
  /// In ar, this message translates to:
  /// **'تم حلّ المحادثة'**
  String get conversations_resolved_snack;

  /// No description provided for @conversations_empty_mine_title.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات مُسندة لك'**
  String get conversations_empty_mine_title;

  /// No description provided for @conversations_empty_mine_body.
  ///
  /// In ar, this message translates to:
  /// **'استلم محادثة من غير المُسندة لتبدأ الرد.'**
  String get conversations_empty_mine_body;

  /// No description provided for @conversations_empty_mine_action.
  ///
  /// In ar, this message translates to:
  /// **'عرض غير المُسندة'**
  String get conversations_empty_mine_action;

  /// No description provided for @conversations_empty_filters_title.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات تطابق الفلاتر'**
  String get conversations_empty_filters_title;

  /// No description provided for @conversations_empty_filters_body.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تغيير الفلاتر أو مسحها لعرض كل المحادثات.'**
  String get conversations_empty_filters_body;

  /// No description provided for @conversations_empty_filters_action.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفلاتر'**
  String get conversations_empty_filters_action;

  /// No description provided for @conversations_empty_done_title.
  ///
  /// In ar, this message translates to:
  /// **'أنهيت كل المحادثات'**
  String get conversations_empty_done_title;

  /// No description provided for @conversations_empty_done_body.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ما ينتظرك الآن. سنُعلمك عند وصول رسالة جديدة.'**
  String get conversations_empty_done_body;

  /// No description provided for @tile_you_prefix.
  ///
  /// In ar, this message translates to:
  /// **'أنت: '**
  String get tile_you_prefix;

  /// No description provided for @tile_ai_reply.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء الاصطناعي'**
  String get tile_ai_reply;

  /// No description provided for @tile_ai_ready.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح جاهز'**
  String get tile_ai_ready;

  /// No description provided for @tile_typing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب…'**
  String get tile_typing;

  /// No description provided for @tile_snoozed_until.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة حتى {time}'**
  String tile_snoozed_until(String time);

  /// No description provided for @tile_media_with_duration.
  ///
  /// In ar, this message translates to:
  /// **'{label} · {duration}'**
  String tile_media_with_duration(String label, String duration);

  /// No description provided for @tile_swipe_resolve.
  ///
  /// In ar, this message translates to:
  /// **'حلّ'**
  String get tile_swipe_resolve;

  /// No description provided for @tile_swipe_snooze.
  ///
  /// In ar, this message translates to:
  /// **'تأجيل'**
  String get tile_swipe_snooze;

  /// No description provided for @tile_swipe_assign.
  ///
  /// In ar, this message translates to:
  /// **'إسناد'**
  String get tile_swipe_assign;

  /// No description provided for @filters_title.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get filters_title;

  /// No description provided for @filters_channel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get filters_channel;

  /// No description provided for @filters_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get filters_status;

  /// No description provided for @filters_priority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get filters_priority;

  /// No description provided for @filters_assignee.
  ///
  /// In ar, this message translates to:
  /// **'المُسند إليه'**
  String get filters_assignee;

  /// No description provided for @filters_assignee_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filters_assignee_all;

  /// No description provided for @filters_assignee_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get filters_assignee_me;

  /// No description provided for @filters_assignee_colleague.
  ///
  /// In ar, this message translates to:
  /// **'زميل'**
  String get filters_assignee_colleague;

  /// No description provided for @filters_assignee_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get filters_assignee_ai;

  /// No description provided for @filters_assignee_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get filters_assignee_unassigned;

  /// No description provided for @filters_date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get filters_date;

  /// No description provided for @filters_date_any.
  ///
  /// In ar, this message translates to:
  /// **'أي وقت'**
  String get filters_date_any;

  /// No description provided for @filters_date_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get filters_date_today;

  /// No description provided for @filters_date_7.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get filters_date_7;

  /// No description provided for @filters_date_30.
  ///
  /// In ar, this message translates to:
  /// **'30 يومًا'**
  String get filters_date_30;

  /// No description provided for @filters_date_custom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get filters_date_custom;

  /// No description provided for @filters_tags.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get filters_tags;

  /// No description provided for @filters_show.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد محادثات} =1{عرض محادثة واحدة} =2{عرض محادثتين} few{عرض {count} محادثات} other{عرض {count} محادثة}}'**
  String filters_show(int count);

  /// No description provided for @newmsg_title.
  ///
  /// In ar, this message translates to:
  /// **'رسالة جديدة'**
  String get newmsg_title;

  /// No description provided for @newmsg_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ محادثة واتساب بقالب معتمد'**
  String get newmsg_subtitle;

  /// No description provided for @newmsg_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get newmsg_name;

  /// No description provided for @newmsg_name_hint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get newmsg_name_hint;

  /// No description provided for @newmsg_phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get newmsg_phone;

  /// No description provided for @newmsg_phone_hint.
  ///
  /// In ar, this message translates to:
  /// **'+966 5x xxx xxxx'**
  String get newmsg_phone_hint;

  /// No description provided for @newmsg_phone_error.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم جوال صحيح مع رمز الدولة'**
  String get newmsg_phone_error;

  /// No description provided for @newmsg_template.
  ///
  /// In ar, this message translates to:
  /// **'القالب'**
  String get newmsg_template;

  /// No description provided for @newmsg_template_error.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالبًا معتمدًا للإرسال'**
  String get newmsg_template_error;

  /// No description provided for @newmsg_send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال القالب'**
  String get newmsg_send;

  /// No description provided for @app_name.
  ///
  /// In ar, this message translates to:
  /// **'Wavadesk'**
  String get app_name;

  /// No description provided for @tab_conversations.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get tab_conversations;

  /// No description provided for @tab_dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get tab_dashboard;

  /// No description provided for @tab_knowledge.
  ///
  /// In ar, this message translates to:
  /// **'المعرفة'**
  String get tab_knowledge;

  /// No description provided for @tab_account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get tab_account;

  /// No description provided for @channel_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get channel_whatsapp;

  /// No description provided for @channel_web.
  ///
  /// In ar, this message translates to:
  /// **'دردشة الموقع'**
  String get channel_web;

  /// No description provided for @channel_messenger.
  ///
  /// In ar, this message translates to:
  /// **'ماسنجر'**
  String get channel_messenger;

  /// No description provided for @channel_instagram.
  ///
  /// In ar, this message translates to:
  /// **'إنستغرام'**
  String get channel_instagram;

  /// No description provided for @channel_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get channel_email;

  /// No description provided for @channel_telegram.
  ///
  /// In ar, this message translates to:
  /// **'تيليغرام'**
  String get channel_telegram;

  /// No description provided for @channel_sms.
  ///
  /// In ar, this message translates to:
  /// **'رسائل SMS'**
  String get channel_sms;

  /// No description provided for @channel_other.
  ///
  /// In ar, this message translates to:
  /// **'قناة أخرى'**
  String get channel_other;

  /// No description provided for @status_open.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get status_open;

  /// No description provided for @status_pending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار العميل'**
  String get status_pending;

  /// No description provided for @status_waiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الرد'**
  String get status_waiting;

  /// No description provided for @status_snoozed.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة'**
  String get status_snoozed;

  /// No description provided for @status_resolved.
  ///
  /// In ar, this message translates to:
  /// **'محلولة'**
  String get status_resolved;

  /// No description provided for @status_closed.
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get status_closed;

  /// No description provided for @status_ai.
  ///
  /// In ar, this message translates to:
  /// **'يتولاها الذكاء'**
  String get status_ai;

  /// No description provided for @priority_urgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get priority_urgent;

  /// No description provided for @priority_high.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get priority_high;

  /// No description provided for @priority_medium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get priority_medium;

  /// No description provided for @priority_low.
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get priority_low;

  /// No description provided for @presence_online.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get presence_online;

  /// No description provided for @presence_busy.
  ///
  /// In ar, this message translates to:
  /// **'مشغول'**
  String get presence_busy;

  /// No description provided for @presence_away.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get presence_away;

  /// No description provided for @role_admin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get role_admin;

  /// No description provided for @role_supervisor.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get role_supervisor;

  /// No description provided for @role_agent.
  ///
  /// In ar, this message translates to:
  /// **'موظف دعم'**
  String get role_agent;

  /// No description provided for @ownership_mine.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لك'**
  String get ownership_mine;

  /// No description provided for @ownership_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get ownership_unassigned;

  /// No description provided for @ownership_colleague.
  ///
  /// In ar, this message translates to:
  /// **'مُسندة لـ{name}'**
  String ownership_colleague(String name);

  /// No description provided for @ownership_ai.
  ///
  /// In ar, this message translates to:
  /// **'يتولاها الذكاء الاصطناعي'**
  String get ownership_ai;

  /// No description provided for @media_image.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get media_image;

  /// No description provided for @media_voice.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية'**
  String get media_voice;

  /// No description provided for @media_file.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get media_file;

  /// No description provided for @media_location.
  ///
  /// In ar, this message translates to:
  /// **'موقع'**
  String get media_location;

  /// No description provided for @media_album.
  ///
  /// In ar, this message translates to:
  /// **'ألبوم صور'**
  String get media_album;

  /// No description provided for @media_video.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get media_video;

  /// No description provided for @media_contact.
  ///
  /// In ar, this message translates to:
  /// **'جهة اتصال'**
  String get media_contact;

  /// No description provided for @media_sticker.
  ///
  /// In ar, this message translates to:
  /// **'ملصق'**
  String get media_sticker;

  /// No description provided for @media_template.
  ///
  /// In ar, this message translates to:
  /// **'قالب'**
  String get media_template;

  /// No description provided for @media_email.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني'**
  String get media_email;

  /// No description provided for @media_deleted.
  ///
  /// In ar, this message translates to:
  /// **'رسالة محذوفة'**
  String get media_deleted;

  /// No description provided for @media_unsupported.
  ///
  /// In ar, this message translates to:
  /// **'رسالة غير مدعومة'**
  String get media_unsupported;

  /// No description provided for @common_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get common_save;

  /// No description provided for @common_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get common_undo;

  /// No description provided for @common_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get common_retry;

  /// No description provided for @common_close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get common_close;

  /// No description provided for @common_back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get common_back;

  /// No description provided for @common_clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get common_clear;

  /// No description provided for @common_done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get common_done;

  /// No description provided for @common_search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get common_search;

  /// No description provided for @common_clear_search.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get common_clear_search;

  /// No description provided for @common_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get common_more;

  /// No description provided for @common_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get common_delete;

  /// No description provided for @common_confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get common_confirm;

  /// No description provided for @common_you.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get common_you;

  /// No description provided for @common_loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get common_loading;

  /// No description provided for @common_selected.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get common_selected;

  /// No description provided for @time_now.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get time_now;

  /// No description provided for @time_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get time_today;

  /// No description provided for @time_yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get time_yesterday;

  /// No description provided for @time_minutes_ago.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل دقيقة} =2{قبل دقيقتين} few{قبل {count} دقائق} other{قبل {count} دقيقة}}'**
  String time_minutes_ago(int count);

  /// No description provided for @time_hours_ago.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل ساعة} =2{قبل ساعتين} few{قبل {count} ساعات} other{قبل {count} ساعة}}'**
  String time_hours_ago(int count);

  /// No description provided for @time_days_ago.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل يوم} =2{قبل يومين} few{قبل {count} أيام} other{قبل {count} يومًا}}'**
  String time_days_ago(int count);

  /// No description provided for @duration_minutes_short.
  ///
  /// In ar, this message translates to:
  /// **'{count} د'**
  String duration_minutes_short(int count);

  /// No description provided for @duration_hours_short.
  ///
  /// In ar, this message translates to:
  /// **'{count} س'**
  String duration_hours_short(int count);

  /// No description provided for @duration_days_short.
  ///
  /// In ar, this message translates to:
  /// **'{count} ي'**
  String duration_days_short(int count);

  /// No description provided for @waiting_for.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر منذ {duration}'**
  String waiting_for(String duration);

  /// No description provided for @network_connecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال…'**
  String get network_connecting;

  /// No description provided for @network_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get network_offline;

  /// No description provided for @empty_offline_title.
  ///
  /// In ar, this message translates to:
  /// **'أنت غير متصل بالإنترنت'**
  String get empty_offline_title;

  /// No description provided for @empty_offline_body.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصالك ثم أعد المحاولة. ستُرسل رسائلك عند عودة الاتصال.'**
  String get empty_offline_body;

  /// No description provided for @a11y_unread_messages.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا رسائل غير مقروءة} =1{رسالة غير مقروءة} =2{رسالتان غير مقروءتين} few{{count} رسائل غير مقروءة} other{{count} رسالة غير مقروءة}}'**
  String a11y_unread_messages(int count);

  /// No description provided for @a11y_notifications_unread.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات، يوجد جديد'**
  String get a11y_notifications_unread;

  /// No description provided for @a11y_ai_avatar.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get a11y_ai_avatar;

  /// No description provided for @a11y_team_avatar.
  ///
  /// In ar, this message translates to:
  /// **'فريق'**
  String get a11y_team_avatar;

  /// No description provided for @a11y_selected.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get a11y_selected;

  /// No description provided for @a11y_priority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية: {label}'**
  String a11y_priority(String label);

  /// No description provided for @time_unit_day.
  ///
  /// In ar, this message translates to:
  /// **'ي'**
  String get time_unit_day;

  /// No description provided for @time_unit_hour.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get time_unit_hour;

  /// No description provided for @time_unit_min.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get time_unit_min;

  /// No description provided for @common_increase.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get common_increase;

  /// No description provided for @common_decrease.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص'**
  String get common_decrease;

  /// No description provided for @dash_title.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dash_title;

  /// No description provided for @dash_morning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير، {name}'**
  String dash_morning(String name);

  /// No description provided for @dash_evening.
  ///
  /// In ar, this message translates to:
  /// **'مساء النور، {name}'**
  String dash_evening(String name);

  /// No description provided for @dash_presence_online_m.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get dash_presence_online_m;

  /// No description provided for @dash_presence_online_f.
  ///
  /// In ar, this message translates to:
  /// **'متاحة'**
  String get dash_presence_online_f;

  /// No description provided for @dash_presence_busy_m.
  ///
  /// In ar, this message translates to:
  /// **'مشغول'**
  String get dash_presence_busy_m;

  /// No description provided for @dash_presence_busy_f.
  ///
  /// In ar, this message translates to:
  /// **'مشغولة'**
  String get dash_presence_busy_f;

  /// No description provided for @dash_presence_away.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get dash_presence_away;

  /// No description provided for @dash_presence_title.
  ///
  /// In ar, this message translates to:
  /// **'حالتك'**
  String get dash_presence_title;

  /// No description provided for @dash_presence_until.
  ///
  /// In ar, this message translates to:
  /// **'حتى…'**
  String get dash_presence_until;

  /// No description provided for @dash_presence_30m.
  ///
  /// In ar, this message translates to:
  /// **'30 دقيقة'**
  String get dash_presence_30m;

  /// No description provided for @dash_presence_1h.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get dash_presence_1h;

  /// No description provided for @dash_presence_eod.
  ///
  /// In ar, this message translates to:
  /// **'نهاية اليوم'**
  String get dash_presence_eod;

  /// No description provided for @dash_presence_auto.
  ///
  /// In ar, this message translates to:
  /// **'تتحول تلقائيًا إلى «غير متاح» بعد 15 دقيقة من الخمول'**
  String get dash_presence_auto;

  /// No description provided for @dash_presence_until_time.
  ///
  /// In ar, this message translates to:
  /// **'حتى {time}'**
  String dash_presence_until_time(String time);

  /// No description provided for @dash_presence_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تغيير حالتك'**
  String get dash_presence_failed;

  /// No description provided for @dash_scope_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get dash_scope_me;

  /// No description provided for @dash_scope_team.
  ///
  /// In ar, this message translates to:
  /// **'فريقي'**
  String get dash_scope_team;

  /// No description provided for @dash_scope_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get dash_scope_all;

  /// No description provided for @dash_team_picker.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفريق'**
  String get dash_team_picker;

  /// No description provided for @dash_range_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get dash_range_today;

  /// No description provided for @dash_range_yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get dash_range_yesterday;

  /// No description provided for @dash_range_7d.
  ///
  /// In ar, this message translates to:
  /// **'آخر 7 أيام'**
  String get dash_range_7d;

  /// No description provided for @dash_range_30d.
  ///
  /// In ar, this message translates to:
  /// **'آخر 30 يومًا'**
  String get dash_range_30d;

  /// No description provided for @dash_range_title.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get dash_range_title;

  /// No description provided for @dash_open.
  ///
  /// In ar, this message translates to:
  /// **'محادثات مفتوحة'**
  String get dash_open;

  /// No description provided for @dash_awaiting_me.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار ردّك'**
  String get dash_awaiting_me;

  /// No description provided for @dash_awaiting_team.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الرد'**
  String get dash_awaiting_team;

  /// No description provided for @dash_oldest.
  ///
  /// In ar, this message translates to:
  /// **'أقدمها {m}'**
  String dash_oldest(String m);

  /// No description provided for @dash_none_waiting.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد ينتظر'**
  String get dash_none_waiting;

  /// No description provided for @dash_first_response.
  ///
  /// In ar, this message translates to:
  /// **'متوسط أول رد'**
  String get dash_first_response;

  /// No description provided for @dash_minute.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get dash_minute;

  /// No description provided for @dash_ai_reply.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء'**
  String get dash_ai_reply;

  /// No description provided for @dash_of_questions.
  ///
  /// In ar, this message translates to:
  /// **'من الأسئلة'**
  String get dash_of_questions;

  /// No description provided for @dash_resolved.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات المحلولة'**
  String get dash_resolved;

  /// No description provided for @dash_volume_today.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات اليوم'**
  String get dash_volume_today;

  /// No description provided for @dash_volume_range.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات · {range}'**
  String dash_volume_range(String range);

  /// No description provided for @dash_total.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثة'**
  String dash_total(String n);

  /// No description provided for @dash_tooltip.
  ///
  /// In ar, this message translates to:
  /// **'{hour}: {n} محادثة · {ai} بالذكاء'**
  String dash_tooltip(String hour, String n, String ai);

  /// No description provided for @dash_legend_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get dash_legend_all;

  /// No description provided for @dash_legend_ai.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء'**
  String get dash_legend_ai;

  /// No description provided for @dash_no_volume.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات بعد اليوم'**
  String get dash_no_volume;

  /// No description provided for @dash_no_volume_range.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات في هذه الفترة'**
  String get dash_no_volume_range;

  /// No description provided for @dash_team_now.
  ///
  /// In ar, this message translates to:
  /// **'الفريق الآن'**
  String get dash_team_now;

  /// No description provided for @dash_see_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get dash_see_all;

  /// No description provided for @dash_ai_name.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء'**
  String get dash_ai_name;

  /// No description provided for @dash_agent_open.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات مفتوحة'**
  String dash_agent_open(String n);

  /// No description provided for @dash_agent_frt.
  ///
  /// In ar, this message translates to:
  /// **'متوسط أول رد اليوم {t}'**
  String dash_agent_frt(String t);

  /// No description provided for @dash_agent_view.
  ///
  /// In ar, this message translates to:
  /// **'عرض محادثاته'**
  String get dash_agent_view;

  /// No description provided for @dash_redistribute.
  ///
  /// In ar, this message translates to:
  /// **'إعادة توزيع'**
  String get dash_redistribute;

  /// No description provided for @dash_redistribute_none.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات مفتوحة لإعادة توزيعها'**
  String get dash_redistribute_none;

  /// No description provided for @dash_solo.
  ///
  /// In ar, this message translates to:
  /// **'أنت وحدك في الفريق'**
  String get dash_solo;

  /// No description provided for @dash_invite.
  ///
  /// In ar, this message translates to:
  /// **'دعوة زميل'**
  String get dash_invite;

  /// No description provided for @dash_ai_impact.
  ///
  /// In ar, this message translates to:
  /// **'{n} سؤالًا أجاب عنها الذكاء'**
  String dash_ai_impact(String n);

  /// No description provided for @dash_ai_saved.
  ///
  /// In ar, this message translates to:
  /// **'وفّر نحو {h} ساعات من وقت الفريق'**
  String dash_ai_saved(String h);

  /// No description provided for @dash_ai_handoffs.
  ///
  /// In ar, this message translates to:
  /// **'تحويلات للفريق {n}'**
  String dash_ai_handoffs(String n);

  /// No description provided for @dash_ai_rating.
  ///
  /// In ar, this message translates to:
  /// **'تقييم إيجابي {p}%'**
  String dash_ai_rating(String p);

  /// No description provided for @dash_ai_handling.
  ///
  /// In ar, this message translates to:
  /// **'يتولّى الذكاء {n} محادثة الآن'**
  String dash_ai_handling(String n);

  /// No description provided for @dash_by_channel.
  ///
  /// In ar, this message translates to:
  /// **'حسب القناة'**
  String get dash_by_channel;

  /// No description provided for @dash_web_reports.
  ///
  /// In ar, this message translates to:
  /// **'تقارير مفصّلة على الويب'**
  String get dash_web_reports;

  /// No description provided for @dash_last_updated.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث {t}'**
  String dash_last_updated(String t);

  /// No description provided for @dash_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل لوحة التحكم'**
  String get dash_load_error;

  /// No description provided for @dash_card_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحميل'**
  String get dash_card_error;

  /// No description provided for @dash_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get dash_retry;

  /// No description provided for @dash_frt_title.
  ///
  /// In ar, this message translates to:
  /// **'سرعة أول رد'**
  String get dash_frt_title;

  /// No description provided for @dash_frt_target.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: {m} د'**
  String dash_frt_target(String m);

  /// No description provided for @dash_frt_lt1.
  ///
  /// In ar, this message translates to:
  /// **'أقل من دقيقة'**
  String get dash_frt_lt1;

  /// No description provided for @dash_frt_1_5.
  ///
  /// In ar, this message translates to:
  /// **'1–5 د'**
  String get dash_frt_1_5;

  /// No description provided for @dash_frt_5_15.
  ///
  /// In ar, this message translates to:
  /// **'5–15 د'**
  String get dash_frt_5_15;

  /// No description provided for @dash_frt_gt15.
  ///
  /// In ar, this message translates to:
  /// **'أكثر من 15 د'**
  String get dash_frt_gt15;

  /// No description provided for @dash_frt_note.
  ///
  /// In ar, this message translates to:
  /// **'محسوب على المحادثات التي ردّ عليها موظف'**
  String get dash_frt_note;

  /// No description provided for @dash_frt_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا ردود بعد في هذه الفترة'**
  String get dash_frt_empty;

  /// No description provided for @dash_days_short.
  ///
  /// In ar, this message translates to:
  /// **'ي'**
  String get dash_days_short;

  /// No description provided for @dash_hours_short.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get dash_hours_short;

  /// No description provided for @dash_minutes_short.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get dash_minutes_short;

  /// No description provided for @dash_thousand.
  ///
  /// In ar, this message translates to:
  /// **'ألف'**
  String get dash_thousand;

  /// No description provided for @dash_onb_title.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ باستقبال المحادثات'**
  String get dash_onb_title;

  /// No description provided for @dash_onb_wa.
  ///
  /// In ar, this message translates to:
  /// **'ربط واتساب'**
  String get dash_onb_wa;

  /// No description provided for @dash_onb_kb.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قاعدة المعرفة'**
  String get dash_onb_kb;

  /// No description provided for @dash_onb_ai.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الذكاء الاصطناعي'**
  String get dash_onb_ai;

  /// No description provided for @dash_onb_cta.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الإعداد'**
  String get dash_onb_cta;

  /// No description provided for @dash_alert_wa_title.
  ///
  /// In ar, this message translates to:
  /// **'واتساب غير متصل'**
  String get dash_alert_wa_title;

  /// No description provided for @dash_alert_wa_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصل الرسائل حتى تعيد الربط'**
  String get dash_alert_wa_body;

  /// No description provided for @dash_alert_wa_action.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الربط'**
  String get dash_alert_wa_action;

  /// No description provided for @dash_alert_sla_title.
  ///
  /// In ar, this message translates to:
  /// **'{n} عملاء ينتظرون أكثر من {sla} د'**
  String dash_alert_sla_title(String n, String sla);

  /// No description provided for @dash_alert_sla_action.
  ///
  /// In ar, this message translates to:
  /// **'رد الآن'**
  String get dash_alert_sla_action;

  /// No description provided for @dash_alert_unassigned_title.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات بانتظار الاستلام'**
  String dash_alert_unassigned_title(String n);

  /// No description provided for @dash_alert_view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get dash_alert_view;

  /// No description provided for @dash_alert_kb_title.
  ///
  /// In ar, this message translates to:
  /// **'{n} أسئلة بلا إجابة'**
  String dash_alert_kb_title(String n);

  /// No description provided for @dash_alert_kb_body.
  ///
  /// In ar, this message translates to:
  /// **'أضفها ليجيب الذكاء تلقائيًا'**
  String get dash_alert_kb_body;

  /// No description provided for @dash_alert_kb_action.
  ///
  /// In ar, this message translates to:
  /// **'راجعها'**
  String get dash_alert_kb_action;

  /// No description provided for @dash_alert_trial_title.
  ///
  /// In ar, this message translates to:
  /// **'تجربتك تنتهي بعد {n} أيام'**
  String dash_alert_trial_title(String n);

  /// No description provided for @dash_alert_trial_action.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخطط'**
  String get dash_alert_trial_action;

  /// No description provided for @dash_alert_dismiss.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get dash_alert_dismiss;

  /// No description provided for @dash_a11y_metric.
  ///
  /// In ar, this message translates to:
  /// **'{label}: {value} {aside}. اضغط لعرض المحادثات'**
  String dash_a11y_metric(String label, String value, String aside);

  /// No description provided for @dash_a11y_chart.
  ///
  /// In ar, this message translates to:
  /// **'{title}: {total}. الذروة {peak} بـ {n} محادثة.'**
  String dash_a11y_chart(String title, String total, String peak, String n);

  /// No description provided for @dash_a11y_team.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {presence}، {n} محادثات مفتوحة'**
  String dash_a11y_team(String name, String presence, String n);

  /// No description provided for @dash_a11y_presence.
  ///
  /// In ar, this message translates to:
  /// **'حالتك: {status}. اضغط للتغيير'**
  String dash_a11y_presence(String status);

  /// No description provided for @dash_afternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير، {name}'**
  String dash_afternoon(String name);

  /// No description provided for @dash_period_7d.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get dash_period_7d;

  /// No description provided for @dash_period_30d.
  ///
  /// In ar, this message translates to:
  /// **'30 يومًا'**
  String get dash_period_30d;

  /// No description provided for @dash_nothing_waiting.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء بانتظارك'**
  String get dash_nothing_waiting;

  /// No description provided for @dash_unit_sec.
  ///
  /// In ar, this message translates to:
  /// **'ثانية'**
  String get dash_unit_sec;

  /// No description provided for @dash_unit_hr.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get dash_unit_hr;

  /// No description provided for @dash_ai_off.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get dash_ai_off;

  /// No description provided for @dash_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات بعد'**
  String get dash_empty;

  /// No description provided for @dash_connect_wa.
  ///
  /// In ar, this message translates to:
  /// **'اربط واتساب'**
  String get dash_connect_wa;

  /// No description provided for @dash_wa_down.
  ///
  /// In ar, this message translates to:
  /// **'انقطع اتصال واتساب'**
  String get dash_wa_down;

  /// No description provided for @dash_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل · آخر تحديث {t}'**
  String dash_offline(String t);

  /// No description provided for @dash_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البيانات'**
  String get dash_error;

  /// No description provided for @dash_bar_tip.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثة · {slot}'**
  String dash_bar_tip(String n, String slot);

  /// No description provided for @dash_bell_a11y.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات، {n} غير مقروءة'**
  String dash_bell_a11y(String n);

  /// No description provided for @dash_kpi_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{label}: {value}، {meta}'**
  String dash_kpi_a11y(String label, String value, String meta);

  /// No description provided for @dash_faster.
  ///
  /// In ar, this message translates to:
  /// **'أسرع بـ {p}%'**
  String dash_faster(String p);

  /// No description provided for @dash_slower.
  ///
  /// In ar, this message translates to:
  /// **'أبطأ بـ {p}%'**
  String dash_slower(String p);

  /// No description provided for @dash_vs_previous.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة بالفترة السابقة'**
  String get dash_vs_previous;

  /// No description provided for @dash_breakdown_you.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get dash_breakdown_you;

  /// No description provided for @dash_breakdown_team.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get dash_breakdown_team;

  /// No description provided for @dash_breakdown_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء'**
  String get dash_breakdown_ai;

  /// No description provided for @dash_ai_instant.
  ///
  /// In ar, this message translates to:
  /// **'فوري'**
  String get dash_ai_instant;

  /// No description provided for @dash_more_team.
  ///
  /// In ar, this message translates to:
  /// **'{n} آخرون'**
  String dash_more_team(String n);

  /// No description provided for @inbox_title.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get inbox_title;

  /// No description provided for @inbox_seg_mine.
  ///
  /// In ar, this message translates to:
  /// **'لي'**
  String get inbox_seg_mine;

  /// No description provided for @inbox_seg_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get inbox_seg_unassigned;

  /// No description provided for @inbox_seg_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get inbox_seg_all;

  /// No description provided for @inbox_chip_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get inbox_chip_all;

  /// No description provided for @inbox_chip_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروءة'**
  String get inbox_chip_unread;

  /// No description provided for @inbox_chip_awaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الرد'**
  String get inbox_chip_awaiting;

  /// No description provided for @inbox_chip_ai.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء'**
  String get inbox_chip_ai;

  /// No description provided for @inbox_chip_snoozed.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة'**
  String get inbox_chip_snoozed;

  /// No description provided for @inbox_chip_closed.
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get inbox_chip_closed;

  /// No description provided for @inbox_chip_filters.
  ///
  /// In ar, this message translates to:
  /// **'فلاتر'**
  String get inbox_chip_filters;

  /// No description provided for @inbox_needs_reply.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج ردّك الآن'**
  String get inbox_needs_reply;

  /// No description provided for @inbox_rest.
  ///
  /// In ar, this message translates to:
  /// **'باقي المحادثات'**
  String get inbox_rest;

  /// No description provided for @inbox_see_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get inbox_see_all;

  /// No description provided for @inbox_show_less.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get inbox_show_less;

  /// No description provided for @inbox_you_prefix.
  ///
  /// In ar, this message translates to:
  /// **'أنت:'**
  String get inbox_you_prefix;

  /// No description provided for @inbox_draft_prefix.
  ///
  /// In ar, this message translates to:
  /// **'مسودة:'**
  String get inbox_draft_prefix;

  /// No description provided for @inbox_note_prefix.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة:'**
  String get inbox_note_prefix;

  /// No description provided for @inbox_typing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب الآن…'**
  String get inbox_typing;

  /// No description provided for @inbox_image.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get inbox_image;

  /// No description provided for @inbox_voice.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية · {d}'**
  String inbox_voice(String d);

  /// No description provided for @inbox_location.
  ///
  /// In ar, this message translates to:
  /// **'موقع'**
  String get inbox_location;

  /// No description provided for @inbox_sticker.
  ///
  /// In ar, this message translates to:
  /// **'ملصق'**
  String get inbox_sticker;

  /// No description provided for @inbox_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف هذه الرسالة'**
  String get inbox_deleted;

  /// No description provided for @inbox_tag_waiting.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر {t}'**
  String inbox_tag_waiting(String t);

  /// No description provided for @inbox_tag_ai_ready.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح جاهز'**
  String get inbox_tag_ai_ready;

  /// No description provided for @inbox_tag_ai_replied.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء الاصطناعي'**
  String get inbox_tag_ai_replied;

  /// No description provided for @inbox_tag_snoozed.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة حتى {t}'**
  String inbox_tag_snoozed(String t);

  /// No description provided for @inbox_tag_window.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي النافذة خلال {h} س'**
  String inbox_tag_window(int h);

  /// No description provided for @inbox_now.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get inbox_now;

  /// No description provided for @inbox_min.
  ///
  /// In ar, this message translates to:
  /// **'{n} د'**
  String inbox_min(int n);

  /// No description provided for @inbox_hour.
  ///
  /// In ar, this message translates to:
  /// **'{n} س'**
  String inbox_hour(int n);

  /// No description provided for @inbox_yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get inbox_yesterday;

  /// No description provided for @inbox_am.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get inbox_am;

  /// No description provided for @inbox_pm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get inbox_pm;

  /// No description provided for @inbox_swipe_resolve.
  ///
  /// In ar, this message translates to:
  /// **'حلّ'**
  String get inbox_swipe_resolve;

  /// No description provided for @inbox_swipe_snooze.
  ///
  /// In ar, this message translates to:
  /// **'تأجيل'**
  String get inbox_swipe_snooze;

  /// No description provided for @inbox_swipe_assign.
  ///
  /// In ar, this message translates to:
  /// **'إسناد'**
  String get inbox_swipe_assign;

  /// No description provided for @inbox_swipe_claim.
  ///
  /// In ar, this message translates to:
  /// **'استلام'**
  String get inbox_swipe_claim;

  /// No description provided for @inbox_resolved.
  ///
  /// In ar, this message translates to:
  /// **'تم حلّ المحادثة'**
  String get inbox_resolved;

  /// No description provided for @inbox_resolved_n.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{تم حلّ محادثة} =2{تم حلّ محادثتين} few{تم حلّ {n} محادثات} other{تم حلّ {n} محادثة}}'**
  String inbox_resolved_n(int n);

  /// No description provided for @inbox_snoozed_1h.
  ///
  /// In ar, this message translates to:
  /// **'أُجّلت لمدة ساعة'**
  String get inbox_snoozed_1h;

  /// No description provided for @inbox_snoozed_n.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{أُجّلت المحادثة} =2{أُجّلت محادثتان} few{أُجّلت {n} محادثات} other{أُجّلت {n} محادثة}}'**
  String inbox_snoozed_n(int n);

  /// No description provided for @inbox_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get inbox_undo;

  /// No description provided for @inbox_assigned_to_you.
  ///
  /// In ar, this message translates to:
  /// **'أُسندت إليك محادثة من {name}'**
  String inbox_assigned_to_you(String name);

  /// No description provided for @inbox_open.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get inbox_open;

  /// No description provided for @inbox_claimed_by.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name}'**
  String inbox_claimed_by(String name);

  /// No description provided for @inbox_new_pill.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{محادثة جديدة} =2{محادثتان جديدتان} few{{n} محادثات جديدة} other{{n} محادثة جديدة}}'**
  String inbox_new_pill(int n);

  /// No description provided for @inbox_selected.
  ///
  /// In ar, this message translates to:
  /// **'{n} محدد'**
  String inbox_selected(int n);

  /// No description provided for @inbox_select_all.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get inbox_select_all;

  /// No description provided for @inbox_exit_selection.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التحديد'**
  String get inbox_exit_selection;

  /// No description provided for @inbox_mark_read.
  ///
  /// In ar, this message translates to:
  /// **'مقروء'**
  String get inbox_mark_read;

  /// No description provided for @inbox_mark_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get inbox_mark_unread;

  /// No description provided for @inbox_marked_read_n.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{تم تعليم محادثة كمقروءة} few{تم تعليم {n} محادثات كمقروءة} other{تم تعليم {n} محادثة كمقروءة}}'**
  String inbox_marked_read_n(int n);

  /// No description provided for @inbox_marked_unread_n.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{تم تعليم محادثة كغير مقروءة} few{تم تعليم {n} محادثات كغير مقروءة} other{تم تعليم {n} محادثة كغير مقروءة}}'**
  String inbox_marked_unread_n(int n);

  /// No description provided for @inbox_new_conversation.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get inbox_new_conversation;

  /// No description provided for @inbox_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحميل · إعادة المحاولة'**
  String get inbox_load_error;

  /// No description provided for @inbox_end.
  ///
  /// In ar, this message translates to:
  /// **'لا مزيد من المحادثات'**
  String get inbox_end;

  /// No description provided for @inbox_exit_hint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرة أخرى للخروج'**
  String get inbox_exit_hint;

  /// No description provided for @inbox_offline_cached.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل — تُعرض آخر نسخة محفوظة'**
  String get inbox_offline_cached;

  /// No description provided for @inbox_action_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ الإجراء. حاول مجددًا.'**
  String get inbox_action_failed;

  /// No description provided for @inbox_tag.
  ///
  /// In ar, this message translates to:
  /// **'وسم'**
  String get inbox_tag;

  /// No description provided for @inbox_tag_added.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف الوسم «{tag}»'**
  String inbox_tag_added(String tag);

  /// No description provided for @inbox_priority.
  ///
  /// In ar, this message translates to:
  /// **'أولوية'**
  String get inbox_priority;

  /// No description provided for @inbox_priority_set.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية الآن: {label}'**
  String inbox_priority_set(String label);

  /// No description provided for @inbox_archive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get inbox_archive;

  /// No description provided for @inbox_archived_n.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{أُرشفت المحادثة} few{أُرشفت {n} محادثات} other{أُرشفت {n} محادثة}}'**
  String inbox_archived_n(int n);

  /// No description provided for @inbox_clear_all.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get inbox_clear_all;

  /// No description provided for @inbox_a11y_unread.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{رسالة غير مقروءة} =2{رسالتان غير مقروءتين} few{{n} رسائل غير مقروءة} other{{n} رسالة غير مقروءة}}'**
  String inbox_a11y_unread(int n);

  /// No description provided for @inbox_a11y_open_hint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرتين لفتح المحادثة'**
  String get inbox_a11y_open_hint;

  /// No description provided for @inbox_a11y_notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات، {n} غير مقروءة'**
  String inbox_a11y_notifications(int n);

  /// No description provided for @inbox_empty_mine_title.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات مُسندة لك'**
  String get inbox_empty_mine_title;

  /// No description provided for @inbox_empty_mine_body.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا المحادثات التي تستلمها أو تُسند إليك.'**
  String get inbox_empty_mine_body;

  /// No description provided for @inbox_empty_mine_action.
  ///
  /// In ar, this message translates to:
  /// **'عرض غير المُسندة'**
  String get inbox_empty_mine_action;

  /// No description provided for @inbox_empty_done_title.
  ///
  /// In ar, this message translates to:
  /// **'أنهيت كل المحادثات'**
  String get inbox_empty_done_title;

  /// No description provided for @inbox_empty_done_body.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد ينتظر ردّك الآن.'**
  String get inbox_empty_done_body;

  /// No description provided for @inbox_empty_unassigned_title.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات بانتظار الاستلام'**
  String get inbox_empty_unassigned_title;

  /// No description provided for @inbox_empty_unassigned_body.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي والفريق يغطّون كل شيء.'**
  String get inbox_empty_unassigned_body;

  /// No description provided for @inbox_empty_new_title.
  ///
  /// In ar, this message translates to:
  /// **'لم تصل أي محادثة بعد'**
  String get inbox_empty_new_title;

  /// No description provided for @inbox_empty_new_body.
  ///
  /// In ar, this message translates to:
  /// **'اربط واتساب لتبدأ باستقبال رسائل عملائك.'**
  String get inbox_empty_new_body;

  /// No description provided for @inbox_empty_new_action.
  ///
  /// In ar, this message translates to:
  /// **'اربط واتساب'**
  String get inbox_empty_new_action;

  /// No description provided for @inbox_empty_filters_title.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات تطابق الفلاتر'**
  String get inbox_empty_filters_title;

  /// No description provided for @inbox_empty_filters_action.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفلاتر'**
  String get inbox_empty_filters_action;

  /// No description provided for @inbox_empty_error_title.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المحادثات'**
  String get inbox_empty_error_title;

  /// No description provided for @inbox_empty_error_body.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من اتصالك ثم حاول مجددًا.'**
  String get inbox_empty_error_body;

  /// No description provided for @inbox_filters_title.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get inbox_filters_title;

  /// No description provided for @inbox_filters_clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get inbox_filters_clear;

  /// No description provided for @inbox_filters_apply.
  ///
  /// In ar, this message translates to:
  /// **'عرض المحادثات'**
  String get inbox_filters_apply;

  /// No description provided for @inbox_filters_show.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا توجد محادثات} =1{عرض محادثة واحدة} =2{عرض محادثتين} few{عرض {n} محادثات} other{عرض {n} محادثة}}'**
  String inbox_filters_show(int n);

  /// No description provided for @inbox_filters_channel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get inbox_filters_channel;

  /// No description provided for @inbox_filters_priority.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get inbox_filters_priority;

  /// No description provided for @inbox_filters_assignee.
  ///
  /// In ar, this message translates to:
  /// **'المُسند إليه'**
  String get inbox_filters_assignee;

  /// No description provided for @inbox_filters_assignee_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get inbox_filters_assignee_all;

  /// No description provided for @inbox_filters_assignee_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get inbox_filters_assignee_me;

  /// No description provided for @inbox_filters_assignee_colleague.
  ///
  /// In ar, this message translates to:
  /// **'زميل محدد ▸'**
  String get inbox_filters_assignee_colleague;

  /// No description provided for @inbox_filters_assignee_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get inbox_filters_assignee_ai;

  /// No description provided for @inbox_filters_assignee_unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مُسندة'**
  String get inbox_filters_assignee_unassigned;

  /// No description provided for @inbox_filters_pick_colleague.
  ///
  /// In ar, this message translates to:
  /// **'اختر زميلًا'**
  String get inbox_filters_pick_colleague;

  /// No description provided for @inbox_filters_team.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get inbox_filters_team;

  /// No description provided for @inbox_filters_tags.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get inbox_filters_tags;

  /// No description provided for @inbox_filters_tags_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الوسوم'**
  String get inbox_filters_tags_search;

  /// No description provided for @inbox_filters_date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get inbox_filters_date;

  /// No description provided for @inbox_filters_date_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get inbox_filters_date_today;

  /// No description provided for @inbox_filters_date_7d.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get inbox_filters_date_7d;

  /// No description provided for @inbox_filters_date_30d.
  ///
  /// In ar, this message translates to:
  /// **'30 يومًا'**
  String get inbox_filters_date_30d;

  /// No description provided for @inbox_filters_date_custom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص ▸'**
  String get inbox_filters_date_custom;

  /// No description provided for @inbox_filters_sort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get inbox_filters_sort;

  /// No description provided for @inbox_filters_sort_smart.
  ///
  /// In ar, this message translates to:
  /// **'ذكي (افتراضي)'**
  String get inbox_filters_sort_smart;

  /// No description provided for @inbox_filters_sort_newest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get inbox_filters_sort_newest;

  /// No description provided for @inbox_filters_sort_oldest.
  ///
  /// In ar, this message translates to:
  /// **'الأقدم'**
  String get inbox_filters_sort_oldest;

  /// No description provided for @inbox_filters_sort_waiting.
  ///
  /// In ar, this message translates to:
  /// **'الأطول انتظارًا'**
  String get inbox_filters_sort_waiting;

  /// No description provided for @kbe_new.
  ///
  /// In ar, this message translates to:
  /// **'سؤال جديد'**
  String get kbe_new;

  /// No description provided for @kbe_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإجابة'**
  String get kbe_edit;

  /// No description provided for @kbe_review.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة مقترح'**
  String get kbe_review;

  /// No description provided for @kbe_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get kbe_save;

  /// No description provided for @kbe_send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get kbe_send;

  /// No description provided for @kbe_src_unanswered.
  ///
  /// In ar, this message translates to:
  /// **'سُئل هذا السؤال {n} مرات ولم يجد الذكاء إجابة'**
  String kbe_src_unanswered(String n);

  /// No description provided for @kbe_src_chat.
  ///
  /// In ar, this message translates to:
  /// **'من محادثة مع {c} · {d}'**
  String kbe_src_chat(String c, String d);

  /// No description provided for @kbe_src_draft.
  ///
  /// In ar, this message translates to:
  /// **'اقترحها {name} · {t}'**
  String kbe_src_draft(String name, String t);

  /// No description provided for @kbe_src_draft_conv.
  ///
  /// In ar, this message translates to:
  /// **'مقترحة من محادثة محلولة'**
  String get kbe_src_draft_conv;

  /// No description provided for @kbe_view_convs.
  ///
  /// In ar, this message translates to:
  /// **'عرض المحادثات'**
  String get kbe_view_convs;

  /// No description provided for @kbe_open.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get kbe_open;

  /// No description provided for @kbe_open_it.
  ///
  /// In ar, this message translates to:
  /// **'فتحه'**
  String get kbe_open_it;

  /// No description provided for @kbe_question.
  ///
  /// In ar, this message translates to:
  /// **'السؤال'**
  String get kbe_question;

  /// No description provided for @kbe_question_ph.
  ///
  /// In ar, this message translates to:
  /// **'مثال: هل يمكن الاسترجاع بعد 30 يومًا؟'**
  String get kbe_question_ph;

  /// No description provided for @kbe_alts.
  ///
  /// In ar, this message translates to:
  /// **'صيغ أخرى يسأل بها العملاء'**
  String get kbe_alts;

  /// No description provided for @kbe_optional.
  ///
  /// In ar, this message translates to:
  /// **'(اختياري)'**
  String get kbe_optional;

  /// No description provided for @kbe_add_alt.
  ///
  /// In ar, this message translates to:
  /// **'+ أضف صيغة'**
  String get kbe_add_alt;

  /// No description provided for @kbe_alt_exists.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصيغة موجودة'**
  String get kbe_alt_exists;

  /// No description provided for @kbe_alt_limit.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأقصى 15 صيغة، 120 حرفًا لكل صيغة'**
  String get kbe_alt_limit;

  /// No description provided for @kbe_answer.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة'**
  String get kbe_answer;

  /// No description provided for @kbe_answer_ph.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الإجابة كما تريد أن يقولها الذكاء للعميل…'**
  String get kbe_answer_ph;

  /// No description provided for @kbe_counter.
  ///
  /// In ar, this message translates to:
  /// **'{n}/2000'**
  String kbe_counter(String n);

  /// No description provided for @kbe_ai_draft_tag.
  ///
  /// In ar, this message translates to:
  /// **'مسودة من الذكاء — راجعها قبل الحفظ'**
  String get kbe_ai_draft_tag;

  /// No description provided for @kbe_tag.
  ///
  /// In ar, this message translates to:
  /// **'وسم'**
  String get kbe_tag;

  /// No description provided for @kbe_tags_title.
  ///
  /// In ar, this message translates to:
  /// **'وسوم الإجابة'**
  String get kbe_tags_title;

  /// No description provided for @kbe_tags_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث أو أنشئ وسمًا'**
  String get kbe_tags_search;

  /// No description provided for @kbe_tags_create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء «{name}»'**
  String kbe_tags_create(String name);

  /// No description provided for @kbe_tags_primary.
  ///
  /// In ar, this message translates to:
  /// **'الوسم الرئيسي'**
  String get kbe_tags_primary;

  /// No description provided for @kbe_done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get kbe_done;

  /// No description provided for @kbe_improve.
  ///
  /// In ar, this message translates to:
  /// **'حسّن الصياغة'**
  String get kbe_improve;

  /// No description provided for @kbe_add_link.
  ///
  /// In ar, this message translates to:
  /// **'أضف رابطًا'**
  String get kbe_add_link;

  /// No description provided for @kbe_link_url.
  ///
  /// In ar, this message translates to:
  /// **'الرابط'**
  String get kbe_link_url;

  /// No description provided for @kbe_link_label.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الرابط (اختياري)'**
  String get kbe_link_label;

  /// No description provided for @kbe_link_invalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رابطًا صحيحًا يبدأ بـ https://'**
  String get kbe_link_invalid;

  /// No description provided for @kbe_insert.
  ///
  /// In ar, this message translates to:
  /// **'إدراج'**
  String get kbe_insert;

  /// No description provided for @kbe_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get kbe_cancel;

  /// No description provided for @kbe_similar.
  ///
  /// In ar, this message translates to:
  /// **'يوجد سؤال مشابه: «{t}»'**
  String kbe_similar(String t);

  /// No description provided for @kbe_merge_alt.
  ///
  /// In ar, this message translates to:
  /// **'دمج كصيغة أخرى'**
  String get kbe_merge_alt;

  /// No description provided for @kbe_conflict.
  ///
  /// In ar, this message translates to:
  /// **'قد تتعارض مع «{t}»: {r}'**
  String kbe_conflict(String t, String r);

  /// No description provided for @kbe_view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get kbe_view;

  /// No description provided for @kbe_preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة: كيف سيردّ الذكاء'**
  String get kbe_preview;

  /// No description provided for @kbe_ai_label.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get kbe_ai_label;

  /// No description provided for @kbe_writing.
  ///
  /// In ar, this message translates to:
  /// **'يكتب…'**
  String get kbe_writing;

  /// No description provided for @kbe_tone.
  ///
  /// In ar, this message translates to:
  /// **'بنبرة: {tone}'**
  String kbe_tone(String tone);

  /// No description provided for @kbe_conf_high.
  ///
  /// In ar, this message translates to:
  /// **'ثقة عالية'**
  String get kbe_conf_high;

  /// No description provided for @kbe_conf_med.
  ///
  /// In ar, this message translates to:
  /// **'ثقة متوسطة'**
  String get kbe_conf_med;

  /// No description provided for @kbe_conf_low.
  ///
  /// In ar, this message translates to:
  /// **'ثقة منخفضة'**
  String get kbe_conf_low;

  /// No description provided for @kbe_low_hint.
  ///
  /// In ar, this message translates to:
  /// **'أضف صيغًا أخرى أو وضّح الإجابة لرفع الثقة'**
  String get kbe_low_hint;

  /// No description provided for @kbe_try_another.
  ///
  /// In ar, this message translates to:
  /// **'جرّب سؤالًا آخر'**
  String get kbe_try_another;

  /// No description provided for @kbe_test_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالًا لتجربته'**
  String get kbe_test_hint;

  /// No description provided for @kbe_preview_err.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المعاينة'**
  String get kbe_preview_err;

  /// No description provided for @kbe_preview_offline.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة تحتاج اتصالًا'**
  String get kbe_preview_offline;

  /// No description provided for @kbe_preview_empty.
  ///
  /// In ar, this message translates to:
  /// **'أكمل السؤال والإجابة لتظهر المعاينة'**
  String get kbe_preview_empty;

  /// No description provided for @kbe_preview_regen.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المعاينة'**
  String get kbe_preview_regen;

  /// No description provided for @kbe_advanced.
  ///
  /// In ar, this message translates to:
  /// **'خيارات متقدمة'**
  String get kbe_advanced;

  /// No description provided for @kbe_enabled.
  ///
  /// In ar, this message translates to:
  /// **'متاح للذكاء الاصطناعي'**
  String get kbe_enabled;

  /// No description provided for @kbe_channels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get kbe_channels;

  /// No description provided for @kbe_channels_all.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get kbe_channels_all;

  /// No description provided for @kbe_expires.
  ///
  /// In ar, this message translates to:
  /// **'صالحة حتى'**
  String get kbe_expires;

  /// No description provided for @kbe_expires_none.
  ///
  /// In ar, this message translates to:
  /// **'بدون تاريخ انتهاء'**
  String get kbe_expires_none;

  /// No description provided for @kbe_expires_clear.
  ///
  /// In ar, this message translates to:
  /// **'إزالة التاريخ'**
  String get kbe_expires_clear;

  /// No description provided for @kbe_verbatim.
  ///
  /// In ar, this message translates to:
  /// **'رد حرفي'**
  String get kbe_verbatim;

  /// No description provided for @kbe_verbatim_sub.
  ///
  /// In ar, this message translates to:
  /// **'يرسل الذكاء الإجابة كما هي دون إعادة صياغة'**
  String get kbe_verbatim_sub;

  /// No description provided for @kbe_handoff_after.
  ///
  /// In ar, this message translates to:
  /// **'تحويل لموظف بعد الإجابة'**
  String get kbe_handoff_after;

  /// No description provided for @kbe_internal_notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات داخلية'**
  String get kbe_internal_notes;

  /// No description provided for @kbe_internal_notes_ph.
  ///
  /// In ar, this message translates to:
  /// **'لا يستخدمها الذكاء'**
  String get kbe_internal_notes_ph;

  /// No description provided for @kbe_meta.
  ///
  /// In ar, this message translates to:
  /// **'آخر تعديل {n} · {t} · استُخدم {u} مرة'**
  String kbe_meta(String n, String t, String u);

  /// No description provided for @kbe_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإجابة'**
  String get kbe_delete;

  /// No description provided for @kbe_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف «{title}»؟'**
  String kbe_delete_title(String title);

  /// No description provided for @kbe_delete_body.
  ///
  /// In ar, this message translates to:
  /// **'لن يستخدمها الذكاء بعد الآن.'**
  String get kbe_delete_body;

  /// No description provided for @kbe_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف'**
  String get kbe_deleted;

  /// No description provided for @kbe_history.
  ///
  /// In ar, this message translates to:
  /// **'سجل التغييرات'**
  String get kbe_history;

  /// No description provided for @kbe_restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة هذه النسخة'**
  String get kbe_restore;

  /// No description provided for @kbe_version_n.
  ///
  /// In ar, this message translates to:
  /// **'النسخة {n}'**
  String kbe_version_n(String n);

  /// No description provided for @kbe_version_current.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get kbe_version_current;

  /// No description provided for @kbe_versions_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نسخ سابقة'**
  String get kbe_versions_empty;

  /// No description provided for @kbe_restored.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة النسخة'**
  String get kbe_restored;

  /// No description provided for @kbe_restore_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت الاستعادة'**
  String get kbe_restore_failed;

  /// No description provided for @kbe_err_q.
  ///
  /// In ar, this message translates to:
  /// **'اكتب السؤال (5 أحرف على الأقل)'**
  String get kbe_err_q;

  /// No description provided for @kbe_err_a.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الإجابة (10 أحرف على الأقل)'**
  String get kbe_err_a;

  /// No description provided for @kbe_err_a_long.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة أطول من 2000 حرف'**
  String get kbe_err_a_long;

  /// No description provided for @kbe_err_date.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخًا في المستقبل'**
  String get kbe_err_date;

  /// No description provided for @kbe_saved_new.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الإجابة · سيستخدمها الذكاء فورًا'**
  String get kbe_saved_new;

  /// No description provided for @kbe_saved_edit.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التعديلات'**
  String get kbe_saved_edit;

  /// No description provided for @kbe_saved_unanswered.
  ///
  /// In ar, this message translates to:
  /// **'تمت الإضافة · {n} محادثات كانت تنتظر هذه الإجابة'**
  String kbe_saved_unanswered(String n);

  /// No description provided for @kbe_saved_chat.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت لقاعدة المعرفة'**
  String get kbe_saved_chat;

  /// No description provided for @kbe_proposed.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت للمراجعة'**
  String get kbe_proposed;

  /// No description provided for @kbe_approve.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد ونشر'**
  String get kbe_approve;

  /// No description provided for @kbe_approved.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد الإجابة ونشرها'**
  String get kbe_approved;

  /// No description provided for @kbe_reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get kbe_reject;

  /// No description provided for @kbe_rejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض المقترح'**
  String get kbe_rejected;

  /// No description provided for @kbe_save_err.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ'**
  String get kbe_save_err;

  /// No description provided for @kbe_save_forbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية الحفظ — أرسلها للمراجعة'**
  String get kbe_save_forbidden;

  /// No description provided for @kbe_save_offline.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ يتطلب اتصالًا بالإنترنت'**
  String get kbe_save_offline;

  /// No description provided for @kbe_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get kbe_retry;

  /// No description provided for @kbe_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الإجابة'**
  String get kbe_load_error;

  /// No description provided for @kbe_conflict_title.
  ///
  /// In ar, this message translates to:
  /// **'عدّل {name} هذه الإجابة للتو'**
  String kbe_conflict_title(String name);

  /// No description provided for @kbe_view_theirs.
  ///
  /// In ar, this message translates to:
  /// **'عرض نسختهم'**
  String get kbe_view_theirs;

  /// No description provided for @kbe_overwrite.
  ///
  /// In ar, this message translates to:
  /// **'حفظ نسختي فوقها'**
  String get kbe_overwrite;

  /// No description provided for @kbe_restore_draft.
  ///
  /// In ar, this message translates to:
  /// **'لديك مسودة غير محفوظة — استعادتها؟'**
  String get kbe_restore_draft;

  /// No description provided for @kbe_restore_btn.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get kbe_restore_btn;

  /// No description provided for @kbe_restore_ignore.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get kbe_restore_ignore;

  /// No description provided for @kbe_discard_title.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التغييرات؟'**
  String get kbe_discard_title;

  /// No description provided for @kbe_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ الإجابة.'**
  String get kbe_discard_body;

  /// No description provided for @kbe_discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get kbe_discard;

  /// No description provided for @kbe_keep.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get kbe_keep;

  /// No description provided for @kbe_deleted_elsewhere.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف هذه الإجابة'**
  String get kbe_deleted_elsewhere;

  /// No description provided for @kbe_close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get kbe_close;

  /// No description provided for @kbe_a11y_alt.
  ///
  /// In ar, this message translates to:
  /// **'صيغة: {text}، اضغط مرتين للتعديل'**
  String kbe_a11y_alt(String text);

  /// No description provided for @kbe_a11y_alt_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get kbe_a11y_alt_delete;

  /// No description provided for @kbe_a11y_ghost.
  ///
  /// In ar, this message translates to:
  /// **'صيغة مقترحة من الذكاء: {text}، اضغط للإضافة'**
  String kbe_a11y_ghost(String text);

  /// No description provided for @kbe_a11y_save_disabled.
  ///
  /// In ar, this message translates to:
  /// **'أكمل السؤال والإجابة'**
  String get kbe_a11y_save_disabled;

  /// No description provided for @kbe_a11y_dismiss.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق التنبيه'**
  String get kbe_a11y_dismiss;

  /// No description provided for @kbe_media.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get kbe_media;

  /// No description provided for @kbe_media_hint.
  ///
  /// In ar, this message translates to:
  /// **'يرسلها الذكاء مع الإجابة'**
  String get kbe_media_hint;

  /// No description provided for @kbe_media_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة أو تسجيل صوتي'**
  String get kbe_media_add;

  /// No description provided for @kbe_media_image.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get kbe_media_image;

  /// No description provided for @kbe_media_voice.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صوتي'**
  String get kbe_media_voice;

  /// No description provided for @kbe_media_with_text.
  ///
  /// In ar, this message translates to:
  /// **'مع النص'**
  String get kbe_media_with_text;

  /// No description provided for @kbe_media_file_only.
  ///
  /// In ar, this message translates to:
  /// **'ملف فقط'**
  String get kbe_media_file_only;

  /// No description provided for @kbe_media_remove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get kbe_media_remove;

  /// No description provided for @kbe_media_uploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع {p}%'**
  String kbe_media_uploading(int p);

  /// No description provided for @kbe_media_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع الملف'**
  String get kbe_media_failed;

  /// No description provided for @kbe_media_queued.
  ///
  /// In ar, this message translates to:
  /// **'يُرفع بعد الحفظ'**
  String get kbe_media_queued;

  /// No description provided for @kbe_media_too_big.
  ///
  /// In ar, this message translates to:
  /// **'الملف أكبر من 16 ميجابايت'**
  String get kbe_media_too_big;

  /// No description provided for @kbe_media_image_too_big.
  ///
  /// In ar, this message translates to:
  /// **'الصورة أكبر من 5 ميجابايت'**
  String get kbe_media_image_too_big;

  /// No description provided for @kbe_media_type_err.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة أو ملفًا صوتيًا'**
  String get kbe_media_type_err;

  /// No description provided for @kbe_media_upgrade.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق الصور والتسجيلات متاح في الباقات المدفوعة'**
  String get kbe_media_upgrade;

  /// No description provided for @kbe_media_upgrade_cta.
  ///
  /// In ar, this message translates to:
  /// **'عرض الباقات'**
  String get kbe_media_upgrade_cta;

  /// No description provided for @kbe_media_some_failed.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ، لكن تعذّر رفع {n} من المرفقات'**
  String kbe_media_some_failed(int n);

  /// No description provided for @kbe_media_send_mode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الإرسال'**
  String get kbe_media_send_mode;

  /// No description provided for @kb_title.
  ///
  /// In ar, this message translates to:
  /// **'المعرفة'**
  String get kb_title;

  /// No description provided for @kb_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في {n} مدخلًا'**
  String kb_search(int n);

  /// No description provided for @kb_qa.
  ///
  /// In ar, this message translates to:
  /// **'سؤال وجواب'**
  String get kb_qa;

  /// No description provided for @kb_files.
  ///
  /// In ar, this message translates to:
  /// **'ملفات'**
  String get kb_files;

  /// No description provided for @kb_links.
  ///
  /// In ar, this message translates to:
  /// **'روابط'**
  String get kb_links;

  /// No description provided for @kb_processing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المعالجة'**
  String get kb_processing;

  /// No description provided for @kb_unanswered_title.
  ///
  /// In ar, this message translates to:
  /// **'{n} أسئلة بلا إجابة'**
  String kb_unanswered_title(int n);

  /// No description provided for @kb_unanswered_body.
  ///
  /// In ar, this message translates to:
  /// **'سألها العملاء ولم يجد الذكاء جوابًا'**
  String get kb_unanswered_body;

  /// No description provided for @kb_review.
  ///
  /// In ar, this message translates to:
  /// **'راجعها'**
  String get kb_review;

  /// No description provided for @kb_sort_usage.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر استخدامًا'**
  String get kb_sort_usage;

  /// No description provided for @kb_sort_recent.
  ///
  /// In ar, this message translates to:
  /// **'المحدّثة مؤخرًا'**
  String get kb_sort_recent;

  /// No description provided for @kb_sort_stale.
  ///
  /// In ar, this message translates to:
  /// **'الأقدم تحديثًا'**
  String get kb_sort_stale;

  /// No description provided for @kb_sort_alpha.
  ///
  /// In ar, this message translates to:
  /// **'أبجديًا'**
  String get kb_sort_alpha;

  /// No description provided for @kb_sort_least.
  ///
  /// In ar, this message translates to:
  /// **'الأقل استخدامًا'**
  String get kb_sort_least;

  /// No description provided for @kb_tags.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get kb_tags;

  /// No description provided for @kb_used_n.
  ///
  /// In ar, this message translates to:
  /// **'استُخدم {n} مرة'**
  String kb_used_n(int n);

  /// No description provided for @kb_updated.
  ///
  /// In ar, this message translates to:
  /// **'محدّث منذ {t}'**
  String kb_updated(String t);

  /// No description provided for @kb_pages.
  ///
  /// In ar, this message translates to:
  /// **'{n} صفحة'**
  String kb_pages(int n);

  /// No description provided for @kb_badge_draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get kb_badge_draft;

  /// No description provided for @kb_badge_disabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get kb_badge_disabled;

  /// No description provided for @kb_badge_stale.
  ///
  /// In ar, this message translates to:
  /// **'قديم'**
  String get kb_badge_stale;

  /// No description provided for @kb_badge_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المعالجة'**
  String get kb_badge_failed;

  /// No description provided for @kb_disable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل للذكاء'**
  String get kb_disable;

  /// No description provided for @kb_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get kb_enable;

  /// No description provided for @kb_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get kb_edit;

  /// No description provided for @kb_copy_answer.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الإجابة'**
  String get kb_copy_answer;

  /// No description provided for @kb_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get kb_delete;

  /// No description provided for @kb_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف «{title}»؟'**
  String kb_delete_title(String title);

  /// No description provided for @kb_delete_body.
  ///
  /// In ar, this message translates to:
  /// **'لن يستخدمها الذكاء بعد الآن.'**
  String get kb_delete_body;

  /// No description provided for @kb_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف'**
  String get kb_deleted;

  /// No description provided for @kb_drafts.
  ///
  /// In ar, this message translates to:
  /// **'مقترحات بانتظار المراجعة · {n}'**
  String kb_drafts(int n);

  /// No description provided for @kb_draft_by.
  ///
  /// In ar, this message translates to:
  /// **'اقترحها {name} · {t}'**
  String kb_draft_by(String name, String t);

  /// No description provided for @kb_draft_from_conv.
  ///
  /// In ar, this message translates to:
  /// **'مقترحة من محادثة محلولة'**
  String get kb_draft_from_conv;

  /// No description provided for @kb_approve.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get kb_approve;

  /// No description provided for @kb_reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get kb_reject;

  /// No description provided for @kb_add_title.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى قاعدة المعرفة'**
  String get kb_add_title;

  /// No description provided for @kb_add_qa_sub.
  ///
  /// In ar, this message translates to:
  /// **'الأسرع والأدق للذكاء'**
  String get kb_add_qa_sub;

  /// No description provided for @kb_add_file.
  ///
  /// In ar, this message translates to:
  /// **'رفع ملف'**
  String get kb_add_file;

  /// No description provided for @kb_add_file_sub.
  ///
  /// In ar, this message translates to:
  /// **'عدة أسئلة وأجوبة دفعة واحدة من ملف JSON (بصيغة لوحة الويب)'**
  String get kb_add_file_sub;

  /// No description provided for @kb_add_link.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رابط'**
  String get kb_add_link;

  /// No description provided for @kb_add_link_sub.
  ///
  /// In ar, this message translates to:
  /// **'صفحة من موقعك، يقرأها الذكاء تلقائيًا'**
  String get kb_add_link_sub;

  /// No description provided for @kb_alt_phrasings.
  ///
  /// In ar, this message translates to:
  /// **'صيغ أخرى'**
  String get kb_alt_phrasings;

  /// No description provided for @kb_answer.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة'**
  String get kb_answer;

  /// No description provided for @kb_usage_month.
  ///
  /// In ar, this message translates to:
  /// **'استُخدم {n} مرة هذا الشهر'**
  String kb_usage_month(int n);

  /// No description provided for @kb_positive.
  ///
  /// In ar, this message translates to:
  /// **'تقييم إيجابي {p}%'**
  String kb_positive(int p);

  /// No description provided for @kb_last_used.
  ///
  /// In ar, this message translates to:
  /// **'آخر استخدام {t}'**
  String kb_last_used(String t);

  /// No description provided for @kb_recent_uses.
  ///
  /// In ar, this message translates to:
  /// **'آخر الاستخدامات'**
  String get kb_recent_uses;

  /// No description provided for @kb_meta.
  ///
  /// In ar, this message translates to:
  /// **'أنشأها {a} · {d} · آخر تعديل {b} {t}'**
  String kb_meta(String a, String d, String b, String t);

  /// No description provided for @kb_available_ai.
  ///
  /// In ar, this message translates to:
  /// **'متاح للذكاء الاصطناعي'**
  String get kb_available_ai;

  /// No description provided for @kb_file_type_err.
  ///
  /// In ar, this message translates to:
  /// **'نوع الملف غير مدعوم'**
  String get kb_file_type_err;

  /// No description provided for @kb_file_size_err.
  ///
  /// In ar, this message translates to:
  /// **'الملف أكبر من 10 ميجابايت'**
  String get kb_file_size_err;

  /// No description provided for @kb_uploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع {p}%'**
  String kb_uploading(int p);

  /// No description provided for @kb_processing_long.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المعالجة… قد يستغرق دقيقة'**
  String get kb_processing_long;

  /// No description provided for @kb_file_ready.
  ///
  /// In ar, this message translates to:
  /// **'أصبح «{f}» جاهزًا · {n} إجابة للمراجعة'**
  String kb_file_ready(String f, int n);

  /// No description provided for @kb_extracted.
  ///
  /// In ar, this message translates to:
  /// **'ما استخرجه الذكاء'**
  String get kb_extracted;

  /// No description provided for @kb_replace.
  ///
  /// In ar, this message translates to:
  /// **'استبدال الملف'**
  String get kb_replace;

  /// No description provided for @kb_download.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get kb_download;

  /// No description provided for @kb_file_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت قراءة الملف'**
  String get kb_file_failed;

  /// No description provided for @kb_fail_encrypted.
  ///
  /// In ar, this message translates to:
  /// **'الملف محمي بكلمة مرور'**
  String get kb_fail_encrypted;

  /// No description provided for @kb_fail_images.
  ///
  /// In ar, this message translates to:
  /// **'الملف صور فقط بدون نص'**
  String get kb_fail_images;

  /// No description provided for @kb_fail_corrupt.
  ///
  /// In ar, this message translates to:
  /// **'الملف تالف'**
  String get kb_fail_corrupt;

  /// No description provided for @kb_link_url.
  ///
  /// In ar, this message translates to:
  /// **'رابط الصفحة'**
  String get kb_link_url;

  /// No description provided for @kb_link_subpages.
  ///
  /// In ar, this message translates to:
  /// **'تضمين الصفحات الفرعية'**
  String get kb_link_subpages;

  /// No description provided for @kb_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get kb_add;

  /// No description provided for @kb_last_crawl.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة {t}'**
  String kb_last_crawl(String t);

  /// No description provided for @kb_recrawl.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الآن'**
  String get kb_recrawl;

  /// No description provided for @kb_auto_refresh.
  ///
  /// In ar, this message translates to:
  /// **'التحديث التلقائي'**
  String get kb_auto_refresh;

  /// No description provided for @kb_weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعيًا'**
  String get kb_weekly;

  /// No description provided for @kb_monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهريًا'**
  String get kb_monthly;

  /// No description provided for @kb_manual.
  ///
  /// In ar, this message translates to:
  /// **'يدويًا'**
  String get kb_manual;

  /// No description provided for @kb_unanswered.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة بلا إجابة'**
  String get kb_unanswered;

  /// No description provided for @kb_unanswered_info.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة سألها العملاء ولم يجد لها الذكاء إجابة. أضف إجابة ليردّ تلقائيًا في المرة القادمة.'**
  String get kb_unanswered_info;

  /// No description provided for @kb_sort_frequency.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر تكرارًا'**
  String get kb_sort_frequency;

  /// No description provided for @kb_sort_newest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get kb_sort_newest;

  /// No description provided for @kb_asked_n.
  ///
  /// In ar, this message translates to:
  /// **'سُئل {n} مرات · آخرها {t}'**
  String kb_asked_n(int n, String t);

  /// No description provided for @kb_similar.
  ///
  /// In ar, this message translates to:
  /// **'+{k} صيغ مشابهة'**
  String kb_similar(int k);

  /// No description provided for @kb_ai_draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة مقترحة'**
  String get kb_ai_draft;

  /// No description provided for @kb_add_answer.
  ///
  /// In ar, this message translates to:
  /// **'أضف إجابة'**
  String get kb_add_answer;

  /// No description provided for @kb_link_existing.
  ///
  /// In ar, this message translates to:
  /// **'ربط بإجابة موجودة'**
  String get kb_link_existing;

  /// No description provided for @kb_ignore.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get kb_ignore;

  /// No description provided for @kb_view_convs.
  ///
  /// In ar, this message translates to:
  /// **'عرض المحادثات'**
  String get kb_view_convs;

  /// No description provided for @kb_suggest_answer.
  ///
  /// In ar, this message translates to:
  /// **'اقترح إجابة'**
  String get kb_suggest_answer;

  /// No description provided for @kb_none_unanswered.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أسئلة بلا إجابة'**
  String get kb_none_unanswered;

  /// No description provided for @kb_none_unanswered_body.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء يجد إجابات لكل ما يُسأل حاليًا.'**
  String get kb_none_unanswered_body;

  /// No description provided for @kb_empty_title.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بتعليم الذكاء عن عملك'**
  String get kb_empty_title;

  /// No description provided for @kb_empty_body.
  ///
  /// In ar, this message translates to:
  /// **'أضف أهم الأسئلة التي يسألها عملاؤك وإجاباتها.'**
  String get kb_empty_body;

  /// No description provided for @kb_empty_cta.
  ///
  /// In ar, this message translates to:
  /// **'أضف أول سؤال'**
  String get kb_empty_cta;

  /// No description provided for @kb_empty_tip.
  ///
  /// In ar, this message translates to:
  /// **'ننصح بـ 10 أسئلة على الأقل'**
  String get kb_empty_tip;

  /// No description provided for @kb_filter_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدخلات من هذا النوع'**
  String get kb_filter_empty;

  /// No description provided for @kb_show_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get kb_show_all;

  /// No description provided for @kb_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل قاعدة المعرفة'**
  String get kb_error;

  /// No description provided for @kb_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get kb_retry;

  /// No description provided for @kb_offline.
  ///
  /// In ar, this message translates to:
  /// **'التعديل يتطلب اتصالًا بالإنترنت'**
  String get kb_offline;

  /// No description provided for @kb_span_now.
  ///
  /// In ar, this message translates to:
  /// **'لحظات'**
  String get kb_span_now;

  /// No description provided for @kb_span_minutes.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{دقيقة} =2{دقيقتين} few{{n} دقائق} other{{n} دقيقة}}'**
  String kb_span_minutes(int n);

  /// No description provided for @kb_span_hours.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{ساعة} =2{ساعتين} few{{n} ساعات} other{{n} ساعة}}'**
  String kb_span_hours(int n);

  /// No description provided for @kb_span_days.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{يوم} =2{يومين} few{{n} أيام} other{{n} يومًا}}'**
  String kb_span_days(int n);

  /// No description provided for @kb_span_months.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{شهر} =2{شهرين} few{{n} أشهر} other{{n} شهرًا}}'**
  String kb_span_months(int n);

  /// No description provided for @kb_span_years.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{سنة} =2{سنتين} few{{n} سنوات} other{{n} سنة}}'**
  String kb_span_years(int n);

  /// No description provided for @kb_web_only.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة متاحة من لوحة الويب حاليًا'**
  String get kb_web_only;

  /// No description provided for @kb_menu_ai_settings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الذكاء الاصطناعي'**
  String get kb_menu_ai_settings;

  /// No description provided for @kb_menu_tags.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الوسوم'**
  String get kb_menu_tags;

  /// No description provided for @kb_menu_import.
  ///
  /// In ar, this message translates to:
  /// **'استيراد من الويب'**
  String get kb_menu_import;

  /// No description provided for @kb_sort_by.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get kb_sort_by;

  /// No description provided for @kb_tags_all.
  ///
  /// In ar, this message translates to:
  /// **'كل الوسوم'**
  String get kb_tags_all;

  /// No description provided for @kb_tags_apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get kb_tags_apply;

  /// No description provided for @kb_tags_none.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وسوم بعد'**
  String get kb_tags_none;

  /// No description provided for @kb_disabled_done.
  ///
  /// In ar, this message translates to:
  /// **'تم التعطيل · لن يستخدمها الذكاء'**
  String get kb_disabled_done;

  /// No description provided for @kb_enabled_done.
  ///
  /// In ar, this message translates to:
  /// **'تم التفعيل'**
  String get kb_enabled_done;

  /// No description provided for @kb_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الإجابة'**
  String get kb_copied;

  /// No description provided for @kb_approved.
  ///
  /// In ar, this message translates to:
  /// **'تم الاعتماد والنشر'**
  String get kb_approved;

  /// No description provided for @kb_rejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض المقترح'**
  String get kb_rejected;

  /// No description provided for @kb_ignored.
  ///
  /// In ar, this message translates to:
  /// **'تم التجاهل'**
  String get kb_ignored;

  /// No description provided for @kb_linked.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت كصيغة أخرى لـ«{t}»'**
  String kb_linked(String t);

  /// No description provided for @kb_pick_answer.
  ///
  /// In ar, this message translates to:
  /// **'اختر إجابة'**
  String get kb_pick_answer;

  /// No description provided for @kb_pick_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الإجابات'**
  String get kb_pick_search;

  /// No description provided for @kb_uploaded_by.
  ///
  /// In ar, this message translates to:
  /// **'رفعه {name} · {d}'**
  String kb_uploaded_by(String name, String d);

  /// No description provided for @kb_mb.
  ///
  /// In ar, this message translates to:
  /// **'{n} ميجابايت'**
  String kb_mb(String n);

  /// No description provided for @kb_kb.
  ///
  /// In ar, this message translates to:
  /// **'{n} كيلوبايت'**
  String kb_kb(String n);

  /// No description provided for @kb_processing_bg.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إغلاق هذه النافذة، ستستمر المعالجة في الخلفية'**
  String get kb_processing_bg;

  /// No description provided for @kb_url_invalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رابطًا صحيحًا يبدأ بـ https://'**
  String get kb_url_invalid;

  /// No description provided for @kb_link_added.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف الرابط · جارٍ قراءته'**
  String get kb_link_added;

  /// No description provided for @kb_link_pages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get kb_link_pages;

  /// No description provided for @kb_never_crawled.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم القراءة بعد'**
  String get kb_never_crawled;

  /// No description provided for @kb_recrawl_started.
  ///
  /// In ar, this message translates to:
  /// **'بدأت إعادة القراءة'**
  String get kb_recrawl_started;

  /// No description provided for @kb_filter_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{label}، {n}، تصفية'**
  String kb_filter_a11y(String label, int n);

  /// No description provided for @kb_banner_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{n} أسئلة بلا إجابة. راجعها'**
  String kb_banner_a11y(int n);

  /// No description provided for @kb_daily_chart.
  ///
  /// In ar, this message translates to:
  /// **'الاستخدام خلال 30 يومًا'**
  String get kb_daily_chart;

  /// No description provided for @kb_not_used_yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُستخدم بعد'**
  String get kb_not_used_yet;

  /// No description provided for @kb_show_less.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get kb_show_less;

  /// No description provided for @kb_proposed.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل اقتراحك للمراجعة'**
  String get kb_proposed;

  /// No description provided for @kb_save_err.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ'**
  String get kb_save_err;

  /// No description provided for @kb_none_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get kb_none_found;

  /// No description provided for @kb_import_title.
  ///
  /// In ar, this message translates to:
  /// **'استيراد من ملف JSON'**
  String get kb_import_title;

  /// No description provided for @kb_import_hint.
  ///
  /// In ar, this message translates to:
  /// **'ملف يحتوي قائمة entries، لكل مدخل type و title و body — بنفس صيغة لوحة الويب.'**
  String get kb_import_hint;

  /// No description provided for @kb_import_pick.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف JSON'**
  String get kb_import_pick;

  /// No description provided for @kb_import_template.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل القالب'**
  String get kb_import_template;

  /// No description provided for @kb_importing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاستيراد…'**
  String get kb_importing;

  /// No description provided for @kb_import_done.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد {n} مدخلًا'**
  String kb_import_done(int n);

  /// No description provided for @kb_import_skipped.
  ///
  /// In ar, this message translates to:
  /// **'تم تخطي {n}'**
  String kb_import_skipped(int n);

  /// No description provided for @kb_import_row_err.
  ///
  /// In ar, this message translates to:
  /// **'السطر {row}: {message}'**
  String kb_import_row_err(int row, String message);

  /// No description provided for @kb_import_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاستيراد'**
  String get kb_import_failed;

  /// No description provided for @kb_import_json_only.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفًا بصيغة JSON'**
  String get kb_import_json_only;

  /// No description provided for @kb_template_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ القالب'**
  String get kb_template_saved;

  /// No description provided for @kb_template_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ القالب إلى الحافظة'**
  String get kb_template_copied;

  /// No description provided for @kb_media_title.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get kb_media_title;

  /// No description provided for @kb_media_n.
  ///
  /// In ar, this message translates to:
  /// **'{n} مرفقات'**
  String kb_media_n(int n);

  /// No description provided for @kb_step_upload.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع الملف'**
  String get kb_step_upload;

  /// No description provided for @kb_step_read.
  ///
  /// In ar, this message translates to:
  /// **'قراءة المستند'**
  String get kb_step_read;

  /// No description provided for @kb_step_prepare.
  ///
  /// In ar, this message translates to:
  /// **'تجهيز الإجابات'**
  String get kb_step_prepare;

  /// No description provided for @kb_processing_hint.
  ///
  /// In ar, this message translates to:
  /// **'يستغرق عادةً أقل من دقيقة. يمكنك الإخفاء وسنكمل العمل.'**
  String get kb_processing_hint;

  /// No description provided for @kb_hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get kb_hide;

  /// No description provided for @kb_found_answers.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لم نجد إجابات} =1{وجدنا إجابة واحدة} =2{وجدنا إجابتين} few{وجدنا {n} إجابات} other{وجدنا {n} إجابة}}'**
  String kb_found_answers(int n);

  /// No description provided for @kb_found_review_hint.
  ///
  /// In ar, this message translates to:
  /// **'راجعها واختر ما يجب أن يعرفه الذكاء الاصطناعي.'**
  String get kb_found_review_hint;

  /// No description provided for @kb_found_admin_hint.
  ///
  /// In ar, this message translates to:
  /// **'سيراجعها أحد المشرفين قبل أن يستخدمها الذكاء الاصطناعي.'**
  String get kb_found_admin_hint;

  /// No description provided for @kb_review_answers.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الإجابات'**
  String get kb_review_answers;

  /// No description provided for @kb_later.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get kb_later;

  /// No description provided for @kb_fail_encrypted_hint.
  ///
  /// In ar, this message translates to:
  /// **'أزل كلمة المرور ثم ارفعه مجددًا.'**
  String get kb_fail_encrypted_hint;

  /// No description provided for @kb_fail_images_hint.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد نصًا قابلًا للقراءة. جرّب ملف PDF بنص قابل للتحديد أو ملف Word.'**
  String get kb_fail_images_hint;

  /// No description provided for @kb_fail_corrupt_hint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب ملفًا آخر: PDF أو Word أو TXT أو MD حتى 10 ميجابايت.'**
  String get kb_fail_corrupt_hint;

  /// No description provided for @kb_fail_no_answers.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد إجابات'**
  String get kb_fail_no_answers;

  /// No description provided for @kb_fail_no_answers_hint.
  ///
  /// In ar, this message translates to:
  /// **'يبدو أن المستند لا يحتوي على معلومات يسأل عنها العملاء.'**
  String get kb_fail_no_answers_hint;

  /// No description provided for @kb_fail_ai.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت قراءة الملف حاليًا'**
  String get kb_fail_ai;

  /// No description provided for @kb_fail_ai_hint.
  ///
  /// In ar, this message translates to:
  /// **'يرجى المحاولة مرة أخرى بعد دقائق.'**
  String get kb_fail_ai_hint;

  /// No description provided for @kb_fail_quota.
  ///
  /// In ar, this message translates to:
  /// **'نفد رصيد الذكاء الاصطناعي'**
  String get kb_fail_quota;

  /// No description provided for @kb_fail_quota_hint.
  ///
  /// In ar, this message translates to:
  /// **'اشحن الرصيد أو رقِّ الباقة لقراءة المستندات بالذكاء الاصطناعي.'**
  String get kb_fail_quota_hint;

  /// No description provided for @kb_fail_network.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال'**
  String get kb_fail_network;

  /// No description provided for @kb_fail_network_hint.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الإنترنت وحاول مرة أخرى.'**
  String get kb_fail_network_hint;

  /// No description provided for @kb_try_another.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفًا آخر'**
  String get kb_try_another;

  /// No description provided for @kb_review_title.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الإجابات'**
  String get kb_review_title;

  /// No description provided for @kb_review_from.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{إجابة واحدة من {file}} =2{إجابتان من {file}} few{{n} إجابات من {file}} other{{n} إجابة من {file}}}'**
  String kb_review_from(int n, String file);

  /// No description provided for @kb_review_hint.
  ///
  /// In ar, this message translates to:
  /// **'حدّد ما يجب أن يعرفه الذكاء الاصطناعي، وعدّل ما يحتاج تعديلًا، ثم أضِف.'**
  String get kb_review_hint;

  /// No description provided for @kb_review_selected.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد {n} من {total}'**
  String kb_review_selected(int n, int total);

  /// No description provided for @kb_review_select_all.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get kb_review_select_all;

  /// No description provided for @kb_review_clear.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التحديد'**
  String get kb_review_clear;

  /// No description provided for @kb_review_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get kb_review_edit;

  /// No description provided for @kb_review_discard.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get kb_review_discard;

  /// No description provided for @kb_review_add.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{إضافة الإجابات} =1{إضافة إجابة واحدة} =2{إضافة إجابتين} few{إضافة {n} إجابات} other{إضافة {n} إجابة}}'**
  String kb_review_add(int n);

  /// No description provided for @kb_review_adding.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإضافة {done}/{total}…'**
  String kb_review_adding(int done, int total);

  /// No description provided for @kb_review_added.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{أُضيفت إجابة واحدة إلى قاعدة المعرفة} other{أُضيفت {n} إجابة إلى قاعدة المعرفة}}'**
  String kb_review_added(int n);

  /// No description provided for @kb_review_added_left.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت {n} · بقيت {left} للمراجعة'**
  String kb_review_added_left(int n, int left);

  /// No description provided for @kb_review_partial.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت {done}، وتعذّرت إضافة {failed}. حاول مرة أخرى.'**
  String kb_review_partial(int done, int failed);

  /// No description provided for @kb_review_all_done.
  ///
  /// In ar, this message translates to:
  /// **'تمت مراجعة كل الإجابات'**
  String get kb_review_all_done;

  /// No description provided for @kb_review_all_done_body.
  ///
  /// In ar, this message translates to:
  /// **'لم يتبقَّ شيء للمراجعة من هذا المستند.'**
  String get kb_review_all_done_body;

  /// No description provided for @kb_file_failed_named.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت قراءة «{f}»'**
  String kb_file_failed_named(String f);

  /// No description provided for @kb_add_document.
  ///
  /// In ar, this message translates to:
  /// **'رفع مستند'**
  String get kb_add_document;

  /// No description provided for @kb_add_document_sub.
  ///
  /// In ar, this message translates to:
  /// **'PDF أو Word أو ملف نصي. يحوّله الذكاء الاصطناعي إلى إجابات تراجعها.'**
  String get kb_add_document_sub;

  /// No description provided for @kb_add_ai_badge.
  ///
  /// In ar, this message translates to:
  /// **'ذكاء'**
  String get kb_add_ai_badge;

  /// No description provided for @kb_import_another.
  ///
  /// In ar, this message translates to:
  /// **'استيراد ملف آخر'**
  String get kb_import_another;

  /// No description provided for @ntf_title.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get ntf_title;

  /// No description provided for @ntf_read_all.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الكل'**
  String get ntf_read_all;

  /// No description provided for @ntf_read_all_done.
  ///
  /// In ar, this message translates to:
  /// **'تم تعليم الكل كمقروء'**
  String get ntf_read_all_done;

  /// No description provided for @ntf_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get ntf_undo;

  /// No description provided for @ntf_settings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الإشعارات'**
  String get ntf_settings;

  /// No description provided for @ntf_delete_read.
  ///
  /// In ar, this message translates to:
  /// **'حذف المقروءة'**
  String get ntf_delete_read;

  /// No description provided for @ntf_filter_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get ntf_filter_all;

  /// No description provided for @ntf_filter_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروءة'**
  String get ntf_filter_unread;

  /// No description provided for @ntf_filter_mentions.
  ///
  /// In ar, this message translates to:
  /// **'الإشارات'**
  String get ntf_filter_mentions;

  /// No description provided for @ntf_filter_assignments.
  ///
  /// In ar, this message translates to:
  /// **'الإسناد'**
  String get ntf_filter_assignments;

  /// No description provided for @ntf_filter_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء'**
  String get ntf_filter_ai;

  /// No description provided for @ntf_filter_system.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get ntf_filter_system;

  /// No description provided for @ntf_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get ntf_today;

  /// No description provided for @ntf_yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get ntf_yesterday;

  /// No description provided for @ntf_this_week.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get ntf_this_week;

  /// No description provided for @ntf_older.
  ///
  /// In ar, this message translates to:
  /// **'أقدم'**
  String get ntf_older;

  /// No description provided for @ntf_push_off_title.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات الفورية متوقفة'**
  String get ntf_push_off_title;

  /// No description provided for @ntf_push_off_body.
  ///
  /// In ar, this message translates to:
  /// **'فعّلها حتى لا تفوتك محادثة مُسندة إليك'**
  String get ntf_push_off_body;

  /// No description provided for @ntf_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get ntf_enable;

  /// No description provided for @ntf_mark_read.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كمقروء'**
  String get ntf_mark_read;

  /// No description provided for @ntf_mark_unread.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كغير مقروء'**
  String get ntf_mark_unread;

  /// No description provided for @ntf_mute_type.
  ///
  /// In ar, this message translates to:
  /// **'كتم هذا النوع'**
  String get ntf_mute_type;

  /// No description provided for @ntf_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get ntf_delete;

  /// No description provided for @ntf_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الإشعار'**
  String get ntf_deleted;

  /// No description provided for @ntf_empty_title.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get ntf_empty_title;

  /// No description provided for @ntf_empty_body.
  ///
  /// In ar, this message translates to:
  /// **'سنخبرك هنا عند إسناد محادثة إليك أو عند حاجة الفريق لك.'**
  String get ntf_empty_body;

  /// No description provided for @ntf_empty_filter.
  ///
  /// In ar, this message translates to:
  /// **'لا إشعارات في «{f}»'**
  String ntf_empty_filter(String f);

  /// No description provided for @ntf_show_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get ntf_show_all;

  /// No description provided for @ntf_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الإشعارات'**
  String get ntf_error;

  /// No description provided for @ntf_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get ntf_retry;

  /// No description provided for @ntf_end.
  ///
  /// In ar, this message translates to:
  /// **'لا مزيد من الإشعارات'**
  String get ntf_end;

  /// No description provided for @ntf_retention.
  ///
  /// In ar, this message translates to:
  /// **'تُحذف الإشعارات بعد 90 يومًا'**
  String get ntf_retention;

  /// No description provided for @ntf_target_gone.
  ///
  /// In ar, this message translates to:
  /// **'لم تعد هذه المحادثة متاحة'**
  String get ntf_target_gone;

  /// No description provided for @ntf_claimed_you.
  ///
  /// In ar, this message translates to:
  /// **'استلمتها'**
  String get ntf_claimed_you;

  /// No description provided for @ntf_claimed_by.
  ///
  /// In ar, this message translates to:
  /// **'استلمها {name}'**
  String ntf_claimed_by(String name);

  /// No description provided for @ntf_approved.
  ///
  /// In ar, this message translates to:
  /// **'وافقت'**
  String get ntf_approved;

  /// No description provided for @ntf_rejected.
  ///
  /// In ar, this message translates to:
  /// **'رفضت'**
  String get ntf_rejected;

  /// No description provided for @ntf_grouped.
  ///
  /// In ar, this message translates to:
  /// **'{n} رسائل جديدة من {name}'**
  String ntf_grouped(int n, String name);

  /// No description provided for @ntf_push_private.
  ///
  /// In ar, this message translates to:
  /// **'لديك محادثة جديدة'**
  String get ntf_push_private;

  /// No description provided for @ntf_t_assigned.
  ///
  /// In ar, this message translates to:
  /// **'أُسندت إليك محادثة جديدة'**
  String get ntf_t_assigned;

  /// No description provided for @ntf_t_claim_needed.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات بانتظار الاستلام'**
  String ntf_t_claim_needed(int n);

  /// No description provided for @ntf_t_sla_breach.
  ///
  /// In ar, this message translates to:
  /// **'{customer} ينتظر ردّك منذ {m}'**
  String ntf_t_sla_breach(String customer, String m);

  /// No description provided for @ntf_t_transfer_request.
  ///
  /// In ar, this message translates to:
  /// **'{agent} يطلب تحويل محادثة إليه'**
  String ntf_t_transfer_request(String agent);

  /// No description provided for @ntf_t_mention.
  ///
  /// In ar, this message translates to:
  /// **'{agent} أشار إليك في ملاحظة'**
  String ntf_t_mention(String agent);

  /// No description provided for @ntf_t_ai_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي لم يجد إجابة'**
  String get ntf_t_ai_no_answer;

  /// No description provided for @ntf_t_ai_handoff.
  ///
  /// In ar, this message translates to:
  /// **'حوّل الذكاء محادثة للفريق'**
  String get ntf_t_ai_handoff;

  /// No description provided for @ntf_t_ai_low_confidence.
  ///
  /// In ar, this message translates to:
  /// **'ردّ الذكاء بثقة منخفضة'**
  String get ntf_t_ai_low_confidence;

  /// No description provided for @ntf_t_kb_suggestion.
  ///
  /// In ar, this message translates to:
  /// **'{n} أسئلة متكررة بلا إجابة'**
  String ntf_t_kb_suggestion(int n);

  /// No description provided for @ntf_t_channel_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'انقطع اتصال واتساب'**
  String get ntf_t_channel_disconnected;

  /// No description provided for @ntf_t_channel_reconnected.
  ///
  /// In ar, this message translates to:
  /// **'انقطع اتصال واتساب ثم عاد'**
  String get ntf_t_channel_reconnected;

  /// No description provided for @ntf_t_channel_quality_low.
  ///
  /// In ar, this message translates to:
  /// **'جودة رقم واتساب منخفضة'**
  String get ntf_t_channel_quality_low;

  /// No description provided for @ntf_t_team_joined.
  ///
  /// In ar, this message translates to:
  /// **'انضم {name} إلى الفريق'**
  String ntf_t_team_joined(String name);

  /// No description provided for @ntf_t_team_role_changed.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر دورك إلى {role}'**
  String ntf_t_team_role_changed(String role);

  /// No description provided for @ntf_t_trial_ending.
  ///
  /// In ar, this message translates to:
  /// **'تجربتك تنتهي بعد {n} أيام'**
  String ntf_t_trial_ending(int n);

  /// No description provided for @ntf_t_payment_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحصيل الاشتراك'**
  String get ntf_t_payment_failed;

  /// No description provided for @ntf_t_plan_limit.
  ///
  /// In ar, this message translates to:
  /// **'اقتربت من حد ردود الذكاء'**
  String get ntf_t_plan_limit;

  /// No description provided for @ntf_t_app_update.
  ///
  /// In ar, this message translates to:
  /// **'يتوفر إصدار جديد'**
  String get ntf_t_app_update;

  /// No description provided for @ntf_b_claim_needed.
  ///
  /// In ar, this message translates to:
  /// **'أقدمها منذ {m}'**
  String ntf_b_claim_needed(String m);

  /// No description provided for @ntf_b_ai_no_answer.
  ///
  /// In ar, this message translates to:
  /// **'سؤال عن {topic}. أضف الإجابة ليردّ تلقائيًا في المرة القادمة.'**
  String ntf_b_ai_no_answer(String topic);

  /// No description provided for @ntf_b_ai_low_confidence.
  ///
  /// In ar, this message translates to:
  /// **'{customer} · راجع الرد'**
  String ntf_b_ai_low_confidence(String customer);

  /// No description provided for @ntf_b_kb_suggestion.
  ///
  /// In ar, this message translates to:
  /// **'أضفها لقاعدة المعرفة لتحسين الردود'**
  String get ntf_b_kb_suggestion;

  /// No description provided for @ntf_b_channel_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'لن تصل الرسائل حتى تعيد الربط'**
  String get ntf_b_channel_disconnected;

  /// No description provided for @ntf_b_channel_reconnected.
  ///
  /// In ar, this message translates to:
  /// **'توقف {m} · لم تُفقد أي رسالة'**
  String ntf_b_channel_reconnected(String m);

  /// No description provided for @ntf_b_channel_quality_low.
  ///
  /// In ar, this message translates to:
  /// **'قلّل الرسائل الجماعية لتجنب التقييد'**
  String get ntf_b_channel_quality_low;

  /// No description provided for @ntf_b_team_joined.
  ///
  /// In ar, this message translates to:
  /// **'دور: {role}'**
  String ntf_b_team_joined(String role);

  /// No description provided for @ntf_b_team_role_changed.
  ///
  /// In ar, this message translates to:
  /// **'بواسطة {actor}'**
  String ntf_b_team_role_changed(String actor);

  /// No description provided for @ntf_b_trial_ending.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطة للحفاظ على محادثاتك والذكاء الاصطناعي.'**
  String get ntf_b_trial_ending;

  /// No description provided for @ntf_b_payment_failed.
  ///
  /// In ar, this message translates to:
  /// **'حدّث وسيلة الدفع لتجنب إيقاف الخدمة'**
  String get ntf_b_payment_failed;

  /// No description provided for @ntf_b_plan_limit.
  ///
  /// In ar, this message translates to:
  /// **'استخدمت {p}% هذا الشهر'**
  String ntf_b_plan_limit(int p);

  /// No description provided for @ntf_b_app_update.
  ///
  /// In ar, this message translates to:
  /// **'{version} · تحسينات وإصلاحات'**
  String ntf_b_app_update(String version);

  /// No description provided for @ntf_a_view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get ntf_a_view;

  /// No description provided for @ntf_a_reply.
  ///
  /// In ar, this message translates to:
  /// **'رد الآن'**
  String get ntf_a_reply;

  /// No description provided for @ntf_a_approve.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get ntf_a_approve;

  /// No description provided for @ntf_a_reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get ntf_a_reject;

  /// No description provided for @ntf_a_add_answer.
  ///
  /// In ar, this message translates to:
  /// **'أضف إجابة'**
  String get ntf_a_add_answer;

  /// No description provided for @ntf_a_claim.
  ///
  /// In ar, this message translates to:
  /// **'استلم'**
  String get ntf_a_claim;

  /// No description provided for @ntf_a_review.
  ///
  /// In ar, this message translates to:
  /// **'راجعها'**
  String get ntf_a_review;

  /// No description provided for @ntf_a_reconnect.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الربط'**
  String get ntf_a_reconnect;

  /// No description provided for @ntf_a_plans.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخطط'**
  String get ntf_a_plans;

  /// No description provided for @ntf_a_update.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get ntf_a_update;

  /// No description provided for @ntf_a_open.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get ntf_a_open;

  /// No description provided for @ntf_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get ntf_more;

  /// No description provided for @ntf_dismiss.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get ntf_dismiss;

  /// No description provided for @ntf_a11y_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get ntf_a11y_unread;

  /// No description provided for @ntf_a11y_filter.
  ///
  /// In ar, this message translates to:
  /// **'{f}، {n} غير مقروءة'**
  String ntf_a11y_filter(String f, int n);

  /// No description provided for @ntf_muted.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك إشعارات من هذا النوع'**
  String get ntf_muted;

  /// No description provided for @ntf_push_unavailable.
  ///
  /// In ar, this message translates to:
  /// **'فعّل الإشعارات من إعدادات الجهاز'**
  String get ntf_push_unavailable;

  /// No description provided for @ntf_offline_action.
  ///
  /// In ar, this message translates to:
  /// **'هذا الإجراء يتطلب اتصالًا بالإنترنت'**
  String get ntf_offline_action;

  /// No description provided for @ntf_action_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ الإجراء. حاول مجددًا.'**
  String get ntf_action_failed;

  /// No description provided for @ntf_billing_agent_title.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك يديره المسؤول'**
  String get ntf_billing_agent_title;

  /// No description provided for @ntf_billing_agent_body.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من مسؤول مساحة العمل إدارة الاشتراك من موقع Wavadesk.'**
  String get ntf_billing_agent_body;

  /// No description provided for @profile_title.
  ///
  /// In ar, this message translates to:
  /// **'ملف العميل'**
  String get profile_title;

  /// No description provided for @profile_add_tag.
  ///
  /// In ar, this message translates to:
  /// **'+ وسم'**
  String get profile_add_tag;

  /// No description provided for @profile_vip.
  ///
  /// In ar, this message translates to:
  /// **'عميل مميز'**
  String get profile_vip;

  /// No description provided for @profile_blocked.
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get profile_blocked;

  /// No description provided for @profile_local_time.
  ///
  /// In ar, this message translates to:
  /// **'{time} بتوقيته'**
  String profile_local_time(String time);

  /// No description provided for @profile_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get profile_copied;

  /// No description provided for @profile_call.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get profile_call;

  /// No description provided for @profile_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get profile_whatsapp;

  /// No description provided for @profile_note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get profile_note;

  /// No description provided for @profile_block.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get profile_block;

  /// No description provided for @profile_unblock.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحظر'**
  String get profile_unblock;

  /// No description provided for @profile_stat_conversations.
  ///
  /// In ar, this message translates to:
  /// **'محادثات'**
  String get profile_stat_conversations;

  /// No description provided for @profile_stat_orders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات'**
  String get profile_stat_orders;

  /// No description provided for @profile_stat_rating.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get profile_stat_rating;

  /// No description provided for @profile_stat_first.
  ///
  /// In ar, this message translates to:
  /// **'أول تواصل'**
  String get profile_stat_first;

  /// No description provided for @profile_ai_summary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الذكاء الاصطناعي'**
  String get profile_ai_summary;

  /// No description provided for @profile_ai_disclaimer.
  ///
  /// In ar, this message translates to:
  /// **'قد يحتوي الملخص على أخطاء'**
  String get profile_ai_disclaimer;

  /// No description provided for @profile_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get profile_more;

  /// No description provided for @profile_notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الفريق'**
  String get profile_notes;

  /// No description provided for @profile_add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get profile_add;

  /// No description provided for @profile_all_notes.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الملاحظات ({n})'**
  String profile_all_notes(int n);

  /// No description provided for @profile_no_notes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بعد'**
  String get profile_no_notes;

  /// No description provided for @profile_first_note.
  ///
  /// In ar, this message translates to:
  /// **'أضف أول ملاحظة'**
  String get profile_first_note;

  /// No description provided for @profile_pin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت'**
  String get profile_pin;

  /// No description provided for @profile_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get profile_edit;

  /// No description provided for @profile_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get profile_delete;

  /// No description provided for @profile_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات'**
  String get profile_info;

  /// No description provided for @profile_phone.
  ///
  /// In ar, this message translates to:
  /// **'الجوال'**
  String get profile_phone;

  /// No description provided for @profile_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get profile_email;

  /// No description provided for @profile_city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get profile_city;

  /// No description provided for @profile_language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة المفضلة'**
  String get profile_language;

  /// No description provided for @profile_timezone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get profile_timezone;

  /// No description provided for @profile_added_by.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف بواسطة'**
  String get profile_added_by;

  /// No description provided for @profile_not_set.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get profile_not_set;

  /// No description provided for @profile_all_info.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل المعلومات'**
  String get profile_all_info;

  /// No description provided for @profile_channels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get profile_channels;

  /// No description provided for @profile_channel_count.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{لا محادثات} =1{محادثة واحدة} =2{محادثتان} few{{n} محادثات} other{{n} محادثة}}'**
  String profile_channel_count(int n);

  /// No description provided for @profile_unlink.
  ///
  /// In ar, this message translates to:
  /// **'فصل هذه الهوية'**
  String get profile_unlink;

  /// No description provided for @profile_merge.
  ///
  /// In ar, this message translates to:
  /// **'دمج مع عميل آخر'**
  String get profile_merge;

  /// No description provided for @profile_orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get profile_orders;

  /// No description provided for @profile_total_spent.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتريات: {sum} ر.س'**
  String profile_total_spent(String sum);

  /// No description provided for @profile_previous.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات السابقة'**
  String get profile_previous;

  /// No description provided for @profile_all_channels.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get profile_all_channels;

  /// No description provided for @profile_closed_by.
  ///
  /// In ar, this message translates to:
  /// **'{date} · أغلقها {name}'**
  String profile_closed_by(String date, String name);

  /// No description provided for @profile_ai_replied.
  ///
  /// In ar, this message translates to:
  /// **'{date} · ردّ الذكاء الاصطناعي'**
  String profile_ai_replied(String date);

  /// No description provided for @profile_open_now.
  ///
  /// In ar, this message translates to:
  /// **'{date} · مفتوحة الآن'**
  String profile_open_now(String date);

  /// No description provided for @profile_load_more.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get profile_load_more;

  /// No description provided for @profile_first_conv.
  ///
  /// In ar, this message translates to:
  /// **'هذه أول محادثة مع العميل'**
  String get profile_first_conv;

  /// No description provided for @profile_block_cta.
  ///
  /// In ar, this message translates to:
  /// **'حظر العميل'**
  String get profile_block_cta;

  /// No description provided for @profile_block_hint.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك رسائل هذا العميل بعد الحظر.'**
  String get profile_block_hint;

  /// No description provided for @profile_erase.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات العميل'**
  String get profile_erase;

  /// No description provided for @profile_visitor.
  ///
  /// In ar, this message translates to:
  /// **'زائر #{id}'**
  String profile_visitor(String id);

  /// No description provided for @profile_add_details.
  ///
  /// In ar, this message translates to:
  /// **'أضف بيانات العميل'**
  String get profile_add_details;

  /// No description provided for @profile_offline.
  ///
  /// In ar, this message translates to:
  /// **'تعرض آخر نسخة محفوظة'**
  String get profile_offline;

  /// No description provided for @profile_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل ملف العميل'**
  String get profile_load_error;

  /// No description provided for @profile_section_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل {section}'**
  String profile_section_error(String section);

  /// No description provided for @profile_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get profile_retry;

  /// No description provided for @profile_open_page.
  ///
  /// In ar, this message translates to:
  /// **'فتح كصفحة'**
  String get profile_open_page;

  /// No description provided for @profile_dialog_label.
  ///
  /// In ar, this message translates to:
  /// **'ملف العميل، {name}'**
  String profile_dialog_label(String name);

  /// No description provided for @profile_unpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get profile_unpin;

  /// No description provided for @profile_regenerate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إنشاء الملخص'**
  String get profile_regenerate;

  /// No description provided for @profile_note_a11y.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة من {author}، {date}: {text}'**
  String profile_note_a11y(String author, String date, String text);

  /// No description provided for @profile_delete_note_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة؟'**
  String get profile_delete_note_title;

  /// No description provided for @profile_delete_note_body.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف هذه الملاحظة لجميع أعضاء الفريق.'**
  String get profile_delete_note_body;

  /// No description provided for @profile_action_call_a11y.
  ///
  /// In ar, this message translates to:
  /// **'اتصال بـ{name}'**
  String profile_action_call_a11y(String name);

  /// No description provided for @profile_action_whatsapp_a11y.
  ///
  /// In ar, this message translates to:
  /// **'واتساب {name}'**
  String profile_action_whatsapp_a11y(String name);

  /// No description provided for @profile_action_note_a11y.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة عن {name}'**
  String profile_action_note_a11y(String name);

  /// No description provided for @profile_action_block_a11y.
  ///
  /// In ar, this message translates to:
  /// **'حظر {name}'**
  String profile_action_block_a11y(String name);

  /// No description provided for @profile_action_unblock_a11y.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء حظر {name}'**
  String profile_action_unblock_a11y(String name);

  /// No description provided for @profile_disabled_no_phone.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح، لا يوجد رقم'**
  String get profile_disabled_no_phone;

  /// No description provided for @profile_stats_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{conversations} محادثات، {orders} {ordersLabel}، أول تواصل {first}'**
  String profile_stats_a11y(
    int conversations,
    String orders,
    String ordersLabel,
    String first,
  );

  /// No description provided for @profile_order_items.
  ///
  /// In ar, this message translates to:
  /// **'{date} · {n, plural, =1{منتج واحد} =2{منتجان} few{{n} منتجات} other{{n} منتجًا}}'**
  String profile_order_items(String date, int n);

  /// No description provided for @profile_amount.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ر.س'**
  String profile_amount(String amount);

  /// No description provided for @profile_order_processing.
  ///
  /// In ar, this message translates to:
  /// **'قيد التجهيز'**
  String get profile_order_processing;

  /// No description provided for @profile_order_shipped.
  ///
  /// In ar, this message translates to:
  /// **'تم الشحن'**
  String get profile_order_shipped;

  /// No description provided for @profile_order_delivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get profile_order_delivered;

  /// No description provided for @profile_order_cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get profile_order_cancelled;

  /// No description provided for @profile_view_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get profile_view_all;

  /// No description provided for @profile_no_order_link.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رابط لهذا الطلب'**
  String get profile_no_order_link;

  /// No description provided for @profile_lang_ar.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get profile_lang_ar;

  /// No description provided for @profile_lang_en.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get profile_lang_en;

  /// No description provided for @profile_tz_value.
  ///
  /// In ar, this message translates to:
  /// **'{tz} · {time}'**
  String profile_tz_value(String tz, String time);

  /// No description provided for @profile_attr_yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get profile_attr_yes;

  /// No description provided for @profile_attr_no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get profile_attr_no;

  /// No description provided for @profile_unlinked.
  ///
  /// In ar, this message translates to:
  /// **'تم فصل الهوية'**
  String get profile_unlinked;

  /// No description provided for @profile_filter_channel.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب القناة'**
  String get profile_filter_channel;

  /// No description provided for @profile_merged.
  ///
  /// In ar, this message translates to:
  /// **'تم دمج هذا العميل'**
  String get profile_merged;

  /// No description provided for @profile_more_actions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات أخرى'**
  String get profile_more_actions;

  /// No description provided for @profile_edit_contact.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات العميل'**
  String get profile_edit_contact;

  /// No description provided for @edit_title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات العميل'**
  String get edit_title;

  /// No description provided for @edit_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get edit_save;

  /// No description provided for @edit_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغييرات'**
  String get edit_saved;

  /// No description provided for @edit_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التغييرات. حاول مجددًا.'**
  String get edit_failed;

  /// No description provided for @edit_discard_title.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التغييرات؟'**
  String get edit_discard_title;

  /// No description provided for @edit_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحفظ تعديلاتك بعد. إذا خرجت الآن ستفقدها.'**
  String get edit_discard_body;

  /// No description provided for @edit_discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get edit_discard;

  /// No description provided for @edit_keep.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get edit_keep;

  /// No description provided for @edit_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get edit_name;

  /// No description provided for @edit_phone.
  ///
  /// In ar, this message translates to:
  /// **'الجوال'**
  String get edit_phone;

  /// No description provided for @edit_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get edit_email;

  /// No description provided for @edit_city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get edit_city;

  /// No description provided for @edit_language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة المفضلة'**
  String get edit_language;

  /// No description provided for @edit_not_set.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get edit_not_set;

  /// No description provided for @edit_phone_invalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال غير صحيح'**
  String get edit_phone_invalid;

  /// No description provided for @edit_email_invalid.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد غير صحيحة'**
  String get edit_email_invalid;

  /// No description provided for @tags_title.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get tags_title;

  /// No description provided for @tags_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث أو أنشئ وسمًا'**
  String get tags_search;

  /// No description provided for @tags_create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء «{q}»'**
  String tags_create(String q);

  /// No description provided for @tags_done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get tags_done;

  /// No description provided for @tags_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الوسوم. حاول مجددًا.'**
  String get tags_failed;

  /// No description provided for @tags_remove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الوسم'**
  String get tags_remove;

  /// No description provided for @note_new.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get note_new;

  /// No description provided for @note_edit_title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get note_edit_title;

  /// No description provided for @note_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما يجب أن يعرفه فريقك عن هذا العميل…'**
  String get note_placeholder;

  /// No description provided for @note_pin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت الملاحظة'**
  String get note_pin;

  /// No description provided for @note_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get note_save;

  /// No description provided for @note_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get note_cancel;

  /// No description provided for @note_saved.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت الملاحظة'**
  String get note_saved;

  /// No description provided for @note_updated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الملاحظة'**
  String get note_updated;

  /// No description provided for @note_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الملاحظة. حاول مجددًا.'**
  String get note_failed;

  /// No description provided for @call_phone.
  ///
  /// In ar, this message translates to:
  /// **'اتصال هاتفي'**
  String get call_phone;

  /// No description provided for @call_whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'اتصال واتساب'**
  String get call_whatsapp;

  /// No description provided for @call_copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرقم'**
  String get call_copy;

  /// No description provided for @call_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get call_cancel;

  /// No description provided for @call_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get call_copied;

  /// No description provided for @call_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح تطبيق الاتصال'**
  String get call_failed;

  /// No description provided for @block_title.
  ///
  /// In ar, this message translates to:
  /// **'حظر {name}؟'**
  String block_title(String name);

  /// No description provided for @block_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك رسائله على أي قناة، وستُغلق محادثاته المفتوحة. يمكنك إلغاء الحظر لاحقًا.'**
  String get block_body;

  /// No description provided for @block_reason_label.
  ///
  /// In ar, this message translates to:
  /// **'سبب الحظر (اختياري)'**
  String get block_reason_label;

  /// No description provided for @block_reason_spam.
  ///
  /// In ar, this message translates to:
  /// **'إزعاج'**
  String get block_reason_spam;

  /// No description provided for @block_reason_fraud.
  ///
  /// In ar, this message translates to:
  /// **'احتيال'**
  String get block_reason_fraud;

  /// No description provided for @block_reason_abuse.
  ///
  /// In ar, this message translates to:
  /// **'لغة مسيئة'**
  String get block_reason_abuse;

  /// No description provided for @block_reason_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get block_reason_other;

  /// No description provided for @block_confirm.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get block_confirm;

  /// No description provided for @block_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get block_cancel;

  /// No description provided for @block_done.
  ///
  /// In ar, this message translates to:
  /// **'تم حظر العميل'**
  String get block_done;

  /// No description provided for @block_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حظر العميل. حاول مجددًا.'**
  String get block_failed;

  /// No description provided for @block_unnamed.
  ///
  /// In ar, this message translates to:
  /// **'هذا العميل'**
  String get block_unnamed;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @merge_title.
  ///
  /// In ar, this message translates to:
  /// **'دمج مع عميل آخر'**
  String get merge_title;

  /// No description provided for @merge_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الجوال أو البريد'**
  String get merge_search;

  /// No description provided for @merge_no_results.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء مطابقون'**
  String get merge_no_results;

  /// No description provided for @merge_unnamed.
  ///
  /// In ar, this message translates to:
  /// **'عميل بلا اسم'**
  String get merge_unnamed;

  /// No description provided for @merge_into_label.
  ///
  /// In ar, this message translates to:
  /// **'سيُدمج في'**
  String get merge_into_label;

  /// No description provided for @merge_change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get merge_change;

  /// No description provided for @merge_no_conflicts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قيم متعارضة — ستُنقل كل المحادثات والملاحظات إلى العميل المختار.'**
  String get merge_no_conflicts;

  /// No description provided for @merge_choose_values.
  ///
  /// In ar, this message translates to:
  /// **'اختر القيم التي تبقى'**
  String get merge_choose_values;

  /// No description provided for @merge_field_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get merge_field_name;

  /// No description provided for @merge_field_phone.
  ///
  /// In ar, this message translates to:
  /// **'الجوال'**
  String get merge_field_phone;

  /// No description provided for @merge_field_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get merge_field_email;

  /// No description provided for @merge_field_city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get merge_field_city;

  /// No description provided for @merge_this_contact.
  ///
  /// In ar, this message translates to:
  /// **'هذا العميل'**
  String get merge_this_contact;

  /// No description provided for @merge_other_contact.
  ///
  /// In ar, this message translates to:
  /// **'العميل الآخر'**
  String get merge_other_contact;

  /// No description provided for @merge_action.
  ///
  /// In ar, this message translates to:
  /// **'دمج'**
  String get merge_action;

  /// No description provided for @merge_confirm_title.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن الدمج'**
  String get merge_confirm_title;

  /// No description provided for @merge_confirm_body.
  ///
  /// In ar, this message translates to:
  /// **'ستُنقل المحادثات والملاحظات إلى العميل المختار ويُحذف هذا الملف.'**
  String get merge_confirm_body;

  /// No description provided for @merge_done.
  ///
  /// In ar, this message translates to:
  /// **'تم دمج العميل'**
  String get merge_done;

  /// No description provided for @merge_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الدمج. حاول مجددًا.'**
  String get merge_failed;

  /// No description provided for @erase_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات العميل نهائيًا؟'**
  String get erase_title;

  /// No description provided for @erase_body.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف كل محادثات العميل وملاحظاته وبياناته ولا يمكن استرجاعها.'**
  String get erase_body;

  /// No description provided for @erase_type_digits.
  ///
  /// In ar, this message translates to:
  /// **'اكتب آخر 4 أرقام من جوال العميل للتأكيد'**
  String get erase_type_digits;

  /// No description provided for @erase_type_word.
  ///
  /// In ar, this message translates to:
  /// **'اكتب «{word}» للتأكيد'**
  String erase_type_word(String word);

  /// No description provided for @erase_word.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get erase_word;

  /// No description provided for @erase_confirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get erase_confirm;

  /// No description provided for @erase_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get erase_cancel;

  /// No description provided for @erase_done.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف بيانات العميل'**
  String get erase_done;

  /// No description provided for @erase_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حذف البيانات. حاول مجددًا.'**
  String get erase_failed;

  /// No description provided for @search_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عميل، رسالة، أو رقم طلب'**
  String get search_placeholder;

  /// No description provided for @search_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get search_cancel;

  /// No description provided for @search_scope_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get search_scope_all;

  /// No description provided for @search_scope_contacts.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get search_scope_contacts;

  /// No description provided for @search_scope_messages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get search_scope_messages;

  /// No description provided for @search_scope_kb.
  ///
  /// In ar, this message translates to:
  /// **'المعرفة'**
  String get search_scope_kb;

  /// No description provided for @search_scope_conversations.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get search_scope_conversations;

  /// No description provided for @search_filters.
  ///
  /// In ar, this message translates to:
  /// **'فلاتر'**
  String get search_filters;

  /// No description provided for @search_section_contacts.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get search_section_contacts;

  /// No description provided for @search_section_messages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get search_section_messages;

  /// No description provided for @search_section_kb.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة المعرفة'**
  String get search_section_kb;

  /// No description provided for @search_section_conversations.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get search_section_conversations;

  /// No description provided for @search_see_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل ({n})'**
  String search_see_all(int n);

  /// No description provided for @search_best_match.
  ///
  /// In ar, this message translates to:
  /// **'أفضل نتيجة'**
  String get search_best_match;

  /// No description provided for @search_open_chat.
  ///
  /// In ar, this message translates to:
  /// **'فتح المحادثة'**
  String get search_open_chat;

  /// No description provided for @search_profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف'**
  String get search_profile;

  /// No description provided for @search_open_badge.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get search_open_badge;

  /// No description provided for @search_more_in_conv.
  ///
  /// In ar, this message translates to:
  /// **'+{n} نتائج أخرى في هذه المحادثة'**
  String search_more_in_conv(int n);

  /// No description provided for @search_kb_usage.
  ///
  /// In ar, this message translates to:
  /// **'استخدمه الذكاء {n} مرة هذا الشهر'**
  String search_kb_usage(int n);

  /// No description provided for @search_insert_reply.
  ///
  /// In ar, this message translates to:
  /// **'إدراج في الرد'**
  String get search_insert_reply;

  /// No description provided for @search_you.
  ///
  /// In ar, this message translates to:
  /// **'أنت:'**
  String get search_you;

  /// No description provided for @search_note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة:'**
  String get search_note;

  /// No description provided for @search_order.
  ///
  /// In ar, this message translates to:
  /// **'طلب {n}'**
  String search_order(String n);

  /// No description provided for @search_tag.
  ///
  /// In ar, this message translates to:
  /// **'وسم: {tag}'**
  String search_tag(String tag);

  /// No description provided for @search_recent.
  ///
  /// In ar, this message translates to:
  /// **'عمليات البحث الأخيرة'**
  String get search_recent;

  /// No description provided for @search_clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get search_clear;

  /// No description provided for @search_suggestions.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات'**
  String get search_suggestions;

  /// No description provided for @search_recent_contacts.
  ///
  /// In ar, this message translates to:
  /// **'آخر من تواصلت معهم'**
  String get search_recent_contacts;

  /// No description provided for @search_tip.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم، رقم الجوال، رقم الطلب، أو أي كلمة في المحادثة'**
  String get search_tip;

  /// No description provided for @search_no_results.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج لـ «{q}»'**
  String search_no_results(String q);

  /// No description provided for @search_no_results_body.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة أخرى أو تحقّق من الإملاء'**
  String get search_no_results_body;

  /// No description provided for @search_clear_filters.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفلاتر'**
  String get search_clear_filters;

  /// No description provided for @search_in_all.
  ///
  /// In ar, this message translates to:
  /// **'البحث في الكل'**
  String get search_in_all;

  /// No description provided for @search_did_you_mean.
  ///
  /// In ar, this message translates to:
  /// **'هل تقصد: {s}؟'**
  String search_did_you_mean(String s);

  /// No description provided for @search_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث'**
  String get search_error;

  /// No description provided for @search_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get search_retry;

  /// No description provided for @search_offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل — نتائج من البيانات المحفوظة فقط'**
  String get search_offline;

  /// No description provided for @search_local.
  ///
  /// In ar, this message translates to:
  /// **'(محليًا)'**
  String get search_local;

  /// No description provided for @search_filter_sender.
  ///
  /// In ar, this message translates to:
  /// **'المرسل'**
  String get search_filter_sender;

  /// No description provided for @search_filter_contains.
  ///
  /// In ar, this message translates to:
  /// **'يحتوي على'**
  String get search_filter_contains;

  /// No description provided for @search_filter_attachments.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات'**
  String get search_filter_attachments;

  /// No description provided for @search_filter_images.
  ///
  /// In ar, this message translates to:
  /// **'صور'**
  String get search_filter_images;

  /// No description provided for @search_filter_voice.
  ///
  /// In ar, this message translates to:
  /// **'رسائل صوتية'**
  String get search_filter_voice;

  /// No description provided for @search_show_results.
  ///
  /// In ar, this message translates to:
  /// **'عرض النتائج ({n})'**
  String search_show_results(int n);

  /// No description provided for @search_field_label.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search_field_label;

  /// No description provided for @search_filters_n.
  ///
  /// In ar, this message translates to:
  /// **'فلاتر · {n}'**
  String search_filters_n(int n);

  /// No description provided for @search_filter_channel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get search_filter_channel;

  /// No description provided for @search_filter_date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get search_filter_date;

  /// No description provided for @search_filter_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة المحادثة'**
  String get search_filter_status;

  /// No description provided for @search_filter_assignee.
  ///
  /// In ar, this message translates to:
  /// **'المسؤول'**
  String get search_filter_assignee;

  /// No description provided for @search_date_any.
  ///
  /// In ar, this message translates to:
  /// **'أي وقت'**
  String get search_date_any;

  /// No description provided for @search_date_today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get search_date_today;

  /// No description provided for @search_date_7.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get search_date_7;

  /// No description provided for @search_date_30.
  ///
  /// In ar, this message translates to:
  /// **'30 يومًا'**
  String get search_date_30;

  /// No description provided for @search_date_custom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get search_date_custom;

  /// No description provided for @search_sender_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get search_sender_all;

  /// No description provided for @search_sender_contact.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get search_sender_contact;

  /// No description provided for @search_sender_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get search_sender_me;

  /// No description provided for @search_sender_colleagues.
  ///
  /// In ar, this message translates to:
  /// **'الزملاء'**
  String get search_sender_colleagues;

  /// No description provided for @search_sender_ai.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي'**
  String get search_sender_ai;

  /// No description provided for @search_sender_notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات داخلية'**
  String get search_sender_notes;

  /// No description provided for @search_status_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get search_status_all;

  /// No description provided for @search_status_open.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get search_status_open;

  /// No description provided for @search_status_resolved.
  ///
  /// In ar, this message translates to:
  /// **'محلولة'**
  String get search_status_resolved;

  /// No description provided for @search_assignee_all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get search_assignee_all;

  /// No description provided for @search_assignee_me.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get search_assignee_me;

  /// No description provided for @search_assignee_colleague.
  ///
  /// In ar, this message translates to:
  /// **'زميل'**
  String get search_assignee_colleague;

  /// No description provided for @search_sugg_unread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروءة'**
  String get search_sugg_unread;

  /// No description provided for @search_sugg_awaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الرد'**
  String get search_sugg_awaiting;

  /// No description provided for @search_sugg_vip.
  ///
  /// In ar, this message translates to:
  /// **'وسم: VIP'**
  String get search_sugg_vip;

  /// No description provided for @search_sugg_orders_today.
  ///
  /// In ar, this message translates to:
  /// **'طلبات اليوم'**
  String get search_sugg_orders_today;

  /// No description provided for @search_recent_remove.
  ///
  /// In ar, this message translates to:
  /// **'حذف {q} من السجل'**
  String search_recent_remove(String q);

  /// No description provided for @search_recents_cleared.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح سجل البحث'**
  String get search_recents_cleared;

  /// No description provided for @search_results_announce.
  ///
  /// In ar, this message translates to:
  /// **'{n} نتائج: {parts}'**
  String search_results_announce(int n, String parts);

  /// No description provided for @search_announce_contacts.
  ///
  /// In ar, this message translates to:
  /// **'{n} عميل'**
  String search_announce_contacts(int n);

  /// No description provided for @search_announce_messages.
  ///
  /// In ar, this message translates to:
  /// **'{n} رسائل'**
  String search_announce_messages(int n);

  /// No description provided for @search_announce_kb.
  ///
  /// In ar, this message translates to:
  /// **'{n} مقال'**
  String search_announce_kb(int n);

  /// No description provided for @search_announce_conversations.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات'**
  String search_announce_conversations(int n);

  /// No description provided for @search_a11y_message.
  ///
  /// In ar, this message translates to:
  /// **'رسالة من {name}، {time}: {text}'**
  String search_a11y_message(String name, String time, String text);

  /// No description provided for @search_last_chat.
  ///
  /// In ar, this message translates to:
  /// **'فتح المحادثة الأخيرة'**
  String get search_last_chat;

  /// No description provided for @search_new_chat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get search_new_chat;

  /// No description provided for @search_copy_number.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرقم'**
  String get search_copy_number;

  /// No description provided for @search_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرقم'**
  String get search_copied;

  /// No description provided for @search_call.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get search_call;

  /// No description provided for @search_section_teammates.
  ///
  /// In ar, this message translates to:
  /// **'الزملاء'**
  String get search_section_teammates;

  /// No description provided for @search_no_chat_yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثة سابقة مع هذا العميل'**
  String get search_no_chat_yet;

  /// No description provided for @search_inserted.
  ///
  /// In ar, this message translates to:
  /// **'تم إدراج الإجابة في الرد'**
  String get search_inserted;

  /// No description provided for @search_in_conv_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في هذه المحادثة'**
  String get search_in_conv_placeholder;

  /// No description provided for @search_in_conv_count.
  ///
  /// In ar, this message translates to:
  /// **'{i} من {n}'**
  String search_in_conv_count(int i, int n);

  /// No description provided for @search_in_conv_action.
  ///
  /// In ar, this message translates to:
  /// **'بحث في المحادثة'**
  String get search_in_conv_action;

  /// No description provided for @search_in_conv_prev.
  ///
  /// In ar, this message translates to:
  /// **'المطابقة السابقة'**
  String get search_in_conv_prev;

  /// No description provided for @search_in_conv_next.
  ///
  /// In ar, this message translates to:
  /// **'المطابقة التالية'**
  String get search_in_conv_next;

  /// No description provided for @search_in_conv_close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق البحث'**
  String get search_in_conv_close;

  /// No description provided for @startup_unavailable_title.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال حاليًا'**
  String get startup_unavailable_title;

  /// No description provided for @startup_unavailable_body.
  ///
  /// In ar, this message translates to:
  /// **'لم يتمكّن Wavadesk من الوصول إلى الخوادم. تأكّد من أنك تستخدم أحدث إصدار من التطبيق، ثم أعد المحاولة.'**
  String get startup_unavailable_body;

  /// No description provided for @startup_unavailable_help.
  ///
  /// In ar, this message translates to:
  /// **'ما زالت المشكلة قائمة؟ تواصل معنا عبر support@wavadesk.com'**
  String get startup_unavailable_help;

  /// No description provided for @startup_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get startup_retry;

  /// No description provided for @startup_contact_support.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع الدعم'**
  String get startup_contact_support;

  /// No description provided for @startup_dev_hint.
  ///
  /// In ar, this message translates to:
  /// **'للمطوّر: عنوان الـ API أو المفتاح غير موجود. شغّل التطبيق مع --dart-define-from-file=dart_defines/<env>.json أو املأ assets/config/api.json.'**
  String get startup_dev_hint;

  /// No description provided for @wa_title.
  ///
  /// In ar, this message translates to:
  /// **'واتساب الخاص بك'**
  String get wa_title;

  /// No description provided for @wa_refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get wa_refresh;

  /// No description provided for @wa_log.
  ///
  /// In ar, this message translates to:
  /// **'سجل الاتصال'**
  String get wa_log;

  /// No description provided for @wa_help.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get wa_help;

  /// No description provided for @wa_connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get wa_connected;

  /// No description provided for @wa_connecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال'**
  String get wa_connecting;

  /// No description provided for @wa_syncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة'**
  String get wa_syncing;

  /// No description provided for @wa_phone_offline.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف غير متصل'**
  String get wa_phone_offline;

  /// No description provided for @wa_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get wa_disconnected;

  /// No description provided for @wa_restricted.
  ///
  /// In ar, this message translates to:
  /// **'مقيّد'**
  String get wa_restricted;

  /// No description provided for @wa_pending.
  ///
  /// In ar, this message translates to:
  /// **'غير مربوط'**
  String get wa_pending;

  /// No description provided for @wa_msgs_today.
  ///
  /// In ar, this message translates to:
  /// **'رسالة اليوم'**
  String get wa_msgs_today;

  /// No description provided for @wa_quality.
  ///
  /// In ar, this message translates to:
  /// **'جودة الرقم'**
  String get wa_quality;

  /// No description provided for @wa_q_high.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get wa_q_high;

  /// No description provided for @wa_q_med.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get wa_q_med;

  /// No description provided for @wa_q_low.
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get wa_q_low;

  /// No description provided for @wa_stable.
  ///
  /// In ar, this message translates to:
  /// **'مستقرة'**
  String get wa_stable;

  /// No description provided for @wa_unstable.
  ///
  /// In ar, this message translates to:
  /// **'غير مستقرة'**
  String get wa_unstable;

  /// No description provided for @wa_linked_since.
  ///
  /// In ar, this message translates to:
  /// **'مرتبط منذ'**
  String get wa_linked_since;

  /// No description provided for @wa_days.
  ///
  /// In ar, this message translates to:
  /// **'{n} يومًا'**
  String wa_days(String n);

  /// No description provided for @wa_alert_disc_title.
  ///
  /// In ar, this message translates to:
  /// **'انقطع الاتصال منذ {t}'**
  String wa_alert_disc_title(String t);

  /// No description provided for @wa_alert_disc_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصل رسائل العملاء حتى تعيد الربط'**
  String get wa_alert_disc_body;

  /// No description provided for @wa_reconnect.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الربط'**
  String get wa_reconnect;

  /// No description provided for @wa_alert_phone_title.
  ///
  /// In ar, this message translates to:
  /// **'هاتفك غير متصل بالإنترنت'**
  String get wa_alert_phone_title;

  /// No description provided for @wa_alert_phone_body.
  ///
  /// In ar, this message translates to:
  /// **'تأكد أن واتساب يعمل على الهاتف المرتبط'**
  String get wa_alert_phone_body;

  /// No description provided for @wa_check_again.
  ///
  /// In ar, this message translates to:
  /// **'تحقق مجددًا'**
  String get wa_check_again;

  /// No description provided for @wa_alert_quality.
  ///
  /// In ar, this message translates to:
  /// **'جودة الرقم منخفضة'**
  String get wa_alert_quality;

  /// No description provided for @wa_alert_quality_body.
  ///
  /// In ar, this message translates to:
  /// **'قلّل الرسائل الجماعية وتجنّب المحتوى المكرر'**
  String get wa_alert_quality_body;

  /// No description provided for @wa_details.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get wa_details;

  /// No description provided for @wa_alert_limit.
  ///
  /// In ar, this message translates to:
  /// **'اقتربت من حد المحادثات اليومي ({u}/{l})'**
  String wa_alert_limit(String l, String u);

  /// No description provided for @wa_alert_update.
  ///
  /// In ar, this message translates to:
  /// **'حدّث تطبيق واتساب على هاتفك'**
  String get wa_alert_update;

  /// No description provided for @wa_alert_pending.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط واتساب بعد'**
  String get wa_alert_pending;

  /// No description provided for @wa_alert_pending_body.
  ///
  /// In ar, this message translates to:
  /// **'اربط رقمك لتبدأ باستقبال رسائل العملاء'**
  String get wa_alert_pending_body;

  /// No description provided for @wa_connect.
  ///
  /// In ar, this message translates to:
  /// **'اربط واتساب'**
  String get wa_connect;

  /// No description provided for @wa_auto.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل التلقائية'**
  String get wa_auto;

  /// No description provided for @wa_welcome.
  ///
  /// In ar, this message translates to:
  /// **'رسالة الترحيب'**
  String get wa_welcome;

  /// No description provided for @wa_away.
  ///
  /// In ar, this message translates to:
  /// **'رسالة خارج الدوام'**
  String get wa_away;

  /// No description provided for @wa_away_ai.
  ///
  /// In ar, this message translates to:
  /// **'يتولاها الذكاء الاصطناعي حاليًا'**
  String get wa_away_ai;

  /// No description provided for @wa_quick.
  ///
  /// In ar, this message translates to:
  /// **'الردود السريعة'**
  String get wa_quick;

  /// No description provided for @wa_welcome_delay.
  ///
  /// In ar, this message translates to:
  /// **'مهلة رسالة الترحيب'**
  String get wa_welcome_delay;

  /// No description provided for @wa_now.
  ///
  /// In ar, this message translates to:
  /// **'فورًا'**
  String get wa_now;

  /// No description provided for @wa_welcome_off.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف رسالة الترحيب'**
  String get wa_welcome_off;

  /// No description provided for @wa_undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get wa_undo;

  /// No description provided for @wa_templates.
  ///
  /// In ar, this message translates to:
  /// **'القوالب المعتمدة'**
  String get wa_templates;

  /// No description provided for @wa_tpl_marketing.
  ///
  /// In ar, this message translates to:
  /// **'تسويق'**
  String get wa_tpl_marketing;

  /// No description provided for @wa_tpl_utility.
  ///
  /// In ar, this message translates to:
  /// **'خدمة'**
  String get wa_tpl_utility;

  /// No description provided for @wa_tpl_auth.
  ///
  /// In ar, this message translates to:
  /// **'مصادقة'**
  String get wa_tpl_auth;

  /// No description provided for @wa_tpl_approved.
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get wa_tpl_approved;

  /// No description provided for @wa_tpl_pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get wa_tpl_pending;

  /// No description provided for @wa_tpl_rejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get wa_tpl_rejected;

  /// No description provided for @wa_tpl_manage_web.
  ///
  /// In ar, this message translates to:
  /// **'إدارة القوالب على الويب'**
  String get wa_tpl_manage_web;

  /// No description provided for @wa_numbers.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام'**
  String get wa_numbers;

  /// No description provided for @wa_add_second.
  ///
  /// In ar, this message translates to:
  /// **'أضف رقمًا ثانيًا'**
  String get wa_add_second;

  /// No description provided for @wa_business_only.
  ///
  /// In ar, this message translates to:
  /// **'متاح في خطة Business'**
  String get wa_business_only;

  /// No description provided for @wa_upgrade.
  ///
  /// In ar, this message translates to:
  /// **'ترقية'**
  String get wa_upgrade;

  /// No description provided for @wa_add_number.
  ///
  /// In ar, this message translates to:
  /// **'أضف رقمًا'**
  String get wa_add_number;

  /// No description provided for @wa_watch.
  ///
  /// In ar, this message translates to:
  /// **'شاهد: كيف تربط واتساب'**
  String get wa_watch;

  /// No description provided for @wa_watch_sub.
  ///
  /// In ar, this message translates to:
  /// **'شرح بالفيديو · {d}'**
  String wa_watch_sub(String d);

  /// No description provided for @wa_advanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get wa_advanced;

  /// No description provided for @wa_read_receipts.
  ///
  /// In ar, this message translates to:
  /// **'إيصالات القراءة للعميل'**
  String get wa_read_receipts;

  /// No description provided for @wa_mark_read_open.
  ///
  /// In ar, this message translates to:
  /// **'تمييز الرسائل كمقروءة عند الفتح'**
  String get wa_mark_read_open;

  /// No description provided for @wa_auto_transcribe.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل الصوتية: تحويل لنص تلقائيًا'**
  String get wa_auto_transcribe;

  /// No description provided for @wa_ignore_groups.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل رسائل المجموعات'**
  String get wa_ignore_groups;

  /// No description provided for @wa_blocked.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام المحظورة'**
  String get wa_blocked;

  /// No description provided for @wa_hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل'**
  String get wa_hours;

  /// No description provided for @wa_disconnect.
  ///
  /// In ar, this message translates to:
  /// **'فصل الرقم'**
  String get wa_disconnect;

  /// No description provided for @wa_disc_title.
  ///
  /// In ar, this message translates to:
  /// **'فصل رقم واتساب؟'**
  String get wa_disc_title;

  /// No description provided for @wa_disc_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تصل رسائل العملاء إلى Wavadesk، وسيتوقف الذكاء الاصطناعي عن الرد. ستبقى المحادثات السابقة محفوظة.'**
  String get wa_disc_body;

  /// No description provided for @wa_disc_open.
  ///
  /// In ar, this message translates to:
  /// **'{n} محادثات مفتوحة ستتوقف'**
  String wa_disc_open(String n);

  /// No description provided for @wa_disc_confirm_label.
  ///
  /// In ar, this message translates to:
  /// **'اكتب آخر 4 أرقام من الرقم للتأكيد'**
  String get wa_disc_confirm_label;

  /// No description provided for @wa_disc_done.
  ///
  /// In ar, this message translates to:
  /// **'تم فصل الرقم'**
  String get wa_disc_done;

  /// No description provided for @wa_connect_title.
  ///
  /// In ar, this message translates to:
  /// **'ربط واتساب'**
  String get wa_connect_title;

  /// No description provided for @wa_step.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {i} من {n}'**
  String wa_step(String i, String n);

  /// No description provided for @wa_by_phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get wa_by_phone;

  /// No description provided for @wa_by_qr.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR'**
  String get wa_by_qr;

  /// No description provided for @wa_get_code.
  ///
  /// In ar, this message translates to:
  /// **'احصل على الرمز'**
  String get wa_get_code;

  /// No description provided for @wa_copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get wa_copy;

  /// No description provided for @wa_expires_in.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي خلال {t}'**
  String wa_expires_in(String t);

  /// No description provided for @wa_steps_pair.
  ///
  /// In ar, this message translates to:
  /// **'افتح واتساب ← الإعدادات ← الأجهزة المرتبطة ← ربط جهاز ← الربط برقم الهاتف بدلًا من ذلك ← أدخل الرمز'**
  String get wa_steps_pair;

  /// No description provided for @wa_open_app.
  ///
  /// In ar, this message translates to:
  /// **'فتح واتساب'**
  String get wa_open_app;

  /// No description provided for @wa_linked_ok.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط واتساب بنجاح'**
  String get wa_linked_ok;

  /// No description provided for @wa_syncing_recent.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ مزامنة المحادثات الأخيرة…'**
  String get wa_syncing_recent;

  /// No description provided for @wa_back.
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get wa_back;

  /// No description provided for @wa_back_online.
  ///
  /// In ar, this message translates to:
  /// **'عاد الاتصال · لم تُفقد أي رسالة'**
  String get wa_back_online;

  /// No description provided for @wa_code_expired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز'**
  String get wa_code_expired;

  /// No description provided for @wa_new_code.
  ///
  /// In ar, this message translates to:
  /// **'رمز جديد'**
  String get wa_new_code;

  /// No description provided for @wa_number_taken.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم مرتبط بمساحة عمل أخرى'**
  String get wa_number_taken;

  /// No description provided for @wa_watch_video.
  ///
  /// In ar, this message translates to:
  /// **'شاهد الشرح بالفيديو'**
  String get wa_watch_video;

  /// No description provided for @wa_welcome_when.
  ///
  /// In ar, this message translates to:
  /// **'متى تُرسل؟'**
  String get wa_welcome_when;

  /// No description provided for @wa_trigger_first.
  ///
  /// In ar, this message translates to:
  /// **'أول رسالة من عميل جديد'**
  String get wa_trigger_first;

  /// No description provided for @wa_trigger_new.
  ///
  /// In ar, this message translates to:
  /// **'كل محادثة جديدة'**
  String get wa_trigger_new;

  /// No description provided for @wa_trigger_24h.
  ///
  /// In ar, this message translates to:
  /// **'بعد غياب 24 ساعة'**
  String get wa_trigger_24h;

  /// No description provided for @wa_buttons.
  ///
  /// In ar, this message translates to:
  /// **'أزرار سريعة'**
  String get wa_buttons;

  /// No description provided for @wa_ai_after_welcome.
  ///
  /// In ar, this message translates to:
  /// **'سيرد الذكاء الاصطناعي بعد رسالة الترحيب مباشرة'**
  String get wa_ai_after_welcome;

  /// No description provided for @wa_away_outside.
  ///
  /// In ar, this message translates to:
  /// **'خارج ساعات العمل'**
  String get wa_away_outside;

  /// No description provided for @wa_away_team.
  ///
  /// In ar, this message translates to:
  /// **'عندما يكون كل الفريق غير متاح'**
  String get wa_away_team;

  /// No description provided for @wa_away_cooldown.
  ///
  /// In ar, this message translates to:
  /// **'مرة كل {n} ساعات لنفس العميل'**
  String wa_away_cooldown(String n);

  /// No description provided for @wa_away_ai_banner.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي يرد خارج الدوام — عدّل ذلك من إعدادات الذكاء'**
  String get wa_away_ai_banner;

  /// No description provided for @wa_qr_team.
  ///
  /// In ar, this message translates to:
  /// **'للفريق'**
  String get wa_qr_team;

  /// No description provided for @wa_qr_mine.
  ///
  /// In ar, this message translates to:
  /// **'الخاصة بي'**
  String get wa_qr_mine;

  /// No description provided for @wa_qr_title_f.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get wa_qr_title_f;

  /// No description provided for @wa_qr_shortcut.
  ///
  /// In ar, this message translates to:
  /// **'الاختصار'**
  String get wa_qr_shortcut;

  /// No description provided for @wa_qr_text.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get wa_qr_text;

  /// No description provided for @wa_qr_shared.
  ///
  /// In ar, this message translates to:
  /// **'مشترك مع الفريق'**
  String get wa_qr_shared;

  /// No description provided for @wa_notify_admin.
  ///
  /// In ar, this message translates to:
  /// **'أبلغ المسؤول'**
  String get wa_notify_admin;

  /// No description provided for @wa_load_error.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل حالة واتساب'**
  String get wa_load_error;

  /// No description provided for @wa_enable_after.
  ///
  /// In ar, this message translates to:
  /// **'فعّلها بعد ربط الرقم'**
  String get wa_enable_after;

  /// No description provided for @wa_more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get wa_more;

  /// No description provided for @wa_last_updated.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث {t}'**
  String wa_last_updated(String t);

  /// No description provided for @wa_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get wa_copied;

  /// No description provided for @wa_details_title.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الاتصال'**
  String get wa_details_title;

  /// No description provided for @wa_d_type.
  ///
  /// In ar, this message translates to:
  /// **'نوع الربط'**
  String get wa_d_type;

  /// No description provided for @wa_d_type_linked.
  ///
  /// In ar, this message translates to:
  /// **'جهاز مرتبط'**
  String get wa_d_type_linked;

  /// No description provided for @wa_d_type_cloud.
  ///
  /// In ar, this message translates to:
  /// **'واجهة واتساب الرسمية'**
  String get wa_d_type_cloud;

  /// No description provided for @wa_d_device.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز'**
  String get wa_d_device;

  /// No description provided for @wa_d_wa_business.
  ///
  /// In ar, this message translates to:
  /// **'واتساب أعمال {v}'**
  String wa_d_wa_business(String v);

  /// No description provided for @wa_d_wa_personal.
  ///
  /// In ar, this message translates to:
  /// **'واتساب {v}'**
  String wa_d_wa_personal(String v);

  /// No description provided for @wa_d_last_activity.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشاط'**
  String get wa_d_last_activity;

  /// No description provided for @wa_d_sync.
  ///
  /// In ar, this message translates to:
  /// **'حالة المزامنة'**
  String get wa_d_sync;

  /// No description provided for @wa_d_synced.
  ///
  /// In ar, this message translates to:
  /// **'متزامنة'**
  String get wa_d_synced;

  /// No description provided for @wa_d_number_id.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الرقم'**
  String get wa_d_number_id;

  /// No description provided for @wa_d_daily_limit.
  ///
  /// In ar, this message translates to:
  /// **'حد المحادثات اليومي'**
  String get wa_d_daily_limit;

  /// No description provided for @wa_d_limit_value.
  ///
  /// In ar, this message translates to:
  /// **'{u} من {l}'**
  String wa_d_limit_value(String l, String u);

  /// No description provided for @wa_unknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get wa_unknown;

  /// No description provided for @wa_qs_explain.
  ///
  /// In ar, this message translates to:
  /// **'تعتمد جودة الرقم على تفاعل العملاء مع رسائلك خلال آخر 7 أيام. الحظر والبلاغات وانخفاض التفاعل تخفضها.'**
  String get wa_qs_explain;

  /// No description provided for @wa_qs_tier.
  ///
  /// In ar, this message translates to:
  /// **'فئة المراسلة'**
  String get wa_qs_tier;

  /// No description provided for @wa_qs_tier_value.
  ///
  /// In ar, this message translates to:
  /// **'{tier} محادثة يوميًا'**
  String wa_qs_tier_value(String tier);

  /// No description provided for @wa_qs_trend.
  ///
  /// In ar, this message translates to:
  /// **'آخر 7 أيام'**
  String get wa_qs_trend;

  /// No description provided for @wa_qs_tips.
  ///
  /// In ar, this message translates to:
  /// **'نصائح لرفع الجودة'**
  String get wa_qs_tips;

  /// No description provided for @wa_qs_tip1.
  ///
  /// In ar, this message translates to:
  /// **'راسل فقط العملاء الذين طلبوا التواصل'**
  String get wa_qs_tip1;

  /// No description provided for @wa_qs_tip2.
  ///
  /// In ar, this message translates to:
  /// **'خصّص الرسائل وتجنّب النصوص المكررة'**
  String get wa_qs_tip2;

  /// No description provided for @wa_qs_tip3.
  ///
  /// In ar, this message translates to:
  /// **'اجعل إيقاف الرسائل سهلًا للعميل'**
  String get wa_qs_tip3;

  /// No description provided for @wa_qs_help.
  ///
  /// In ar, this message translates to:
  /// **'مركز مساعدة واتساب'**
  String get wa_qs_help;

  /// No description provided for @wa_log_connected.
  ///
  /// In ar, this message translates to:
  /// **'تم الربط'**
  String get wa_log_connected;

  /// No description provided for @wa_log_connected_by.
  ///
  /// In ar, this message translates to:
  /// **'ربطه {name}'**
  String wa_log_connected_by(String name);

  /// No description provided for @wa_log_disconnected.
  ///
  /// In ar, this message translates to:
  /// **'انقطع الاتصال · {d}'**
  String wa_log_disconnected(String d);

  /// No description provided for @wa_log_reconnected.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد الربط'**
  String get wa_log_reconnected;

  /// No description provided for @wa_log_reconnected_by.
  ///
  /// In ar, this message translates to:
  /// **'أعاد {name} الربط'**
  String wa_log_reconnected_by(String name);

  /// No description provided for @wa_log_recovered.
  ///
  /// In ar, this message translates to:
  /// **'استُعيدت {n} رسالة'**
  String wa_log_recovered(String n);

  /// No description provided for @wa_reason_phone_offline.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف غير متصل'**
  String get wa_reason_phone_offline;

  /// No description provided for @wa_reason_logged_out.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل خروج'**
  String get wa_reason_logged_out;

  /// No description provided for @wa_reason_update.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get wa_reason_update;

  /// No description provided for @wa_log_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحداث خلال آخر 30 يومًا'**
  String get wa_log_empty;

  /// No description provided for @wa_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get wa_cancel;

  /// No description provided for @wa_disc_mismatch.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام غير مطابقة'**
  String get wa_disc_mismatch;

  /// No description provided for @wa_disc_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فصل الرقم'**
  String get wa_disc_failed;

  /// No description provided for @wa_notify_sent.
  ///
  /// In ar, this message translates to:
  /// **'تم إبلاغ المسؤول'**
  String get wa_notify_sent;

  /// No description provided for @wa_save_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التغيير'**
  String get wa_save_failed;

  /// No description provided for @wa_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get wa_retry;

  /// No description provided for @wa_offline.
  ///
  /// In ar, this message translates to:
  /// **'التعديل يتطلب اتصالًا بالإنترنت'**
  String get wa_offline;

  /// No description provided for @wa_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get wa_saved;

  /// No description provided for @wa_welcome_on.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل رسالة الترحيب'**
  String get wa_welcome_on;

  /// No description provided for @wa_away_on.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل رسالة خارج الدوام'**
  String get wa_away_on;

  /// No description provided for @wa_away_off.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف رسالة خارج الدوام'**
  String get wa_away_off;

  /// No description provided for @wa_delay_30s.
  ///
  /// In ar, this message translates to:
  /// **'بعد 30 ثانية'**
  String get wa_delay_30s;

  /// No description provided for @wa_delay_1m.
  ///
  /// In ar, this message translates to:
  /// **'بعد دقيقة'**
  String get wa_delay_1m;

  /// No description provided for @wa_delay_2m.
  ///
  /// In ar, this message translates to:
  /// **'بعد دقيقتين'**
  String get wa_delay_2m;

  /// No description provided for @wa_delay_5m.
  ///
  /// In ar, this message translates to:
  /// **'بعد 5 دقائق'**
  String get wa_delay_5m;

  /// No description provided for @wa_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get wa_save;

  /// No description provided for @wa_welcome_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل رسالة الترحيب'**
  String get wa_welcome_enable;

  /// No description provided for @wa_away_enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل رسالة خارج الدوام'**
  String get wa_away_enable;

  /// No description provided for @wa_message.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة'**
  String get wa_message;

  /// No description provided for @wa_message_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرسالة…'**
  String get wa_message_hint;

  /// No description provided for @wa_send_when.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال'**
  String get wa_send_when;

  /// No description provided for @wa_buttons_hint.
  ///
  /// In ar, this message translates to:
  /// **'حتى 3 أزرار، 20 حرفًا لكل زر'**
  String get wa_buttons_hint;

  /// No description provided for @wa_button_add.
  ///
  /// In ar, this message translates to:
  /// **'+ أضف زرًا'**
  String get wa_button_add;

  /// No description provided for @wa_button_hint.
  ///
  /// In ar, this message translates to:
  /// **'نص الزر'**
  String get wa_button_hint;

  /// No description provided for @wa_preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get wa_preview;

  /// No description provided for @wa_err_text.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرسالة (1–1024 حرفًا)'**
  String get wa_err_text;

  /// No description provided for @wa_err_button.
  ///
  /// In ar, this message translates to:
  /// **'نص الزر أطول من 20 حرفًا'**
  String get wa_err_button;

  /// No description provided for @wa_go_ai.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الذكاء'**
  String get wa_go_ai;

  /// No description provided for @wa_discard_title.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل التغييرات؟'**
  String get wa_discard_title;

  /// No description provided for @wa_discard_body.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحفظ تعديلاتك.'**
  String get wa_discard_body;

  /// No description provided for @wa_discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get wa_discard;

  /// No description provided for @wa_keep.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get wa_keep;

  /// No description provided for @wa_qr_new.
  ///
  /// In ar, this message translates to:
  /// **'رد سريع جديد'**
  String get wa_qr_new;

  /// No description provided for @wa_qr_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الرد السريع'**
  String get wa_qr_edit;

  /// No description provided for @wa_qr_search.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الردود'**
  String get wa_qr_search;

  /// No description provided for @wa_qr_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ردود سريعة بعد'**
  String get wa_qr_empty;

  /// No description provided for @wa_qr_empty_body.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ ردًا واستخدمه بكتابة / في المحادثة'**
  String get wa_qr_empty_body;

  /// No description provided for @wa_qr_no_results.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج'**
  String get wa_qr_no_results;

  /// No description provided for @wa_qr_add.
  ///
  /// In ar, this message translates to:
  /// **'أضف ردًا'**
  String get wa_qr_add;

  /// No description provided for @wa_qr_used.
  ///
  /// In ar, this message translates to:
  /// **'استُخدم {n} مرة'**
  String wa_qr_used(String n);

  /// No description provided for @wa_qr_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف «{title}»؟'**
  String wa_qr_delete_title(String title);

  /// No description provided for @wa_qr_delete_body.
  ///
  /// In ar, this message translates to:
  /// **'لن يظهر في قائمة / بعد الآن.'**
  String get wa_qr_delete_body;

  /// No description provided for @wa_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get wa_delete;

  /// No description provided for @wa_qr_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الرد'**
  String get wa_qr_deleted;

  /// No description provided for @wa_qr_delete_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حذف الرد'**
  String get wa_qr_delete_failed;

  /// No description provided for @wa_qr_attach.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة أو ملف'**
  String get wa_qr_attach;

  /// No description provided for @wa_qr_attach_hint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري · حتى 5 ميجابايت'**
  String get wa_qr_attach_hint;

  /// No description provided for @wa_qr_attach_too_big.
  ///
  /// In ar, this message translates to:
  /// **'الملف أكبر من 5 ميجابايت'**
  String get wa_qr_attach_too_big;

  /// No description provided for @wa_qr_attach_remove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المرفق'**
  String get wa_qr_attach_remove;

  /// No description provided for @wa_qr_err_title.
  ///
  /// In ar, this message translates to:
  /// **'اكتب العنوان'**
  String get wa_qr_err_title;

  /// No description provided for @wa_qr_err_text.
  ///
  /// In ar, this message translates to:
  /// **'اكتب النص'**
  String get wa_qr_err_text;

  /// No description provided for @wa_qr_err_shortcut_empty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاختصار'**
  String get wa_qr_err_shortcut_empty;

  /// No description provided for @wa_qr_err_shortcut_invalid.
  ///
  /// In ar, this message translates to:
  /// **'استخدم a–z و0–9 و_ و- فقط'**
  String get wa_qr_err_shortcut_invalid;

  /// No description provided for @wa_qr_err_shortcut_taken.
  ///
  /// In ar, this message translates to:
  /// **'هذا الاختصار مستخدم'**
  String get wa_qr_err_shortcut_taken;

  /// No description provided for @wa_qr_err_shortcut_long.
  ///
  /// In ar, this message translates to:
  /// **'الاختصار طويل جدًا'**
  String get wa_qr_err_shortcut_long;

  /// No description provided for @wa_qr_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الرد'**
  String get wa_qr_saved;

  /// No description provided for @wa_qr_save_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الرد'**
  String get wa_qr_save_failed;

  /// No description provided for @wa_qr_reorder_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الترتيب'**
  String get wa_qr_reorder_failed;

  /// No description provided for @wa_qr_shared_sub.
  ///
  /// In ar, this message translates to:
  /// **'يظهر لكل أعضاء الفريق'**
  String get wa_qr_shared_sub;

  /// No description provided for @wa_qr_readonly.
  ///
  /// In ar, this message translates to:
  /// **'ردود الفريق يعدّلها المسؤول فقط'**
  String get wa_qr_readonly;

  /// No description provided for @wa_tpl_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قوالب معتمدة بعد'**
  String get wa_tpl_empty;

  /// No description provided for @wa_tpl_preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة القالب'**
  String get wa_tpl_preview;

  /// No description provided for @wa_phone_hint.
  ///
  /// In ar, this message translates to:
  /// **'5X XXX XXXX'**
  String get wa_phone_hint;

  /// No description provided for @wa_err_phone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقمًا صحيحًا'**
  String get wa_err_phone;

  /// No description provided for @wa_rate_limited.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، حاول بعد قليل'**
  String get wa_rate_limited;

  /// No description provided for @wa_multi_device.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب لا يدعم الأجهزة المرتبطة؛ حدّث واتساب ثم حاول مجددًا'**
  String get wa_multi_device;

  /// No description provided for @wa_connect_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الربط، حاول مجددًا'**
  String get wa_connect_failed;

  /// No description provided for @wa_network_error.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get wa_network_error;

  /// No description provided for @wa_qr_steps.
  ///
  /// In ar, this message translates to:
  /// **'افتح واتساب على الهاتف الآخر ← الإعدادات ← الأجهزة المرتبطة ← ربط جهاز ← امسح الرمز'**
  String get wa_qr_steps;

  /// No description provided for @wa_qr_refresh_in.
  ///
  /// In ar, this message translates to:
  /// **'يتجدد خلال {s} ث'**
  String wa_qr_refresh_in(String s);

  /// No description provided for @wa_qr_alt.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR لربط واتساب، يتجدد كل 20 ثانية'**
  String get wa_qr_alt;

  /// No description provided for @wa_waiting_link.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار إدخال الرمز على هاتفك…'**
  String get wa_waiting_link;

  /// No description provided for @wa_change_number.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get wa_change_number;

  /// No description provided for @wa_phone_tip.
  ///
  /// In ar, this message translates to:
  /// **'الربط برقم الهاتف أسهل عند استخدام نفس الجهاز، ولا يمكن مسح رمز QR بنفس الهاتف.'**
  String get wa_phone_tip;

  /// No description provided for @wa_plan_title.
  ///
  /// In ar, this message translates to:
  /// **'واتساب غير متاح في خطتك'**
  String get wa_plan_title;

  /// No description provided for @wa_plan_body.
  ///
  /// In ar, this message translates to:
  /// **'رقِّ خطتك لربط رقم واتساب واستقبال رسائل العملاء'**
  String get wa_plan_body;

  /// No description provided for @wa_view_plans.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخطط'**
  String get wa_view_plans;

  /// No description provided for @wa_upgrade_info.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع مالك مساحة العمل للترقية'**
  String get wa_upgrade_info;

  /// No description provided for @wa_blocked_empty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أرقام محظورة'**
  String get wa_blocked_empty;

  /// No description provided for @wa_unblock.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحظر'**
  String get wa_unblock;

  /// No description provided for @wa_unblocked.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الحظر'**
  String get wa_unblocked;

  /// No description provided for @wa_card_a11y.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {phone}، {status}. {n} رسالة اليوم، جودة الرقم {q}، مرتبط منذ {d} يومًا'**
  String wa_card_a11y(
    String d,
    String n,
    String name,
    String phone,
    String q,
    String status,
  );

  /// No description provided for @wa_save_disabled.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الحقول المطلوبة'**
  String get wa_save_disabled;

  /// No description provided for @wa_log_disconnected_by.
  ///
  /// In ar, this message translates to:
  /// **'فصله {name}'**
  String wa_log_disconnected_by(String name);

  /// No description provided for @wa_log_connect_started.
  ///
  /// In ar, this message translates to:
  /// **'بدأت محاولة ربط'**
  String get wa_log_connect_started;

  /// No description provided for @wa_log_connect_started_by.
  ///
  /// In ar, this message translates to:
  /// **'بدأ {name} محاولة ربط'**
  String wa_log_connect_started_by(String name);

  /// No description provided for @wa_already_linked.
  ///
  /// In ar, this message translates to:
  /// **'الرقم مرتبط بالفعل'**
  String get wa_already_linked;

  /// No description provided for @wa_banned.
  ///
  /// In ar, this message translates to:
  /// **'حظر واتساب هذا الرقم'**
  String get wa_banned;

  /// No description provided for @wa_demo_state.
  ///
  /// In ar, this message translates to:
  /// **'حالة تجريبية'**
  String get wa_demo_state;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
