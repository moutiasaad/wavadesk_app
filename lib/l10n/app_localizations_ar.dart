// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String dashboard_greeting(String name) {
    return 'مرحبًا، $name 👋';
  }

  @override
  String get dashboard_open => 'محادثات مفتوحة';

  @override
  String get dashboard_waiting_sla => 'تجاوزت وقت الانتظار';

  @override
  String get dashboard_view_queue => 'عرض قائمة الانتظار';

  @override
  String get dashboard_first_response => 'متوسط أول رد';

  @override
  String get dashboard_resolved_today => 'محلولة اليوم';

  @override
  String get dashboard_ai_rate => 'حلّها الذكاء الاصطناعي';

  @override
  String get dashboard_csat => 'رضا العملاء';

  @override
  String get dashboard_csat_scale => 'من 5';

  @override
  String dashboard_vs_yesterday(String delta) {
    return '$delta عن أمس';
  }

  @override
  String get dashboard_volume_title => 'حجم المحادثات اليوم';

  @override
  String dashboard_volume_a11y(int total, int peak, String hour) {
    return '$total محادثة اليوم، الذروة $peak عند الساعة $hour';
  }

  @override
  String get dashboard_channels_title => 'حسب القناة';

  @override
  String get dashboard_ai_usage_title => 'استخدام الذكاء الاصطناعي';

  @override
  String get dashboard_ai_manage => 'إدارة';

  @override
  String dashboard_ai_usage_value(int used, int quota) {
    return '$used من $quota ردًّا هذا الشهر';
  }

  @override
  String get dashboard_team_title => 'الفريق الآن';

  @override
  String dashboard_team_open(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محادثة',
      few: '$count محادثات',
      two: 'محادثتان',
      one: 'محادثة واحدة',
      zero: 'لا محادثات',
    );
    return '$_temp0';
  }

  @override
  String get notifications_title => 'الإشعارات';

  @override
  String get notifications_mark_all => 'تحديد الكل كمقروء';

  @override
  String get notifications_earlier => 'سابقًا';

  @override
  String get notifications_empty_title => 'لا إشعارات بعد';

  @override
  String get notifications_empty_body =>
      'سنخبرك عند إسناد محادثة إليك أو ذكرك في ملاحظة.';

  @override
  String get knowledge_search => 'بحث في المعرفة';

  @override
  String get knowledge_search_hint => 'ابحث في الإجابات…';

  @override
  String get knowledge_add => 'إضافة إجابة';

  @override
  String get knowledge_filter_all => 'الكل';

  @override
  String get knowledge_type_faq => 'أسئلة شائعة';

  @override
  String get knowledge_type_policy => 'سياسات';

  @override
  String get knowledge_type_product => 'منتجات';

  @override
  String get knowledge_type_snippet => 'ردود جاهزة';

  @override
  String get knowledge_type_website => 'الموقع';

  @override
  String get knowledge_coverage_title => 'ما يعرفه الذكاء الاصطناعي';

  @override
  String knowledge_coverage_body(int total, int enabled) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total إجابة',
      few: '$total إجابات',
      two: 'إجابتان',
      one: 'إجابة واحدة',
    );
    return '$_temp0، منها $enabled مفعّلة';
  }

  @override
  String knowledge_coverage_top(String title) {
    return 'الأكثر استخدامًا: $title';
  }

  @override
  String knowledge_used(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استُخدمت $count مرة',
      few: 'استُخدمت $count مرات',
      two: 'استُخدمت مرتين',
      one: 'استُخدمت مرة',
      zero: 'لم تُستخدم بعد',
    );
    return '$_temp0';
  }

  @override
  String knowledge_updated(String time) {
    return 'حُدّثت $time';
  }

  @override
  String get knowledge_disabled => 'متوقفة';

  @override
  String knowledge_enabled_a11y(String title) {
    return 'تفعيل «$title»';
  }

  @override
  String get knowledge_empty_title => 'قاعدة المعرفة فارغة';

  @override
  String get knowledge_empty_body =>
      'أضف إجابات وسياسات ليستخدمها الذكاء الاصطناعي في اقتراح الردود.';

  @override
  String get knowledge_empty_filtered => 'لا إجابات من هذا النوع';

  @override
  String knowledge_no_results(String query) {
    return 'لا نتائج لـ «$query»';
  }

  @override
  String get knowledge_edit_title_add => 'إضافة إجابة';

  @override
  String get knowledge_edit_title_edit => 'تعديل الإجابة';

  @override
  String get knowledge_edit_type => 'النوع';

  @override
  String get knowledge_edit_question => 'السؤال';

  @override
  String get knowledge_edit_title_label => 'العنوان';

  @override
  String get knowledge_edit_title_hint => 'مثال: كم مدة التوصيل؟';

  @override
  String get knowledge_edit_body_label => 'الإجابة';

  @override
  String get knowledge_edit_body_hint =>
      'اكتب الإجابة كما تريد أن يقولها الذكاء الاصطناعي…';

  @override
  String knowledge_edit_counter(int count, int max) {
    return '$count / $max';
  }

  @override
  String get knowledge_edit_keywords => 'كلمات مفتاحية';

  @override
  String get knowledge_edit_keywords_hint => 'أضف كلمة واضغط إدخال';

  @override
  String get knowledge_edit_keyword_add => 'إضافة كلمة مفتاحية';

  @override
  String get knowledge_edit_enabled => 'متاحة للذكاء الاصطناعي';

  @override
  String get knowledge_edit_enabled_sub =>
      'عند الإيقاف لن تُستخدم في الاقتراحات';

  @override
  String get knowledge_edit_preview_title => 'كيف سيستخدمها الذكاء الاصطناعي';

  @override
  String get knowledge_edit_preview_q => 'سؤال العميل يظهر هنا';

  @override
  String get knowledge_edit_preview_a => 'وهنا الرد المقترح بناءً على إجابتك';

  @override
  String get knowledge_edit_error_title => 'العنوان مطلوب';

  @override
  String get knowledge_edit_error_body => 'اكتب إجابة من 10 أحرف على الأقل';

  @override
  String get knowledge_edit_saved => 'تم حفظ الإجابة';

  @override
  String get knowledge_edit_delete => 'حذف الإجابة';

  @override
  String get knowledge_edit_delete_title => 'حذف هذه الإجابة؟';

  @override
  String get knowledge_edit_delete_body =>
      'لن يستخدمها الذكاء الاصطناعي بعد الآن في اقتراح الردود.';

  @override
  String get knowledge_edit_deleted => 'تم حذف الإجابة';

  @override
  String get knowledge_edit_discard_title => 'تجاهل التغييرات؟';

  @override
  String get knowledge_edit_discard_body =>
      'لديك تعديلات غير محفوظة ستضيع إذا خرجت الآن.';

  @override
  String get knowledge_edit_discard_confirm => 'تجاهل والخروج';

  @override
  String get account_section_admin => 'الإدارة';

  @override
  String get account_section_app => 'التطبيق';

  @override
  String get account_whatsapp => 'واتساب الخاص بك';

  @override
  String get account_whatsapp_connected => 'متصل';

  @override
  String get account_whatsapp_disconnected => 'غير متصل';

  @override
  String get account_channels => 'القنوات';

  @override
  String get account_ai_agent => 'وكيل الذكاء الاصطناعي';

  @override
  String get account_team => 'الفريق والمستخدمون';

  @override
  String get account_subscription => 'الاشتراك';

  @override
  String get account_notifications => 'الإشعارات';

  @override
  String get account_language => 'اللغة';

  @override
  String get account_appearance => 'المظهر';

  @override
  String get account_theme_light => 'فاتح';

  @override
  String get account_theme_dark => 'داكن';

  @override
  String get account_theme_system => 'تلقائي';

  @override
  String get account_theme_system_sub => 'يتبع إعدادات الجهاز';

  @override
  String get account_help => 'المساعدة والشروحات';

  @override
  String get account_logout => 'تسجيل الخروج';

  @override
  String get account_logout_title => 'تسجيل الخروج؟';

  @override
  String get account_logout_body =>
      'لن تصلك إشعارات المحادثات على هذا الجهاز حتى تسجّل الدخول مجددًا.';

  @override
  String account_version(String version) {
    return 'Wavadesk $version';
  }

  @override
  String get account_network_online => 'متصل';

  @override
  String get ai_settings_title => 'وكيل الذكاء الاصطناعي';

  @override
  String get ai_settings_enable => 'تفعيل وكيل الذكاء الاصطناعي';

  @override
  String get ai_settings_status_on => 'يعمل ويقترح الردود';

  @override
  String get ai_settings_status_off => 'متوقف';

  @override
  String ai_settings_usage(int used, int quota) {
    return '$used من $quota ردًّا هذا الشهر';
  }

  @override
  String get ai_settings_section_behavior => 'السلوك';

  @override
  String get ai_settings_suggest => 'اقتراح الردود';

  @override
  String get ai_settings_suggest_sub => 'مسودة جاهزة قبل أن تفتح المحادثة';

  @override
  String get ai_settings_auto => 'الرد التلقائي';

  @override
  String get ai_settings_auto_sub =>
      'يرد على المحادثات غير المُسندة دون انتظار';

  @override
  String get ai_settings_claimed => 'الرد حتى بعد الاستلام';

  @override
  String get ai_settings_claimed_sub =>
      'يستمر في الرد بعد أن يستلم موظف المحادثة';

  @override
  String get ai_settings_handoff => 'التحويل عند الاستياء';

  @override
  String get ai_settings_handoff_sub =>
      'يحوّل المحادثة للفريق إذا بدا العميل منزعجًا';

  @override
  String get ai_settings_section_tone => 'أسلوب الرد';

  @override
  String get ai_settings_tone_friendly => 'ودّي';

  @override
  String get ai_settings_tone_friendly_sub => 'دافئ وقريب من العميل';

  @override
  String get ai_settings_tone_formal => 'رسمي';

  @override
  String get ai_settings_tone_formal_sub => 'مهذب ومهني';

  @override
  String get ai_settings_tone_concise => 'مختصر';

  @override
  String get ai_settings_tone_concise_sub => 'جمل قصيرة ومباشرة';

  @override
  String get ai_settings_section_knowledge => 'مصدر المعرفة';

  @override
  String get ai_settings_knowledge => 'الإجابات المفعّلة';

  @override
  String get ai_settings_knowledge_footer =>
      'يعتمد الذكاء الاصطناعي على قاعدة المعرفة فقط ولا يخترع معلومات.';

  @override
  String get whatsapp_title => 'واتساب الخاص بك';

  @override
  String get whatsapp_status_connected => 'متصل';

  @override
  String get whatsapp_status_disconnected => 'غير متصل';

  @override
  String get whatsapp_since => 'متصل منذ';

  @override
  String get whatsapp_messages_today => 'رسائل اليوم';

  @override
  String get whatsapp_connected_tip =>
      'أبقِ هاتفك متصلًا بالإنترنت. إذا سجّلت الخروج من واتساب على الهاتف ستحتاج لمسح الرمز من جديد.';

  @override
  String get whatsapp_disconnect => 'قطع الاتصال';

  @override
  String get whatsapp_disconnect_title => 'قطع اتصال واتساب؟';

  @override
  String get whatsapp_disconnect_body =>
      'ستتوقف رسائل العملاء عن الوصول إلى المحادثات حتى تعيد ربط الرقم.';

  @override
  String get whatsapp_qr_a11y => 'رمز QR لربط واتساب';

  @override
  String get whatsapp_qr_expires => 'ينتهي الرمز خلال دقيقة';

  @override
  String get whatsapp_waiting_scan => 'بانتظار المسح من هاتفك…';

  @override
  String get whatsapp_steps_title => 'طريقة الربط';

  @override
  String get whatsapp_step1 => 'افتح واتساب على هاتف العمل';

  @override
  String get whatsapp_step2 => 'اضغط ⋮ ثم «الأجهزة المرتبطة»';

  @override
  String get whatsapp_step3 => 'اختر «ربط جهاز»';

  @override
  String get whatsapp_step4 => 'وجّه الكاميرا نحو هذا الرمز';

  @override
  String get whatsapp_simulate_scan => 'مسح الرمز (تجريبي)';

  @override
  String get whatsapp_new_code => 'إنشاء رمز جديد';

  @override
  String get whatsapp_connected_toast => 'تم ربط واتساب بنجاح';

  @override
  String get channels_title => 'القنوات';

  @override
  String get channels_section_connected => 'متصلة';

  @override
  String get channels_section_available => 'متاحة للربط';

  @override
  String get channels_connected => 'متصلة وتستقبل الرسائل';

  @override
  String get channels_not_connected => 'غير مربوطة';

  @override
  String get channels_manage_on_web => 'إدارة هذه القناة متاحة من لوحة الويب';

  @override
  String get channels_footer => 'تصل رسائل كل القنوات المربوطة إلى صندوق واحد.';

  @override
  String get team_title => 'الفريق والمستخدمون';

  @override
  String get team_invite => 'دعوة زميل';

  @override
  String get team_invite_sent => 'أرسلنا رابط الدعوة';

  @override
  String team_section_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String get team_section_teams => 'الفرق';

  @override
  String team_you(String name) {
    return '$name (أنت)';
  }

  @override
  String team_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String get subscription_title => 'الاشتراك';

  @override
  String get subscription_current => 'باقتك الحالية';

  @override
  String get subscription_plan_name => 'الاحترافية';

  @override
  String get subscription_price => '199 ر.س / شهريًا';

  @override
  String subscription_renews(String date) {
    return 'تتجدد في $date';
  }

  @override
  String get subscription_section_usage => 'الاستخدام هذا الشهر';

  @override
  String get subscription_ai_replies => 'ردود الذكاء الاصطناعي';

  @override
  String get subscription_agents => 'المستخدمون';

  @override
  String get subscription_channels => 'القنوات';

  @override
  String subscription_usage(String used, String total) {
    return '$used / $total';
  }

  @override
  String get subscription_upgrade => 'ترقية الباقة';

  @override
  String get subscription_invoices => 'الفواتير';

  @override
  String get subscription_upgrade_web => 'سنفتح صفحة الفوترة على الويب';

  @override
  String get notif_settings_title => 'الإشعارات';

  @override
  String get notif_settings_section_push => 'أبلغني عند';

  @override
  String get notif_settings_assigned => 'إسناد محادثة إليّ';

  @override
  String get notif_settings_assigned_sub => 'عندما يسندها زميل أو قاعدة توزيع';

  @override
  String get notif_settings_mentions => 'ذكري في ملاحظة';

  @override
  String get notif_settings_mentions_sub => 'عندما يكتب زميل ‎@اسمك';

  @override
  String get notif_settings_waiting => 'تجاوز وقت الانتظار';

  @override
  String get notif_settings_waiting_sub => 'عميل ينتظر أكثر من الوقت المستهدف';

  @override
  String get notif_settings_section_sound => 'الصوت';

  @override
  String get notif_settings_sound => 'صوت الإشعار';

  @override
  String get notif_settings_sound_sub => 'تشغيل صوت عند وصول رسالة جديدة';

  @override
  String get notif_settings_footer =>
      'لا تصلك إشعارات عندما تكون حالتك «غير متاح».';

  @override
  String get help_title => 'المساعدة والشروحات';

  @override
  String get help_section_guides => 'الشروحات';

  @override
  String get help_topic_claim => 'استلام المحادثات وإسنادها';

  @override
  String get help_topic_ai => 'كيف تعمل اقتراحات الذكاء الاصطناعي';

  @override
  String get help_topic_whatsapp => 'ربط رقم واتساب';

  @override
  String get help_topic_knowledge => 'بناء قاعدة المعرفة';

  @override
  String get help_topic_snooze => 'التأجيل والإغلاق';

  @override
  String get help_section_contact => 'تواصل معنا';

  @override
  String get help_contact_chat => 'محادثة مع الدعم';

  @override
  String get help_contact_chat_sub => 'نرد عادة خلال دقائق';

  @override
  String get help_contact_email => 'البريد الإلكتروني';

  @override
  String get help_opening => 'جارٍ الفتح…';

  @override
  String get account_load_error => 'تعذّر التحميل';

  @override
  String subscription_ends(String date) {
    return 'تنتهي في $date';
  }

  @override
  String subscription_trial_ends(String date) {
    return 'تنتهي الفترة التجريبية في $date';
  }

  @override
  String get subscription_trial => 'فترة تجريبية';

  @override
  String get subscription_unlimited => 'غير محدود';

  @override
  String get subscription_no_plan => 'لا توجد باقة';

  @override
  String subscription_per_month(String price) {
    return '$price / شهريًا';
  }

  @override
  String get channels_meta => 'واتساب للأعمال (ميتا)';

  @override
  String get channels_open_on_web => 'يُفتح على الموقع';

  @override
  String get channels_open_web_failed => 'تعذّر فتح الموقع';

  @override
  String get channels_meta_sub => 'الواجهة الرسمية · يُفتح على الموقع';

  @override
  String get ai_title => 'وكيل الذكاء الاصطناعي';

  @override
  String get ai_master_switch => 'تشغيل الذكاء الاصطناعي';

  @override
  String get ai_state_on => 'مفعّل';

  @override
  String get ai_state_off => 'متوقف';

  @override
  String get ai_readonly => 'يمكن للمسؤول فقط تعديل إعدادات الذكاء الاصطناعي';

  @override
  String ai_hero_answered(String n) {
    return '$n سؤالًا';
  }

  @override
  String ai_hero_caption(String h) {
    return 'أجاب عنها هذا الأسبوع · وفّر نحو $h ساعات';
  }

  @override
  String get ai_hero_off => 'الذكاء الاصطناعي متوقف';

  @override
  String get ai_hero_off_body => 'فعّله ليجيب عن أسئلة عملائك من قاعدة المعرفة';

  @override
  String get ai_hero_ready => 'جاهز للعمل';

  @override
  String get ai_hero_ready_body => 'لم يجب عن أي سؤال بعد — جرّبه أولًا';

  @override
  String ai_hero_a11y(String n) {
    return '$n سؤالًا أجاب عنها هذا الأسبوع، عرض الأداء';
  }

  @override
  String ai_usage(String p) {
    return 'استخدمت $p% من ردود هذا الشهر';
  }

  @override
  String get ai_ready_title => 'قبل التفعيل الكامل';

  @override
  String ai_ready_kb(String n) {
    return 'قاعدة المعرفة تحتوي 10 إجابات على الأقل ($n/10)';
  }

  @override
  String get ai_ready_hours => 'ساعات العمل محددة';

  @override
  String get ai_ready_handoff => 'قاعدة تحويل للموظفين مفعّلة';

  @override
  String get ai_ready_tested => 'تمت تجربة الوكيل';

  @override
  String get ai_ready_done => 'مكتمل';

  @override
  String get ai_ready_missing => 'غير مكتمل';

  @override
  String get ai_mode => 'طريقة العمل';

  @override
  String get ai_mode_suggest => 'اقتراح';

  @override
  String get ai_mode_suggest_sub => 'يقترح الردود مع إبقاء الوكيل في التحكم';

  @override
  String get ai_mode_auto => 'ذاتي';

  @override
  String get ai_mode_auto_sub => 'يرد تلقائياً ضمن الحدود المسموح بها';

  @override
  String get ai_mode_after => 'خارج الدوام فقط';

  @override
  String get ai_mode_after_sub => 'يرد تلقائيًا بعد ساعات العمل';

  @override
  String get ai_mode_after_sub2 => 'واقتراحات خلال الدوام';

  @override
  String get ai_mode_needs_hours => 'حدّد ساعات العمل أولًا';

  @override
  String get ai_mode_needs_ready => 'أكمل قائمة الجاهزية أولًا';

  @override
  String get ai_recommended => 'موصى به';

  @override
  String ai_mode_changed(String mode) {
    return 'تم التغيير إلى «$mode»';
  }

  @override
  String get ai_undo => 'تراجع';

  @override
  String get ai_tone => 'نبرة الرد';

  @override
  String get ai_tone_friendly => 'ودود';

  @override
  String get ai_tone_formal => 'رسمي';

  @override
  String get ai_tone_concise => 'مختصر';

  @override
  String get ai_tone_sample_friendly =>
      'أهلًا نورة، التوصيل للدمام 25 ريال، ومجاني فوق 300. يوصلك خلال 2–3 أيام!';

  @override
  String get ai_tone_sample_formal =>
      'مرحبًا بك. رسوم التوصيل إلى الدمام 25 ريالًا، ويكون مجانيًا للطلبات التي تتجاوز 300 ريال، خلال 2–3 أيام عمل.';

  @override
  String get ai_tone_sample_concise =>
      'التوصيل للدمام 25 ريال (مجاني فوق 300) · 2–3 أيام.';

  @override
  String get ai_use_name => 'استخدم اسم العميل في الرد';

  @override
  String get ai_rules => 'القواعد';

  @override
  String get ai_hours => 'ساعات العمل';

  @override
  String get ai_hours_24 => '24 ساعة';

  @override
  String get ai_hours_unset => 'غير محددة';

  @override
  String get ai_handoff => 'التحويل لموظف';

  @override
  String get ai_handoff_sub => 'عند طلب إنسان، شكوى، أو دفع';

  @override
  String get ai_language => 'لغة الرد';

  @override
  String get ai_lang_customer => 'لغة العميل';

  @override
  String get ai_lang_customer_sub => 'يكتشف اللغة في كل رسالة';

  @override
  String get ai_lang_ar => 'العربية دائمًا';

  @override
  String get ai_lang_en => 'الإنجليزية دائمًا';

  @override
  String get ai_lang_style => 'الأسلوب';

  @override
  String get ai_lang_msa => 'فصحى مبسطة';

  @override
  String get ai_lang_saudi => 'لهجة سعودية بيضاء';

  @override
  String get ai_handoff_msg => 'رسالة التحويل';

  @override
  String get ai_handoff_msg_default =>
      'سأحوّلك الآن لأحد زملائي ليساعدك، لحظات من فضلك.';

  @override
  String get ai_var_customer => 'اسم العميل';

  @override
  String get ai_var_return => 'وقت العودة';

  @override
  String get ai_save => 'حفظ';

  @override
  String get ai_delay => 'مهلة الرد التلقائي';

  @override
  String get ai_delay_instant => 'فوري';

  @override
  String get ai_delay_30s => 'بعد 30 ث';

  @override
  String get ai_delay_1m => 'بعد دقيقة';

  @override
  String get ai_delay_2m => 'بعد دقيقتين';

  @override
  String get ai_delay_note =>
      'المهلة تتيح للموظفين الرد أولًا في وضع الرد التلقائي';

  @override
  String get ai_perf => 'الأداء';

  @override
  String get ai_perf_resolution => 'معدل الإجابة دون تحويل';

  @override
  String get ai_perf_rating => 'التقييم الإيجابي';

  @override
  String get ai_perf_unanswered => 'أسئلة بلا إجابة';

  @override
  String get ai_perf_detail => 'عرض الأداء التفصيلي';

  @override
  String get ai_perf_week => 'هذا الأسبوع';

  @override
  String get ai_perf_answered => 'أجاب';

  @override
  String get ai_perf_handoffs => 'تحويلات';

  @override
  String get ai_perf_reasons => 'أكثر أسباب التحويل';

  @override
  String get ai_perf_sources => 'أكثر المصادر استخدامًا';

  @override
  String get ai_perf_none => 'لا بيانات بعد';

  @override
  String get ai_reason_human_request => 'طلب موظف';

  @override
  String get ai_reason_complaint => 'شكوى';

  @override
  String get ai_reason_payment => 'دفع أو استرجاع';

  @override
  String get ai_reason_no_answer => 'لا توجد إجابة';

  @override
  String get ai_reason_low_confidence => 'ثقة منخفضة';

  @override
  String get ai_reason_after_replies => 'ردود دون حل';

  @override
  String ai_reason_keyword(String word) {
    return 'كلمة محددة: $word';
  }

  @override
  String get ai_reason_other => 'سبب آخر';

  @override
  String get ai_advanced => 'متقدم';

  @override
  String get ai_channels => 'القنوات المفعّلة';

  @override
  String get ai_channels_none => 'لا قنوات';

  @override
  String get ai_channel_whatsapp => 'واتساب';

  @override
  String get ai_channel_web => 'الموقع';

  @override
  String get ai_channel_messenger => 'ماسنجر';

  @override
  String get ai_instructions => 'تعليمات إضافية';

  @override
  String get ai_instructions_ph =>
      'مثال: لا تذكر أسعار الجملة، واطلب رقم الطلب دائمًا قبل الإجابة عن الشحن';

  @override
  String get ai_instructions_empty => 'بدون';

  @override
  String get ai_outside_kb => 'الإجابة من خارج قاعدة المعرفة';

  @override
  String get ai_outside_kb_sub => 'غير مستحسن — قد يجيب بمعلومات غير دقيقة';

  @override
  String get ai_confidence => 'حد الثقة للإرسال التلقائي';

  @override
  String get ai_conf_low => 'منخفض';

  @override
  String get ai_conf_med => 'متوسط';

  @override
  String get ai_conf_high => 'مرتفع';

  @override
  String get ai_conf_low_sub => 'يرسل أغلب الردود تلقائيًا';

  @override
  String get ai_conf_med_sub => 'توازن بين السرعة والدقة';

  @override
  String get ai_conf_high_sub =>
      'يرسل فقط الردود المؤكدة، والباقي اقتراح أو تحويل';

  @override
  String get ai_team_styles => 'أساليب إعادة الصياغة للفريق';

  @override
  String get ai_style_add => 'إضافة أسلوب';

  @override
  String get ai_style_name => 'اسم الأسلوب';

  @override
  String get ai_style_instruction => 'التعليمات';

  @override
  String get ai_style_delete => 'حذف';

  @override
  String get ai_styles_empty => 'لا أساليب بعد';

  @override
  String get ai_audit => 'سجل التغييرات';

  @override
  String ai_audit_row(String fields) {
    return 'غيّر $fields';
  }

  @override
  String get ai_audit_empty => 'لا تغييرات بعد';

  @override
  String get ai_test => 'اختبر الوكيل بمحادثة تجريبية';

  @override
  String get ai_test_title => 'محادثة تجريبية';

  @override
  String get ai_test_sub => 'لن تُرسل لأي عميل';

  @override
  String get ai_test_info => 'أنت تتحدث كعميل. جرّب أسئلة عملائك الحقيقية.';

  @override
  String get ai_test_why => 'لماذا هذا الرد؟';

  @override
  String ai_test_handoff(String reason) {
    return 'في المحادثة الحقيقية سيتحوّل هنا للفريق: $reason';
  }

  @override
  String get ai_test_reset => 'إعادة البدء';

  @override
  String get ai_test_channel => 'تغيير القناة';

  @override
  String get ai_test_p1 => 'كم سعر التوصيل؟';

  @override
  String get ai_test_p2 => 'أبي أرجّع طلبي';

  @override
  String get ai_test_p3 => 'متى تفتحون؟';

  @override
  String get ai_test_p4 => 'أبي أكلم موظف';

  @override
  String get ai_test_hint => 'اكتب سؤالك كعميل…';

  @override
  String get ai_test_label => 'الذكاء';

  @override
  String get ai_test_error => 'تعذّر الحصول على رد. حاول مرة أخرى.';

  @override
  String get ai_test_unsaved => 'لديك تعديلات غير محفوظة على ساعات العمل';

  @override
  String get ai_why_sources => 'المصادر';

  @override
  String get ai_why_no_sources => 'لم يستخدم مصادر من قاعدة المعرفة';

  @override
  String get ai_why_confidence => 'الثقة';

  @override
  String get ai_why_rule => 'القاعدة';

  @override
  String get ai_why_tone => 'النبرة';

  @override
  String get ai_off_title => 'إيقاف الذكاء الاصطناعي؟';

  @override
  String get ai_off_body =>
      'سيتوقف عن الرد والاقتراح في كل المحادثات. المحادثات التي يتولاها الآن ستتحوّل للفريق.';

  @override
  String ai_off_handling(String n) {
    return '$n محادثات يتولاها الآن';
  }

  @override
  String get ai_off_confirm => 'إيقاف';

  @override
  String get ai_cancel => 'إلغاء';

  @override
  String get ai_kb_first_title => 'أضف قاعدة المعرفة أولًا';

  @override
  String get ai_kb_first_body =>
      'يجيب الذكاء فقط من معلوماتك. أضف 10 إجابات على الأقل ليبدأ.';

  @override
  String get ai_kb_add => 'إضافة إجابات';

  @override
  String get ai_enable_suggest => 'فعّله لوضع الاقتراح فقط';

  @override
  String get ai_auto_title => 'سيرد الذكاء على عملائك مباشرة';

  @override
  String get ai_auto_b1 => 'يجيب فقط من قاعدة المعرفة';

  @override
  String get ai_auto_b2 => 'يحوّل للفريق حسب قواعد التحويل';

  @override
  String get ai_auto_b3 => 'يمكنك إيقافه في أي وقت';

  @override
  String get ai_auto_tested => 'جرّبت الوكيل بمحادثة تجريبية';

  @override
  String get ai_auto_try => 'جرّب الآن';

  @override
  String get ai_auto_confirm => 'تفعيل الرد التلقائي';

  @override
  String get ai_outside_title => 'السماح بالإجابة من خارج قاعدة المعرفة؟';

  @override
  String get ai_outside_body =>
      'قد يقدّم الذكاء معلومات غير صحيحة عن منتجاتك أو أسعارك.';

  @override
  String get ai_allow => 'سماح';

  @override
  String get ai_plan_off => 'ميزة الذكاء الاصطناعي غير متاحة في خطتك';

  @override
  String get ai_view_plans => 'عرض الخطط';

  @override
  String ai_quota_out(String date) {
    return 'انتهت ردود هذا الشهر — يعمل كاقتراح فقط حتى $date';
  }

  @override
  String get ai_save_failed => 'تعذّر حفظ التغيير';

  @override
  String get ai_retry => 'إعادة المحاولة';

  @override
  String ai_conflict(String name) {
    return 'عدّل $name الإعدادات للتو';
  }

  @override
  String get ai_conflict_anon => 'عدّل شخص آخر الإعدادات للتو';

  @override
  String get ai_offline => 'التعديل يتطلب اتصالًا بالإنترنت';

  @override
  String get ai_load_error => 'تعذّر تحميل إعدادات الذكاء الاصطناعي';

  @override
  String get ai_saved => 'تم الحفظ';

  @override
  String get ai_hours_247 => 'العمل على مدار الساعة';

  @override
  String get ai_hours_closed => 'مغلق';

  @override
  String get ai_hours_add_range => '+ فترة';

  @override
  String get ai_hours_copy_all => 'نسخ إلى كل الأيام';

  @override
  String get ai_hours_timezone => 'المنطقة الزمنية';

  @override
  String get ai_hours_holidays => 'العطل الرسمية';

  @override
  String get ai_hours_err_order => 'يجب أن يكون وقت الانتهاء بعد البداية';

  @override
  String get ai_hours_err_overlap => 'الفترات متداخلة';

  @override
  String get ai_hours_err_max => 'فترتان كحد أقصى';

  @override
  String get ai_hours_start => 'من';

  @override
  String get ai_hours_end => 'إلى';

  @override
  String get ai_hours_discard => 'تجاهل التعديلات؟';

  @override
  String get ai_hours_discard_body => 'لم تحفظ ساعات العمل بعد.';

  @override
  String get ai_hours_discard_confirm => 'تجاهل';

  @override
  String get ai_day_sat => 'السبت';

  @override
  String get ai_day_sun => 'الأحد';

  @override
  String get ai_day_mon => 'الاثنين';

  @override
  String get ai_day_tue => 'الثلاثاء';

  @override
  String get ai_day_wed => 'الأربعاء';

  @override
  String get ai_day_thu => 'الخميس';

  @override
  String get ai_day_fri => 'الجمعة';

  @override
  String get ai_ho_intro =>
      'يحوّل الذكاء المحادثة للفريق تلقائيًا في هذه الحالات:';

  @override
  String get ai_ho_human => 'العميل يطلب التحدث مع موظف';

  @override
  String get ai_ho_always => 'دائمًا مفعّلة';

  @override
  String get ai_ho_complaint => 'شكوى أو عميل غاضب';

  @override
  String get ai_ho_payment => 'موضوع دفع أو استرجاع مبالغ';

  @override
  String get ai_ho_no_answer => 'لم يجد إجابة في قاعدة المعرفة';

  @override
  String get ai_ho_low_conf => 'ثقة منخفضة في الإجابة';

  @override
  String ai_ho_after_n(String n) {
    return 'بعد $n ردود دون حل';
  }

  @override
  String get ai_ho_keywords => 'كلمات محددة';

  @override
  String get ai_ho_keyword_add => 'أضف كلمة…';

  @override
  String get ai_ho_target => 'إلى من يُحوّل؟';

  @override
  String get ai_ho_target_unassigned => 'غير مُسندة (أول من يستلم)';

  @override
  String get ai_ho_target_team => 'فريق محدد';

  @override
  String get ai_ho_target_last => 'آخر موظف تعامل مع العميل';

  @override
  String get ai_ho_after_hours => 'خارج الدوام';

  @override
  String get ai_ho_tell_return => 'يخبر العميل بموعد العودة';

  @override
  String get ai_ho_notify => 'يحوّل ويرسل إشعارًا للفريق';

  @override
  String get ai_mode_hybrid => 'هجين';

  @override
  String get ai_mode_hybrid_sub => 'يمزج بين الاقتراح والرد التلقائي';

  @override
  String get ai_replies => 'الردود';

  @override
  String get ai_suggestions => 'عدد الاقتراحات لكل رسالة';

  @override
  String get ai_suggestions_sub =>
      'كم اقتراح رد يقدّمه الذكاء الاصطناعي في كل مرة.';

  @override
  String get ai_reply_claimed => 'الرد عندما يستلم موظف المحادثة';

  @override
  String get ai_reply_claimed_sub =>
      'عند الإيقاف: يتوقف الذكاء الاصطناعي بمجرد أن يستلم شخص المحادثة.';

  @override
  String get ai_keywords => 'كلمات التحويل';

  @override
  String get ai_keywords_sub =>
      'عندما يكتب العميل إحدى هذه الكلمات، تُحوَّل المحادثة إلى موظف.';

  @override
  String get ai_keywords_none => 'لا توجد';

  @override
  String ai_keywords_count(int n) {
    return '$n كلمات';
  }

  @override
  String get ai_keywords_empty => 'لا توجد كلمات بعد.';

  @override
  String get ai_keywords_hint => 'أضف كلمة، مثل: مدير';

  @override
  String get ai_keywords_add => 'إضافة';

  @override
  String get ai_keywords_remove => 'حذف';

  @override
  String get ai_answer_source => 'مصدر الإجابات';

  @override
  String get ai_answer_source_kb => 'قاعدة المعرفة';

  @override
  String get ai_answer_source_kb_sub =>
      'يجيب الذكاء الاصطناعي من قاعدة المعرفة.';

  @override
  String get ai_answer_source_flow => 'تنظيم البوت';

  @override
  String get ai_answer_source_flow_sub =>
      'يتبع الذكاء الاصطناعي مسار البوت الذي أنشأته على الويب.';

  @override
  String get ai_lang_fr => 'الفرنسية';

  @override
  String get ai_lang_es => 'الإسبانية';

  @override
  String get ai_lang_pt => 'البرتغالية';

  @override
  String get ai_lang_de => 'الألمانية';

  @override
  String get ai_lang_it => 'الإيطالية';

  @override
  String get ai_mode_off => 'متوقف';

  @override
  String get ai_mode_off_sub => 'لا توجد ردود آلية';

  @override
  String get ai_mode_auto_info =>
      'في الوضع الذاتي يرسل الذكاء الاصطناعي الردود مباشرة دون مراجعة الوكيل. كلمات التصعيد توقف الذكاء الاصطناعي وتنبّه الوكلاء.';

  @override
  String get ai_mode_set_on_web => 'يُضبط من الموقع حاليًا';

  @override
  String get ai_mode_hybrid_on_web =>
      'اختر «هجين» على الموقع ثم عُد إلى التطبيق.';

  @override
  String get rw_title => 'حسّن الرد';

  @override
  String get rw_subtitle => 'اختر الأسلوب وسيعيد الذكاء الصياغة';

  @override
  String get rw_original => 'ردّك الأصلي';

  @override
  String get rw_edit => 'تعديل';

  @override
  String get rw_more => 'المزيد';

  @override
  String get rw_selection_hint => 'سيتم استبدال الجزء المحدد فقط';

  @override
  String get rw_style_professional => 'أكثر احترافية';

  @override
  String get rw_style_shorter => 'أقصر';

  @override
  String get rw_style_friendlier => 'أكثر ودًّا';

  @override
  String get rw_style_apology => 'اعتذار';

  @override
  String get rw_style_fix => 'صحّح الإملاء';

  @override
  String get rw_style_to_en => 'ترجم للإنجليزية';

  @override
  String get rw_style_to_ar => 'ترجم للعربية';

  @override
  String get rw_style_more => 'المزيد';

  @override
  String get rw_style_formal => 'رسمي جدًا';

  @override
  String get rw_style_saudi => 'بلهجة سعودية';

  @override
  String get rw_style_msa => 'بالفصحى';

  @override
  String get rw_style_greeting => 'أضف تحية وخاتمة';

  @override
  String get rw_style_bullets => 'حوّلها لنقاط';

  @override
  String get rw_style_sales => 'أكثر إقناعًا للبيع';

  @override
  String get rw_style_simple => 'أبسط وأوضح';

  @override
  String get rw_team_styles => 'أساليب فريقك';

  @override
  String rw_customer_prefers(String language) {
    return 'العميل يفضّل $language';
  }

  @override
  String get rw_result => 'الصياغة المقترحة';

  @override
  String get rw_writing => 'يعيد الصياغة…';

  @override
  String get rw_streaming => 'يكتب…';

  @override
  String get rw_edited => 'معدّلة يدويًا';

  @override
  String get rw_name_added => 'أُضيف اسم العميل';

  @override
  String get rw_fact_warning => 'تحقق: أضاف الذكاء معلومة غير موجودة في ردّك';

  @override
  String rw_chars(int n, String delta) {
    return '$n حرف ($delta)';
  }

  @override
  String get rw_over_limit => 'أطول من الحد المسموح للقناة';

  @override
  String get rw_show_diff => 'إظهار التغييرات';

  @override
  String get rw_hide_diff => 'إخفاء التغييرات';

  @override
  String get rw_use => 'استخدم هذا الرد';

  @override
  String get rw_use_as_is => 'استخدم الرد كما هو';

  @override
  String get rw_rerun => 'أعد الصياغة';

  @override
  String get rw_regenerate => 'صياغة أخرى';

  @override
  String get rw_max_versions => 'وصلت للحد الأقصى من المحاولات';

  @override
  String get rw_no_change => 'ردّك سليم، لا توجد تعديلات';

  @override
  String get rw_error => 'تعذّرت إعادة الصياغة';

  @override
  String get rw_retry => 'إعادة المحاولة';

  @override
  String rw_rate_limited(int n) {
    return 'وصلت لحد الاستخدام مؤقتًا، حاول بعد $n ث';
  }

  @override
  String get rw_plan_limit => 'ميزة إعادة الصياغة غير متاحة في خطتك';

  @override
  String get rw_view_plans => 'عرض الخطط';

  @override
  String get rw_blocked => 'لا يمكن إعادة صياغة هذا النص';

  @override
  String get rw_offline => 'تحتاج اتصالًا بالإنترنت';

  @override
  String get rw_too_long => 'النص طويل جدًا لإعادة الصياغة (الحد 2,000 حرف)';

  @override
  String get rw_empty_hint => 'اكتب ردًّا أولًا أو استخدم اقتراح الذكاء';

  @override
  String get rw_toolbar => 'حسّن بالذكاء';

  @override
  String get rw_lang_ar => 'العربية';

  @override
  String get rw_lang_en => 'الإنجليزية';

  @override
  String get rw_copy => 'نسخ';

  @override
  String get rw_copied => 'تم النسخ';

  @override
  String rw_a11y_ready(String text) {
    return 'الصياغة المقترحة جاهزة: $text';
  }

  @override
  String get rw_a11y_cached => 'تم إنشاؤها';

  @override
  String rw_a11y_version(int i, int n) {
    return 'الإصدار $i من $n';
  }

  @override
  String get rw_a11y_prev => 'السابق';

  @override
  String get rw_a11y_next => 'التالي';

  @override
  String get rw_a11y_edit_result => 'اضغط لتعديل الصياغة، واضغط مطولًا للنسخ';

  @override
  String get as_title => 'إسناد المحادثة';

  @override
  String as_title_bulk(int n) {
    return 'إسناد $n محادثات';
  }

  @override
  String as_current(String name) {
    return 'المسؤول الحالي: $name';
  }

  @override
  String get as_search => 'ابحث عن زميل أو فريق';

  @override
  String as_no_results(String q) {
    return 'لا نتائج لـ «$q»';
  }

  @override
  String get as_filter_all => 'الكل';

  @override
  String as_filter_available(int n) {
    return 'متاحون ($n)';
  }

  @override
  String get as_filter_my_team => 'فريقي';

  @override
  String get as_suggested => 'مقترح';

  @override
  String get as_teammates => 'الزملاء';

  @override
  String get as_teams => 'الفرق';

  @override
  String get as_ai_section => 'الذكاء الاصطناعي';

  @override
  String get as_me => 'أنا';

  @override
  String get as_badge_current => 'الحالي';

  @override
  String get as_badge_capacity => 'عند الحد';

  @override
  String get as_online_m => 'متاح';

  @override
  String get as_online_f => 'متاحة';

  @override
  String get as_busy_m => 'مشغول';

  @override
  String get as_busy_f => 'مشغولة';

  @override
  String get as_away => 'غير متاح';

  @override
  String as_last_seen(String t) {
    return 'آخر ظهور منذ $t';
  }

  @override
  String as_open_count(int n) {
    return '$n محادثات مفتوحة';
  }

  @override
  String as_members(int n) {
    return '$n أعضاء';
  }

  @override
  String as_available_count(int n) {
    return '$n متاحون';
  }

  @override
  String get as_routing_least => 'يُسند لأقل زميل انشغالًا';

  @override
  String get as_routing_rr => 'يُسند بالتناوب';

  @override
  String get as_routing_manual => 'يبقى في قائمة الفريق';

  @override
  String get as_team_none_available =>
      'لا يوجد أحد متاح الآن — ستنتظر في قائمة الفريق';

  @override
  String get as_ai_name => 'وكيل الذكاء الاصطناعي';

  @override
  String get as_ai_sub => 'يرد تلقائيًا ويحوّل للفريق عند الحاجة';

  @override
  String get as_ai_unavailable => 'لا توجد قاعدة معرفة كافية';

  @override
  String get as_reason_handled => 'تعامل مع العميل سابقًا';

  @override
  String get as_reason_handled_f => 'تعاملت مع العميل سابقًا';

  @override
  String as_reason_skill(String skill) {
    return 'خبير $skill';
  }

  @override
  String as_reason_skill_f(String skill) {
    return 'خبيرة $skill';
  }

  @override
  String get as_reason_least => 'الأقل انشغالًا';

  @override
  String get as_note => 'ملاحظة للزميل (اختياري)';

  @override
  String get as_note_q1 => 'العميل ينتظر ردًا عاجلًا';

  @override
  String get as_note_q2 => 'موضوع دفع';

  @override
  String get as_note_q3 => 'يحتاج متابعة غدًا';

  @override
  String get as_pick => 'اختر زميلًا أو فريقًا';

  @override
  String as_assign_to(String name) {
    return 'إسناد إلى $name';
  }

  @override
  String get as_claim => 'استلم المحادثة';

  @override
  String get as_assign_ai => 'إسناد للذكاء الاصطناعي';

  @override
  String as_assign_bulk_to(int n, String name) {
    return 'إسناد $n محادثات إلى $name';
  }

  @override
  String get as_unassign => 'إلغاء الإسناد (إرجاعها لغير المُسندة)';

  @override
  String get as_busy_hint => 'مشغول الآن — قد يتأخر الرد';

  @override
  String get as_busy_hint_f => 'مشغولة الآن — قد يتأخر الرد';

  @override
  String get as_away_hint => 'غير متاح — سيصله إشعار';

  @override
  String get as_away_hint_f => 'غير متاحة — سيصلها إشعار';

  @override
  String as_capacity_reached(int max) {
    return 'وصل للحد الأقصى ($max)';
  }

  @override
  String get as_unavailable => 'غير متاح للإسناد';

  @override
  String as_taken_live(String name) {
    return 'استلمها $name للتو';
  }

  @override
  String as_reassign_to(String name) {
    return 'إعادة الإسناد إلى $name';
  }

  @override
  String get as_offline => 'الإسناد يتطلب اتصالًا بالإنترنت';

  @override
  String get as_none_available => 'لا يوجد زملاء متاحون الآن';

  @override
  String get as_show_all => 'عرض الكل';

  @override
  String as_done(String name) {
    return 'تم الإسناد إلى $name';
  }

  @override
  String as_done_bulk(int ok, int n) {
    return 'تم إسناد $ok من $n';
  }

  @override
  String get as_show_errors => 'عرض الأخطاء';

  @override
  String get as_undo => 'تراجع';

  @override
  String get as_forbidden => 'لا تملك صلاحية الإسناد لهذا الزميل';

  @override
  String get as_error => 'تعذّر الإسناد. حاول مجددًا.';

  @override
  String get as_retry => 'إعادة المحاولة';

  @override
  String as_event_assigned(String name) {
    return 'أسندت المحادثة إلى $name';
  }

  @override
  String as_event_undo(String actor) {
    return 'ألغى $actor الإسناد';
  }

  @override
  String get as_resolved_live => 'تم حلّ المحادثة';

  @override
  String as_queued_team(String team) {
    return 'في قائمة $team بانتظار الاستلام';
  }

  @override
  String get as_unassigned_done => 'أصبحت المحادثة غير مُسندة';

  @override
  String as_errors_title(int n) {
    return 'تعذّر إسناد $n';
  }

  @override
  String get as_err_same => 'مُسندة له بالفعل';

  @override
  String get as_err_resolved => 'المحادثة محلولة';

  @override
  String get as_err_state => 'تغيّر المسؤول';

  @override
  String get as_err_generic => 'خطأ غير متوقع';

  @override
  String as_expand_team(String team) {
    return 'عرض أعضاء $team';
  }

  @override
  String get as_a11y_selected => 'محدد';

  @override
  String get as_load_error => 'تعذّر تحميل الزملاء';

  @override
  String get login_title => 'أهلًا بعودتك';

  @override
  String get login_subtitle => 'سجّل دخولك لمتابعة محادثات عملائك من أي مكان.';

  @override
  String get login_identifier_label => 'البريد الإلكتروني أو الجوال';

  @override
  String get login_identifier_hint => 'name@company.com';

  @override
  String get login_password_label => 'كلمة المرور';

  @override
  String get login_password_show => 'إظهار كلمة المرور';

  @override
  String get login_password_hide => 'إخفاء كلمة المرور';

  @override
  String get login_forgot => 'نسيت كلمة المرور؟';

  @override
  String get login_submit => 'تسجيل الدخول';

  @override
  String get login_or => 'أو';

  @override
  String get login_biometric_face => 'الدخول ببصمة الوجه';

  @override
  String get login_biometric_finger => 'الدخول بالبصمة';

  @override
  String get login_biometric_reason => 'سجّل الدخول إلى Wavadesk';

  @override
  String get login_biometric_locked =>
      'تم إيقاف البصمة مؤقتًا، استخدم كلمة المرور';

  @override
  String get login_no_account => 'ليس لديك حساب؟';

  @override
  String get login_start_trial => 'ابدأ تجربة 7 أيام مجانًا';

  @override
  String get login_offline => 'غير متصل بالإنترنت';

  @override
  String get login_err_invalid => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get login_err_disabled =>
      'تم إيقاف هذا الحساب. تواصل مع مدير مساحة العمل.';

  @override
  String get login_err_suspended => 'اشتراك مساحة العمل متوقف.';

  @override
  String get login_manage_subscription => 'إدارة الاشتراك';

  @override
  String login_err_locked(String time) {
    return 'محاولات كثيرة. حاول بعد $time.';
  }

  @override
  String get login_err_network =>
      'تعذّر الاتصال. تحقّق من الإنترنت وحاول مجددًا.';

  @override
  String get login_err_server => 'حدث خطأ من جهتنا. حاول مجددًا بعد قليل.';

  @override
  String get login_retry => 'إعادة المحاولة';

  @override
  String get login_val_identifier_required =>
      'أدخل بريدك الإلكتروني أو رقم جوالك';

  @override
  String get login_val_email_invalid => 'صيغة البريد غير صحيحة';

  @override
  String get login_val_phone_invalid => 'رقم الجوال غير صحيح';

  @override
  String get login_val_password_required => 'أدخل كلمة المرور';

  @override
  String get login_val_password_short => 'كلمة المرور 8 أحرف على الأقل';

  @override
  String get login_bio_sheet_title => 'سجّل دخولك أسرع في المرة القادمة';

  @override
  String get login_bio_sheet_body => 'استخدم بصمة الوجه بدل كلمة المرور.';

  @override
  String get login_bio_sheet_body_finger =>
      'استخدم بصمة الإصبع بدل كلمة المرور.';

  @override
  String get login_bio_sheet_enable => 'تفعيل بصمة الوجه';

  @override
  String get login_bio_sheet_enable_finger => 'تفعيل البصمة';

  @override
  String get login_bio_sheet_later => 'ليس الآن';

  @override
  String get auth_coming_soon_title => 'قريبًا';

  @override
  String get auth_forgot_placeholder =>
      'استعادة كلمة المرور ستتوفر في تحديث قادم.';

  @override
  String auth_forgot_placeholder_for(String identifier) {
    return 'استعادة كلمة المرور لـ $identifier ستتوفر في تحديث قادم.';
  }

  @override
  String get auth_2fa_title => 'رمز التحقق';

  @override
  String get auth_2fa_placeholder =>
      'إدخال رمز التحقق الثنائي سيتوفر في تحديث قادم.';

  @override
  String get auth_workspace_title => 'اختر مساحة العمل';

  @override
  String get auth_workspace_placeholder =>
      'حسابك مرتبط بأكثر من مساحة عمل. اختيار المساحة سيتوفر في تحديث قادم.';

  @override
  String get chat_ai_suggestion => 'اقتراح الذكاء الاصطناعي';

  @override
  String chat_ai_source(String title) {
    return 'من: $title';
  }

  @override
  String get chat_ai_send => 'إرسال';

  @override
  String get chat_ai_edit => 'تعديل';

  @override
  String get chat_ai_more => 'المزيد';

  @override
  String get chat_ai_low_conf => 'تأكد من الرد قبل الإرسال';

  @override
  String get chat_ai_writing => 'يكتب الاقتراح…';

  @override
  String get chat_ai_no_answer => 'لم يجد الذكاء إجابة في قاعدة المعرفة';

  @override
  String get chat_ai_add_answer => 'أضف إجابة';

  @override
  String get chat_ai_ready_pill => 'اقتراح جاهز';

  @override
  String get chat_placeholder => 'اكتب ردًّا…';

  @override
  String get chat_note_placeholder => 'اكتب ملاحظة لفريقك — لن يراها العميل';

  @override
  String get chat_mode_reply => 'رد';

  @override
  String get chat_mode_note => 'ملاحظة داخلية';

  @override
  String get chat_attach_media => 'صورة/فيديو';

  @override
  String get chat_attach_camera => 'كاميرا';

  @override
  String get chat_attach_file => 'ملف';

  @override
  String get chat_attach_location => 'موقع';

  @override
  String get chat_attach_quick => 'ردود سريعة';

  @override
  String get chat_attach_template => 'قالب واتساب';

  @override
  String get chat_attach_product => 'منتج';

  @override
  String get chat_record_cancel_hint => 'اسحب للإلغاء';

  @override
  String get chat_claim => 'استلم المحادثة';

  @override
  String get chat_assign_colleague => 'إسناد لزميل';

  @override
  String chat_viewing_now(String name) {
    return '$name تشاهد هذه المحادثة الآن';
  }

  @override
  String get chat_waiting_claim => 'بانتظار الاستلام';

  @override
  String chat_claimed_before(String name) {
    return 'استلمها $name قبلك';
  }

  @override
  String chat_ro_colleague(String name) {
    return 'مُسندة إلى $name';
  }

  @override
  String get chat_ro_request => 'اطلب التحويل';

  @override
  String get chat_ro_resolved => 'المحادثة محلولة';

  @override
  String get chat_reopen => 'إعادة الفتح';

  @override
  String get chat_ro_ai => 'الذكاء الاصطناعي يتولى هذه المحادثة';

  @override
  String get chat_take_over => 'تولَّ المحادثة';

  @override
  String get chat_ro_blocked => 'هذا العميل محظور';

  @override
  String get chat_unblock => 'إلغاء الحظر';

  @override
  String get chat_ro_past => 'محادثة سابقة — للقراءة فقط';

  @override
  String get chat_banner_offline => 'غير متصل — ستُرسل رسائلك عند عودة الاتصال';

  @override
  String get chat_banner_window_closed =>
      'انتهت نافذة 24 ساعة — يمكنك إرسال قالب معتمد فقط';

  @override
  String get chat_choose_template => 'اختر قالبًا';

  @override
  String chat_banner_window_soon(String t) {
    return 'تنتهي نافذة الرد خلال $t';
  }

  @override
  String get chat_banner_channel_down => 'واتساب غير متصل — لن تصل الرسائل';

  @override
  String get chat_reconnect => 'إعادة الربط';

  @override
  String chat_snoozed_until(String t) {
    return 'مؤجلة حتى $t';
  }

  @override
  String get chat_unsnooze => 'إلغاء التأجيل';

  @override
  String get composer_attach => 'إرفاق';

  @override
  String get composer_send => 'إرسال';

  @override
  String get composer_send_note => 'إرسال الملاحظة';

  @override
  String get composer_record => 'اضغط مطولًا لتسجيل رسالة صوتية';

  @override
  String get composer_recording => 'جارٍ التسجيل';

  @override
  String get composer_record_stop => 'إيقاف';

  @override
  String get composer_record_send => 'إرسال التسجيل';

  @override
  String get composer_record_cancelled => 'أُلغي التسجيل';

  @override
  String get composer_record_locked => 'التسجيل مستمر بدون ضغط';

  @override
  String get composer_record_slide_up => 'اسحب للأعلى للتثبيت';

  @override
  String get composer_ai_rewrite => 'حسّن الرد بالذكاء الاصطناعي';

  @override
  String get composer_saved_replies => 'الردود المحفوظة';

  @override
  String get composer_field_label => 'اكتب ردًّا';

  @override
  String get composer_note_field_label => 'اكتب ملاحظة داخلية';

  @override
  String get composer_template => 'قالب';

  @override
  String get composer_template_only => 'النافذة مغلقة — أرسل قالبًا معتمدًا';

  @override
  String composer_colleague_typing_note(String name) {
    return '$name يكتب ملاحظة…';
  }

  @override
  String composer_colleague_viewing(String name) {
    return '$name يشاهد أيضًا';
  }

  @override
  String get composer_quick_title => 'ردود سريعة';

  @override
  String get composer_quick_empty => 'لا توجد ردود سريعة مطابقة';

  @override
  String get composer_mention_title => 'اذكر زميلًا';

  @override
  String composer_reply_to(String name) {
    return 'رد على $name';
  }

  @override
  String get composer_cancel_reply => 'إلغاء الرد';

  @override
  String get composer_remove_attachment => 'إزالة المرفق';

  @override
  String composer_uploading(int percent) {
    return 'جارٍ الرفع $percent٪';
  }

  @override
  String get composer_customer => 'العميل';

  @override
  String get composer_location_sample => 'حي الملقا، الرياض';

  @override
  String get aicard_close => 'طي الاقتراح';

  @override
  String get aicard_regenerate => 'إعادة إنشاء الاقتراح';

  @override
  String get aicard_less => 'أقل';

  @override
  String get aicard_open_pill => 'عرض اقتراح الذكاء الاصطناعي';

  @override
  String claimbar_waiting_minutes(int n) {
    return '$n د';
  }

  @override
  String claimbar_viewers_more(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count زميلًا آخر',
      few: '$count زملاء آخرين',
      two: 'زميلان آخران',
      one: 'زميل آخر',
    );
    return '$name و$_temp0 يشاهدون المحادثة';
  }

  @override
  String get readonly_take_instead => 'استلم بدلًا عنه';

  @override
  String get readonly_add_note => 'إضافة ملاحظة داخلية';

  @override
  String get banner_connecting => 'جارٍ الاتصال…';

  @override
  String get composer_mic_denied =>
      'اسمح بالوصول إلى الميكروفون من الإعدادات لتسجيل الرسائل الصوتية.';

  @override
  String get composer_record_failed => 'تعذّر التسجيل. حاول مرة أخرى.';

  @override
  String get composer_record_delete => 'حذف التسجيل';

  @override
  String get chat_ai_suggest_pill => 'اقترح ردًا';

  @override
  String composer_file_too_big(String names) {
    return 'حجم كبير لا يمكن إرساله: $names. الصور حتى 5 ميجابايت، والفيديو والصوت 16، والمستندات 10.';
  }

  @override
  String composer_file_type(String names) {
    return 'لا يمكن إرسال هذا النوع من الملفات: $names';
  }

  @override
  String get composer_upload_failed => 'فشل الرفع';

  @override
  String get composer_upload_retry => 'إعادة الرفع';

  @override
  String sys_called(String actor) {
    return 'اتصل $actor بالعميل';
  }

  @override
  String get sys_called_me => 'اتصلت بالعميل';

  @override
  String get snooze_title => 'تأجيل المحادثة';

  @override
  String get snooze_one_hour => 'بعد ساعة';

  @override
  String get snooze_three_hours => 'بعد 3 ساعات';

  @override
  String get snooze_tomorrow => 'غدًا 9 ص';

  @override
  String get snooze_next_week => 'الأسبوع القادم';

  @override
  String get snooze_custom => 'مخصص';

  @override
  String sys_claimed(String actor) {
    return 'استلم $actor المحادثة';
  }

  @override
  String get sys_claimed_me => 'استلمت المحادثة';

  @override
  String sys_assigned(String actor, String target) {
    return 'أسند $actor المحادثة إلى $target';
  }

  @override
  String sys_assigned_me(String target) {
    return 'أسندت المحادثة إلى $target';
  }

  @override
  String sys_unassigned(String actor) {
    return 'حرّر $actor المحادثة';
  }

  @override
  String get sys_unassigned_me => 'حرّرت المحادثة';

  @override
  String sys_ai_handoff(String reason) {
    return 'حوّل الذكاء الاصطناعي المحادثة للفريق: $reason';
  }

  @override
  String sys_ai_paused(String actor) {
    return 'أوقف $actor الذكاء الاصطناعي لهذه المحادثة';
  }

  @override
  String get sys_ai_paused_me => 'أوقفت الذكاء الاصطناعي لهذه المحادثة';

  @override
  String sys_ai_resumed(String actor) {
    return 'فعّل $actor الذكاء الاصطناعي لهذه المحادثة';
  }

  @override
  String get sys_ai_resumed_me => 'فعّلت الذكاء الاصطناعي لهذه المحادثة';

  @override
  String sys_resolved(String actor) {
    return 'حلّ $actor المحادثة';
  }

  @override
  String get sys_resolved_me => 'حللت المحادثة';

  @override
  String get sys_reopened => 'أُعيد فتح المحادثة';

  @override
  String sys_snoozed(String actor, String time) {
    return 'أجّل $actor المحادثة حتى $time';
  }

  @override
  String sys_snoozed_me(String time) {
    return 'أجّلت المحادثة حتى $time';
  }

  @override
  String sys_priority(String actor, String value) {
    return 'غيّر $actor الأولوية إلى $value';
  }

  @override
  String sys_priority_me(String value) {
    return 'غيّرت الأولوية إلى $value';
  }

  @override
  String sys_tag_added(String actor, String tag) {
    return 'أضاف $actor وسم «$tag»';
  }

  @override
  String sys_tag_added_me(String tag) {
    return 'أضفت وسم «$tag»';
  }

  @override
  String get sys_window_closed => 'انتهت نافذة الرد 24 ساعة';

  @override
  String sys_blocked(String actor) {
    return 'حظر $actor هذا العميل';
  }

  @override
  String get sys_blocked_me => 'حظرت هذا العميل';

  @override
  String sys_unblocked(String actor) {
    return 'ألغى $actor حظر هذا العميل';
  }

  @override
  String get sys_unblocked_me => 'ألغيت حظر هذا العميل';

  @override
  String sys_started(String channel) {
    return 'بدأت المحادثة عبر $channel';
  }

  @override
  String get msgaction_add_to_profile => 'إضافة لملف العميل';

  @override
  String get msgaction_added_to_profile => 'أُضيفت الملاحظة إلى ملف العميل';

  @override
  String chat_new_messages(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n رسالة جديدة',
      few: '$n رسائل جديدة',
      two: 'رسالتان جديدتان',
      one: 'رسالة جديدة',
    );
    return '$_temp0';
  }

  @override
  String get chat_ai_reply_label => 'ردّ الذكاء الاصطناعي';

  @override
  String chat_note_label(String name) {
    return 'ملاحظة داخلية · $name';
  }

  @override
  String get chat_failed => 'لم تُرسل';

  @override
  String get chat_retry => 'إعادة المحاولة';

  @override
  String get chat_delete => 'حذف';

  @override
  String get chat_edited => 'معدّلة';

  @override
  String get chat_deleted => 'تم حذف هذه الرسالة';

  @override
  String get chat_unsupported => 'نوع رسالة غير مدعوم — افتحها في واتساب';

  @override
  String get chat_transcribe => 'تحويل لنص';

  @override
  String bubble_template_label(String name) {
    return 'قالب: $name';
  }

  @override
  String get bubble_show_all => 'عرض الكل';

  @override
  String get bubble_show_less => 'عرض أقل';

  @override
  String get bubble_save_contact => 'حفظ';

  @override
  String get bubble_contact_saved => 'تم حفظ جهة الاتصال';

  @override
  String get bubble_play => 'تشغيل الرسالة الصوتية';

  @override
  String get bubble_pause => 'إيقاف الرسالة الصوتية مؤقتًا';

  @override
  String bubble_speed(String speed) {
    return 'سرعة التشغيل $speed';
  }

  @override
  String bubble_voice_summary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'رسالة صوتية $n ثانية',
      few: 'رسالة صوتية $n ثوانٍ',
      two: 'رسالة صوتية ثانيتان',
      one: 'رسالة صوتية ثانية واحدة',
    );
    return '$_temp0';
  }

  @override
  String bubble_image_from(String name) {
    return 'صورة من $name';
  }

  @override
  String bubble_album_summary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n صورة',
      few: '$n صور',
      two: 'صورتان',
    );
    return '$_temp0';
  }

  @override
  String bubble_video_summary(String duration) {
    return 'فيديو $duration';
  }

  @override
  String get bubble_play_video => 'تشغيل الفيديو';

  @override
  String get bubble_video_unavailable =>
      'معاينة الفيديو غير متاحة في البيانات التجريبية';

  @override
  String get bubble_download => 'تنزيل الملف';

  @override
  String get bubble_downloaded => 'تم تنزيل الملف';

  @override
  String get bubble_open_maps => 'فتح الموقع في الخرائط';

  @override
  String get bubble_transcribing => 'جارٍ التحويل إلى نص…';

  @override
  String get bubble_transcript => 'النص';

  @override
  String get bubble_delivery_sending => 'قيد الإرسال';

  @override
  String get bubble_delivery_sent => 'أُرسلت';

  @override
  String get bubble_delivery_delivered => 'تم التسليم';

  @override
  String get bubble_delivery_read => 'تمت القراءة';

  @override
  String bubble_reply_to(String name) {
    return 'رد على $name';
  }

  @override
  String get bubble_viewer_share => 'مشاركة';

  @override
  String get bubble_viewer_save => 'حفظ';

  @override
  String get bubble_viewer_sample =>
      'هذه صورة تجريبية ولا يمكن مشاركتها أو حفظها';

  @override
  String bubble_reactions(String emojis) {
    return 'التفاعلات: $emojis';
  }

  @override
  String get chatlist_jump_latest => 'الانتقال إلى أحدث رسالة';

  @override
  String get chatlist_loading_older => 'جارٍ تحميل الرسائل الأقدم';

  @override
  String get chatlist_typing => 'يكتب الآن…';

  @override
  String get msgaction_reply => 'رد';

  @override
  String get msgaction_copy => 'نسخ';

  @override
  String get msgaction_copied => 'تم نسخ الرسالة';

  @override
  String get msgaction_forward => 'إعادة توجيه';

  @override
  String get msgaction_forward_soon => 'إعادة التوجيه ستتوفر قريبًا';

  @override
  String get msgaction_save_kb => 'حفظ في قاعدة المعرفة';

  @override
  String get msgaction_info => 'معلومات';

  @override
  String get msgaction_info_title => 'معلومات الرسالة';

  @override
  String get msgaction_info_sent => 'وقت الإرسال';

  @override
  String get msgaction_info_status => 'الحالة';

  @override
  String get msgaction_info_channel => 'القناة';

  @override
  String get msgaction_info_via => 'طريقة الإرسال';

  @override
  String get msgaction_via_manual => 'كتابة يدوية';

  @override
  String get msgaction_via_ai_suggestion => 'اقتراح الذكاء الاصطناعي';

  @override
  String get msgaction_via_ai_edited => 'اقتراح معدّل';

  @override
  String get msgaction_via_quick_reply => 'رد سريع';

  @override
  String get msgaction_via_template => 'قالب معتمد';

  @override
  String get msgaction_delete_title => 'حذف الرسالة؟';

  @override
  String get msgaction_delete_body =>
      'ستُحذف الرسالة لدى الجميع إن كانت القناة تسمح بذلك. لا يمكن التراجع.';

  @override
  String get msgaction_rate => 'تقييم الرد';

  @override
  String get msgaction_rate_up => 'رد مفيد';

  @override
  String get msgaction_rate_down => 'رد غير مفيد';

  @override
  String get msgaction_rated => 'شكرًا، سيتعلم الذكاء الاصطناعي من تقييمك';

  @override
  String get msgaction_more_reactions => 'المزيد من التفاعلات';

  @override
  String get msgaction_pick_reaction => 'اختر تفاعلًا';

  @override
  String msgaction_react(String emoji) {
    return 'تفاعل $emoji';
  }

  @override
  String get bubble_file_sending => 'ما زال قيد الإرسال، حاول بعد لحظات';

  @override
  String get bubble_file_unavailable => 'هذا الملف غير متاح على الهاتف';

  @override
  String bubble_saved(String name) {
    return 'تم الحفظ: $name';
  }

  @override
  String get bubble_save_failed => 'تعذّر تنزيل الملف. حاول مرة أخرى.';

  @override
  String get bubble_open_file => 'فتح';

  @override
  String get bubble_tap_retry => 'اضغط لإعادة المحاولة';

  @override
  String get bubble_photo_fetching => 'جارٍ جلب الصورة…';

  @override
  String get bubble_photo_unavailable => 'الصورة غير متاحة';

  @override
  String get chatscreen_load_failed => 'تعذّر تحميل المحادثة';

  @override
  String get chatscreen_not_found => 'لم نعثر على هذه المحادثة';

  @override
  String get chatscreen_action_failed => 'تعذّر تنفيذ الإجراء. حاول مجددًا.';

  @override
  String chatscreen_taken_from_me(String name) {
    return 'أُسندت المحادثة إلى $name';
  }

  @override
  String chatscreen_claimed_by(String name) {
    return 'استلمها $name';
  }

  @override
  String chatscreen_transfer_note(String name) {
    return '@$name أرجو تحويل هذه المحادثة إليّ لأتابعها.';
  }

  @override
  String chatscreen_transfer_sent(String name) {
    return 'أُرسل طلب التحويل إلى $name';
  }

  @override
  String get chatscreen_takeover_title => 'استلام المحادثة من زميل؟';

  @override
  String chatscreen_takeover_body(String name) {
    return 'ستُسند المحادثة إليك بدلًا من $name وسيصله إشعار بذلك.';
  }

  @override
  String get chatscreen_takeover_confirm => 'استلم بدلًا عنه';

  @override
  String get chat_online => 'متصل الآن';

  @override
  String chat_last_seen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get chat_typing => 'يكتب الآن…';

  @override
  String get chat_assigned_you => 'مُسندة لك';

  @override
  String chat_assigned_to(String name) {
    return 'مُسندة لـ$name';
  }

  @override
  String get chat_unassigned => 'غير مُسندة';

  @override
  String get chat_ai_handling => 'يتولاها الذكاء الاصطناعي';

  @override
  String get chat_resolve => 'حلّ المحادثة';

  @override
  String get chat_resolved_toast => 'تم حلّ المحادثة';

  @override
  String get chat_undo => 'تراجع';

  @override
  String chatbar_browsing(String page) {
    return 'يتصفح: $page';
  }

  @override
  String chatbar_back_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'رجوع، $n محادثة أخرى غير مقروءة',
      few: 'رجوع، $n محادثات أخرى غير مقروءة',
      two: 'رجوع، محادثتان أخريان غير مقروءتين',
      one: 'رجوع، محادثة أخرى غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String chatbar_open_profile(String name) {
    return 'فتح ملف $name';
  }

  @override
  String get chatbar_call => 'اتصال';

  @override
  String get chatbar_more => 'إجراءات المحادثة';

  @override
  String get chatbar_call_phone => 'اتصال هاتفي';

  @override
  String get chatbar_call_whatsapp => 'اتصال واتساب';

  @override
  String get chatbar_call_failed => 'تعذّر بدء الاتصال على هذا الجهاز';

  @override
  String strip_snoozed_until(String t) {
    return 'مؤجلة حتى $t';
  }

  @override
  String strip_order(String ref) {
    return 'طلب $ref';
  }

  @override
  String get strip_no_store_integration => 'لا يوجد تكامل مع المتجر بعد';

  @override
  String get strip_add_tag => 'وسم';

  @override
  String get snoozepick_subtitle => 'ستعود المحادثة إلى قائمتك في الوقت المحدد';

  @override
  String get templates_title => 'القوالب المعتمدة';

  @override
  String get templates_subtitle => 'قوالب واتساب الموافق عليها من Meta';

  @override
  String get templates_empty => 'لا توجد قوالب معتمدة بعد';

  @override
  String get templates_sent => 'تم إرسال القالب';

  @override
  String get actions_assign => 'إسناد';

  @override
  String get actions_change_owner => 'إسناد / تغيير المسؤول';

  @override
  String get actions_unassign => 'تحرير من المسؤولية';

  @override
  String get actions_unassigned_toast => 'أُعيدت المحادثة إلى غير المُسندة';

  @override
  String get actions_snooze => 'تأجيل';

  @override
  String get actions_snoozed_toast => 'أُجّلت المحادثة';

  @override
  String get actions_priority => 'الأولوية';

  @override
  String get actions_tag => 'إضافة وسم';

  @override
  String get actions_tag_subtitle => 'اختر الوسوم أو أضف وسمًا جديدًا';

  @override
  String get actions_tag_new_hint => 'وسم جديد';

  @override
  String get actions_tag_add => 'إضافة الوسم';

  @override
  String get actions_ai_pause => 'إيقاف الذكاء الاصطناعي لهذه المحادثة';

  @override
  String get actions_ai_resume => 'تفعيل الذكاء الاصطناعي لهذه المحادثة';

  @override
  String get actions_ai_paused_toast => 'أُوقف الذكاء الاصطناعي لهذه المحادثة';

  @override
  String get actions_ai_resumed_toast => 'فُعّل الذكاء الاصطناعي لهذه المحادثة';

  @override
  String get actions_mark_unread => 'وضع علامة غير مقروءة';

  @override
  String get actions_export => 'تصدير المحادثة';

  @override
  String get actions_export_note => 'ملاحظة داخلية';

  @override
  String get actions_exported_toast => 'نُسخ نص المحادثة، الصقه حيث تريد';

  @override
  String get actions_block => 'حظر العميل';

  @override
  String get actions_unblock => 'إلغاء حظر العميل';

  @override
  String actions_block_title(String name) {
    return 'حظر $name؟';
  }

  @override
  String get actions_block_body =>
      'لن تصلك رسائل هذا العميل وستُغلق المحادثة. يمكنك إلغاء الحظر لاحقًا.';

  @override
  String get actions_blocked_toast => 'تم حظر العميل';

  @override
  String get actions_unblocked_toast => 'تم إلغاء الحظر';

  @override
  String get close_title => 'إغلاق المحادثة';

  @override
  String get close_subtitle =>
      'عنوان قصير يساعد فريقك على العثور عليها لاحقًا.';

  @override
  String get close_field_label => 'العنوان';

  @override
  String get close_field_hint => 'مثال: استفسار عن التوصيل';

  @override
  String get close_ai_writing => 'جارٍ كتابة عنوان بالذكاء الاصطناعي…';

  @override
  String get close_ai_suggest => 'اقترح عنوانًا';

  @override
  String get close_ai_again => 'اقترح عنوانًا آخر';

  @override
  String get close_ai_unavailable =>
      'تعذّر اقتراح عنوان الآن. يمكنك كتابته بنفسك.';

  @override
  String get close_hint =>
      'يمكن للعميل المراسلة مجددًا، وأي رسالة جديدة تعيد فتح المحادثة.';

  @override
  String get close_confirm => 'إغلاق المحادثة';

  @override
  String get claim_button => 'استلم المحادثة';

  @override
  String get claim_button_hint => 'ستُسند إليك ويمكنك الرد';

  @override
  String get claim_region => 'استلام المحادثة';

  @override
  String get claim_assign_colleague => 'إسناد لزميل';

  @override
  String get claim_ai_takeover => 'تولَّ الذكاء الاصطناعي الرد';

  @override
  String get claim_ai_takeover_done => 'أُسندت المحادثة إلى الذكاء الاصطناعي';

  @override
  String get claim_waiting => 'بانتظار الاستلام';

  @override
  String claim_viewer_one_f(String name) {
    return '$name تشاهد هذه المحادثة الآن';
  }

  @override
  String claim_viewer_one_m(String name) {
    return '$name يشاهد هذه المحادثة الآن';
  }

  @override
  String claim_viewer_two(String a, String b) {
    return '$a و$b يشاهدان المحادثة';
  }

  @override
  String claim_viewer_many(String a, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$a و$n آخرون يشاهدون المحادثة',
      few: '$a و$n آخرون يشاهدون المحادثة',
      two: '$a وآخران يشاهدون المحادثة',
    );
    return '$_temp0';
  }

  @override
  String claim_viewing_since_sec(int n) {
    return 'منذ $n ث';
  }

  @override
  String claim_viewing_since_min(String t) {
    return 'منذ $t';
  }

  @override
  String claim_wait_sec(int n) {
    return '$n ث';
  }

  @override
  String claim_wait_min(int n) {
    return '$n د';
  }

  @override
  String claim_wait_hm(int h, int m) {
    return '$h س $m د';
  }

  @override
  String claim_a11y_wait_sec(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ينتظر منذ $n ثانية',
      few: 'ينتظر منذ $n ثوانٍ',
      two: 'ينتظر منذ ثانيتين',
      one: 'ينتظر منذ ثانية',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_min(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ينتظر منذ $n دقيقة',
      few: 'ينتظر منذ $n دقائق',
      two: 'ينتظر منذ دقيقتين',
      one: 'ينتظر منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_hm(int h, int m) {
    return 'ينتظر منذ $h ساعة و$m دقيقة';
  }

  @override
  String get claim_success_event => 'استلمت المحادثة';

  @override
  String claim_conflict(String name) {
    return 'استلمها $name قبلك';
  }

  @override
  String claim_taken_live(String name) {
    return 'استلم $name هذه المحادثة';
  }

  @override
  String claim_assigned_to_you(String name) {
    return 'أسند $name المحادثة إليك';
  }

  @override
  String claim_resolved_live(String name) {
    return 'حلّ $name المحادثة';
  }

  @override
  String get claim_network_error =>
      'تعذّر الاستلام. تحقّق من الاتصال وحاول مجددًا.';

  @override
  String get claim_retry => 'إعادة المحاولة';

  @override
  String get claim_forbidden => 'لا تملك صلاحية استلام هذه المحادثة';

  @override
  String claim_team_only(String team) {
    return 'هذه المحادثة لفريق $team';
  }

  @override
  String get claim_offline_hint => 'الاستلام يتطلب اتصالًا بالإنترنت';

  @override
  String claim_capacity_hint(int n, int max) {
    return 'لديك $n محادثات مفتوحة (الحد $max)';
  }

  @override
  String get claim_capacity_reached => 'وصلت للحد الأقصى من المحادثات';

  @override
  String get claim_away_title => 'حالتك الآن: غير متاح';

  @override
  String get claim_away_body => 'استلام المحادثة سيغيّر حالتك إلى «متاح».';

  @override
  String get claim_away_confirm => 'استلم وغيّر حالتي إلى متاح';

  @override
  String claim_capacity_title(int n) {
    return 'لديك $n محادثات مفتوحة';
  }

  @override
  String get claim_capacity_body => 'هل تريد استلام محادثة إضافية؟';

  @override
  String get claim_capacity_confirm => 'استلم على أي حال';

  @override
  String get claim_cancel => 'إلغاء';

  @override
  String claim_assigned_toast(String name) {
    return 'تم الإسناد إلى $name';
  }

  @override
  String get claim_undo => 'تراجع';

  @override
  String get claim_reply_placeholder => 'اكتب للاستلام والرد…';

  @override
  String get claim_short => 'استلم';

  @override
  String claim_handoff_event(String reason) {
    return 'حوّل الذكاء الاصطناعي المحادثة للفريق: $reason';
  }

  @override
  String get claim_reason_payment => 'موضوع دفع';

  @override
  String get claim_reason_human => 'طلب التحدث مع موظف';

  @override
  String get claim_reason_complaint => 'شكوى';

  @override
  String get claim_reason_no_answer => 'سؤال بلا إجابة';

  @override
  String get claim_reason_refund => 'طلب استرجاع';

  @override
  String get claim_reason_other => 'أخرى';

  @override
  String get claim_push_title => 'محادثة جديدة بانتظار الاستلام';

  @override
  String get claim_push_action => 'استلم';

  @override
  String claim_push_success(String customer) {
    return 'استلمت المحادثة مع $customer';
  }

  @override
  String get actions_add_note => 'إضافة ملاحظة داخلية';

  @override
  String claim_a11y_wait_span(String t) {
    return 'ينتظر منذ $t';
  }

  @override
  String get conversations_segment_mine => 'لي';

  @override
  String get conversations_segment_unassigned => 'غير مُسندة';

  @override
  String get conversations_segment_all => 'الكل';

  @override
  String get conversations_filter_all => 'الكل';

  @override
  String get conversations_filter_unread => 'غير مقروءة';

  @override
  String get conversations_filter_awaiting => 'بانتظار الرد';

  @override
  String get conversations_filter_ai => 'ردّ الذكاء';

  @override
  String get conversations_filter_closed => 'مغلقة';

  @override
  String get conversations_filter_more => 'فلاتر';

  @override
  String get conversations_channel_any => 'كل القنوات';

  @override
  String get conversations_priority_any => 'كل الأولويات';

  @override
  String get conversations_notifications => 'الإشعارات';

  @override
  String get conversations_new_message => 'رسالة جديدة';

  @override
  String get conversations_exit_selection => 'إلغاء التحديد';

  @override
  String conversations_selected_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محادثة محددة',
      few: '$count محادثات محددة',
      two: 'محادثتان محددتان',
      one: 'محادثة واحدة محددة',
    );
    return '$_temp0';
  }

  @override
  String get conversations_bulk_assign => 'إسناد المحدد';

  @override
  String get conversations_bulk_resolve => 'حلّ المحدد';

  @override
  String conversations_bulk_resolved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم حلّ $count محادثة',
      few: 'تم حلّ $count محادثات',
      two: 'تم حلّ محادثتين',
      one: 'تم حلّ محادثة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get conversations_resolved_snack => 'تم حلّ المحادثة';

  @override
  String get conversations_empty_mine_title => 'لا توجد محادثات مُسندة لك';

  @override
  String get conversations_empty_mine_body =>
      'استلم محادثة من غير المُسندة لتبدأ الرد.';

  @override
  String get conversations_empty_mine_action => 'عرض غير المُسندة';

  @override
  String get conversations_empty_filters_title => 'لا محادثات تطابق الفلاتر';

  @override
  String get conversations_empty_filters_body =>
      'جرّب تغيير الفلاتر أو مسحها لعرض كل المحادثات.';

  @override
  String get conversations_empty_filters_action => 'مسح الفلاتر';

  @override
  String get conversations_empty_done_title => 'أنهيت كل المحادثات';

  @override
  String get conversations_empty_done_body =>
      'لا يوجد ما ينتظرك الآن. سنُعلمك عند وصول رسالة جديدة.';

  @override
  String get tile_you_prefix => 'أنت: ';

  @override
  String get tile_ai_reply => 'ردّ الذكاء الاصطناعي';

  @override
  String get tile_ai_ready => 'اقتراح جاهز';

  @override
  String get tile_typing => 'يكتب…';

  @override
  String tile_snoozed_until(String time) {
    return 'مؤجلة حتى $time';
  }

  @override
  String tile_media_with_duration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String get tile_swipe_resolve => 'حلّ';

  @override
  String get tile_swipe_snooze => 'تأجيل';

  @override
  String get tile_swipe_assign => 'إسناد';

  @override
  String get filters_title => 'الفلاتر';

  @override
  String get filters_channel => 'القناة';

  @override
  String get filters_status => 'الحالة';

  @override
  String get filters_priority => 'الأولوية';

  @override
  String get filters_assignee => 'المُسند إليه';

  @override
  String get filters_assignee_all => 'الكل';

  @override
  String get filters_assignee_me => 'أنا';

  @override
  String get filters_assignee_colleague => 'زميل';

  @override
  String get filters_assignee_ai => 'الذكاء الاصطناعي';

  @override
  String get filters_assignee_unassigned => 'غير مُسندة';

  @override
  String get filters_date => 'التاريخ';

  @override
  String get filters_date_any => 'أي وقت';

  @override
  String get filters_date_today => 'اليوم';

  @override
  String get filters_date_7 => '7 أيام';

  @override
  String get filters_date_30 => '30 يومًا';

  @override
  String get filters_date_custom => 'مخصص';

  @override
  String get filters_tags => 'الوسوم';

  @override
  String filters_show(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض $count محادثة',
      few: 'عرض $count محادثات',
      two: 'عرض محادثتين',
      one: 'عرض محادثة واحدة',
      zero: 'لا توجد محادثات',
    );
    return '$_temp0';
  }

  @override
  String get newmsg_title => 'رسالة جديدة';

  @override
  String get newmsg_subtitle => 'ابدأ محادثة واتساب بقالب معتمد';

  @override
  String get newmsg_name => 'اسم العميل';

  @override
  String get newmsg_name_hint => 'اختياري';

  @override
  String get newmsg_phone => 'رقم الجوال';

  @override
  String get newmsg_phone_hint => '+966 5x xxx xxxx';

  @override
  String get newmsg_phone_error => 'أدخل رقم جوال صحيح مع رمز الدولة';

  @override
  String get newmsg_template => 'القالب';

  @override
  String get newmsg_template_error => 'اختر قالبًا معتمدًا للإرسال';

  @override
  String get newmsg_send => 'إرسال القالب';

  @override
  String get app_name => 'Wavadesk';

  @override
  String get tab_conversations => 'المحادثات';

  @override
  String get tab_dashboard => 'لوحة التحكم';

  @override
  String get tab_knowledge => 'المعرفة';

  @override
  String get tab_account => 'الحساب';

  @override
  String get channel_whatsapp => 'واتساب';

  @override
  String get channel_web => 'دردشة الموقع';

  @override
  String get channel_messenger => 'ماسنجر';

  @override
  String get channel_instagram => 'إنستغرام';

  @override
  String get channel_email => 'البريد الإلكتروني';

  @override
  String get channel_telegram => 'تيليغرام';

  @override
  String get channel_sms => 'رسائل SMS';

  @override
  String get channel_other => 'قناة أخرى';

  @override
  String get status_open => 'مفتوحة';

  @override
  String get status_pending => 'بانتظار العميل';

  @override
  String get status_waiting => 'بانتظار الرد';

  @override
  String get status_snoozed => 'مؤجلة';

  @override
  String get status_resolved => 'محلولة';

  @override
  String get status_closed => 'مغلقة';

  @override
  String get status_ai => 'يتولاها الذكاء';

  @override
  String get priority_urgent => 'عاجل';

  @override
  String get priority_high => 'عالية';

  @override
  String get priority_medium => 'متوسطة';

  @override
  String get priority_low => 'منخفضة';

  @override
  String get presence_online => 'متاح';

  @override
  String get presence_busy => 'مشغول';

  @override
  String get presence_away => 'غير متاح';

  @override
  String get role_admin => 'مدير';

  @override
  String get role_supervisor => 'مشرف';

  @override
  String get role_agent => 'موظف دعم';

  @override
  String get ownership_mine => 'مُسندة لك';

  @override
  String get ownership_unassigned => 'غير مُسندة';

  @override
  String ownership_colleague(String name) {
    return 'مُسندة لـ$name';
  }

  @override
  String get ownership_ai => 'يتولاها الذكاء الاصطناعي';

  @override
  String get media_image => 'صورة';

  @override
  String get media_voice => 'رسالة صوتية';

  @override
  String get media_file => 'ملف';

  @override
  String get media_location => 'موقع';

  @override
  String get media_album => 'ألبوم صور';

  @override
  String get media_video => 'فيديو';

  @override
  String get media_contact => 'جهة اتصال';

  @override
  String get media_sticker => 'ملصق';

  @override
  String get media_template => 'قالب';

  @override
  String get media_email => 'بريد إلكتروني';

  @override
  String get media_deleted => 'رسالة محذوفة';

  @override
  String get media_unsupported => 'رسالة غير مدعومة';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_undo => 'تراجع';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_close => 'إغلاق';

  @override
  String get common_back => 'رجوع';

  @override
  String get common_clear => 'مسح';

  @override
  String get common_done => 'تم';

  @override
  String get common_search => 'بحث';

  @override
  String get common_clear_search => 'مسح البحث';

  @override
  String get common_more => 'المزيد';

  @override
  String get common_edit => 'تعديل';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_confirm => 'تأكيد';

  @override
  String get common_you => 'أنت';

  @override
  String get common_loading => 'جارٍ التحميل…';

  @override
  String get common_selected => 'محدد';

  @override
  String get time_now => 'الآن';

  @override
  String get time_today => 'اليوم';

  @override
  String get time_yesterday => 'أمس';

  @override
  String time_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String time_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
    );
    return '$_temp0';
  }

  @override
  String time_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String duration_minutes_short(int count) {
    return '$count د';
  }

  @override
  String duration_hours_short(int count) {
    return '$count س';
  }

  @override
  String duration_days_short(int count) {
    return '$count ي';
  }

  @override
  String waiting_for(String duration) {
    return 'ينتظر منذ $duration';
  }

  @override
  String get network_connecting => 'جارٍ الاتصال…';

  @override
  String get network_offline => 'غير متصل';

  @override
  String get empty_offline_title => 'أنت غير متصل بالإنترنت';

  @override
  String get empty_offline_body =>
      'تحقق من اتصالك ثم أعد المحاولة. ستُرسل رسائلك عند عودة الاتصال.';

  @override
  String a11y_unread_messages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسالة غير مقروءة',
      few: '$count رسائل غير مقروءة',
      two: 'رسالتان غير مقروءتين',
      one: 'رسالة غير مقروءة',
      zero: 'لا رسائل غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get a11y_notifications_unread => 'الإشعارات، يوجد جديد';

  @override
  String get a11y_ai_avatar => 'الذكاء الاصطناعي';

  @override
  String get a11y_team_avatar => 'فريق';

  @override
  String get a11y_selected => 'محدد';

  @override
  String a11y_priority(String label) {
    return 'الأولوية: $label';
  }

  @override
  String get time_unit_day => 'ي';

  @override
  String get time_unit_hour => 'س';

  @override
  String get time_unit_min => 'د';

  @override
  String get common_increase => 'زيادة';

  @override
  String get common_decrease => 'إنقاص';

  @override
  String get dash_title => 'لوحة التحكم';

  @override
  String dash_morning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String dash_evening(String name) {
    return 'مساء النور، $name';
  }

  @override
  String get dash_presence_online_m => 'متاح';

  @override
  String get dash_presence_online_f => 'متاحة';

  @override
  String get dash_presence_busy_m => 'مشغول';

  @override
  String get dash_presence_busy_f => 'مشغولة';

  @override
  String get dash_presence_away => 'غير متاح';

  @override
  String get dash_presence_title => 'حالتك';

  @override
  String get dash_presence_until => 'حتى…';

  @override
  String get dash_presence_30m => '30 دقيقة';

  @override
  String get dash_presence_1h => 'ساعة';

  @override
  String get dash_presence_eod => 'نهاية اليوم';

  @override
  String get dash_presence_auto =>
      'تتحول تلقائيًا إلى «غير متاح» بعد 15 دقيقة من الخمول';

  @override
  String dash_presence_until_time(String time) {
    return 'حتى $time';
  }

  @override
  String get dash_presence_failed => 'تعذّر تغيير حالتك';

  @override
  String get dash_scope_me => 'أنا';

  @override
  String get dash_scope_team => 'فريقي';

  @override
  String get dash_scope_all => 'الكل';

  @override
  String get dash_team_picker => 'اختر الفريق';

  @override
  String get dash_range_today => 'اليوم';

  @override
  String get dash_range_yesterday => 'أمس';

  @override
  String get dash_range_7d => 'آخر 7 أيام';

  @override
  String get dash_range_30d => 'آخر 30 يومًا';

  @override
  String get dash_range_title => 'الفترة';

  @override
  String get dash_open => 'محادثات مفتوحة';

  @override
  String get dash_awaiting_me => 'بانتظار ردّك';

  @override
  String get dash_awaiting_team => 'بانتظار الرد';

  @override
  String dash_oldest(String m) {
    return 'أقدمها $m';
  }

  @override
  String get dash_none_waiting => 'لا أحد ينتظر';

  @override
  String get dash_first_response => 'متوسط أول رد';

  @override
  String get dash_minute => 'دقيقة';

  @override
  String get dash_ai_reply => 'ردّ الذكاء';

  @override
  String get dash_of_questions => 'من الأسئلة';

  @override
  String get dash_resolved => 'المحادثات المحلولة';

  @override
  String get dash_volume_today => 'المحادثات اليوم';

  @override
  String dash_volume_range(String range) {
    return 'المحادثات · $range';
  }

  @override
  String dash_total(String n) {
    return '$n محادثة';
  }

  @override
  String dash_tooltip(String hour, String n, String ai) {
    return '$hour: $n محادثة · $ai بالذكاء';
  }

  @override
  String get dash_legend_all => 'الكل';

  @override
  String get dash_legend_ai => 'ردّ الذكاء';

  @override
  String get dash_no_volume => 'لا محادثات بعد اليوم';

  @override
  String get dash_no_volume_range => 'لا محادثات في هذه الفترة';

  @override
  String get dash_team_now => 'الفريق الآن';

  @override
  String get dash_see_all => 'عرض الكل';

  @override
  String get dash_ai_name => 'الذكاء';

  @override
  String dash_agent_open(String n) {
    return '$n محادثات مفتوحة';
  }

  @override
  String dash_agent_frt(String t) {
    return 'متوسط أول رد اليوم $t';
  }

  @override
  String get dash_agent_view => 'عرض محادثاته';

  @override
  String get dash_redistribute => 'إعادة توزيع';

  @override
  String get dash_redistribute_none => 'لا محادثات مفتوحة لإعادة توزيعها';

  @override
  String get dash_solo => 'أنت وحدك في الفريق';

  @override
  String get dash_invite => 'دعوة زميل';

  @override
  String dash_ai_impact(String n) {
    return '$n سؤالًا أجاب عنها الذكاء';
  }

  @override
  String dash_ai_saved(String h) {
    return 'وفّر نحو $h ساعات من وقت الفريق';
  }

  @override
  String dash_ai_handoffs(String n) {
    return 'تحويلات للفريق $n';
  }

  @override
  String dash_ai_rating(String p) {
    return 'تقييم إيجابي $p%';
  }

  @override
  String dash_ai_handling(String n) {
    return 'يتولّى الذكاء $n محادثة الآن';
  }

  @override
  String get dash_by_channel => 'حسب القناة';

  @override
  String get dash_web_reports => 'تقارير مفصّلة على الويب';

  @override
  String dash_last_updated(String t) {
    return 'آخر تحديث $t';
  }

  @override
  String get dash_load_error => 'تعذّر تحميل لوحة التحكم';

  @override
  String get dash_card_error => 'تعذّر التحميل';

  @override
  String get dash_retry => 'إعادة المحاولة';

  @override
  String get dash_frt_title => 'سرعة أول رد';

  @override
  String dash_frt_target(String m) {
    return 'الهدف: $m د';
  }

  @override
  String get dash_frt_lt1 => 'أقل من دقيقة';

  @override
  String get dash_frt_1_5 => '1–5 د';

  @override
  String get dash_frt_5_15 => '5–15 د';

  @override
  String get dash_frt_gt15 => 'أكثر من 15 د';

  @override
  String get dash_frt_note => 'محسوب على المحادثات التي ردّ عليها موظف';

  @override
  String get dash_frt_empty => 'لا ردود بعد في هذه الفترة';

  @override
  String get dash_days_short => 'ي';

  @override
  String get dash_hours_short => 'س';

  @override
  String get dash_minutes_short => 'د';

  @override
  String get dash_thousand => 'ألف';

  @override
  String get dash_onb_title => 'ابدأ باستقبال المحادثات';

  @override
  String get dash_onb_wa => 'ربط واتساب';

  @override
  String get dash_onb_kb => 'إضافة قاعدة المعرفة';

  @override
  String get dash_onb_ai => 'تفعيل الذكاء الاصطناعي';

  @override
  String get dash_onb_cta => 'أكمل الإعداد';

  @override
  String get dash_alert_wa_title => 'واتساب غير متصل';

  @override
  String get dash_alert_wa_body => 'لن تصل الرسائل حتى تعيد الربط';

  @override
  String get dash_alert_wa_action => 'إعادة الربط';

  @override
  String dash_alert_sla_title(String n, String sla) {
    return '$n عملاء ينتظرون أكثر من $sla د';
  }

  @override
  String get dash_alert_sla_action => 'رد الآن';

  @override
  String dash_alert_unassigned_title(String n) {
    return '$n محادثات بانتظار الاستلام';
  }

  @override
  String get dash_alert_view => 'عرض';

  @override
  String dash_alert_kb_title(String n) {
    return '$n أسئلة بلا إجابة';
  }

  @override
  String get dash_alert_kb_body => 'أضفها ليجيب الذكاء تلقائيًا';

  @override
  String get dash_alert_kb_action => 'راجعها';

  @override
  String dash_alert_trial_title(String n) {
    return 'تجربتك تنتهي بعد $n أيام';
  }

  @override
  String get dash_alert_trial_action => 'عرض الخطط';

  @override
  String get dash_alert_dismiss => 'إخفاء';

  @override
  String dash_a11y_metric(String label, String value, String aside) {
    return '$label: $value $aside. اضغط لعرض المحادثات';
  }

  @override
  String dash_a11y_chart(String title, String total, String peak, String n) {
    return '$title: $total. الذروة $peak بـ $n محادثة.';
  }

  @override
  String dash_a11y_team(String name, String presence, String n) {
    return '$name، $presence، $n محادثات مفتوحة';
  }

  @override
  String dash_a11y_presence(String status) {
    return 'حالتك: $status. اضغط للتغيير';
  }

  @override
  String dash_afternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get dash_period_7d => '7 أيام';

  @override
  String get dash_period_30d => '30 يومًا';

  @override
  String get dash_nothing_waiting => 'لا شيء بانتظارك';

  @override
  String get dash_unit_sec => 'ثانية';

  @override
  String get dash_unit_hr => 'ساعة';

  @override
  String get dash_ai_off => 'متوقف';

  @override
  String get dash_empty => 'لا توجد محادثات بعد';

  @override
  String get dash_connect_wa => 'اربط واتساب';

  @override
  String get dash_wa_down => 'انقطع اتصال واتساب';

  @override
  String dash_offline(String t) {
    return 'غير متصل · آخر تحديث $t';
  }

  @override
  String get dash_error => 'تعذّر تحميل البيانات';

  @override
  String dash_bar_tip(String n, String slot) {
    return '$n محادثة · $slot';
  }

  @override
  String dash_bell_a11y(String n) {
    return 'الإشعارات، $n غير مقروءة';
  }

  @override
  String dash_kpi_a11y(String label, String value, String meta) {
    return '$label: $value، $meta';
  }

  @override
  String dash_faster(String p) {
    return 'أسرع بـ $p%';
  }

  @override
  String dash_slower(String p) {
    return 'أبطأ بـ $p%';
  }

  @override
  String get dash_vs_previous => 'مقارنة بالفترة السابقة';

  @override
  String get dash_breakdown_you => 'أنت';

  @override
  String get dash_breakdown_team => 'الفريق';

  @override
  String get dash_breakdown_ai => 'الذكاء';

  @override
  String get dash_ai_instant => 'فوري';

  @override
  String dash_more_team(String n) {
    return '$n آخرون';
  }

  @override
  String get inbox_title => 'المحادثات';

  @override
  String get inbox_seg_mine => 'لي';

  @override
  String get inbox_seg_unassigned => 'غير مُسندة';

  @override
  String get inbox_seg_all => 'الكل';

  @override
  String get inbox_chip_all => 'الكل';

  @override
  String get inbox_chip_unread => 'غير مقروءة';

  @override
  String get inbox_chip_awaiting => 'بانتظار الرد';

  @override
  String get inbox_chip_ai => 'ردّ الذكاء';

  @override
  String get inbox_chip_snoozed => 'مؤجلة';

  @override
  String get inbox_chip_closed => 'مغلقة';

  @override
  String get inbox_chip_filters => 'فلاتر';

  @override
  String get inbox_needs_reply => 'تحتاج ردّك الآن';

  @override
  String get inbox_rest => 'باقي المحادثات';

  @override
  String get inbox_see_all => 'عرض الكل';

  @override
  String get inbox_show_less => 'عرض أقل';

  @override
  String get inbox_you_prefix => 'أنت:';

  @override
  String get inbox_draft_prefix => 'مسودة:';

  @override
  String get inbox_note_prefix => 'ملاحظة:';

  @override
  String get inbox_typing => 'يكتب الآن…';

  @override
  String get inbox_image => 'صورة';

  @override
  String inbox_voice(String d) {
    return 'رسالة صوتية · $d';
  }

  @override
  String get inbox_location => 'موقع';

  @override
  String get inbox_sticker => 'ملصق';

  @override
  String get inbox_deleted => 'تم حذف هذه الرسالة';

  @override
  String inbox_tag_waiting(String t) {
    return 'ينتظر $t';
  }

  @override
  String get inbox_tag_ai_ready => 'اقتراح جاهز';

  @override
  String get inbox_tag_ai_replied => 'ردّ الذكاء الاصطناعي';

  @override
  String inbox_tag_snoozed(String t) {
    return 'مؤجلة حتى $t';
  }

  @override
  String inbox_tag_window(int h) {
    return 'تنتهي النافذة خلال $h س';
  }

  @override
  String get inbox_now => 'الآن';

  @override
  String inbox_min(int n) {
    return '$n د';
  }

  @override
  String inbox_hour(int n) {
    return '$n س';
  }

  @override
  String get inbox_yesterday => 'أمس';

  @override
  String get inbox_am => 'ص';

  @override
  String get inbox_pm => 'م';

  @override
  String get inbox_swipe_resolve => 'حلّ';

  @override
  String get inbox_swipe_snooze => 'تأجيل';

  @override
  String get inbox_swipe_assign => 'إسناد';

  @override
  String get inbox_swipe_claim => 'استلام';

  @override
  String get inbox_resolved => 'تم حلّ المحادثة';

  @override
  String inbox_resolved_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم حلّ $n محادثة',
      few: 'تم حلّ $n محادثات',
      two: 'تم حلّ محادثتين',
      one: 'تم حلّ محادثة',
    );
    return '$_temp0';
  }

  @override
  String get inbox_snoozed_1h => 'أُجّلت لمدة ساعة';

  @override
  String inbox_snoozed_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'أُجّلت $n محادثة',
      few: 'أُجّلت $n محادثات',
      two: 'أُجّلت محادثتان',
      one: 'أُجّلت المحادثة',
    );
    return '$_temp0';
  }

  @override
  String get inbox_undo => 'تراجع';

  @override
  String inbox_assigned_to_you(String name) {
    return 'أُسندت إليك محادثة من $name';
  }

  @override
  String get inbox_open => 'فتح';

  @override
  String inbox_claimed_by(String name) {
    return 'استلمها $name';
  }

  @override
  String inbox_new_pill(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n محادثة جديدة',
      few: '$n محادثات جديدة',
      two: 'محادثتان جديدتان',
      one: 'محادثة جديدة',
    );
    return '$_temp0';
  }

  @override
  String inbox_selected(int n) {
    return '$n محدد';
  }

  @override
  String get inbox_select_all => 'تحديد الكل';

  @override
  String get inbox_exit_selection => 'إنهاء التحديد';

  @override
  String get inbox_mark_read => 'مقروء';

  @override
  String get inbox_mark_unread => 'غير مقروء';

  @override
  String inbox_marked_read_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم تعليم $n محادثة كمقروءة',
      few: 'تم تعليم $n محادثات كمقروءة',
      one: 'تم تعليم محادثة كمقروءة',
    );
    return '$_temp0';
  }

  @override
  String inbox_marked_unread_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم تعليم $n محادثة كغير مقروءة',
      few: 'تم تعليم $n محادثات كغير مقروءة',
      one: 'تم تعليم محادثة كغير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get inbox_new_conversation => 'محادثة جديدة';

  @override
  String get inbox_load_error => 'تعذّر التحميل · إعادة المحاولة';

  @override
  String get inbox_end => 'لا مزيد من المحادثات';

  @override
  String get inbox_exit_hint => 'اضغط مرة أخرى للخروج';

  @override
  String get inbox_offline_cached => 'غير متصل — تُعرض آخر نسخة محفوظة';

  @override
  String get inbox_action_failed => 'تعذّر تنفيذ الإجراء. حاول مجددًا.';

  @override
  String get inbox_tag => 'وسم';

  @override
  String inbox_tag_added(String tag) {
    return 'أُضيف الوسم «$tag»';
  }

  @override
  String get inbox_priority => 'أولوية';

  @override
  String inbox_priority_set(String label) {
    return 'الأولوية الآن: $label';
  }

  @override
  String get inbox_archive => 'أرشفة';

  @override
  String inbox_archived_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'أُرشفت $n محادثة',
      few: 'أُرشفت $n محادثات',
      one: 'أُرشفت المحادثة',
    );
    return '$_temp0';
  }

  @override
  String get inbox_clear_all => 'مسح الكل';

  @override
  String inbox_a11y_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n رسالة غير مقروءة',
      few: '$n رسائل غير مقروءة',
      two: 'رسالتان غير مقروءتين',
      one: 'رسالة غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get inbox_a11y_open_hint => 'اضغط مرتين لفتح المحادثة';

  @override
  String inbox_a11y_notifications(int n) {
    return 'الإشعارات، $n غير مقروءة';
  }

  @override
  String get inbox_empty_mine_title => 'لا توجد محادثات مُسندة لك';

  @override
  String get inbox_empty_mine_body =>
      'ستظهر هنا المحادثات التي تستلمها أو تُسند إليك.';

  @override
  String get inbox_empty_mine_action => 'عرض غير المُسندة';

  @override
  String get inbox_empty_done_title => 'أنهيت كل المحادثات';

  @override
  String get inbox_empty_done_body => 'لا أحد ينتظر ردّك الآن.';

  @override
  String get inbox_empty_unassigned_title => 'لا توجد محادثات بانتظار الاستلام';

  @override
  String get inbox_empty_unassigned_body =>
      'الذكاء الاصطناعي والفريق يغطّون كل شيء.';

  @override
  String get inbox_empty_new_title => 'لم تصل أي محادثة بعد';

  @override
  String get inbox_empty_new_body => 'اربط واتساب لتبدأ باستقبال رسائل عملائك.';

  @override
  String get inbox_empty_new_action => 'اربط واتساب';

  @override
  String get inbox_empty_filters_title => 'لا محادثات تطابق الفلاتر';

  @override
  String get inbox_empty_filters_action => 'مسح الفلاتر';

  @override
  String get inbox_empty_error_title => 'تعذّر تحميل المحادثات';

  @override
  String get inbox_empty_error_body => 'تحقّق من اتصالك ثم حاول مجددًا.';

  @override
  String get inbox_filters_title => 'الفلاتر';

  @override
  String get inbox_filters_clear => 'مسح';

  @override
  String get inbox_filters_apply => 'عرض المحادثات';

  @override
  String inbox_filters_show(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'عرض $n محادثة',
      few: 'عرض $n محادثات',
      two: 'عرض محادثتين',
      one: 'عرض محادثة واحدة',
      zero: 'لا توجد محادثات',
    );
    return '$_temp0';
  }

  @override
  String get inbox_filters_channel => 'القناة';

  @override
  String get inbox_filters_priority => 'الأولوية';

  @override
  String get inbox_filters_assignee => 'المُسند إليه';

  @override
  String get inbox_filters_assignee_all => 'الكل';

  @override
  String get inbox_filters_assignee_me => 'أنا';

  @override
  String get inbox_filters_assignee_colleague => 'زميل محدد ▸';

  @override
  String get inbox_filters_assignee_ai => 'الذكاء الاصطناعي';

  @override
  String get inbox_filters_assignee_unassigned => 'غير مُسندة';

  @override
  String get inbox_filters_pick_colleague => 'اختر زميلًا';

  @override
  String get inbox_filters_team => 'الفريق';

  @override
  String get inbox_filters_tags => 'الوسوم';

  @override
  String get inbox_filters_tags_search => 'ابحث في الوسوم';

  @override
  String get inbox_filters_date => 'التاريخ';

  @override
  String get inbox_filters_date_today => 'اليوم';

  @override
  String get inbox_filters_date_7d => '7 أيام';

  @override
  String get inbox_filters_date_30d => '30 يومًا';

  @override
  String get inbox_filters_date_custom => 'مخصص ▸';

  @override
  String get inbox_filters_sort => 'الترتيب';

  @override
  String get inbox_filters_sort_smart => 'ذكي (افتراضي)';

  @override
  String get inbox_filters_sort_newest => 'الأحدث';

  @override
  String get inbox_filters_sort_oldest => 'الأقدم';

  @override
  String get inbox_filters_sort_waiting => 'الأطول انتظارًا';

  @override
  String get kbe_new => 'سؤال جديد';

  @override
  String get kbe_edit => 'تعديل الإجابة';

  @override
  String get kbe_review => 'مراجعة مقترح';

  @override
  String get kbe_save => 'حفظ';

  @override
  String get kbe_send => 'إرسال';

  @override
  String kbe_src_unanswered(String n) {
    return 'سُئل هذا السؤال $n مرات ولم يجد الذكاء إجابة';
  }

  @override
  String kbe_src_chat(String c, String d) {
    return 'من محادثة مع $c · $d';
  }

  @override
  String kbe_src_draft(String name, String t) {
    return 'اقترحها $name · $t';
  }

  @override
  String get kbe_src_draft_conv => 'مقترحة من محادثة محلولة';

  @override
  String get kbe_view_convs => 'عرض المحادثات';

  @override
  String get kbe_open => 'فتح';

  @override
  String get kbe_open_it => 'فتحه';

  @override
  String get kbe_question => 'السؤال';

  @override
  String get kbe_question_ph => 'مثال: هل يمكن الاسترجاع بعد 30 يومًا؟';

  @override
  String get kbe_alts => 'صيغ أخرى يسأل بها العملاء';

  @override
  String get kbe_optional => '(اختياري)';

  @override
  String get kbe_add_alt => '+ أضف صيغة';

  @override
  String get kbe_alt_exists => 'هذه الصيغة موجودة';

  @override
  String get kbe_alt_limit => 'الحد الأقصى 15 صيغة، 120 حرفًا لكل صيغة';

  @override
  String get kbe_answer => 'الإجابة';

  @override
  String get kbe_answer_ph => 'اكتب الإجابة كما تريد أن يقولها الذكاء للعميل…';

  @override
  String kbe_counter(String n) {
    return '$n/2000';
  }

  @override
  String get kbe_ai_draft_tag => 'مسودة من الذكاء — راجعها قبل الحفظ';

  @override
  String get kbe_tag => 'وسم';

  @override
  String get kbe_tags_title => 'وسوم الإجابة';

  @override
  String get kbe_tags_search => 'ابحث أو أنشئ وسمًا';

  @override
  String kbe_tags_create(String name) {
    return 'إنشاء «$name»';
  }

  @override
  String get kbe_tags_primary => 'الوسم الرئيسي';

  @override
  String get kbe_done => 'تم';

  @override
  String get kbe_improve => 'حسّن الصياغة';

  @override
  String get kbe_add_link => 'أضف رابطًا';

  @override
  String get kbe_link_url => 'الرابط';

  @override
  String get kbe_link_label => 'عنوان الرابط (اختياري)';

  @override
  String get kbe_link_invalid => 'أدخل رابطًا صحيحًا يبدأ بـ https://';

  @override
  String get kbe_insert => 'إدراج';

  @override
  String get kbe_cancel => 'إلغاء';

  @override
  String kbe_similar(String t) {
    return 'يوجد سؤال مشابه: «$t»';
  }

  @override
  String get kbe_merge_alt => 'دمج كصيغة أخرى';

  @override
  String kbe_conflict(String t, String r) {
    return 'قد تتعارض مع «$t»: $r';
  }

  @override
  String get kbe_view => 'عرض';

  @override
  String get kbe_preview => 'معاينة: كيف سيردّ الذكاء';

  @override
  String get kbe_ai_label => 'الذكاء الاصطناعي';

  @override
  String get kbe_writing => 'يكتب…';

  @override
  String kbe_tone(String tone) {
    return 'بنبرة: $tone';
  }

  @override
  String get kbe_conf_high => 'ثقة عالية';

  @override
  String get kbe_conf_med => 'ثقة متوسطة';

  @override
  String get kbe_conf_low => 'ثقة منخفضة';

  @override
  String get kbe_low_hint => 'أضف صيغًا أخرى أو وضّح الإجابة لرفع الثقة';

  @override
  String get kbe_try_another => 'جرّب سؤالًا آخر';

  @override
  String get kbe_test_hint => 'اكتب سؤالًا لتجربته';

  @override
  String get kbe_preview_err => 'تعذّرت المعاينة';

  @override
  String get kbe_preview_offline => 'المعاينة تحتاج اتصالًا';

  @override
  String get kbe_preview_empty => 'أكمل السؤال والإجابة لتظهر المعاينة';

  @override
  String get kbe_preview_regen => 'تحديث المعاينة';

  @override
  String get kbe_advanced => 'خيارات متقدمة';

  @override
  String get kbe_enabled => 'متاح للذكاء الاصطناعي';

  @override
  String get kbe_channels => 'القنوات';

  @override
  String get kbe_channels_all => 'كل القنوات';

  @override
  String get kbe_expires => 'صالحة حتى';

  @override
  String get kbe_expires_none => 'بدون تاريخ انتهاء';

  @override
  String get kbe_expires_clear => 'إزالة التاريخ';

  @override
  String get kbe_verbatim => 'رد حرفي';

  @override
  String get kbe_verbatim_sub => 'يرسل الذكاء الإجابة كما هي دون إعادة صياغة';

  @override
  String get kbe_handoff_after => 'تحويل لموظف بعد الإجابة';

  @override
  String get kbe_internal_notes => 'ملاحظات داخلية';

  @override
  String get kbe_internal_notes_ph => 'لا يستخدمها الذكاء';

  @override
  String kbe_meta(String n, String t, String u) {
    return 'آخر تعديل $n · $t · استُخدم $u مرة';
  }

  @override
  String get kbe_delete => 'حذف الإجابة';

  @override
  String kbe_delete_title(String title) {
    return 'حذف «$title»؟';
  }

  @override
  String get kbe_delete_body => 'لن يستخدمها الذكاء بعد الآن.';

  @override
  String get kbe_deleted => 'تم الحذف';

  @override
  String get kbe_history => 'سجل التغييرات';

  @override
  String get kbe_restore => 'استعادة هذه النسخة';

  @override
  String kbe_version_n(String n) {
    return 'النسخة $n';
  }

  @override
  String get kbe_version_current => 'الحالية';

  @override
  String get kbe_versions_empty => 'لا توجد نسخ سابقة';

  @override
  String get kbe_restored => 'تمت استعادة النسخة';

  @override
  String get kbe_restore_failed => 'تعذّرت الاستعادة';

  @override
  String get kbe_err_q => 'اكتب السؤال (5 أحرف على الأقل)';

  @override
  String get kbe_err_a => 'اكتب الإجابة (10 أحرف على الأقل)';

  @override
  String get kbe_err_a_long => 'الإجابة أطول من 2000 حرف';

  @override
  String get kbe_err_date => 'اختر تاريخًا في المستقبل';

  @override
  String get kbe_saved_new => 'تمت إضافة الإجابة · سيستخدمها الذكاء فورًا';

  @override
  String get kbe_saved_edit => 'تم حفظ التعديلات';

  @override
  String kbe_saved_unanswered(String n) {
    return 'تمت الإضافة · $n محادثات كانت تنتظر هذه الإجابة';
  }

  @override
  String get kbe_saved_chat => 'أُضيفت لقاعدة المعرفة';

  @override
  String get kbe_proposed => 'أُرسلت للمراجعة';

  @override
  String get kbe_approve => 'اعتماد ونشر';

  @override
  String get kbe_approved => 'تم اعتماد الإجابة ونشرها';

  @override
  String get kbe_reject => 'رفض';

  @override
  String get kbe_rejected => 'تم رفض المقترح';

  @override
  String get kbe_save_err => 'تعذّر الحفظ';

  @override
  String get kbe_save_forbidden => 'لا تملك صلاحية الحفظ — أرسلها للمراجعة';

  @override
  String get kbe_save_offline => 'الحفظ يتطلب اتصالًا بالإنترنت';

  @override
  String get kbe_retry => 'إعادة المحاولة';

  @override
  String get kbe_load_error => 'تعذّر تحميل الإجابة';

  @override
  String kbe_conflict_title(String name) {
    return 'عدّل $name هذه الإجابة للتو';
  }

  @override
  String get kbe_view_theirs => 'عرض نسختهم';

  @override
  String get kbe_overwrite => 'حفظ نسختي فوقها';

  @override
  String get kbe_restore_draft => 'لديك مسودة غير محفوظة — استعادتها؟';

  @override
  String get kbe_restore_btn => 'استعادة';

  @override
  String get kbe_restore_ignore => 'تجاهل';

  @override
  String get kbe_discard_title => 'تجاهل التغييرات؟';

  @override
  String get kbe_discard_body => 'لن تُحفظ الإجابة.';

  @override
  String get kbe_discard => 'تجاهل';

  @override
  String get kbe_keep => 'متابعة التعديل';

  @override
  String get kbe_deleted_elsewhere => 'تم حذف هذه الإجابة';

  @override
  String get kbe_close => 'إغلاق';

  @override
  String kbe_a11y_alt(String text) {
    return 'صيغة: $text، اضغط مرتين للتعديل';
  }

  @override
  String get kbe_a11y_alt_delete => 'حذف';

  @override
  String kbe_a11y_ghost(String text) {
    return 'صيغة مقترحة من الذكاء: $text، اضغط للإضافة';
  }

  @override
  String get kbe_a11y_save_disabled => 'أكمل السؤال والإجابة';

  @override
  String get kbe_a11y_dismiss => 'إغلاق التنبيه';

  @override
  String get kbe_media => 'المرفقات';

  @override
  String get kbe_media_hint => 'يرسلها الذكاء مع الإجابة';

  @override
  String get kbe_media_add => 'إضافة صورة أو تسجيل صوتي';

  @override
  String get kbe_media_image => 'صورة';

  @override
  String get kbe_media_voice => 'تسجيل صوتي';

  @override
  String get kbe_media_with_text => 'مع النص';

  @override
  String get kbe_media_file_only => 'ملف فقط';

  @override
  String get kbe_media_remove => 'إزالة';

  @override
  String kbe_media_uploading(int p) {
    return 'جارٍ الرفع $p%';
  }

  @override
  String get kbe_media_failed => 'تعذّر رفع الملف';

  @override
  String get kbe_media_queued => 'يُرفع بعد الحفظ';

  @override
  String get kbe_media_too_big => 'الملف أكبر من 16 ميجابايت';

  @override
  String get kbe_media_image_too_big => 'الصورة أكبر من 5 ميجابايت';

  @override
  String get kbe_media_type_err => 'اختر صورة أو ملفًا صوتيًا';

  @override
  String get kbe_media_upgrade =>
      'إرفاق الصور والتسجيلات متاح في الباقات المدفوعة';

  @override
  String get kbe_media_upgrade_cta => 'عرض الباقات';

  @override
  String kbe_media_some_failed(int n) {
    return 'تم الحفظ، لكن تعذّر رفع $n من المرفقات';
  }

  @override
  String get kbe_media_send_mode => 'طريقة الإرسال';

  @override
  String get kb_title => 'المعرفة';

  @override
  String kb_search(int n) {
    return 'ابحث في $n مدخلًا';
  }

  @override
  String get kb_qa => 'سؤال وجواب';

  @override
  String get kb_files => 'ملفات';

  @override
  String get kb_links => 'روابط';

  @override
  String get kb_processing => 'جارٍ المعالجة';

  @override
  String kb_unanswered_title(int n) {
    return '$n أسئلة بلا إجابة';
  }

  @override
  String get kb_unanswered_body => 'سألها العملاء ولم يجد الذكاء جوابًا';

  @override
  String get kb_review => 'راجعها';

  @override
  String get kb_sort_usage => 'الأكثر استخدامًا';

  @override
  String get kb_sort_recent => 'المحدّثة مؤخرًا';

  @override
  String get kb_sort_stale => 'الأقدم تحديثًا';

  @override
  String get kb_sort_alpha => 'أبجديًا';

  @override
  String get kb_sort_least => 'الأقل استخدامًا';

  @override
  String get kb_tags => 'الوسوم';

  @override
  String kb_used_n(int n) {
    return 'استُخدم $n مرة';
  }

  @override
  String kb_updated(String t) {
    return 'محدّث منذ $t';
  }

  @override
  String kb_pages(int n) {
    return '$n صفحة';
  }

  @override
  String get kb_badge_draft => 'مسودة';

  @override
  String get kb_badge_disabled => 'معطّل';

  @override
  String get kb_badge_stale => 'قديم';

  @override
  String get kb_badge_failed => 'فشلت المعالجة';

  @override
  String get kb_disable => 'تعطيل للذكاء';

  @override
  String get kb_enable => 'تفعيل';

  @override
  String get kb_edit => 'تعديل';

  @override
  String get kb_copy_answer => 'نسخ الإجابة';

  @override
  String get kb_delete => 'حذف';

  @override
  String kb_delete_title(String title) {
    return 'حذف «$title»؟';
  }

  @override
  String get kb_delete_body => 'لن يستخدمها الذكاء بعد الآن.';

  @override
  String get kb_deleted => 'تم الحذف';

  @override
  String kb_drafts(int n) {
    return 'مقترحات بانتظار المراجعة · $n';
  }

  @override
  String kb_draft_by(String name, String t) {
    return 'اقترحها $name · $t';
  }

  @override
  String get kb_draft_from_conv => 'مقترحة من محادثة محلولة';

  @override
  String get kb_approve => 'اعتماد';

  @override
  String get kb_reject => 'رفض';

  @override
  String get kb_add_title => 'إضافة إلى قاعدة المعرفة';

  @override
  String get kb_add_qa_sub => 'الأسرع والأدق للذكاء';

  @override
  String get kb_add_file => 'رفع ملف';

  @override
  String get kb_add_file_sub =>
      'عدة أسئلة وأجوبة دفعة واحدة من ملف JSON (بصيغة لوحة الويب)';

  @override
  String get kb_add_link => 'إضافة رابط';

  @override
  String get kb_add_link_sub => 'صفحة من موقعك، يقرأها الذكاء تلقائيًا';

  @override
  String get kb_alt_phrasings => 'صيغ أخرى';

  @override
  String get kb_answer => 'الإجابة';

  @override
  String kb_usage_month(int n) {
    return 'استُخدم $n مرة هذا الشهر';
  }

  @override
  String kb_positive(int p) {
    return 'تقييم إيجابي $p%';
  }

  @override
  String kb_last_used(String t) {
    return 'آخر استخدام $t';
  }

  @override
  String get kb_recent_uses => 'آخر الاستخدامات';

  @override
  String kb_meta(String a, String d, String b, String t) {
    return 'أنشأها $a · $d · آخر تعديل $b $t';
  }

  @override
  String get kb_available_ai => 'متاح للذكاء الاصطناعي';

  @override
  String get kb_file_type_err => 'نوع الملف غير مدعوم';

  @override
  String get kb_file_size_err => 'الملف أكبر من 10 ميجابايت';

  @override
  String kb_uploading(int p) {
    return 'جارٍ الرفع $p%';
  }

  @override
  String get kb_processing_long => 'جارٍ المعالجة… قد يستغرق دقيقة';

  @override
  String kb_file_ready(String f, int n) {
    return 'أصبح «$f» جاهزًا · $n إجابة للمراجعة';
  }

  @override
  String get kb_extracted => 'ما استخرجه الذكاء';

  @override
  String get kb_replace => 'استبدال الملف';

  @override
  String get kb_download => 'تحميل';

  @override
  String get kb_file_failed => 'تعذّرت قراءة الملف';

  @override
  String get kb_fail_encrypted => 'الملف محمي بكلمة مرور';

  @override
  String get kb_fail_images => 'الملف صور فقط بدون نص';

  @override
  String get kb_fail_corrupt => 'الملف تالف';

  @override
  String get kb_link_url => 'رابط الصفحة';

  @override
  String get kb_link_subpages => 'تضمين الصفحات الفرعية';

  @override
  String get kb_add => 'إضافة';

  @override
  String kb_last_crawl(String t) {
    return 'آخر قراءة $t';
  }

  @override
  String get kb_recrawl => 'تحديث الآن';

  @override
  String get kb_auto_refresh => 'التحديث التلقائي';

  @override
  String get kb_weekly => 'أسبوعيًا';

  @override
  String get kb_monthly => 'شهريًا';

  @override
  String get kb_manual => 'يدويًا';

  @override
  String get kb_unanswered => 'أسئلة بلا إجابة';

  @override
  String get kb_unanswered_info =>
      'أسئلة سألها العملاء ولم يجد لها الذكاء إجابة. أضف إجابة ليردّ تلقائيًا في المرة القادمة.';

  @override
  String get kb_sort_frequency => 'الأكثر تكرارًا';

  @override
  String get kb_sort_newest => 'الأحدث';

  @override
  String kb_asked_n(int n, String t) {
    return 'سُئل $n مرات · آخرها $t';
  }

  @override
  String kb_similar(int k) {
    return '+$k صيغ مشابهة';
  }

  @override
  String get kb_ai_draft => 'مسودة مقترحة';

  @override
  String get kb_add_answer => 'أضف إجابة';

  @override
  String get kb_link_existing => 'ربط بإجابة موجودة';

  @override
  String get kb_ignore => 'تجاهل';

  @override
  String get kb_view_convs => 'عرض المحادثات';

  @override
  String get kb_suggest_answer => 'اقترح إجابة';

  @override
  String get kb_none_unanswered => 'لا توجد أسئلة بلا إجابة';

  @override
  String get kb_none_unanswered_body =>
      'الذكاء يجد إجابات لكل ما يُسأل حاليًا.';

  @override
  String get kb_empty_title => 'ابدأ بتعليم الذكاء عن عملك';

  @override
  String get kb_empty_body => 'أضف أهم الأسئلة التي يسألها عملاؤك وإجاباتها.';

  @override
  String get kb_empty_cta => 'أضف أول سؤال';

  @override
  String get kb_empty_tip => 'ننصح بـ 10 أسئلة على الأقل';

  @override
  String get kb_filter_empty => 'لا توجد مدخلات من هذا النوع';

  @override
  String get kb_show_all => 'عرض الكل';

  @override
  String get kb_error => 'تعذّر تحميل قاعدة المعرفة';

  @override
  String get kb_retry => 'إعادة المحاولة';

  @override
  String get kb_offline => 'التعديل يتطلب اتصالًا بالإنترنت';

  @override
  String get kb_span_now => 'لحظات';

  @override
  String kb_span_minutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دقيقة',
      few: '$n دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String kb_span_hours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ساعة',
      few: '$n ساعات',
      two: 'ساعتين',
      one: 'ساعة',
    );
    return '$_temp0';
  }

  @override
  String kb_span_days(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا',
      few: '$n أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String kb_span_months(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n شهرًا',
      few: '$n أشهر',
      two: 'شهرين',
      one: 'شهر',
    );
    return '$_temp0';
  }

  @override
  String kb_span_years(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n سنة',
      few: '$n سنوات',
      two: 'سنتين',
      one: 'سنة',
    );
    return '$_temp0';
  }

  @override
  String get kb_web_only => 'هذه الميزة متاحة من لوحة الويب حاليًا';

  @override
  String get kb_menu_ai_settings => 'إعدادات الذكاء الاصطناعي';

  @override
  String get kb_menu_tags => 'إدارة الوسوم';

  @override
  String get kb_menu_import => 'استيراد من الويب';

  @override
  String get kb_sort_by => 'ترتيب حسب';

  @override
  String get kb_tags_all => 'كل الوسوم';

  @override
  String get kb_tags_apply => 'تطبيق';

  @override
  String get kb_tags_none => 'لا توجد وسوم بعد';

  @override
  String get kb_disabled_done => 'تم التعطيل · لن يستخدمها الذكاء';

  @override
  String get kb_enabled_done => 'تم التفعيل';

  @override
  String get kb_copied => 'تم نسخ الإجابة';

  @override
  String get kb_approved => 'تم الاعتماد والنشر';

  @override
  String get kb_rejected => 'تم رفض المقترح';

  @override
  String get kb_ignored => 'تم التجاهل';

  @override
  String kb_linked(String t) {
    return 'أُضيفت كصيغة أخرى لـ«$t»';
  }

  @override
  String get kb_pick_answer => 'اختر إجابة';

  @override
  String get kb_pick_search => 'ابحث في الإجابات';

  @override
  String kb_uploaded_by(String name, String d) {
    return 'رفعه $name · $d';
  }

  @override
  String kb_mb(String n) {
    return '$n ميجابايت';
  }

  @override
  String kb_kb(String n) {
    return '$n كيلوبايت';
  }

  @override
  String get kb_processing_bg =>
      'يمكنك إغلاق هذه النافذة، ستستمر المعالجة في الخلفية';

  @override
  String get kb_url_invalid => 'أدخل رابطًا صحيحًا يبدأ بـ https://';

  @override
  String get kb_link_added => 'أُضيف الرابط · جارٍ قراءته';

  @override
  String get kb_link_pages => 'الصفحات';

  @override
  String get kb_never_crawled => 'لم تتم القراءة بعد';

  @override
  String get kb_recrawl_started => 'بدأت إعادة القراءة';

  @override
  String kb_filter_a11y(String label, int n) {
    return '$label، $n، تصفية';
  }

  @override
  String kb_banner_a11y(int n) {
    return '$n أسئلة بلا إجابة. راجعها';
  }

  @override
  String get kb_daily_chart => 'الاستخدام خلال 30 يومًا';

  @override
  String get kb_not_used_yet => 'لم يُستخدم بعد';

  @override
  String get kb_show_less => 'عرض أقل';

  @override
  String get kb_proposed => 'أُرسل اقتراحك للمراجعة';

  @override
  String get kb_save_err => 'تعذّر الحفظ';

  @override
  String get kb_none_found => 'لا توجد نتائج';

  @override
  String get kb_import_title => 'استيراد من ملف JSON';

  @override
  String get kb_import_hint =>
      'ملف يحتوي قائمة entries، لكل مدخل type و title و body — بنفس صيغة لوحة الويب.';

  @override
  String get kb_import_pick => 'اختيار ملف JSON';

  @override
  String get kb_import_template => 'تنزيل القالب';

  @override
  String get kb_importing => 'جارٍ الاستيراد…';

  @override
  String kb_import_done(int n) {
    return 'تم استيراد $n مدخلًا';
  }

  @override
  String kb_import_skipped(int n) {
    return 'تم تخطي $n';
  }

  @override
  String kb_import_row_err(int row, String message) {
    return 'السطر $row: $message';
  }

  @override
  String get kb_import_failed => 'تعذّر الاستيراد';

  @override
  String get kb_import_json_only => 'اختر ملفًا بصيغة JSON';

  @override
  String get kb_template_saved => 'تم حفظ القالب';

  @override
  String get kb_template_copied => 'تم نسخ القالب إلى الحافظة';

  @override
  String get kb_media_title => 'المرفقات';

  @override
  String kb_media_n(int n) {
    return '$n مرفقات';
  }

  @override
  String get kb_step_upload => 'تم رفع الملف';

  @override
  String get kb_step_read => 'قراءة المستند';

  @override
  String get kb_step_prepare => 'تجهيز الإجابات';

  @override
  String get kb_processing_hint =>
      'يستغرق عادةً أقل من دقيقة. يمكنك الإخفاء وسنكمل العمل.';

  @override
  String get kb_hide => 'إخفاء';

  @override
  String kb_found_answers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'وجدنا $n إجابة',
      few: 'وجدنا $n إجابات',
      two: 'وجدنا إجابتين',
      one: 'وجدنا إجابة واحدة',
      zero: 'لم نجد إجابات',
    );
    return '$_temp0';
  }

  @override
  String get kb_found_review_hint =>
      'راجعها واختر ما يجب أن يعرفه الذكاء الاصطناعي.';

  @override
  String get kb_found_admin_hint =>
      'سيراجعها أحد المشرفين قبل أن يستخدمها الذكاء الاصطناعي.';

  @override
  String get kb_review_answers => 'مراجعة الإجابات';

  @override
  String get kb_later => 'لاحقًا';

  @override
  String get kb_fail_encrypted_hint => 'أزل كلمة المرور ثم ارفعه مجددًا.';

  @override
  String get kb_fail_images_hint =>
      'لم نجد نصًا قابلًا للقراءة. جرّب ملف PDF بنص قابل للتحديد أو ملف Word.';

  @override
  String get kb_fail_corrupt_hint =>
      'جرّب ملفًا آخر: PDF أو Word أو TXT أو MD حتى 10 ميجابايت.';

  @override
  String get kb_fail_no_answers => 'لم نجد إجابات';

  @override
  String get kb_fail_no_answers_hint =>
      'يبدو أن المستند لا يحتوي على معلومات يسأل عنها العملاء.';

  @override
  String get kb_fail_ai => 'تعذّرت قراءة الملف حاليًا';

  @override
  String get kb_fail_ai_hint => 'يرجى المحاولة مرة أخرى بعد دقائق.';

  @override
  String get kb_fail_quota => 'نفد رصيد الذكاء الاصطناعي';

  @override
  String get kb_fail_quota_hint =>
      'اشحن الرصيد أو رقِّ الباقة لقراءة المستندات بالذكاء الاصطناعي.';

  @override
  String get kb_fail_network => 'لا يوجد اتصال';

  @override
  String get kb_fail_network_hint => 'تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get kb_try_another => 'اختر ملفًا آخر';

  @override
  String get kb_review_title => 'مراجعة الإجابات';

  @override
  String kb_review_from(int n, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n إجابة من $file',
      few: '$n إجابات من $file',
      two: 'إجابتان من $file',
      one: 'إجابة واحدة من $file',
    );
    return '$_temp0';
  }

  @override
  String get kb_review_hint =>
      'حدّد ما يجب أن يعرفه الذكاء الاصطناعي، وعدّل ما يحتاج تعديلًا، ثم أضِف.';

  @override
  String kb_review_selected(int n, int total) {
    return 'تم تحديد $n من $total';
  }

  @override
  String get kb_review_select_all => 'تحديد الكل';

  @override
  String get kb_review_clear => 'إلغاء التحديد';

  @override
  String get kb_review_edit => 'تعديل';

  @override
  String get kb_review_discard => 'حذف';

  @override
  String kb_review_add(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'إضافة $n إجابة',
      few: 'إضافة $n إجابات',
      two: 'إضافة إجابتين',
      one: 'إضافة إجابة واحدة',
      zero: 'إضافة الإجابات',
    );
    return '$_temp0';
  }

  @override
  String kb_review_adding(int done, int total) {
    return 'جارٍ الإضافة $done/$total…';
  }

  @override
  String kb_review_added(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'أُضيفت $n إجابة إلى قاعدة المعرفة',
      one: 'أُضيفت إجابة واحدة إلى قاعدة المعرفة',
    );
    return '$_temp0';
  }

  @override
  String kb_review_added_left(int n, int left) {
    return 'أُضيفت $n · بقيت $left للمراجعة';
  }

  @override
  String kb_review_partial(int done, int failed) {
    return 'أُضيفت $done، وتعذّرت إضافة $failed. حاول مرة أخرى.';
  }

  @override
  String get kb_review_all_done => 'تمت مراجعة كل الإجابات';

  @override
  String get kb_review_all_done_body =>
      'لم يتبقَّ شيء للمراجعة من هذا المستند.';

  @override
  String kb_file_failed_named(String f) {
    return 'تعذّرت قراءة «$f»';
  }

  @override
  String get kb_add_document => 'رفع مستند';

  @override
  String get kb_add_document_sub =>
      'PDF أو Word أو ملف نصي. يحوّله الذكاء الاصطناعي إلى إجابات تراجعها.';

  @override
  String get kb_add_ai_badge => 'ذكاء';

  @override
  String get kb_import_another => 'استيراد ملف آخر';

  @override
  String get ntf_title => 'الإشعارات';

  @override
  String get ntf_read_all => 'قراءة الكل';

  @override
  String get ntf_read_all_done => 'تم تعليم الكل كمقروء';

  @override
  String get ntf_undo => 'تراجع';

  @override
  String get ntf_settings => 'إعدادات الإشعارات';

  @override
  String get ntf_delete_read => 'حذف المقروءة';

  @override
  String get ntf_filter_all => 'الكل';

  @override
  String get ntf_filter_unread => 'غير مقروءة';

  @override
  String get ntf_filter_mentions => 'الإشارات';

  @override
  String get ntf_filter_assignments => 'الإسناد';

  @override
  String get ntf_filter_ai => 'الذكاء';

  @override
  String get ntf_filter_system => 'النظام';

  @override
  String get ntf_today => 'اليوم';

  @override
  String get ntf_yesterday => 'أمس';

  @override
  String get ntf_this_week => 'هذا الأسبوع';

  @override
  String get ntf_older => 'أقدم';

  @override
  String get ntf_push_off_title => 'الإشعارات الفورية متوقفة';

  @override
  String get ntf_push_off_body => 'فعّلها حتى لا تفوتك محادثة مُسندة إليك';

  @override
  String get ntf_enable => 'تفعيل';

  @override
  String get ntf_mark_read => 'تعليم كمقروء';

  @override
  String get ntf_mark_unread => 'تعليم كغير مقروء';

  @override
  String get ntf_mute_type => 'كتم هذا النوع';

  @override
  String get ntf_delete => 'حذف';

  @override
  String get ntf_deleted => 'تم حذف الإشعار';

  @override
  String get ntf_empty_title => 'لا توجد إشعارات';

  @override
  String get ntf_empty_body =>
      'سنخبرك هنا عند إسناد محادثة إليك أو عند حاجة الفريق لك.';

  @override
  String ntf_empty_filter(String f) {
    return 'لا إشعارات في «$f»';
  }

  @override
  String get ntf_show_all => 'عرض الكل';

  @override
  String get ntf_error => 'تعذّر تحميل الإشعارات';

  @override
  String get ntf_retry => 'إعادة المحاولة';

  @override
  String get ntf_end => 'لا مزيد من الإشعارات';

  @override
  String get ntf_retention => 'تُحذف الإشعارات بعد 90 يومًا';

  @override
  String get ntf_target_gone => 'لم تعد هذه المحادثة متاحة';

  @override
  String get ntf_claimed_you => 'استلمتها';

  @override
  String ntf_claimed_by(String name) {
    return 'استلمها $name';
  }

  @override
  String get ntf_approved => 'وافقت';

  @override
  String get ntf_rejected => 'رفضت';

  @override
  String ntf_grouped(int n, String name) {
    return '$n رسائل جديدة من $name';
  }

  @override
  String get ntf_push_private => 'لديك محادثة جديدة';

  @override
  String get ntf_t_assigned => 'أُسندت إليك محادثة جديدة';

  @override
  String ntf_t_claim_needed(int n) {
    return '$n محادثات بانتظار الاستلام';
  }

  @override
  String ntf_t_sla_breach(String customer, String m) {
    return '$customer ينتظر ردّك منذ $m';
  }

  @override
  String ntf_t_transfer_request(String agent) {
    return '$agent يطلب تحويل محادثة إليه';
  }

  @override
  String ntf_t_mention(String agent) {
    return '$agent أشار إليك في ملاحظة';
  }

  @override
  String get ntf_t_ai_no_answer => 'الذكاء الاصطناعي لم يجد إجابة';

  @override
  String get ntf_t_ai_handoff => 'حوّل الذكاء محادثة للفريق';

  @override
  String get ntf_t_ai_low_confidence => 'ردّ الذكاء بثقة منخفضة';

  @override
  String ntf_t_kb_suggestion(int n) {
    return '$n أسئلة متكررة بلا إجابة';
  }

  @override
  String get ntf_t_channel_disconnected => 'انقطع اتصال واتساب';

  @override
  String get ntf_t_channel_reconnected => 'انقطع اتصال واتساب ثم عاد';

  @override
  String get ntf_t_channel_quality_low => 'جودة رقم واتساب منخفضة';

  @override
  String ntf_t_team_joined(String name) {
    return 'انضم $name إلى الفريق';
  }

  @override
  String ntf_t_team_role_changed(String role) {
    return 'تغيّر دورك إلى $role';
  }

  @override
  String ntf_t_trial_ending(int n) {
    return 'تجربتك تنتهي بعد $n أيام';
  }

  @override
  String get ntf_t_payment_failed => 'فشل تحصيل الاشتراك';

  @override
  String get ntf_t_plan_limit => 'اقتربت من حد ردود الذكاء';

  @override
  String get ntf_t_app_update => 'يتوفر إصدار جديد';

  @override
  String ntf_b_claim_needed(String m) {
    return 'أقدمها منذ $m';
  }

  @override
  String ntf_b_ai_no_answer(String topic) {
    return 'سؤال عن $topic. أضف الإجابة ليردّ تلقائيًا في المرة القادمة.';
  }

  @override
  String ntf_b_ai_low_confidence(String customer) {
    return '$customer · راجع الرد';
  }

  @override
  String get ntf_b_kb_suggestion => 'أضفها لقاعدة المعرفة لتحسين الردود';

  @override
  String get ntf_b_channel_disconnected => 'لن تصل الرسائل حتى تعيد الربط';

  @override
  String ntf_b_channel_reconnected(String m) {
    return 'توقف $m · لم تُفقد أي رسالة';
  }

  @override
  String get ntf_b_channel_quality_low => 'قلّل الرسائل الجماعية لتجنب التقييد';

  @override
  String ntf_b_team_joined(String role) {
    return 'دور: $role';
  }

  @override
  String ntf_b_team_role_changed(String actor) {
    return 'بواسطة $actor';
  }

  @override
  String get ntf_b_trial_ending =>
      'اختر خطة للحفاظ على محادثاتك والذكاء الاصطناعي.';

  @override
  String get ntf_b_payment_failed => 'حدّث وسيلة الدفع لتجنب إيقاف الخدمة';

  @override
  String ntf_b_plan_limit(int p) {
    return 'استخدمت $p% هذا الشهر';
  }

  @override
  String ntf_b_app_update(String version) {
    return '$version · تحسينات وإصلاحات';
  }

  @override
  String get ntf_a_view => 'عرض';

  @override
  String get ntf_a_reply => 'رد الآن';

  @override
  String get ntf_a_approve => 'موافقة';

  @override
  String get ntf_a_reject => 'رفض';

  @override
  String get ntf_a_add_answer => 'أضف إجابة';

  @override
  String get ntf_a_claim => 'استلم';

  @override
  String get ntf_a_review => 'راجعها';

  @override
  String get ntf_a_reconnect => 'إعادة الربط';

  @override
  String get ntf_a_plans => 'عرض الخطط';

  @override
  String get ntf_a_update => 'تحديث';

  @override
  String get ntf_a_open => 'فتح';

  @override
  String get ntf_more => 'المزيد';

  @override
  String get ntf_dismiss => 'إخفاء';

  @override
  String get ntf_a11y_unread => 'غير مقروء';

  @override
  String ntf_a11y_filter(String f, int n) {
    return '$f، $n غير مقروءة';
  }

  @override
  String get ntf_muted => 'لن تصلك إشعارات من هذا النوع';

  @override
  String get ntf_push_unavailable => 'فعّل الإشعارات من إعدادات الجهاز';

  @override
  String get ntf_offline_action => 'هذا الإجراء يتطلب اتصالًا بالإنترنت';

  @override
  String get ntf_action_failed => 'تعذّر تنفيذ الإجراء. حاول مجددًا.';

  @override
  String get ntf_billing_agent_title => 'الاشتراك يديره المسؤول';

  @override
  String get ntf_billing_agent_body =>
      'اطلب من مسؤول مساحة العمل إدارة الاشتراك من موقع Wavadesk.';

  @override
  String get profile_title => 'ملف العميل';

  @override
  String get profile_add_tag => '+ وسم';

  @override
  String get profile_vip => 'عميل مميز';

  @override
  String get profile_blocked => 'محظور';

  @override
  String profile_local_time(String time) {
    return '$time بتوقيته';
  }

  @override
  String get profile_copied => 'تم النسخ';

  @override
  String get profile_call => 'اتصال';

  @override
  String get profile_whatsapp => 'واتساب';

  @override
  String get profile_note => 'ملاحظة';

  @override
  String get profile_block => 'حظر';

  @override
  String get profile_unblock => 'إلغاء الحظر';

  @override
  String get profile_stat_conversations => 'محادثات';

  @override
  String get profile_stat_orders => 'طلبات';

  @override
  String get profile_stat_rating => 'التقييم';

  @override
  String get profile_stat_first => 'أول تواصل';

  @override
  String get profile_ai_summary => 'ملخص الذكاء الاصطناعي';

  @override
  String get profile_ai_disclaimer => 'قد يحتوي الملخص على أخطاء';

  @override
  String get profile_more => 'المزيد';

  @override
  String get profile_notes => 'ملاحظات الفريق';

  @override
  String get profile_add => 'إضافة';

  @override
  String profile_all_notes(int n) {
    return 'عرض كل الملاحظات ($n)';
  }

  @override
  String get profile_no_notes => 'لا توجد ملاحظات بعد';

  @override
  String get profile_first_note => 'أضف أول ملاحظة';

  @override
  String get profile_pin => 'تثبيت';

  @override
  String get profile_edit => 'تعديل';

  @override
  String get profile_delete => 'حذف';

  @override
  String get profile_info => 'معلومات';

  @override
  String get profile_phone => 'الجوال';

  @override
  String get profile_email => 'البريد';

  @override
  String get profile_city => 'المدينة';

  @override
  String get profile_language => 'اللغة المفضلة';

  @override
  String get profile_timezone => 'المنطقة الزمنية';

  @override
  String get profile_added_by => 'أُضيف بواسطة';

  @override
  String get profile_not_set => 'غير محدد';

  @override
  String get profile_all_info => 'عرض كل المعلومات';

  @override
  String get profile_channels => 'القنوات';

  @override
  String profile_channel_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n محادثة',
      few: '$n محادثات',
      two: 'محادثتان',
      one: 'محادثة واحدة',
      zero: 'لا محادثات',
    );
    return '$_temp0';
  }

  @override
  String get profile_unlink => 'فصل هذه الهوية';

  @override
  String get profile_merge => 'دمج مع عميل آخر';

  @override
  String get profile_orders => 'الطلبات';

  @override
  String profile_total_spent(String sum) {
    return 'إجمالي المشتريات: $sum ر.س';
  }

  @override
  String get profile_previous => 'المحادثات السابقة';

  @override
  String get profile_all_channels => 'كل القنوات';

  @override
  String profile_closed_by(String date, String name) {
    return '$date · أغلقها $name';
  }

  @override
  String profile_ai_replied(String date) {
    return '$date · ردّ الذكاء الاصطناعي';
  }

  @override
  String profile_open_now(String date) {
    return '$date · مفتوحة الآن';
  }

  @override
  String get profile_load_more => 'عرض المزيد';

  @override
  String get profile_first_conv => 'هذه أول محادثة مع العميل';

  @override
  String get profile_block_cta => 'حظر العميل';

  @override
  String get profile_block_hint => 'لن تصلك رسائل هذا العميل بعد الحظر.';

  @override
  String get profile_erase => 'حذف بيانات العميل';

  @override
  String profile_visitor(String id) {
    return 'زائر #$id';
  }

  @override
  String get profile_add_details => 'أضف بيانات العميل';

  @override
  String get profile_offline => 'تعرض آخر نسخة محفوظة';

  @override
  String get profile_load_error => 'تعذّر تحميل ملف العميل';

  @override
  String profile_section_error(String section) {
    return 'تعذّر تحميل $section';
  }

  @override
  String get profile_retry => 'إعادة المحاولة';

  @override
  String get profile_open_page => 'فتح كصفحة';

  @override
  String profile_dialog_label(String name) {
    return 'ملف العميل، $name';
  }

  @override
  String get profile_unpin => 'إلغاء التثبيت';

  @override
  String get profile_regenerate => 'إعادة إنشاء الملخص';

  @override
  String profile_note_a11y(String author, String date, String text) {
    return 'ملاحظة من $author، $date: $text';
  }

  @override
  String get profile_delete_note_title => 'حذف الملاحظة؟';

  @override
  String get profile_delete_note_body =>
      'ستُحذف هذه الملاحظة لجميع أعضاء الفريق.';

  @override
  String profile_action_call_a11y(String name) {
    return 'اتصال بـ$name';
  }

  @override
  String profile_action_whatsapp_a11y(String name) {
    return 'واتساب $name';
  }

  @override
  String profile_action_note_a11y(String name) {
    return 'إضافة ملاحظة عن $name';
  }

  @override
  String profile_action_block_a11y(String name) {
    return 'حظر $name';
  }

  @override
  String profile_action_unblock_a11y(String name) {
    return 'إلغاء حظر $name';
  }

  @override
  String get profile_disabled_no_phone => 'غير متاح، لا يوجد رقم';

  @override
  String profile_stats_a11y(
    int conversations,
    String orders,
    String ordersLabel,
    String first,
  ) {
    return '$conversations محادثات، $orders $ordersLabel، أول تواصل $first';
  }

  @override
  String profile_order_items(String date, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n منتجًا',
      few: '$n منتجات',
      two: 'منتجان',
      one: 'منتج واحد',
    );
    return '$date · $_temp0';
  }

  @override
  String profile_amount(String amount) {
    return '$amount ر.س';
  }

  @override
  String get profile_order_processing => 'قيد التجهيز';

  @override
  String get profile_order_shipped => 'تم الشحن';

  @override
  String get profile_order_delivered => 'تم التوصيل';

  @override
  String get profile_order_cancelled => 'ملغي';

  @override
  String get profile_view_all => 'عرض الكل';

  @override
  String get profile_no_order_link => 'لا يوجد رابط لهذا الطلب';

  @override
  String get profile_lang_ar => 'العربية';

  @override
  String get profile_lang_en => 'English';

  @override
  String profile_tz_value(String tz, String time) {
    return '$tz · $time';
  }

  @override
  String get profile_attr_yes => 'نعم';

  @override
  String get profile_attr_no => 'لا';

  @override
  String get profile_unlinked => 'تم فصل الهوية';

  @override
  String get profile_filter_channel => 'تصفية حسب القناة';

  @override
  String get profile_merged => 'تم دمج هذا العميل';

  @override
  String get profile_more_actions => 'خيارات أخرى';

  @override
  String get profile_edit_contact => 'تعديل بيانات العميل';

  @override
  String get edit_title => 'تعديل بيانات العميل';

  @override
  String get edit_save => 'حفظ';

  @override
  String get edit_saved => 'تم حفظ التغييرات';

  @override
  String get edit_failed => 'تعذّر حفظ التغييرات. حاول مجددًا.';

  @override
  String get edit_discard_title => 'تجاهل التغييرات؟';

  @override
  String get edit_discard_body =>
      'لم تُحفظ تعديلاتك بعد. إذا خرجت الآن ستفقدها.';

  @override
  String get edit_discard => 'تجاهل';

  @override
  String get edit_keep => 'متابعة التعديل';

  @override
  String get edit_name => 'الاسم';

  @override
  String get edit_phone => 'الجوال';

  @override
  String get edit_email => 'البريد';

  @override
  String get edit_city => 'المدينة';

  @override
  String get edit_language => 'اللغة المفضلة';

  @override
  String get edit_not_set => 'غير محدد';

  @override
  String get edit_phone_invalid => 'رقم الجوال غير صحيح';

  @override
  String get edit_email_invalid => 'صيغة البريد غير صحيحة';

  @override
  String get tags_title => 'الوسوم';

  @override
  String get tags_search => 'ابحث أو أنشئ وسمًا';

  @override
  String tags_create(String q) {
    return 'إنشاء «$q»';
  }

  @override
  String get tags_done => 'تم';

  @override
  String get tags_failed => 'تعذّر حفظ الوسوم. حاول مجددًا.';

  @override
  String get tags_remove => 'إزالة الوسم';

  @override
  String get note_new => 'ملاحظة جديدة';

  @override
  String get note_edit_title => 'تعديل الملاحظة';

  @override
  String get note_placeholder => 'اكتب ما يجب أن يعرفه فريقك عن هذا العميل…';

  @override
  String get note_pin => 'تثبيت الملاحظة';

  @override
  String get note_save => 'حفظ';

  @override
  String get note_cancel => 'إلغاء';

  @override
  String get note_saved => 'أُضيفت الملاحظة';

  @override
  String get note_updated => 'تم تحديث الملاحظة';

  @override
  String get note_failed => 'تعذّر حفظ الملاحظة. حاول مجددًا.';

  @override
  String get call_phone => 'اتصال هاتفي';

  @override
  String get call_whatsapp => 'اتصال واتساب';

  @override
  String get call_copy => 'نسخ الرقم';

  @override
  String get call_cancel => 'إلغاء';

  @override
  String get call_copied => 'تم النسخ';

  @override
  String get call_failed => 'تعذّر فتح تطبيق الاتصال';

  @override
  String block_title(String name) {
    return 'حظر $name؟';
  }

  @override
  String get block_body =>
      'لن تصلك رسائله على أي قناة، وستُغلق محادثاته المفتوحة. يمكنك إلغاء الحظر لاحقًا.';

  @override
  String get block_reason_label => 'سبب الحظر (اختياري)';

  @override
  String get block_reason_spam => 'إزعاج';

  @override
  String get block_reason_fraud => 'احتيال';

  @override
  String get block_reason_abuse => 'لغة مسيئة';

  @override
  String get block_reason_other => 'أخرى';

  @override
  String get block_confirm => 'حظر';

  @override
  String get block_cancel => 'إلغاء';

  @override
  String get block_done => 'تم حظر العميل';

  @override
  String get block_failed => 'تعذّر حظر العميل. حاول مجددًا.';

  @override
  String get block_unnamed => 'هذا العميل';

  @override
  String get undo => 'تراجع';

  @override
  String get merge_title => 'دمج مع عميل آخر';

  @override
  String get merge_search => 'ابحث بالاسم أو الجوال أو البريد';

  @override
  String get merge_no_results => 'لا يوجد عملاء مطابقون';

  @override
  String get merge_unnamed => 'عميل بلا اسم';

  @override
  String get merge_into_label => 'سيُدمج في';

  @override
  String get merge_change => 'تغيير';

  @override
  String get merge_no_conflicts =>
      'لا توجد قيم متعارضة — ستُنقل كل المحادثات والملاحظات إلى العميل المختار.';

  @override
  String get merge_choose_values => 'اختر القيم التي تبقى';

  @override
  String get merge_field_name => 'الاسم';

  @override
  String get merge_field_phone => 'الجوال';

  @override
  String get merge_field_email => 'البريد';

  @override
  String get merge_field_city => 'المدينة';

  @override
  String get merge_this_contact => 'هذا العميل';

  @override
  String get merge_other_contact => 'العميل الآخر';

  @override
  String get merge_action => 'دمج';

  @override
  String get merge_confirm_title => 'لا يمكن التراجع عن الدمج';

  @override
  String get merge_confirm_body =>
      'ستُنقل المحادثات والملاحظات إلى العميل المختار ويُحذف هذا الملف.';

  @override
  String get merge_done => 'تم دمج العميل';

  @override
  String get merge_failed => 'تعذّر الدمج. حاول مجددًا.';

  @override
  String get erase_title => 'حذف بيانات العميل نهائيًا؟';

  @override
  String get erase_body =>
      'ستُحذف كل محادثات العميل وملاحظاته وبياناته ولا يمكن استرجاعها.';

  @override
  String get erase_type_digits => 'اكتب آخر 4 أرقام من جوال العميل للتأكيد';

  @override
  String erase_type_word(String word) {
    return 'اكتب «$word» للتأكيد';
  }

  @override
  String get erase_word => 'حذف';

  @override
  String get erase_confirm => 'حذف نهائي';

  @override
  String get erase_cancel => 'إلغاء';

  @override
  String get erase_done => 'تم حذف بيانات العميل';

  @override
  String get erase_failed => 'تعذّر حذف البيانات. حاول مجددًا.';

  @override
  String get search_placeholder => 'ابحث عن عميل، رسالة، أو رقم طلب';

  @override
  String get search_cancel => 'إلغاء';

  @override
  String get search_scope_all => 'الكل';

  @override
  String get search_scope_contacts => 'العملاء';

  @override
  String get search_scope_messages => 'الرسائل';

  @override
  String get search_scope_kb => 'المعرفة';

  @override
  String get search_scope_conversations => 'المحادثات';

  @override
  String get search_filters => 'فلاتر';

  @override
  String get search_section_contacts => 'العملاء';

  @override
  String get search_section_messages => 'الرسائل';

  @override
  String get search_section_kb => 'قاعدة المعرفة';

  @override
  String get search_section_conversations => 'المحادثات';

  @override
  String search_see_all(int n) {
    return 'عرض الكل ($n)';
  }

  @override
  String get search_best_match => 'أفضل نتيجة';

  @override
  String get search_open_chat => 'فتح المحادثة';

  @override
  String get search_profile => 'الملف';

  @override
  String get search_open_badge => 'مفتوحة';

  @override
  String search_more_in_conv(int n) {
    return '+$n نتائج أخرى في هذه المحادثة';
  }

  @override
  String search_kb_usage(int n) {
    return 'استخدمه الذكاء $n مرة هذا الشهر';
  }

  @override
  String get search_insert_reply => 'إدراج في الرد';

  @override
  String get search_you => 'أنت:';

  @override
  String get search_note => 'ملاحظة:';

  @override
  String search_order(String n) {
    return 'طلب $n';
  }

  @override
  String search_tag(String tag) {
    return 'وسم: $tag';
  }

  @override
  String get search_recent => 'عمليات البحث الأخيرة';

  @override
  String get search_clear => 'مسح';

  @override
  String get search_suggestions => 'اقتراحات';

  @override
  String get search_recent_contacts => 'آخر من تواصلت معهم';

  @override
  String get search_tip =>
      'ابحث بالاسم، رقم الجوال، رقم الطلب، أو أي كلمة في المحادثة';

  @override
  String search_no_results(String q) {
    return 'لا نتائج لـ «$q»';
  }

  @override
  String get search_no_results_body => 'جرّب كلمة أخرى أو تحقّق من الإملاء';

  @override
  String get search_clear_filters => 'مسح الفلاتر';

  @override
  String get search_in_all => 'البحث في الكل';

  @override
  String search_did_you_mean(String s) {
    return 'هل تقصد: $s؟';
  }

  @override
  String get search_error => 'تعذّر البحث';

  @override
  String get search_retry => 'إعادة المحاولة';

  @override
  String get search_offline => 'غير متصل — نتائج من البيانات المحفوظة فقط';

  @override
  String get search_local => '(محليًا)';

  @override
  String get search_filter_sender => 'المرسل';

  @override
  String get search_filter_contains => 'يحتوي على';

  @override
  String get search_filter_attachments => 'مرفقات';

  @override
  String get search_filter_images => 'صور';

  @override
  String get search_filter_voice => 'رسائل صوتية';

  @override
  String search_show_results(int n) {
    return 'عرض النتائج ($n)';
  }

  @override
  String get search_field_label => 'بحث';

  @override
  String search_filters_n(int n) {
    return 'فلاتر · $n';
  }

  @override
  String get search_filter_channel => 'القناة';

  @override
  String get search_filter_date => 'التاريخ';

  @override
  String get search_filter_status => 'حالة المحادثة';

  @override
  String get search_filter_assignee => 'المسؤول';

  @override
  String get search_date_any => 'أي وقت';

  @override
  String get search_date_today => 'اليوم';

  @override
  String get search_date_7 => '7 أيام';

  @override
  String get search_date_30 => '30 يومًا';

  @override
  String get search_date_custom => 'مخصص';

  @override
  String get search_sender_all => 'الكل';

  @override
  String get search_sender_contact => 'العميل';

  @override
  String get search_sender_me => 'أنا';

  @override
  String get search_sender_colleagues => 'الزملاء';

  @override
  String get search_sender_ai => 'الذكاء الاصطناعي';

  @override
  String get search_sender_notes => 'ملاحظات داخلية';

  @override
  String get search_status_all => 'الكل';

  @override
  String get search_status_open => 'مفتوحة';

  @override
  String get search_status_resolved => 'محلولة';

  @override
  String get search_assignee_all => 'الكل';

  @override
  String get search_assignee_me => 'أنا';

  @override
  String get search_assignee_colleague => 'زميل';

  @override
  String get search_sugg_unread => 'غير مقروءة';

  @override
  String get search_sugg_awaiting => 'بانتظار الرد';

  @override
  String get search_sugg_vip => 'وسم: VIP';

  @override
  String get search_sugg_orders_today => 'طلبات اليوم';

  @override
  String search_recent_remove(String q) {
    return 'حذف $q من السجل';
  }

  @override
  String get search_recents_cleared => 'تم مسح سجل البحث';

  @override
  String search_results_announce(int n, String parts) {
    return '$n نتائج: $parts';
  }

  @override
  String search_announce_contacts(int n) {
    return '$n عميل';
  }

  @override
  String search_announce_messages(int n) {
    return '$n رسائل';
  }

  @override
  String search_announce_kb(int n) {
    return '$n مقال';
  }

  @override
  String search_announce_conversations(int n) {
    return '$n محادثات';
  }

  @override
  String search_a11y_message(String name, String time, String text) {
    return 'رسالة من $name، $time: $text';
  }

  @override
  String get search_last_chat => 'فتح المحادثة الأخيرة';

  @override
  String get search_new_chat => 'محادثة جديدة';

  @override
  String get search_copy_number => 'نسخ الرقم';

  @override
  String get search_copied => 'تم نسخ الرقم';

  @override
  String get search_call => 'اتصال';

  @override
  String get search_section_teammates => 'الزملاء';

  @override
  String get search_no_chat_yet => 'لا توجد محادثة سابقة مع هذا العميل';

  @override
  String get search_inserted => 'تم إدراج الإجابة في الرد';

  @override
  String get search_in_conv_placeholder => 'ابحث في هذه المحادثة';

  @override
  String search_in_conv_count(int i, int n) {
    return '$i من $n';
  }

  @override
  String get search_in_conv_action => 'بحث في المحادثة';

  @override
  String get search_in_conv_prev => 'المطابقة السابقة';

  @override
  String get search_in_conv_next => 'المطابقة التالية';

  @override
  String get search_in_conv_close => 'إغلاق البحث';

  @override
  String get startup_unavailable_title => 'تعذّر الاتصال حاليًا';

  @override
  String get startup_unavailable_body =>
      'لم يتمكّن Wavadesk من الوصول إلى الخوادم. تأكّد من أنك تستخدم أحدث إصدار من التطبيق، ثم أعد المحاولة.';

  @override
  String get startup_unavailable_help =>
      'ما زالت المشكلة قائمة؟ تواصل معنا عبر support@wavadesk.com';

  @override
  String get startup_retry => 'إعادة المحاولة';

  @override
  String get startup_contact_support => 'التواصل مع الدعم';

  @override
  String get startup_dev_hint =>
      'للمطوّر: عنوان الـ API أو المفتاح غير موجود. شغّل التطبيق مع --dart-define-from-file=dart_defines/<env>.json أو املأ assets/config/api.json.';

  @override
  String get wa_title => 'واتساب الخاص بك';

  @override
  String get wa_refresh => 'تحديث الحالة';

  @override
  String get wa_log => 'سجل الاتصال';

  @override
  String get wa_help => 'المساعدة';

  @override
  String get wa_connected => 'متصل';

  @override
  String get wa_connecting => 'جارٍ الاتصال';

  @override
  String get wa_syncing => 'جارٍ المزامنة';

  @override
  String get wa_phone_offline => 'الهاتف غير متصل';

  @override
  String get wa_disconnected => 'غير متصل';

  @override
  String get wa_restricted => 'مقيّد';

  @override
  String get wa_pending => 'غير مربوط';

  @override
  String get wa_msgs_today => 'رسالة اليوم';

  @override
  String get wa_quality => 'جودة الرقم';

  @override
  String get wa_q_high => 'عالية';

  @override
  String get wa_q_med => 'متوسطة';

  @override
  String get wa_q_low => 'منخفضة';

  @override
  String get wa_stable => 'مستقرة';

  @override
  String get wa_unstable => 'غير مستقرة';

  @override
  String get wa_linked_since => 'مرتبط منذ';

  @override
  String wa_days(String n) {
    return '$n يومًا';
  }

  @override
  String wa_alert_disc_title(String t) {
    return 'انقطع الاتصال منذ $t';
  }

  @override
  String get wa_alert_disc_body => 'لن تصل رسائل العملاء حتى تعيد الربط';

  @override
  String get wa_reconnect => 'إعادة الربط';

  @override
  String get wa_alert_phone_title => 'هاتفك غير متصل بالإنترنت';

  @override
  String get wa_alert_phone_body => 'تأكد أن واتساب يعمل على الهاتف المرتبط';

  @override
  String get wa_check_again => 'تحقق مجددًا';

  @override
  String get wa_alert_quality => 'جودة الرقم منخفضة';

  @override
  String get wa_alert_quality_body =>
      'قلّل الرسائل الجماعية وتجنّب المحتوى المكرر';

  @override
  String get wa_details => 'التفاصيل';

  @override
  String wa_alert_limit(String l, String u) {
    return 'اقتربت من حد المحادثات اليومي ($u/$l)';
  }

  @override
  String get wa_alert_update => 'حدّث تطبيق واتساب على هاتفك';

  @override
  String get wa_alert_pending => 'لم يتم ربط واتساب بعد';

  @override
  String get wa_alert_pending_body => 'اربط رقمك لتبدأ باستقبال رسائل العملاء';

  @override
  String get wa_connect => 'اربط واتساب';

  @override
  String get wa_auto => 'الرسائل التلقائية';

  @override
  String get wa_welcome => 'رسالة الترحيب';

  @override
  String get wa_away => 'رسالة خارج الدوام';

  @override
  String get wa_away_ai => 'يتولاها الذكاء الاصطناعي حاليًا';

  @override
  String get wa_quick => 'الردود السريعة';

  @override
  String get wa_welcome_delay => 'مهلة رسالة الترحيب';

  @override
  String get wa_now => 'فورًا';

  @override
  String get wa_welcome_off => 'تم إيقاف رسالة الترحيب';

  @override
  String get wa_undo => 'تراجع';

  @override
  String get wa_templates => 'القوالب المعتمدة';

  @override
  String get wa_tpl_marketing => 'تسويق';

  @override
  String get wa_tpl_utility => 'خدمة';

  @override
  String get wa_tpl_auth => 'مصادقة';

  @override
  String get wa_tpl_approved => 'معتمد';

  @override
  String get wa_tpl_pending => 'قيد المراجعة';

  @override
  String get wa_tpl_rejected => 'مرفوض';

  @override
  String get wa_tpl_manage_web => 'إدارة القوالب على الويب';

  @override
  String get wa_numbers => 'الأرقام';

  @override
  String get wa_add_second => 'أضف رقمًا ثانيًا';

  @override
  String get wa_business_only => 'متاح في خطة Business';

  @override
  String get wa_upgrade => 'ترقية';

  @override
  String get wa_add_number => 'أضف رقمًا';

  @override
  String get wa_watch => 'شاهد: كيف تربط واتساب';

  @override
  String wa_watch_sub(String d) {
    return 'شرح بالفيديو · $d';
  }

  @override
  String get wa_advanced => 'متقدم';

  @override
  String get wa_read_receipts => 'إيصالات القراءة للعميل';

  @override
  String get wa_mark_read_open => 'تمييز الرسائل كمقروءة عند الفتح';

  @override
  String get wa_auto_transcribe => 'الرسائل الصوتية: تحويل لنص تلقائيًا';

  @override
  String get wa_ignore_groups => 'تجاهل رسائل المجموعات';

  @override
  String get wa_blocked => 'الأرقام المحظورة';

  @override
  String get wa_hours => 'ساعات العمل';

  @override
  String get wa_disconnect => 'فصل الرقم';

  @override
  String get wa_disc_title => 'فصل رقم واتساب؟';

  @override
  String get wa_disc_body =>
      'لن تصل رسائل العملاء إلى Wavadesk، وسيتوقف الذكاء الاصطناعي عن الرد. ستبقى المحادثات السابقة محفوظة.';

  @override
  String wa_disc_open(String n) {
    return '$n محادثات مفتوحة ستتوقف';
  }

  @override
  String get wa_disc_confirm_label => 'اكتب آخر 4 أرقام من الرقم للتأكيد';

  @override
  String get wa_disc_done => 'تم فصل الرقم';

  @override
  String get wa_connect_title => 'ربط واتساب';

  @override
  String wa_step(String i, String n) {
    return 'الخطوة $i من $n';
  }

  @override
  String get wa_by_phone => 'رقم الهاتف';

  @override
  String get wa_by_qr => 'رمز QR';

  @override
  String get wa_get_code => 'احصل على الرمز';

  @override
  String get wa_copy => 'نسخ';

  @override
  String wa_expires_in(String t) {
    return 'ينتهي خلال $t';
  }

  @override
  String get wa_steps_pair =>
      'افتح واتساب ← الإعدادات ← الأجهزة المرتبطة ← ربط جهاز ← الربط برقم الهاتف بدلًا من ذلك ← أدخل الرمز';

  @override
  String get wa_open_app => 'فتح واتساب';

  @override
  String get wa_linked_ok => 'تم ربط واتساب بنجاح';

  @override
  String get wa_syncing_recent => 'جارٍ مزامنة المحادثات الأخيرة…';

  @override
  String get wa_back => 'العودة';

  @override
  String get wa_back_online => 'عاد الاتصال · لم تُفقد أي رسالة';

  @override
  String get wa_code_expired => 'انتهت صلاحية الرمز';

  @override
  String get wa_new_code => 'رمز جديد';

  @override
  String get wa_number_taken => 'هذا الرقم مرتبط بمساحة عمل أخرى';

  @override
  String get wa_watch_video => 'شاهد الشرح بالفيديو';

  @override
  String get wa_welcome_when => 'متى تُرسل؟';

  @override
  String get wa_trigger_first => 'أول رسالة من عميل جديد';

  @override
  String get wa_trigger_new => 'كل محادثة جديدة';

  @override
  String get wa_trigger_24h => 'بعد غياب 24 ساعة';

  @override
  String get wa_buttons => 'أزرار سريعة';

  @override
  String get wa_ai_after_welcome =>
      'سيرد الذكاء الاصطناعي بعد رسالة الترحيب مباشرة';

  @override
  String get wa_away_outside => 'خارج ساعات العمل';

  @override
  String get wa_away_team => 'عندما يكون كل الفريق غير متاح';

  @override
  String wa_away_cooldown(String n) {
    return 'مرة كل $n ساعات لنفس العميل';
  }

  @override
  String get wa_away_ai_banner =>
      'الذكاء الاصطناعي يرد خارج الدوام — عدّل ذلك من إعدادات الذكاء';

  @override
  String get wa_qr_team => 'للفريق';

  @override
  String get wa_qr_mine => 'الخاصة بي';

  @override
  String get wa_qr_title_f => 'العنوان';

  @override
  String get wa_qr_shortcut => 'الاختصار';

  @override
  String get wa_qr_text => 'النص';

  @override
  String get wa_qr_shared => 'مشترك مع الفريق';

  @override
  String get wa_notify_admin => 'أبلغ المسؤول';

  @override
  String get wa_load_error => 'تعذّر تحميل حالة واتساب';

  @override
  String get wa_enable_after => 'فعّلها بعد ربط الرقم';

  @override
  String get wa_more => 'المزيد';

  @override
  String wa_last_updated(String t) {
    return 'آخر تحديث $t';
  }

  @override
  String get wa_copied => 'تم النسخ';

  @override
  String get wa_details_title => 'تفاصيل الاتصال';

  @override
  String get wa_d_type => 'نوع الربط';

  @override
  String get wa_d_type_linked => 'جهاز مرتبط';

  @override
  String get wa_d_type_cloud => 'واجهة واتساب الرسمية';

  @override
  String get wa_d_device => 'الجهاز';

  @override
  String wa_d_wa_business(String v) {
    return 'واتساب أعمال $v';
  }

  @override
  String wa_d_wa_personal(String v) {
    return 'واتساب $v';
  }

  @override
  String get wa_d_last_activity => 'آخر نشاط';

  @override
  String get wa_d_sync => 'حالة المزامنة';

  @override
  String get wa_d_synced => 'متزامنة';

  @override
  String get wa_d_number_id => 'معرّف الرقم';

  @override
  String get wa_d_daily_limit => 'حد المحادثات اليومي';

  @override
  String wa_d_limit_value(String l, String u) {
    return '$u من $l';
  }

  @override
  String get wa_unknown => 'غير معروف';

  @override
  String get wa_qs_explain =>
      'تعتمد جودة الرقم على تفاعل العملاء مع رسائلك خلال آخر 7 أيام. الحظر والبلاغات وانخفاض التفاعل تخفضها.';

  @override
  String get wa_qs_tier => 'فئة المراسلة';

  @override
  String wa_qs_tier_value(String tier) {
    return '$tier محادثة يوميًا';
  }

  @override
  String get wa_qs_trend => 'آخر 7 أيام';

  @override
  String get wa_qs_tips => 'نصائح لرفع الجودة';

  @override
  String get wa_qs_tip1 => 'راسل فقط العملاء الذين طلبوا التواصل';

  @override
  String get wa_qs_tip2 => 'خصّص الرسائل وتجنّب النصوص المكررة';

  @override
  String get wa_qs_tip3 => 'اجعل إيقاف الرسائل سهلًا للعميل';

  @override
  String get wa_qs_help => 'مركز مساعدة واتساب';

  @override
  String get wa_log_connected => 'تم الربط';

  @override
  String wa_log_connected_by(String name) {
    return 'ربطه $name';
  }

  @override
  String wa_log_disconnected(String d) {
    return 'انقطع الاتصال · $d';
  }

  @override
  String get wa_log_reconnected => 'أُعيد الربط';

  @override
  String wa_log_reconnected_by(String name) {
    return 'أعاد $name الربط';
  }

  @override
  String wa_log_recovered(String n) {
    return 'استُعيدت $n رسالة';
  }

  @override
  String get wa_reason_phone_offline => 'الهاتف غير متصل';

  @override
  String get wa_reason_logged_out => 'تسجيل خروج';

  @override
  String get wa_reason_update => 'تحديث';

  @override
  String get wa_log_empty => 'لا توجد أحداث خلال آخر 30 يومًا';

  @override
  String get wa_cancel => 'إلغاء';

  @override
  String get wa_disc_mismatch => 'الأرقام غير مطابقة';

  @override
  String get wa_disc_failed => 'تعذّر فصل الرقم';

  @override
  String get wa_notify_sent => 'تم إبلاغ المسؤول';

  @override
  String get wa_save_failed => 'تعذّر حفظ التغيير';

  @override
  String get wa_retry => 'إعادة المحاولة';

  @override
  String get wa_offline => 'التعديل يتطلب اتصالًا بالإنترنت';

  @override
  String get wa_saved => 'تم الحفظ';

  @override
  String get wa_welcome_on => 'تم تفعيل رسالة الترحيب';

  @override
  String get wa_away_on => 'تم تفعيل رسالة خارج الدوام';

  @override
  String get wa_away_off => 'تم إيقاف رسالة خارج الدوام';

  @override
  String get wa_delay_30s => 'بعد 30 ثانية';

  @override
  String get wa_delay_1m => 'بعد دقيقة';

  @override
  String get wa_delay_2m => 'بعد دقيقتين';

  @override
  String get wa_delay_5m => 'بعد 5 دقائق';

  @override
  String get wa_save => 'حفظ';

  @override
  String get wa_welcome_enable => 'تفعيل رسالة الترحيب';

  @override
  String get wa_away_enable => 'تفعيل رسالة خارج الدوام';

  @override
  String get wa_message => 'الرسالة';

  @override
  String get wa_message_hint => 'اكتب الرسالة…';

  @override
  String get wa_send_when => 'الإرسال';

  @override
  String get wa_buttons_hint => 'حتى 3 أزرار، 20 حرفًا لكل زر';

  @override
  String get wa_button_add => '+ أضف زرًا';

  @override
  String get wa_button_hint => 'نص الزر';

  @override
  String get wa_preview => 'معاينة';

  @override
  String get wa_err_text => 'اكتب الرسالة (1–1024 حرفًا)';

  @override
  String get wa_err_button => 'نص الزر أطول من 20 حرفًا';

  @override
  String get wa_go_ai => 'إعدادات الذكاء';

  @override
  String get wa_discard_title => 'تجاهل التغييرات؟';

  @override
  String get wa_discard_body => 'لن تُحفظ تعديلاتك.';

  @override
  String get wa_discard => 'تجاهل';

  @override
  String get wa_keep => 'متابعة التعديل';

  @override
  String get wa_qr_new => 'رد سريع جديد';

  @override
  String get wa_qr_edit => 'تعديل الرد السريع';

  @override
  String get wa_qr_search => 'ابحث في الردود';

  @override
  String get wa_qr_empty => 'لا توجد ردود سريعة بعد';

  @override
  String get wa_qr_empty_body => 'أنشئ ردًا واستخدمه بكتابة / في المحادثة';

  @override
  String get wa_qr_no_results => 'لا نتائج';

  @override
  String get wa_qr_add => 'أضف ردًا';

  @override
  String wa_qr_used(String n) {
    return 'استُخدم $n مرة';
  }

  @override
  String wa_qr_delete_title(String title) {
    return 'حذف «$title»؟';
  }

  @override
  String get wa_qr_delete_body => 'لن يظهر في قائمة / بعد الآن.';

  @override
  String get wa_delete => 'حذف';

  @override
  String get wa_qr_deleted => 'تم حذف الرد';

  @override
  String get wa_qr_delete_failed => 'تعذّر حذف الرد';

  @override
  String get wa_qr_attach => 'إرفاق صورة أو ملف';

  @override
  String get wa_qr_attach_hint => 'اختياري · حتى 5 ميجابايت';

  @override
  String get wa_qr_attach_too_big => 'الملف أكبر من 5 ميجابايت';

  @override
  String get wa_qr_attach_remove => 'إزالة المرفق';

  @override
  String get wa_qr_err_title => 'اكتب العنوان';

  @override
  String get wa_qr_err_text => 'اكتب النص';

  @override
  String get wa_qr_err_shortcut_empty => 'اكتب الاختصار';

  @override
  String get wa_qr_err_shortcut_invalid => 'استخدم a–z و0–9 و_ و- فقط';

  @override
  String get wa_qr_err_shortcut_taken => 'هذا الاختصار مستخدم';

  @override
  String get wa_qr_err_shortcut_long => 'الاختصار طويل جدًا';

  @override
  String get wa_qr_saved => 'تم حفظ الرد';

  @override
  String get wa_qr_save_failed => 'تعذّر حفظ الرد';

  @override
  String get wa_qr_reorder_failed => 'تعذّر حفظ الترتيب';

  @override
  String get wa_qr_shared_sub => 'يظهر لكل أعضاء الفريق';

  @override
  String get wa_qr_readonly => 'ردود الفريق يعدّلها المسؤول فقط';

  @override
  String get wa_tpl_empty => 'لا توجد قوالب معتمدة بعد';

  @override
  String get wa_tpl_preview => 'معاينة القالب';

  @override
  String get wa_phone_hint => '5X XXX XXXX';

  @override
  String get wa_err_phone => 'أدخل رقمًا صحيحًا';

  @override
  String get wa_rate_limited => 'محاولات كثيرة، حاول بعد قليل';

  @override
  String get wa_multi_device =>
      'هذا الحساب لا يدعم الأجهزة المرتبطة؛ حدّث واتساب ثم حاول مجددًا';

  @override
  String get wa_connect_failed => 'تعذّر الربط، حاول مجددًا';

  @override
  String get wa_network_error => 'لا يوجد اتصال بالإنترنت';

  @override
  String get wa_qr_steps =>
      'افتح واتساب على الهاتف الآخر ← الإعدادات ← الأجهزة المرتبطة ← ربط جهاز ← امسح الرمز';

  @override
  String wa_qr_refresh_in(String s) {
    return 'يتجدد خلال $s ث';
  }

  @override
  String get wa_qr_alt => 'رمز QR لربط واتساب، يتجدد كل 20 ثانية';

  @override
  String get wa_waiting_link => 'بانتظار إدخال الرمز على هاتفك…';

  @override
  String get wa_change_number => 'تغيير الرقم';

  @override
  String get wa_phone_tip =>
      'الربط برقم الهاتف أسهل عند استخدام نفس الجهاز، ولا يمكن مسح رمز QR بنفس الهاتف.';

  @override
  String get wa_plan_title => 'واتساب غير متاح في خطتك';

  @override
  String get wa_plan_body => 'رقِّ خطتك لربط رقم واتساب واستقبال رسائل العملاء';

  @override
  String get wa_view_plans => 'عرض الخطط';

  @override
  String get wa_upgrade_info => 'تواصل مع مالك مساحة العمل للترقية';

  @override
  String get wa_blocked_empty => 'لا توجد أرقام محظورة';

  @override
  String get wa_unblock => 'إلغاء الحظر';

  @override
  String get wa_unblocked => 'تم إلغاء الحظر';

  @override
  String wa_card_a11y(
    String d,
    String n,
    String name,
    String phone,
    String q,
    String status,
  ) {
    return '$name، $phone، $status. $n رسالة اليوم، جودة الرقم $q، مرتبط منذ $d يومًا';
  }

  @override
  String get wa_save_disabled => 'أكمل الحقول المطلوبة';

  @override
  String wa_log_disconnected_by(String name) {
    return 'فصله $name';
  }

  @override
  String get wa_log_connect_started => 'بدأت محاولة ربط';

  @override
  String wa_log_connect_started_by(String name) {
    return 'بدأ $name محاولة ربط';
  }

  @override
  String get wa_already_linked => 'الرقم مرتبط بالفعل';

  @override
  String get wa_banned => 'حظر واتساب هذا الرقم';

  @override
  String get wa_demo_state => 'حالة تجريبية';
}
