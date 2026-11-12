// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String dashboard_greeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get dashboard_open => 'Open conversations';

  @override
  String get dashboard_waiting_sla => 'Waiting over SLA';

  @override
  String get dashboard_view_queue => 'View queue';

  @override
  String get dashboard_first_response => 'Avg. first response';

  @override
  String get dashboard_resolved_today => 'Resolved today';

  @override
  String get dashboard_ai_rate => 'Resolved by AI';

  @override
  String get dashboard_csat => 'Customer satisfaction';

  @override
  String get dashboard_csat_scale => 'out of 5';

  @override
  String dashboard_vs_yesterday(String delta) {
    return '$delta vs yesterday';
  }

  @override
  String get dashboard_volume_title => 'Conversations today';

  @override
  String dashboard_volume_a11y(int total, int peak, String hour) {
    return '$total conversations today, peak of $peak at $hour';
  }

  @override
  String get dashboard_channels_title => 'By channel';

  @override
  String get dashboard_ai_usage_title => 'AI usage';

  @override
  String get dashboard_ai_manage => 'Manage';

  @override
  String dashboard_ai_usage_value(int used, int quota) {
    return '$used of $quota replies this month';
  }

  @override
  String get dashboard_team_title => 'Team right now';

  @override
  String dashboard_team_open(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats',
      one: '1 chat',
      zero: 'No chats',
    );
    return '$_temp0';
  }

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_mark_all => 'Mark all as read';

  @override
  String get notifications_earlier => 'Earlier';

  @override
  String get notifications_empty_title => 'No notifications yet';

  @override
  String get notifications_empty_body =>
      'We\'ll let you know when a chat is assigned to you or you\'re mentioned in a note.';

  @override
  String get knowledge_search => 'Search knowledge';

  @override
  String get knowledge_search_hint => 'Search answers…';

  @override
  String get knowledge_add => 'Add answer';

  @override
  String get knowledge_filter_all => 'All';

  @override
  String get knowledge_type_faq => 'FAQs';

  @override
  String get knowledge_type_policy => 'Policies';

  @override
  String get knowledge_type_product => 'Products';

  @override
  String get knowledge_type_snippet => 'Snippets';

  @override
  String get knowledge_type_website => 'Website';

  @override
  String get knowledge_coverage_title => 'What the AI knows';

  @override
  String knowledge_coverage_body(int total, int enabled) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total answers',
      one: '1 answer',
    );
    return '$_temp0, $enabled enabled';
  }

  @override
  String knowledge_coverage_top(String title) {
    return 'Most used: $title';
  }

  @override
  String knowledge_used(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used $count times',
      one: 'Used once',
      zero: 'Not used yet',
    );
    return '$_temp0';
  }

  @override
  String knowledge_updated(String time) {
    return 'Updated $time';
  }

  @override
  String get knowledge_disabled => 'Off';

  @override
  String knowledge_enabled_a11y(String title) {
    return 'Enable “$title”';
  }

  @override
  String get knowledge_empty_title => 'Your knowledge base is empty';

  @override
  String get knowledge_empty_body =>
      'Add answers and policies so the AI can draft replies from them.';

  @override
  String get knowledge_empty_filtered => 'No answers of this type';

  @override
  String knowledge_no_results(String query) {
    return 'No results for “$query”';
  }

  @override
  String get knowledge_edit_title_add => 'Add answer';

  @override
  String get knowledge_edit_title_edit => 'Edit answer';

  @override
  String get knowledge_edit_type => 'Type';

  @override
  String get knowledge_edit_question => 'Question';

  @override
  String get knowledge_edit_title_label => 'Title';

  @override
  String get knowledge_edit_title_hint => 'e.g. How long does delivery take?';

  @override
  String get knowledge_edit_body_label => 'Answer';

  @override
  String get knowledge_edit_body_hint =>
      'Write the answer the way you want the AI to say it…';

  @override
  String knowledge_edit_counter(int count, int max) {
    return '$count / $max';
  }

  @override
  String get knowledge_edit_keywords => 'Keywords';

  @override
  String get knowledge_edit_keywords_hint => 'Type a keyword and press enter';

  @override
  String get knowledge_edit_keyword_add => 'Add keyword';

  @override
  String get knowledge_edit_enabled => 'Available to the AI';

  @override
  String get knowledge_edit_enabled_sub =>
      'When off, it won\'t be used in suggestions';

  @override
  String get knowledge_edit_preview_title => 'How the AI will use it';

  @override
  String get knowledge_edit_preview_q => 'The customer\'s question shows here';

  @override
  String get knowledge_edit_preview_a =>
      'And the suggested reply based on your answer';

  @override
  String get knowledge_edit_error_title => 'Title is required';

  @override
  String get knowledge_edit_error_body =>
      'Write an answer of at least 10 characters';

  @override
  String get knowledge_edit_saved => 'Answer saved';

  @override
  String get knowledge_edit_delete => 'Delete answer';

  @override
  String get knowledge_edit_delete_title => 'Delete this answer?';

  @override
  String get knowledge_edit_delete_body =>
      'The AI will no longer use it to suggest replies.';

  @override
  String get knowledge_edit_deleted => 'Answer deleted';

  @override
  String get knowledge_edit_discard_title => 'Discard changes?';

  @override
  String get knowledge_edit_discard_body =>
      'You have unsaved edits that will be lost if you leave now.';

  @override
  String get knowledge_edit_discard_confirm => 'Discard and leave';

  @override
  String get account_section_admin => 'Management';

  @override
  String get account_section_app => 'App';

  @override
  String get account_whatsapp => 'Your WhatsApp';

  @override
  String get account_whatsapp_connected => 'Connected';

  @override
  String get account_whatsapp_disconnected => 'Disconnected';

  @override
  String get account_channels => 'Channels';

  @override
  String get account_ai_agent => 'AI agent';

  @override
  String get account_team => 'Team & users';

  @override
  String get account_subscription => 'Subscription';

  @override
  String get account_notifications => 'Notifications';

  @override
  String get account_language => 'Language';

  @override
  String get account_appearance => 'Appearance';

  @override
  String get account_theme_light => 'Light';

  @override
  String get account_theme_dark => 'Dark';

  @override
  String get account_theme_system => 'Automatic';

  @override
  String get account_theme_system_sub => 'Follows your device setting';

  @override
  String get account_help => 'Help & guides';

  @override
  String get account_logout => 'Log out';

  @override
  String get account_logout_title => 'Log out?';

  @override
  String get account_logout_body =>
      'You won\'t get conversation notifications on this device until you sign in again.';

  @override
  String account_version(String version) {
    return 'Wavadesk $version';
  }

  @override
  String get account_network_online => 'Online';

  @override
  String get ai_settings_title => 'AI agent';

  @override
  String get ai_settings_enable => 'Enable AI agent';

  @override
  String get ai_settings_status_on => 'Active and suggesting replies';

  @override
  String get ai_settings_status_off => 'Off';

  @override
  String ai_settings_usage(int used, int quota) {
    return '$used of $quota replies this month';
  }

  @override
  String get ai_settings_section_behavior => 'Behavior';

  @override
  String get ai_settings_suggest => 'Suggest replies';

  @override
  String get ai_settings_suggest_sub =>
      'A draft is ready before you open the chat';

  @override
  String get ai_settings_auto => 'Auto-reply';

  @override
  String get ai_settings_auto_sub =>
      'Replies to unassigned chats without waiting';

  @override
  String get ai_settings_claimed => 'Reply after claim';

  @override
  String get ai_settings_claimed_sub =>
      'Keeps replying after an agent claims the chat';

  @override
  String get ai_settings_handoff => 'Hand off on frustration';

  @override
  String get ai_settings_handoff_sub =>
      'Passes the chat to the team if the customer seems upset';

  @override
  String get ai_settings_section_tone => 'Reply tone';

  @override
  String get ai_settings_tone_friendly => 'Friendly';

  @override
  String get ai_settings_tone_friendly_sub => 'Warm and approachable';

  @override
  String get ai_settings_tone_formal => 'Formal';

  @override
  String get ai_settings_tone_formal_sub => 'Polite and professional';

  @override
  String get ai_settings_tone_concise => 'Concise';

  @override
  String get ai_settings_tone_concise_sub => 'Short, direct sentences';

  @override
  String get ai_settings_section_knowledge => 'Knowledge source';

  @override
  String get ai_settings_knowledge => 'Enabled answers';

  @override
  String get ai_settings_knowledge_footer =>
      'The AI only uses your knowledge base and never makes things up.';

  @override
  String get whatsapp_title => 'Your WhatsApp';

  @override
  String get whatsapp_status_connected => 'Connected';

  @override
  String get whatsapp_status_disconnected => 'Disconnected';

  @override
  String get whatsapp_since => 'Connected since';

  @override
  String get whatsapp_messages_today => 'Messages today';

  @override
  String get whatsapp_connected_tip =>
      'Keep your phone online. If you log out of WhatsApp on the phone you\'ll need to scan the code again.';

  @override
  String get whatsapp_disconnect => 'Disconnect';

  @override
  String get whatsapp_disconnect_title => 'Disconnect WhatsApp?';

  @override
  String get whatsapp_disconnect_body =>
      'Customer messages will stop reaching your inbox until you link the number again.';

  @override
  String get whatsapp_qr_a11y => 'QR code to link WhatsApp';

  @override
  String get whatsapp_qr_expires => 'The code expires in one minute';

  @override
  String get whatsapp_waiting_scan => 'Waiting for your phone to scan…';

  @override
  String get whatsapp_steps_title => 'How to link';

  @override
  String get whatsapp_step1 => 'Open WhatsApp on the business phone';

  @override
  String get whatsapp_step2 => 'Tap ⋮ then “Linked devices”';

  @override
  String get whatsapp_step3 => 'Choose “Link a device”';

  @override
  String get whatsapp_step4 => 'Point the camera at this code';

  @override
  String get whatsapp_simulate_scan => 'Scan code (demo)';

  @override
  String get whatsapp_new_code => 'Generate new code';

  @override
  String get whatsapp_connected_toast => 'WhatsApp linked successfully';

  @override
  String get channels_title => 'Channels';

  @override
  String get channels_section_connected => 'Connected';

  @override
  String get channels_section_available => 'Available';

  @override
  String get channels_connected => 'Connected and receiving messages';

  @override
  String get channels_not_connected => 'Not linked';

  @override
  String get channels_manage_on_web =>
      'This channel is managed from the web dashboard';

  @override
  String get channels_footer =>
      'Messages from every linked channel land in one inbox.';

  @override
  String get team_title => 'Team & users';

  @override
  String get team_invite => 'Invite a colleague';

  @override
  String get team_invite_sent => 'Invite link sent';

  @override
  String team_section_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get team_section_teams => 'Teams';

  @override
  String team_you(String name) {
    return '$name (you)';
  }

  @override
  String team_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get subscription_title => 'Subscription';

  @override
  String get subscription_current => 'Current plan';

  @override
  String get subscription_plan_name => 'Professional';

  @override
  String get subscription_price => 'SAR 199 / month';

  @override
  String subscription_renews(String date) {
    return 'Renews on $date';
  }

  @override
  String get subscription_section_usage => 'Usage this month';

  @override
  String get subscription_ai_replies => 'AI replies';

  @override
  String get subscription_agents => 'Users';

  @override
  String get subscription_channels => 'Channels';

  @override
  String subscription_usage(String used, String total) {
    return '$used / $total';
  }

  @override
  String get subscription_upgrade => 'Upgrade plan';

  @override
  String get subscription_invoices => 'Invoices';

  @override
  String get subscription_upgrade_web =>
      'We\'ll open the billing page on the web';

  @override
  String get notif_settings_title => 'Notifications';

  @override
  String get notif_settings_section_push => 'Notify me when';

  @override
  String get notif_settings_assigned => 'A chat is assigned to me';

  @override
  String get notif_settings_assigned_sub => 'By a colleague or a routing rule';

  @override
  String get notif_settings_mentions => 'I\'m mentioned in a note';

  @override
  String get notif_settings_mentions_sub => 'When a colleague types @your-name';

  @override
  String get notif_settings_waiting => 'Waiting time exceeded';

  @override
  String get notif_settings_waiting_sub =>
      'A customer waits longer than the target';

  @override
  String get notif_settings_section_sound => 'Sound';

  @override
  String get notif_settings_sound => 'Notification sound';

  @override
  String get notif_settings_sound_sub =>
      'Play a sound when a new message arrives';

  @override
  String get notif_settings_footer =>
      'You won\'t get notifications while your status is “Away”.';

  @override
  String get help_title => 'Help & guides';

  @override
  String get help_section_guides => 'Guides';

  @override
  String get help_topic_claim => 'Claiming and assigning chats';

  @override
  String get help_topic_ai => 'How AI suggestions work';

  @override
  String get help_topic_whatsapp => 'Linking a WhatsApp number';

  @override
  String get help_topic_knowledge => 'Building your knowledge base';

  @override
  String get help_topic_snooze => 'Snoozing and resolving';

  @override
  String get help_section_contact => 'Contact us';

  @override
  String get help_contact_chat => 'Chat with support';

  @override
  String get help_contact_chat_sub => 'We usually reply within minutes';

  @override
  String get help_contact_email => 'Email';

  @override
  String get help_opening => 'Opening…';

  @override
  String get account_load_error => 'Couldn\'t load';

  @override
  String subscription_ends(String date) {
    return 'Ends on $date';
  }

  @override
  String subscription_trial_ends(String date) {
    return 'Trial ends on $date';
  }

  @override
  String get subscription_trial => 'Trial';

  @override
  String get subscription_unlimited => 'Unlimited';

  @override
  String get subscription_no_plan => 'No plan';

  @override
  String subscription_per_month(String price) {
    return '$price / month';
  }

  @override
  String get channels_meta => 'WhatsApp Business (Meta)';

  @override
  String get channels_open_on_web => 'Opens on the website';

  @override
  String get channels_open_web_failed => 'Couldn\'t open the website';

  @override
  String get channels_meta_sub => 'Official API · opens on the website';

  @override
  String get acc_title => 'Account';

  @override
  String get acc_role_owner => 'Owner';

  @override
  String get acc_role_admin => 'Admin';

  @override
  String get acc_role_lead => 'Team lead';

  @override
  String get acc_role_agent => 'Agent';

  @override
  String get acc_menu => 'Account options';

  @override
  String get acc_menu_edit => 'Edit profile';

  @override
  String get acc_menu_copy_id => 'Copy user ID';

  @override
  String get acc_id_copied => 'ID copied';

  @override
  String acc_header_a11y(
    String name,
    String role,
    String workspace,
    String status,
  ) {
    return '$name, $role, $workspace, status: $status';
  }

  @override
  String get acc_my_status => 'My status';

  @override
  String acc_away_open_title(int n) {
    return 'You have $n open chats';
  }

  @override
  String get acc_away_open_body =>
      'What should happen to them while you are away?';

  @override
  String get acc_away_release => 'Return them to unassigned';

  @override
  String get acc_away_keep => 'Keep them';

  @override
  String get acc_presence_failed => 'Couldn\'t change status';

  @override
  String acc_released(int n) {
    return '$n chats returned to unassigned';
  }

  @override
  String get acc_sec_admin => 'Management';

  @override
  String get acc_sec_app => 'App';

  @override
  String get acc_sec_about => 'About';

  @override
  String get acc_wa_connected => 'Connected';

  @override
  String get acc_wa_disconnected => 'Disconnected';

  @override
  String get acc_wa_phone_off => 'Phone offline';

  @override
  String get acc_wa_pending => 'Not linked';

  @override
  String get acc_wa_connecting => 'Connecting';

  @override
  String get acc_ai_on => 'On';

  @override
  String get acc_ai_off => 'Off';

  @override
  String get acc_ai_suggest => 'Suggest only';

  @override
  String get acc_ai_hybrid => 'Hybrid';

  @override
  String acc_plan_trial(String plan, int d) {
    return '$plan · Trial, $d days left';
  }

  @override
  String acc_plan_trial_ended(String plan) {
    return '$plan · Trial ended';
  }

  @override
  String acc_plan_active(String plan) {
    return '$plan · Active';
  }

  @override
  String get acc_plan_failed => 'Payment failed — update card';

  @override
  String get acc_plan_badge_trial => 'Trial';

  @override
  String get acc_plan_badge_active => 'Active';

  @override
  String acc_plan_days_left(int d) {
    return '$d trial days left';
  }

  @override
  String get acc_plan_seats => 'Seats';

  @override
  String get acc_plan_ai => 'AI replies';

  @override
  String get acc_plan_unlimited => 'Unlimited';

  @override
  String get acc_plan_manage => 'Manage subscription';

  @override
  String get acc_plan_readonly => 'Managed by the workspace owner';

  @override
  String get acc_notif_all => 'All';

  @override
  String get acc_notif_assigned => 'Assigned to me';

  @override
  String get acc_notif_mentions => 'Mentions only';

  @override
  String get acc_notif_none => 'Off';

  @override
  String get acc_notif_denied => 'Blocked on device';

  @override
  String get acc_security => 'Security';

  @override
  String get acc_terms => 'Terms & privacy';

  @override
  String get acc_contact => 'Contact support';

  @override
  String get acc_version => 'Version';

  @override
  String get acc_debug_copied => 'Debug info copied';

  @override
  String get acc_logout_title => 'Sign out?';

  @override
  String get acc_logout_body => 'Chat notifications will stop on this device.';

  @override
  String acc_logout_open(int n) {
    return '$n open chats will stay assigned to you.';
  }

  @override
  String get acc_offline => 'Offline';

  @override
  String get acc_offline_presence => 'Changing status needs a connection';

  @override
  String get acc_open_failed => 'Couldn\'t open the page';

  @override
  String get prof_title => 'Profile';

  @override
  String get prof_name => 'Name';

  @override
  String get prof_name_error => 'Name must be 2–50 characters';

  @override
  String get prof_email => 'Email';

  @override
  String get prof_email_locked => 'Contact an admin to change email';

  @override
  String get prof_photo_web => 'Change your photo from the web panel';

  @override
  String get prof_save => 'Save';

  @override
  String get prof_saved => 'Profile saved';

  @override
  String get prof_save_failed => 'Couldn\'t save';

  @override
  String get prof_discard => 'Discard changes?';

  @override
  String get prof_discard_body => 'Your edits won\'t be saved.';

  @override
  String get prof_discard_ok => 'Discard';

  @override
  String get sec_change_pw => 'Change password';

  @override
  String get sec_change_pw_sub => 'Opens on the website';

  @override
  String get sec_biometric => 'Sign in with biometrics';

  @override
  String get sec_biometric_reason => 'Confirm it’s you to turn on biometrics';

  @override
  String get sec_biometric_unavailable =>
      'Biometrics are not available on this device';

  @override
  String get sec_devices => 'Signed-in devices';

  @override
  String get sec_this_device => 'This device';

  @override
  String get sec_device_logout => 'Sign out';

  @override
  String get sec_logout_others => 'Sign out of all other devices';

  @override
  String get sec_logout_others_body =>
      'Other devices will need to sign in again.';

  @override
  String get sec_logout_done => 'Signed out';

  @override
  String sec_last_active(String t) {
    return 'Last active $t';
  }

  @override
  String get sec_devices_failed => 'Couldn\'t load devices';

  @override
  String get common_locked => 'Locked';

  @override
  String get ai_title => 'AI agent';

  @override
  String get ai_master_switch => 'Turn on AI';

  @override
  String get ai_state_on => 'On';

  @override
  String get ai_state_off => 'Off';

  @override
  String get ai_readonly => 'Only admins can edit AI settings';

  @override
  String ai_hero_answered(String n) {
    return '$n questions';
  }

  @override
  String ai_hero_caption(String h) {
    return 'answered this week · saved ~$h hours';
  }

  @override
  String get ai_hero_off => 'AI is off';

  @override
  String get ai_hero_off_body =>
      'Turn it on to answer from your knowledge base';

  @override
  String get ai_hero_ready => 'Ready to work';

  @override
  String get ai_hero_ready_body => 'Hasn\'t answered yet — try it first';

  @override
  String ai_hero_a11y(String n) {
    return '$n questions answered this week, view performance';
  }

  @override
  String ai_usage(String p) {
    return 'Used $p% of this month\'s replies';
  }

  @override
  String get ai_ready_title => 'Before going live';

  @override
  String ai_ready_kb(String n) {
    return 'Knowledge base has at least 10 answers ($n/10)';
  }

  @override
  String get ai_ready_hours => 'Working hours set';

  @override
  String get ai_ready_handoff => 'Handoff rule enabled';

  @override
  String get ai_ready_tested => 'Agent tested';

  @override
  String get ai_ready_done => 'Done';

  @override
  String get ai_ready_missing => 'Not done';

  @override
  String get ai_mode => 'How it works';

  @override
  String get ai_mode_suggest => 'Suggestion';

  @override
  String get ai_mode_suggest_sub => 'AI drafts, agent sends';

  @override
  String get ai_mode_auto => 'Autonomous';

  @override
  String get ai_mode_auto_sub => 'AI replies automatically';

  @override
  String get ai_mode_after => 'After hours only';

  @override
  String get ai_mode_after_sub => 'Auto-replies outside working hours';

  @override
  String get ai_mode_after_sub2 => 'and suggests during hours';

  @override
  String get ai_mode_needs_hours => 'Set working hours first';

  @override
  String get ai_mode_needs_ready => 'Finish the readiness checklist first';

  @override
  String get ai_recommended => 'Recommended';

  @override
  String ai_mode_changed(String mode) {
    return 'Changed to \"$mode\"';
  }

  @override
  String get ai_undo => 'Undo';

  @override
  String get ai_tone => 'Tone';

  @override
  String get ai_tone_friendly => 'Friendly';

  @override
  String get ai_tone_formal => 'Formal';

  @override
  String get ai_tone_concise => 'Concise';

  @override
  String get ai_tone_sample_friendly =>
      'Hi Noura! Delivery to Dammam is 25 SAR, free over 300. It arrives in 2–3 days!';

  @override
  String get ai_tone_sample_formal =>
      'Welcome. Delivery to Dammam costs 25 SAR and is free for orders over 300 SAR, within 2–3 business days.';

  @override
  String get ai_tone_sample_concise =>
      'Dammam delivery 25 SAR (free over 300) · 2–3 days.';

  @override
  String get ai_use_name => 'Use the customer\'s name';

  @override
  String get ai_rules => 'Rules';

  @override
  String get ai_hours => 'Working hours';

  @override
  String get ai_hours_24 => '24 hours';

  @override
  String get ai_hours_unset => 'Not set';

  @override
  String get ai_handoff => 'Handoff to agent';

  @override
  String get ai_handoff_sub => 'On human request, complaint, or payment';

  @override
  String get ai_language => 'Reply language';

  @override
  String get ai_lang_customer => 'Customer\'s language';

  @override
  String get ai_lang_customer_sub => 'Detected per message';

  @override
  String get ai_lang_ar => 'Always Arabic';

  @override
  String get ai_lang_en => 'Always English';

  @override
  String get ai_lang_style => 'Style';

  @override
  String get ai_lang_msa => 'Simple MSA';

  @override
  String get ai_lang_saudi => 'Neutral Saudi dialect';

  @override
  String get ai_handoff_msg => 'Handoff message';

  @override
  String get ai_handoff_msg_default =>
      'I\'ll connect you with a colleague now, one moment please.';

  @override
  String get ai_var_customer => 'Customer name';

  @override
  String get ai_var_return => 'Return time';

  @override
  String get ai_save => 'Save';

  @override
  String get ai_delay => 'Auto-reply delay';

  @override
  String get ai_delay_instant => 'Instant';

  @override
  String get ai_delay_30s => 'After 30s';

  @override
  String get ai_delay_1m => 'After 1 min';

  @override
  String get ai_delay_2m => 'After 2 min';

  @override
  String get ai_delay_note =>
      'The delay lets agents answer first in auto-reply';

  @override
  String get ai_perf => 'Performance';

  @override
  String get ai_perf_resolution => 'Answered without handoff';

  @override
  String get ai_perf_rating => 'Positive rating';

  @override
  String get ai_perf_unanswered => 'Unanswered questions';

  @override
  String get ai_perf_detail => 'View detailed performance';

  @override
  String get ai_perf_week => 'This week';

  @override
  String get ai_perf_answered => 'Answered';

  @override
  String get ai_perf_handoffs => 'Handoffs';

  @override
  String get ai_perf_reasons => 'Top handoff reasons';

  @override
  String get ai_perf_sources => 'Most used sources';

  @override
  String get ai_perf_none => 'No data yet';

  @override
  String get ai_reason_human_request => 'Asked for a human';

  @override
  String get ai_reason_complaint => 'Complaint';

  @override
  String get ai_reason_payment => 'Payment or refund';

  @override
  String get ai_reason_no_answer => 'No answer found';

  @override
  String get ai_reason_low_confidence => 'Low confidence';

  @override
  String get ai_reason_after_replies => 'Replies without resolution';

  @override
  String ai_reason_keyword(String word) {
    return 'Keyword: $word';
  }

  @override
  String get ai_reason_other => 'Other';

  @override
  String get ai_advanced => 'Advanced';

  @override
  String get ai_channels => 'Enabled channels';

  @override
  String get ai_channels_none => 'No channels';

  @override
  String get ai_channel_whatsapp => 'WhatsApp';

  @override
  String get ai_channel_web => 'Website';

  @override
  String get ai_channel_messenger => 'Messenger';

  @override
  String get ai_instructions => 'Extra instructions';

  @override
  String get ai_instructions_ph =>
      'e.g. Don\'t mention wholesale prices; always ask for the order number before shipping questions';

  @override
  String get ai_instructions_empty => 'None';

  @override
  String get ai_outside_kb => 'Answer outside the knowledge base';

  @override
  String get ai_outside_kb_sub => 'Not recommended — may give inaccurate info';

  @override
  String get ai_confidence => 'Auto-send confidence threshold';

  @override
  String get ai_conf_low => 'Low';

  @override
  String get ai_conf_med => 'Medium';

  @override
  String get ai_conf_high => 'High';

  @override
  String get ai_conf_low_sub => 'Sends most replies automatically';

  @override
  String get ai_conf_med_sub => 'Balance of speed and accuracy';

  @override
  String get ai_conf_high_sub =>
      'Only sends sure replies; the rest are suggested or handed off';

  @override
  String get ai_team_styles => 'Team rewrite styles';

  @override
  String get ai_style_add => 'Add style';

  @override
  String get ai_style_name => 'Style name';

  @override
  String get ai_style_instruction => 'Instruction';

  @override
  String get ai_style_delete => 'Delete';

  @override
  String get ai_styles_empty => 'No styles yet';

  @override
  String get ai_audit => 'Change log';

  @override
  String ai_audit_row(String fields) {
    return 'Changed $fields';
  }

  @override
  String get ai_audit_empty => 'No changes yet';

  @override
  String get ai_test => 'Test the agent in a sample chat';

  @override
  String get ai_test_title => 'Test chat';

  @override
  String get ai_test_sub => 'Won\'t be sent to any customer';

  @override
  String get ai_test_info =>
      'You\'re the customer. Try real customer questions.';

  @override
  String get ai_test_why => 'Why this reply?';

  @override
  String ai_test_handoff(String reason) {
    return 'In a real chat this would go to the team: $reason';
  }

  @override
  String get ai_test_reset => 'Restart';

  @override
  String get ai_test_channel => 'Change channel';

  @override
  String get ai_test_p1 => 'How much is delivery?';

  @override
  String get ai_test_p2 => 'I want to return my order';

  @override
  String get ai_test_p3 => 'When are you open?';

  @override
  String get ai_test_p4 => 'I want to talk to someone';

  @override
  String get ai_test_hint => 'Type your question as a customer…';

  @override
  String get ai_test_label => 'AI';

  @override
  String get ai_test_error => 'Couldn\'t get a reply. Try again.';

  @override
  String get ai_test_unsaved => 'You have unsaved working-hours edits';

  @override
  String get ai_why_sources => 'Sources';

  @override
  String get ai_why_no_sources => 'No knowledge base sources used';

  @override
  String get ai_why_confidence => 'Confidence';

  @override
  String get ai_why_rule => 'Rule';

  @override
  String get ai_why_tone => 'Tone';

  @override
  String get ai_off_title => 'Turn off AI?';

  @override
  String get ai_off_body =>
      'It will stop replying and suggesting. Chats it\'s handling will go to the team.';

  @override
  String ai_off_handling(String n) {
    return 'Handling $n chats now';
  }

  @override
  String get ai_off_confirm => 'Turn off';

  @override
  String get ai_cancel => 'Cancel';

  @override
  String get ai_kb_first_title => 'Add your knowledge base first';

  @override
  String get ai_kb_first_body =>
      'AI only answers from your info. Add at least 10 answers.';

  @override
  String get ai_kb_add => 'Add answers';

  @override
  String get ai_enable_suggest => 'Enable in suggest-only mode';

  @override
  String get ai_auto_title => 'AI will reply to customers directly';

  @override
  String get ai_auto_b1 => 'Answers only from your knowledge base';

  @override
  String get ai_auto_b2 => 'Hands off by your rules';

  @override
  String get ai_auto_b3 => 'You can turn it off anytime';

  @override
  String get ai_auto_tested => 'I tested the agent';

  @override
  String get ai_auto_try => 'Try now';

  @override
  String get ai_auto_confirm => 'Enable auto-reply';

  @override
  String get ai_outside_title => 'Allow answers outside the knowledge base?';

  @override
  String get ai_outside_body =>
      'AI may give incorrect info about your products or prices.';

  @override
  String get ai_allow => 'Allow';

  @override
  String get ai_plan_off => 'AI isn\'t available on your plan';

  @override
  String get ai_view_plans => 'View plans';

  @override
  String ai_quota_out(String date) {
    return 'Monthly replies used — suggest-only until $date';
  }

  @override
  String get ai_save_failed => 'Couldn\'t save change';

  @override
  String get ai_retry => 'Retry';

  @override
  String ai_conflict(String name) {
    return '$name just changed the settings';
  }

  @override
  String get ai_conflict_anon => 'Someone else just changed the settings';

  @override
  String get ai_offline => 'Editing requires internet';

  @override
  String get ai_load_error => 'Couldn\'t load AI settings';

  @override
  String get ai_saved => 'Saved';

  @override
  String get ai_hours_247 => 'Open 24/7';

  @override
  String get ai_hours_closed => 'Closed';

  @override
  String get ai_hours_add_range => '+ Shift';

  @override
  String get ai_hours_copy_all => 'Copy to all days';

  @override
  String get ai_hours_timezone => 'Time zone';

  @override
  String get ai_hours_holidays => 'Public holidays';

  @override
  String get ai_hours_err_order => 'End must be after start';

  @override
  String get ai_hours_err_overlap => 'Shifts overlap';

  @override
  String get ai_hours_err_max => 'At most 2 shifts';

  @override
  String get ai_hours_start => 'From';

  @override
  String get ai_hours_end => 'To';

  @override
  String get ai_hours_discard => 'Discard changes?';

  @override
  String get ai_hours_discard_body => 'You haven\'t saved the working hours.';

  @override
  String get ai_hours_discard_confirm => 'Discard';

  @override
  String get ai_day_sat => 'Saturday';

  @override
  String get ai_day_sun => 'Sunday';

  @override
  String get ai_day_mon => 'Monday';

  @override
  String get ai_day_tue => 'Tuesday';

  @override
  String get ai_day_wed => 'Wednesday';

  @override
  String get ai_day_thu => 'Thursday';

  @override
  String get ai_day_fri => 'Friday';

  @override
  String get ai_ho_intro =>
      'The AI hands the chat to the team automatically when:';

  @override
  String get ai_ho_human => 'The customer asks for a person';

  @override
  String get ai_ho_always => 'Always on';

  @override
  String get ai_ho_complaint => 'Complaint or upset customer';

  @override
  String get ai_ho_payment => 'Payment or refund topic';

  @override
  String get ai_ho_no_answer => 'No answer in the knowledge base';

  @override
  String get ai_ho_low_conf => 'Low confidence in the answer';

  @override
  String ai_ho_after_n(String n) {
    return 'After $n replies without resolution';
  }

  @override
  String get ai_ho_keywords => 'Specific words';

  @override
  String get ai_ho_keyword_add => 'Add a word…';

  @override
  String get ai_ho_target => 'Hand off to?';

  @override
  String get ai_ho_target_unassigned => 'Unassigned (first to claim)';

  @override
  String get ai_ho_target_team => 'A specific team';

  @override
  String get ai_ho_target_last => 'Last agent who helped the customer';

  @override
  String get ai_ho_after_hours => 'Outside working hours';

  @override
  String get ai_ho_tell_return => 'Tell the customer when you\'re back';

  @override
  String get ai_ho_notify => 'Hand off and notify the team';

  @override
  String get ai_mode_hybrid => 'Hybrid';

  @override
  String get ai_mode_hybrid_sub => 'Auto until escalation keyword';

  @override
  String get ai_replies => 'Replies';

  @override
  String get ai_suggestions => 'Suggestions per message';

  @override
  String get ai_suggestions_sub =>
      'How many reply suggestions the AI offers each time.';

  @override
  String get ai_reply_claimed => 'Reply when an agent has the chat';

  @override
  String get ai_reply_claimed_sub =>
      'Off: the AI stays quiet once a person takes the conversation.';

  @override
  String get ai_keywords => 'Escalation keywords';

  @override
  String get ai_keywords_sub =>
      'When a customer writes one of these words, the conversation goes to a person.';

  @override
  String get ai_keywords_none => 'None';

  @override
  String ai_keywords_count(int n) {
    return '$n words';
  }

  @override
  String get ai_keywords_empty => 'No keywords yet.';

  @override
  String get ai_keywords_hint => 'Add a word, e.g. manager';

  @override
  String get ai_keywords_add => 'Add';

  @override
  String get ai_keywords_remove => 'Remove';

  @override
  String get ai_answer_source => 'Answer source';

  @override
  String get ai_answer_source_kb => 'Knowledge base';

  @override
  String get ai_answer_source_kb_sub =>
      'The AI answers from your knowledge base.';

  @override
  String get ai_answer_source_flow => 'Bot organisation';

  @override
  String get ai_answer_source_flow_sub =>
      'The AI follows the bot flow you built on the web.';

  @override
  String get ai_lang_fr => 'French';

  @override
  String get ai_lang_es => 'Spanish';

  @override
  String get ai_lang_pt => 'Portuguese';

  @override
  String get ai_lang_de => 'German';

  @override
  String get ai_lang_it => 'Italian';

  @override
  String get ai_mode_off => 'Off';

  @override
  String get ai_mode_off_sub => 'AI disabled';

  @override
  String get ai_mode_auto_info =>
      'In autonomous mode the AI sends replies directly without agent review. Escalation keywords will pause the AI and alert agents.';

  @override
  String get ai_mode_set_on_web => 'Set on the website for now';

  @override
  String get ai_mode_hybrid_on_web =>
      'Choose Hybrid on the website, then come back.';

  @override
  String get rw_title => 'Improve reply';

  @override
  String get rw_subtitle => 'Pick a style and AI will rewrite it';

  @override
  String get rw_original => 'Your original';

  @override
  String get rw_edit => 'Edit';

  @override
  String get rw_more => 'More';

  @override
  String get rw_selection_hint => 'Only the selected part will be replaced';

  @override
  String get rw_style_professional => 'More professional';

  @override
  String get rw_style_shorter => 'Shorter';

  @override
  String get rw_style_friendlier => 'Friendlier';

  @override
  String get rw_style_apology => 'Apology';

  @override
  String get rw_style_fix => 'Fix spelling';

  @override
  String get rw_style_to_en => 'Translate to English';

  @override
  String get rw_style_to_ar => 'Translate to Arabic';

  @override
  String get rw_style_more => 'More';

  @override
  String get rw_style_formal => 'Very formal';

  @override
  String get rw_style_saudi => 'Saudi dialect';

  @override
  String get rw_style_msa => 'Modern Standard Arabic';

  @override
  String get rw_style_greeting => 'Add greeting & sign-off';

  @override
  String get rw_style_bullets => 'Make bullet points';

  @override
  String get rw_style_sales => 'More persuasive';

  @override
  String get rw_style_simple => 'Simpler & clearer';

  @override
  String get rw_team_styles => 'Your team\'s styles';

  @override
  String rw_customer_prefers(String language) {
    return 'Customer prefers $language';
  }

  @override
  String get rw_result => 'Suggested wording';

  @override
  String get rw_writing => 'Rewriting…';

  @override
  String get rw_streaming => 'Writing…';

  @override
  String get rw_edited => 'Edited manually';

  @override
  String get rw_name_added => 'Customer name added';

  @override
  String get rw_fact_warning => 'Check: AI added info not in your reply';

  @override
  String rw_chars(int n, String delta) {
    return '$n chars ($delta)';
  }

  @override
  String get rw_over_limit => 'Longer than the channel allows';

  @override
  String get rw_show_diff => 'Show changes';

  @override
  String get rw_hide_diff => 'Hide changes';

  @override
  String get rw_use => 'Use this reply';

  @override
  String get rw_use_as_is => 'Use as is';

  @override
  String get rw_rerun => 'Rewrite again';

  @override
  String get rw_regenerate => 'Another version';

  @override
  String get rw_max_versions => 'Maximum attempts reached';

  @override
  String get rw_no_change => 'Your reply is fine — no changes';

  @override
  String get rw_error => 'Couldn\'t rewrite';

  @override
  String get rw_retry => 'Retry';

  @override
  String rw_rate_limited(int n) {
    return 'Usage limit reached, try again in ${n}s';
  }

  @override
  String get rw_plan_limit => 'Rewrite isn\'t available on your plan';

  @override
  String get rw_view_plans => 'View plans';

  @override
  String get rw_blocked => 'This text can\'t be rewritten';

  @override
  String get rw_offline => 'Internet connection required';

  @override
  String get rw_too_long => 'Text too long to rewrite (2,000 max)';

  @override
  String get rw_empty_hint => 'Write a reply first or use the AI suggestion';

  @override
  String get rw_toolbar => 'Improve with AI';

  @override
  String get rw_lang_ar => 'Arabic';

  @override
  String get rw_lang_en => 'English';

  @override
  String get rw_copy => 'Copy';

  @override
  String get rw_copied => 'Copied';

  @override
  String rw_a11y_ready(String text) {
    return 'Suggested wording ready: $text';
  }

  @override
  String get rw_a11y_cached => 'Generated';

  @override
  String rw_a11y_version(int i, int n) {
    return 'Version $i of $n';
  }

  @override
  String get rw_a11y_prev => 'Previous';

  @override
  String get rw_a11y_next => 'Next';

  @override
  String get rw_a11y_edit_result =>
      'Tap to edit the wording, long-press to copy';

  @override
  String get as_title => 'Assign conversation';

  @override
  String as_title_bulk(int n) {
    return 'Assign $n conversations';
  }

  @override
  String as_current(String name) {
    return 'Current: $name';
  }

  @override
  String get as_search => 'Search a teammate or team';

  @override
  String as_no_results(String q) {
    return 'No results for \"$q\"';
  }

  @override
  String get as_filter_all => 'All';

  @override
  String as_filter_available(int n) {
    return 'Available ($n)';
  }

  @override
  String get as_filter_my_team => 'My team';

  @override
  String get as_suggested => 'Suggested';

  @override
  String get as_teammates => 'Teammates';

  @override
  String get as_teams => 'Teams';

  @override
  String get as_ai_section => 'AI';

  @override
  String get as_me => 'Me';

  @override
  String get as_badge_current => 'Current';

  @override
  String get as_badge_capacity => 'At limit';

  @override
  String get as_online_m => 'Available';

  @override
  String get as_online_f => 'Available';

  @override
  String get as_busy_m => 'Busy';

  @override
  String get as_busy_f => 'Busy';

  @override
  String get as_away => 'Away';

  @override
  String as_last_seen(String t) {
    return 'Last seen $t ago';
  }

  @override
  String as_open_count(int n) {
    return '$n open conversations';
  }

  @override
  String as_members(int n) {
    return '$n members';
  }

  @override
  String as_available_count(int n) {
    return '$n available';
  }

  @override
  String get as_routing_least => 'Goes to least busy member';

  @override
  String get as_routing_rr => 'Round-robin';

  @override
  String get as_routing_manual => 'Stays in team queue';

  @override
  String get as_team_none_available =>
      'No one available — it will wait in the team queue';

  @override
  String get as_ai_name => 'AI agent';

  @override
  String get as_ai_sub => 'Replies automatically and hands off when needed';

  @override
  String get as_ai_unavailable => 'Knowledge base is too small';

  @override
  String get as_reason_handled => 'Handled this customer before';

  @override
  String get as_reason_handled_f => 'Handled this customer before';

  @override
  String as_reason_skill(String skill) {
    return '$skill expert';
  }

  @override
  String as_reason_skill_f(String skill) {
    return '$skill expert';
  }

  @override
  String get as_reason_least => 'Least busy';

  @override
  String get as_note => 'Note for teammate (optional)';

  @override
  String get as_note_q1 => 'Customer needs a fast reply';

  @override
  String get as_note_q2 => 'Payment issue';

  @override
  String get as_note_q3 => 'Follow up tomorrow';

  @override
  String get as_pick => 'Pick a teammate or team';

  @override
  String as_assign_to(String name) {
    return 'Assign to $name';
  }

  @override
  String get as_claim => 'Claim conversation';

  @override
  String get as_assign_ai => 'Assign to AI';

  @override
  String as_assign_bulk_to(int n, String name) {
    return 'Assign $n to $name';
  }

  @override
  String get as_unassign => 'Unassign (back to unassigned)';

  @override
  String get as_busy_hint => 'Busy — reply may be delayed';

  @override
  String get as_busy_hint_f => 'Busy — reply may be delayed';

  @override
  String get as_away_hint => 'Away — they\'ll be notified';

  @override
  String get as_away_hint_f => 'Away — they\'ll be notified';

  @override
  String as_capacity_reached(int max) {
    return 'At maximum ($max)';
  }

  @override
  String get as_unavailable => 'Not assignable';

  @override
  String as_taken_live(String name) {
    return '$name just took it';
  }

  @override
  String as_reassign_to(String name) {
    return 'Reassign to $name';
  }

  @override
  String get as_offline => 'Assigning requires internet';

  @override
  String get as_none_available => 'No teammates available';

  @override
  String get as_show_all => 'Show all';

  @override
  String as_done(String name) {
    return 'Assigned to $name';
  }

  @override
  String as_done_bulk(int ok, int n) {
    return 'Assigned $ok of $n';
  }

  @override
  String get as_show_errors => 'View errors';

  @override
  String get as_undo => 'Undo';

  @override
  String get as_forbidden => 'You can\'t assign to this teammate';

  @override
  String get as_error => 'Couldn\'t assign. Try again.';

  @override
  String get as_retry => 'Retry';

  @override
  String as_event_assigned(String name) {
    return 'You assigned this to $name';
  }

  @override
  String as_event_undo(String actor) {
    return '$actor undid the assignment';
  }

  @override
  String get as_resolved_live => 'The conversation was resolved';

  @override
  String as_queued_team(String team) {
    return 'Waiting in the $team queue';
  }

  @override
  String get as_unassigned_done => 'Conversation is now unassigned';

  @override
  String as_errors_title(int n) {
    return '$n couldn\'t be assigned';
  }

  @override
  String get as_err_same => 'Already assigned to them';

  @override
  String get as_err_resolved => 'Conversation is resolved';

  @override
  String get as_err_state => 'Owner changed';

  @override
  String get as_err_generic => 'Unexpected error';

  @override
  String as_expand_team(String team) {
    return 'Show $team members';
  }

  @override
  String get as_a11y_selected => 'selected';

  @override
  String get as_load_error => 'Couldn\'t load teammates';

  @override
  String get login_title => 'Sign in';

  @override
  String get login_subtitle => 'Welcome back, sign in to continue';

  @override
  String get login_identifier_label => 'Email or phone';

  @override
  String get login_identifier_hint => 'name@company.com';

  @override
  String get login_password_label => 'Password';

  @override
  String get login_password_show => 'Show password';

  @override
  String get login_password_hide => 'Hide password';

  @override
  String get login_forgot => 'Forgot password?';

  @override
  String get login_submit => 'Sign in';

  @override
  String get login_or => 'or';

  @override
  String get login_biometric_face => 'Sign in with Face ID';

  @override
  String get login_biometric_finger => 'Sign in with fingerprint';

  @override
  String get login_biometric_reason => 'Sign in to Wavadesk';

  @override
  String get login_biometric_locked =>
      'Biometrics are temporarily locked. Use your password.';

  @override
  String get login_no_account => 'Don\'t have an account?';

  @override
  String get login_start_trial => 'Start a free 7-day trial';

  @override
  String get login_offline => 'No internet connection';

  @override
  String get login_err_invalid => 'Incorrect email or password';

  @override
  String get login_err_disabled =>
      'Your account is disabled. Contact your workspace admin';

  @override
  String get login_err_suspended => 'Workspace subscription is suspended.';

  @override
  String get login_manage_subscription => 'Manage subscription';

  @override
  String login_err_locked(String time) {
    return 'Too many attempts. Try again in $time';
  }

  @override
  String get login_err_network =>
      'Couldn\'t connect. Check your internet and try again.';

  @override
  String get login_err_server => 'Something went wrong, try again';

  @override
  String get login_retry => 'Retry';

  @override
  String get login_val_identifier_required => 'Enter your email or phone';

  @override
  String get login_val_email_invalid => 'Invalid email format';

  @override
  String get login_val_phone_invalid => 'Invalid phone number';

  @override
  String get login_val_password_required => 'Enter your password';

  @override
  String get login_val_password_short => 'At least 8 characters';

  @override
  String get login_bio_sheet_title => 'Sign in faster next time';

  @override
  String get login_bio_sheet_body => 'Use Face ID instead of your password.';

  @override
  String get login_bio_sheet_body_finger =>
      'Use your fingerprint instead of your password.';

  @override
  String get login_bio_sheet_enable => 'Enable Face ID';

  @override
  String get login_bio_sheet_enable_finger => 'Enable fingerprint';

  @override
  String get login_bio_sheet_later => 'Not now';

  @override
  String get auth_coming_soon_title => 'Coming soon';

  @override
  String get auth_forgot_placeholder =>
      'Password recovery is coming in a future update.';

  @override
  String auth_forgot_placeholder_for(String identifier) {
    return 'Password recovery for $identifier is coming in a future update.';
  }

  @override
  String get auth_2fa_title => 'Verification code';

  @override
  String get auth_2fa_placeholder =>
      'Two-factor code entry is coming in a future update.';

  @override
  String get auth_workspace_title => 'Choose a workspace';

  @override
  String get auth_workspace_placeholder =>
      'Your account belongs to more than one workspace. Picking one is coming in a future update.';

  @override
  String get login_email => 'Email';

  @override
  String get login_register => 'Create a new account';

  @override
  String get login_lang_title => 'Language';

  @override
  String login_lang_a11y(String lang) {
    return 'Language: $lang, change';
  }

  @override
  String get login_err_email_empty => 'Enter your email';

  @override
  String get login_err_email_format => 'Check the email format';

  @override
  String get login_err_pw_empty => 'Enter your password';

  @override
  String get login_err_offline => 'No internet connection';

  @override
  String get login_session_expired => 'Your session expired, sign in again';

  @override
  String get chat_ai_suggestion => 'AI suggestion';

  @override
  String chat_ai_source(String title) {
    return 'From: $title';
  }

  @override
  String get chat_ai_send => 'Send';

  @override
  String get chat_ai_edit => 'Edit';

  @override
  String get chat_ai_more => 'More';

  @override
  String get chat_ai_low_conf => 'Review before sending';

  @override
  String get chat_ai_writing => 'Writing suggestion…';

  @override
  String get chat_ai_no_answer => 'AI found no answer in the knowledge base';

  @override
  String get chat_ai_add_answer => 'Add answer';

  @override
  String get chat_ai_ready_pill => 'Suggestion ready';

  @override
  String get chat_placeholder => 'Write a reply…';

  @override
  String get chat_note_placeholder =>
      'Note for your team — customer won\'t see it';

  @override
  String get chat_mode_reply => 'Reply';

  @override
  String get chat_mode_note => 'Internal note';

  @override
  String get chat_attach_media => 'Photo/Video';

  @override
  String get chat_attach_camera => 'Camera';

  @override
  String get chat_attach_file => 'File';

  @override
  String get chat_attach_location => 'Location';

  @override
  String get chat_attach_quick => 'Quick replies';

  @override
  String get chat_attach_template => 'WhatsApp template';

  @override
  String get chat_attach_product => 'Product';

  @override
  String get chat_record_cancel_hint => 'Slide to cancel';

  @override
  String get chat_claim => 'Claim conversation';

  @override
  String get chat_assign_colleague => 'Assign to a colleague';

  @override
  String chat_viewing_now(String name) {
    return '$name is viewing this now';
  }

  @override
  String get chat_waiting_claim => 'Waiting to be claimed';

  @override
  String chat_claimed_before(String name) {
    return '$name claimed it first';
  }

  @override
  String chat_ro_colleague(String name) {
    return 'Assigned to $name';
  }

  @override
  String get chat_ro_request => 'Request transfer';

  @override
  String get chat_ro_resolved => 'Conversation resolved';

  @override
  String get chat_reopen => 'Reopen';

  @override
  String get chat_ro_ai => 'AI is handling this conversation';

  @override
  String get chat_take_over => 'Take over';

  @override
  String get chat_ro_blocked => 'This contact is blocked';

  @override
  String get chat_unblock => 'Unblock';

  @override
  String get chat_ro_past => 'Past conversation — read only';

  @override
  String get chat_banner_offline =>
      'Offline — messages will send when you reconnect';

  @override
  String get chat_banner_window_closed =>
      '24-hour window closed — only approved templates';

  @override
  String get chat_choose_template => 'Choose template';

  @override
  String chat_banner_window_soon(String t) {
    return 'Reply window closes in $t';
  }

  @override
  String get chat_banner_channel_down =>
      'WhatsApp disconnected — messages won\'t deliver';

  @override
  String get chat_reconnect => 'Reconnect';

  @override
  String chat_snoozed_until(String t) {
    return 'Snoozed until $t';
  }

  @override
  String get chat_unsnooze => 'Unsnooze';

  @override
  String get composer_attach => 'Attach';

  @override
  String get composer_send => 'Send';

  @override
  String get composer_send_note => 'Send note';

  @override
  String get composer_record => 'Hold to record a voice message';

  @override
  String get composer_recording => 'Recording';

  @override
  String get composer_record_stop => 'Stop';

  @override
  String get composer_record_send => 'Send recording';

  @override
  String get composer_record_cancelled => 'Recording cancelled';

  @override
  String get composer_record_locked => 'Recording hands-free';

  @override
  String get composer_record_slide_up => 'Slide up to lock';

  @override
  String get composer_ai_rewrite => 'Improve reply with AI';

  @override
  String get composer_saved_replies => 'Saved replies';

  @override
  String get composer_field_label => 'Write a reply';

  @override
  String get composer_note_field_label => 'Write an internal note';

  @override
  String get composer_template => 'Template';

  @override
  String get composer_template_only =>
      'Window closed — send an approved template';

  @override
  String composer_colleague_typing_note(String name) {
    return '$name is writing a note…';
  }

  @override
  String composer_colleague_viewing(String name) {
    return '$name is also viewing';
  }

  @override
  String get composer_quick_title => 'Quick replies';

  @override
  String get composer_quick_empty => 'No matching quick replies';

  @override
  String get composer_mention_title => 'Mention a teammate';

  @override
  String composer_reply_to(String name) {
    return 'Replying to $name';
  }

  @override
  String get composer_cancel_reply => 'Cancel reply';

  @override
  String get composer_remove_attachment => 'Remove attachment';

  @override
  String composer_uploading(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get composer_customer => 'Customer';

  @override
  String get composer_location_sample => 'Al Malqa, Riyadh';

  @override
  String get aicard_close => 'Collapse suggestion';

  @override
  String get aicard_regenerate => 'Regenerate suggestion';

  @override
  String get aicard_less => 'Less';

  @override
  String get aicard_open_pill => 'Show AI suggestion';

  @override
  String claimbar_waiting_minutes(int n) {
    return '${n}m';
  }

  @override
  String claimbar_viewers_more(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count others',
      one: '1 other',
    );
    return '$name and $_temp0 are viewing';
  }

  @override
  String get readonly_take_instead => 'Take over instead';

  @override
  String get readonly_add_note => 'Add internal note';

  @override
  String get banner_connecting => 'Connecting…';

  @override
  String get composer_mic_denied =>
      'Allow microphone access in Settings to record voice messages.';

  @override
  String get composer_record_failed => 'Couldn\'t record. Please try again.';

  @override
  String get composer_record_delete => 'Delete recording';

  @override
  String get chat_ai_suggest_pill => 'Suggest a reply';

  @override
  String composer_file_too_big(String names) {
    return 'Too large to send: $names. Photos up to 5 MB, videos and audio 16 MB, documents 10 MB.';
  }

  @override
  String composer_file_type(String names) {
    return 'This file type can’t be sent: $names';
  }

  @override
  String get composer_upload_failed => 'Upload failed';

  @override
  String get composer_upload_retry => 'Retry upload';

  @override
  String sys_called(String actor) {
    return '$actor called the customer';
  }

  @override
  String get sys_called_me => 'You called the customer';

  @override
  String get snooze_title => 'Snooze conversation';

  @override
  String get snooze_one_hour => 'In 1 hour';

  @override
  String get snooze_three_hours => 'In 3 hours';

  @override
  String get snooze_tomorrow => 'Tomorrow 9 AM';

  @override
  String get snooze_next_week => 'Next week';

  @override
  String get snooze_custom => 'Custom';

  @override
  String sys_claimed(String actor) {
    return '$actor claimed the conversation';
  }

  @override
  String get sys_claimed_me => 'You claimed the conversation';

  @override
  String sys_assigned(String actor, String target) {
    return '$actor assigned the conversation to $target';
  }

  @override
  String sys_assigned_me(String target) {
    return 'You assigned the conversation to $target';
  }

  @override
  String sys_unassigned(String actor) {
    return '$actor released the conversation';
  }

  @override
  String get sys_unassigned_me => 'You released the conversation';

  @override
  String sys_ai_handoff(String reason) {
    return 'AI handed the conversation to the team: $reason';
  }

  @override
  String sys_ai_paused(String actor) {
    return '$actor paused AI for this conversation';
  }

  @override
  String get sys_ai_paused_me => 'You paused AI for this conversation';

  @override
  String sys_ai_resumed(String actor) {
    return '$actor turned AI back on for this conversation';
  }

  @override
  String get sys_ai_resumed_me => 'You turned AI back on for this conversation';

  @override
  String sys_resolved(String actor) {
    return '$actor resolved the conversation';
  }

  @override
  String get sys_resolved_me => 'You resolved the conversation';

  @override
  String get sys_reopened => 'The conversation was reopened';

  @override
  String sys_snoozed(String actor, String time) {
    return '$actor snoozed the conversation until $time';
  }

  @override
  String sys_snoozed_me(String time) {
    return 'You snoozed the conversation until $time';
  }

  @override
  String sys_priority(String actor, String value) {
    return '$actor changed the priority to $value';
  }

  @override
  String sys_priority_me(String value) {
    return 'You changed the priority to $value';
  }

  @override
  String sys_tag_added(String actor, String tag) {
    return '$actor added the tag “$tag”';
  }

  @override
  String sys_tag_added_me(String tag) {
    return 'You added the tag “$tag”';
  }

  @override
  String get sys_window_closed => 'The 24-hour reply window closed';

  @override
  String sys_blocked(String actor) {
    return '$actor blocked this contact';
  }

  @override
  String get sys_blocked_me => 'You blocked this contact';

  @override
  String sys_unblocked(String actor) {
    return '$actor unblocked this contact';
  }

  @override
  String get sys_unblocked_me => 'You unblocked this contact';

  @override
  String sys_started(String channel) {
    return 'Conversation started on $channel';
  }

  @override
  String get msgaction_add_to_profile => 'Add to customer profile';

  @override
  String get msgaction_added_to_profile => 'Note added to the customer profile';

  @override
  String chat_new_messages(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String get chat_ai_reply_label => 'AI reply';

  @override
  String chat_note_label(String name) {
    return 'Internal note · $name';
  }

  @override
  String get chat_failed => 'Not sent';

  @override
  String get chat_retry => 'Retry';

  @override
  String get chat_delete => 'Delete';

  @override
  String get chat_edited => 'edited';

  @override
  String get chat_deleted => 'This message was deleted';

  @override
  String get chat_unsupported => 'Unsupported message — open in WhatsApp';

  @override
  String get chat_transcribe => 'Transcribe';

  @override
  String bubble_template_label(String name) {
    return 'Template: $name';
  }

  @override
  String get bubble_show_all => 'Show all';

  @override
  String get bubble_show_less => 'Show less';

  @override
  String get bubble_save_contact => 'Save';

  @override
  String get bubble_contact_saved => 'Contact saved';

  @override
  String get bubble_play => 'Play voice message';

  @override
  String get bubble_pause => 'Pause voice message';

  @override
  String bubble_speed(String speed) {
    return 'Playback speed $speed';
  }

  @override
  String bubble_voice_summary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Voice message, $n seconds',
      one: 'Voice message, 1 second',
    );
    return '$_temp0';
  }

  @override
  String bubble_image_from(String name) {
    return 'Photo from $name';
  }

  @override
  String bubble_album_summary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String bubble_video_summary(String duration) {
    return 'Video $duration';
  }

  @override
  String get bubble_play_video => 'Play video';

  @override
  String get bubble_video_unavailable =>
      'Video preview isn\'t available in sample data';

  @override
  String get bubble_download => 'Download file';

  @override
  String get bubble_downloaded => 'File downloaded';

  @override
  String get bubble_open_maps => 'Open location in maps';

  @override
  String get bubble_transcribing => 'Transcribing…';

  @override
  String get bubble_transcript => 'Transcript';

  @override
  String get bubble_delivery_sending => 'Sending';

  @override
  String get bubble_delivery_sent => 'Sent';

  @override
  String get bubble_delivery_delivered => 'Delivered';

  @override
  String get bubble_delivery_read => 'Read';

  @override
  String bubble_reply_to(String name) {
    return 'Reply to $name';
  }

  @override
  String get bubble_viewer_share => 'Share';

  @override
  String get bubble_viewer_save => 'Save';

  @override
  String get bubble_viewer_sample =>
      'This is a sample image and can\'t be shared or saved';

  @override
  String bubble_reactions(String emojis) {
    return 'Reactions: $emojis';
  }

  @override
  String get chatlist_jump_latest => 'Jump to the latest message';

  @override
  String get chatlist_loading_older => 'Loading older messages';

  @override
  String get chatlist_typing => 'typing…';

  @override
  String get msgaction_reply => 'Reply';

  @override
  String get msgaction_copy => 'Copy';

  @override
  String get msgaction_copied => 'Message copied';

  @override
  String get msgaction_forward => 'Forward';

  @override
  String get msgaction_forward_soon => 'Forwarding is coming soon';

  @override
  String get msgaction_save_kb => 'Save to knowledge base';

  @override
  String get msgaction_info => 'Info';

  @override
  String get msgaction_info_title => 'Message info';

  @override
  String get msgaction_info_sent => 'Sent at';

  @override
  String get msgaction_info_status => 'Status';

  @override
  String get msgaction_info_channel => 'Channel';

  @override
  String get msgaction_info_via => 'Sent via';

  @override
  String get msgaction_via_manual => 'Typed manually';

  @override
  String get msgaction_via_ai_suggestion => 'AI suggestion';

  @override
  String get msgaction_via_ai_edited => 'Edited AI suggestion';

  @override
  String get msgaction_via_quick_reply => 'Quick reply';

  @override
  String get msgaction_via_template => 'Approved template';

  @override
  String get msgaction_delete_title => 'Delete message?';

  @override
  String get msgaction_delete_body =>
      'The message will be deleted for everyone where the channel allows it. This can\'t be undone.';

  @override
  String get msgaction_rate => 'Rate reply';

  @override
  String get msgaction_rate_up => 'Helpful reply';

  @override
  String get msgaction_rate_down => 'Unhelpful reply';

  @override
  String get msgaction_rated => 'Thanks — the AI will learn from your rating';

  @override
  String get msgaction_more_reactions => 'More reactions';

  @override
  String get msgaction_pick_reaction => 'Pick a reaction';

  @override
  String msgaction_react(String emoji) {
    return 'React $emoji';
  }

  @override
  String get bubble_file_sending => 'Still sending — try again in a moment';

  @override
  String get bubble_file_unavailable =>
      'This file isn’t available on the phone';

  @override
  String bubble_saved(String name) {
    return 'Saved: $name';
  }

  @override
  String get bubble_save_failed => 'Couldn\'t download the file. Try again.';

  @override
  String get bubble_open_file => 'Open';

  @override
  String get bubble_tap_retry => 'Tap to retry';

  @override
  String get bubble_photo_fetching => 'Getting the photo…';

  @override
  String get bubble_photo_unavailable => 'Photo not available';

  @override
  String get chatscreen_load_failed => 'Couldn\'t load this conversation';

  @override
  String get chatscreen_not_found => 'We couldn\'t find this conversation';

  @override
  String get chatscreen_action_failed => 'Couldn\'t complete that. Try again.';

  @override
  String chatscreen_taken_from_me(String name) {
    return 'The conversation was assigned to $name';
  }

  @override
  String chatscreen_claimed_by(String name) {
    return 'Claimed by $name';
  }

  @override
  String chatscreen_transfer_note(String name) {
    return '@$name Could you transfer this conversation to me so I can follow up?';
  }

  @override
  String chatscreen_transfer_sent(String name) {
    return 'Transfer request sent to $name';
  }

  @override
  String get chatscreen_takeover_title => 'Take over from a teammate?';

  @override
  String chatscreen_takeover_body(String name) {
    return 'The conversation will be assigned to you instead of $name, and they\'ll be notified.';
  }

  @override
  String get chatscreen_takeover_confirm => 'Take over';

  @override
  String get chat_online => 'Online';

  @override
  String chat_last_seen(String time) {
    return 'Last seen $time';
  }

  @override
  String get chat_typing => 'typing…';

  @override
  String get chat_assigned_you => 'Assigned to you';

  @override
  String chat_assigned_to(String name) {
    return 'Assigned to $name';
  }

  @override
  String get chat_unassigned => 'Unassigned';

  @override
  String get chat_ai_handling => 'AI is handling';

  @override
  String get chat_resolve => 'Resolve conversation';

  @override
  String get chat_resolved_toast => 'Conversation resolved';

  @override
  String get chat_undo => 'Undo';

  @override
  String chatbar_browsing(String page) {
    return 'Browsing: $page';
  }

  @override
  String chatbar_back_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Back, $n other unread conversations',
      one: 'Back, 1 other unread conversation',
    );
    return '$_temp0';
  }

  @override
  String chatbar_open_profile(String name) {
    return 'Open $name\'s profile';
  }

  @override
  String get chatbar_call => 'Call';

  @override
  String get chatbar_more => 'Conversation actions';

  @override
  String get chatbar_call_phone => 'Phone call';

  @override
  String get chatbar_call_whatsapp => 'WhatsApp call';

  @override
  String get chatbar_call_failed => 'Couldn\'t start a call on this device';

  @override
  String strip_snoozed_until(String t) {
    return 'Snoozed until $t';
  }

  @override
  String strip_order(String ref) {
    return 'Order $ref';
  }

  @override
  String get strip_no_store_integration => 'No store integration yet';

  @override
  String get strip_add_tag => 'Tag';

  @override
  String get snoozepick_subtitle =>
      'The conversation comes back to your list at that time';

  @override
  String get templates_title => 'Approved templates';

  @override
  String get templates_subtitle => 'WhatsApp templates approved by Meta';

  @override
  String get templates_empty => 'No approved templates yet';

  @override
  String get templates_sent => 'Template sent';

  @override
  String get actions_assign => 'Assign';

  @override
  String get actions_change_owner => 'Assign / change owner';

  @override
  String get actions_unassign => 'Release conversation';

  @override
  String get actions_unassigned_toast => 'Moved back to Unassigned';

  @override
  String get actions_snooze => 'Snooze';

  @override
  String get actions_snoozed_toast => 'Conversation snoozed';

  @override
  String get actions_priority => 'Priority';

  @override
  String get actions_tag => 'Add tag';

  @override
  String get actions_tag_subtitle => 'Pick tags or add a new one';

  @override
  String get actions_tag_new_hint => 'New tag';

  @override
  String get actions_tag_add => 'Add tag';

  @override
  String get actions_ai_pause => 'Pause AI for this conversation';

  @override
  String get actions_ai_resume => 'Turn AI on for this conversation';

  @override
  String get actions_ai_paused_toast => 'AI paused for this conversation';

  @override
  String get actions_ai_resumed_toast => 'AI turned on for this conversation';

  @override
  String get actions_mark_unread => 'Mark as unread';

  @override
  String get actions_export => 'Export conversation';

  @override
  String get actions_export_note => 'Internal note';

  @override
  String get actions_exported_toast =>
      'Conversation text copied — paste it anywhere';

  @override
  String get actions_block => 'Block contact';

  @override
  String get actions_unblock => 'Unblock contact';

  @override
  String actions_block_title(String name) {
    return 'Block $name?';
  }

  @override
  String get actions_block_body =>
      'You won\'t receive messages from this contact and the conversation will close. You can unblock later.';

  @override
  String get actions_blocked_toast => 'Contact blocked';

  @override
  String get actions_unblocked_toast => 'Contact unblocked';

  @override
  String get close_title => 'Close conversation';

  @override
  String get close_subtitle => 'A short title helps your team find it later.';

  @override
  String get close_field_label => 'Title';

  @override
  String get close_field_hint => 'e.g. Delivery question';

  @override
  String get close_ai_writing => 'Writing a title with AI…';

  @override
  String get close_ai_suggest => 'Suggest a title';

  @override
  String get close_ai_again => 'Suggest another';

  @override
  String get close_ai_unavailable =>
      'Couldn\'t suggest a title right now. You can type one.';

  @override
  String get close_hint =>
      'The customer can still write again; a new message reopens the conversation.';

  @override
  String get close_confirm => 'Close conversation';

  @override
  String get claim_button => 'Claim conversation';

  @override
  String get claim_button_hint =>
      'It will be assigned to you and you can reply';

  @override
  String get claim_region => 'Claim conversation';

  @override
  String get claim_assign_colleague => 'Assign to a colleague';

  @override
  String get claim_ai_takeover => 'Let AI handle it';

  @override
  String get claim_ai_takeover_done =>
      'The conversation was handed to the AI agent';

  @override
  String get claim_waiting => 'Waiting to be claimed';

  @override
  String claim_viewer_one_f(String name) {
    return '$name is viewing this now';
  }

  @override
  String claim_viewer_one_m(String name) {
    return '$name is viewing this now';
  }

  @override
  String claim_viewer_two(String a, String b) {
    return '$a and $b are viewing';
  }

  @override
  String claim_viewer_many(String a, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$a and $n others are viewing',
      one: '$a and 1 other are viewing',
    );
    return '$_temp0';
  }

  @override
  String claim_viewing_since_sec(int n) {
    return '${n}s ago';
  }

  @override
  String claim_viewing_since_min(String t) {
    return '$t ago';
  }

  @override
  String claim_wait_sec(int n) {
    return '${n}s';
  }

  @override
  String claim_wait_min(int n) {
    return '${n}m';
  }

  @override
  String claim_wait_hm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String claim_a11y_wait_sec(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Waiting for $n seconds',
      one: 'Waiting for 1 second',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_min(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Waiting for $n minutes',
      one: 'Waiting for 1 minute',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_hm(int h, int m) {
    return 'Waiting for $h hours $m minutes';
  }

  @override
  String get claim_success_event => 'You claimed the conversation';

  @override
  String claim_conflict(String name) {
    return '$name claimed it first';
  }

  @override
  String claim_taken_live(String name) {
    return '$name claimed this conversation';
  }

  @override
  String claim_assigned_to_you(String name) {
    return '$name assigned this to you';
  }

  @override
  String claim_resolved_live(String name) {
    return '$name resolved the conversation';
  }

  @override
  String get claim_network_error =>
      'Couldn\'t claim. Check your connection and try again.';

  @override
  String get claim_retry => 'Retry';

  @override
  String get claim_forbidden => 'You don\'t have permission to claim this';

  @override
  String claim_team_only(String team) {
    return 'This conversation belongs to $team';
  }

  @override
  String get claim_offline_hint => 'Claiming requires an internet connection';

  @override
  String claim_capacity_hint(int n, int max) {
    return 'You have $n open conversations (limit $max)';
  }

  @override
  String get claim_capacity_reached =>
      'You\'ve reached your conversation limit';

  @override
  String get claim_away_title => 'Your status: Away';

  @override
  String get claim_away_body => 'Claiming will set your status to Available.';

  @override
  String get claim_away_confirm => 'Claim and set me Available';

  @override
  String claim_capacity_title(int n) {
    return 'You have $n open conversations';
  }

  @override
  String get claim_capacity_body => 'Claim one more?';

  @override
  String get claim_capacity_confirm => 'Claim anyway';

  @override
  String get claim_cancel => 'Cancel';

  @override
  String claim_assigned_toast(String name) {
    return 'Assigned to $name';
  }

  @override
  String get claim_undo => 'Undo';

  @override
  String get claim_reply_placeholder => 'Type to claim and reply…';

  @override
  String get claim_short => 'Claim';

  @override
  String claim_handoff_event(String reason) {
    return 'AI handed this to the team: $reason';
  }

  @override
  String get claim_reason_payment => 'Payment issue';

  @override
  String get claim_reason_human => 'Asked for a human';

  @override
  String get claim_reason_complaint => 'Complaint';

  @override
  String get claim_reason_no_answer => 'Unanswered question';

  @override
  String get claim_reason_refund => 'Refund request';

  @override
  String get claim_reason_other => 'Other';

  @override
  String get claim_push_title => 'New conversation waiting';

  @override
  String get claim_push_action => 'Claim';

  @override
  String claim_push_success(String customer) {
    return 'You claimed the chat with $customer';
  }

  @override
  String get actions_add_note => 'Add internal note';

  @override
  String claim_a11y_wait_span(String t) {
    return 'Waiting for $t';
  }

  @override
  String get conversations_segment_mine => 'Mine';

  @override
  String get conversations_segment_unassigned => 'Unassigned';

  @override
  String get conversations_segment_all => 'All';

  @override
  String get conversations_filter_all => 'All';

  @override
  String get conversations_filter_unread => 'Unread';

  @override
  String get conversations_filter_awaiting => 'Awaiting reply';

  @override
  String get conversations_filter_ai => 'AI replied';

  @override
  String get conversations_filter_closed => 'Closed';

  @override
  String get conversations_filter_more => 'Filters';

  @override
  String get conversations_channel_any => 'All channels';

  @override
  String get conversations_priority_any => 'All priorities';

  @override
  String get conversations_notifications => 'Notifications';

  @override
  String get conversations_new_message => 'New message';

  @override
  String get conversations_exit_selection => 'Exit selection';

  @override
  String conversations_selected_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get conversations_bulk_assign => 'Assign selected';

  @override
  String get conversations_bulk_resolve => 'Resolve selected';

  @override
  String conversations_bulk_resolved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations resolved',
      one: '1 conversation resolved',
    );
    return '$_temp0';
  }

  @override
  String get conversations_resolved_snack => 'Conversation resolved';

  @override
  String get conversations_empty_mine_title =>
      'No conversations assigned to you';

  @override
  String get conversations_empty_mine_body =>
      'Claim one from Unassigned to start replying.';

  @override
  String get conversations_empty_mine_action => 'Show unassigned';

  @override
  String get conversations_empty_filters_title =>
      'No conversations match the filters';

  @override
  String get conversations_empty_filters_body =>
      'Try changing or clearing the filters to see everything.';

  @override
  String get conversations_empty_filters_action => 'Clear filters';

  @override
  String get conversations_empty_done_title => 'You\'re all caught up';

  @override
  String get conversations_empty_done_body =>
      'Nothing needs you right now. We\'ll let you know when a new message arrives.';

  @override
  String get tile_you_prefix => 'You: ';

  @override
  String get tile_ai_reply => 'AI reply';

  @override
  String get tile_ai_ready => 'Suggestion ready';

  @override
  String get tile_typing => 'Typing…';

  @override
  String tile_snoozed_until(String time) {
    return 'Snoozed until $time';
  }

  @override
  String tile_media_with_duration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String get tile_swipe_resolve => 'Resolve';

  @override
  String get tile_swipe_snooze => 'Snooze';

  @override
  String get tile_swipe_assign => 'Assign';

  @override
  String get filters_title => 'Filters';

  @override
  String get filters_channel => 'Channel';

  @override
  String get filters_status => 'Status';

  @override
  String get filters_priority => 'Priority';

  @override
  String get filters_assignee => 'Assignee';

  @override
  String get filters_assignee_all => 'Everyone';

  @override
  String get filters_assignee_me => 'Me';

  @override
  String get filters_assignee_colleague => 'A colleague';

  @override
  String get filters_assignee_ai => 'AI';

  @override
  String get filters_assignee_unassigned => 'Unassigned';

  @override
  String get filters_date => 'Date';

  @override
  String get filters_date_any => 'Any time';

  @override
  String get filters_date_today => 'Today';

  @override
  String get filters_date_7 => '7 days';

  @override
  String get filters_date_30 => '30 days';

  @override
  String get filters_date_custom => 'Custom';

  @override
  String get filters_tags => 'Tags';

  @override
  String filters_show(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count conversations',
      one: 'Show 1 conversation',
      zero: 'No conversations',
    );
    return '$_temp0';
  }

  @override
  String get newmsg_title => 'New message';

  @override
  String get newmsg_subtitle =>
      'Start a WhatsApp conversation with an approved template';

  @override
  String get newmsg_name => 'Customer name';

  @override
  String get newmsg_name_hint => 'Optional';

  @override
  String get newmsg_phone => 'Mobile number';

  @override
  String get newmsg_phone_hint => '+966 5x xxx xxxx';

  @override
  String get newmsg_phone_error =>
      'Enter a valid mobile number with country code';

  @override
  String get newmsg_template => 'Template';

  @override
  String get newmsg_template_error => 'Choose an approved template to send';

  @override
  String get newmsg_send => 'Send template';

  @override
  String get app_name => 'Wavadesk';

  @override
  String get tab_conversations => 'Conversations';

  @override
  String get tab_dashboard => 'Dashboard';

  @override
  String get tab_knowledge => 'Knowledge';

  @override
  String get tab_account => 'Account';

  @override
  String get channel_whatsapp => 'WhatsApp';

  @override
  String get channel_web => 'Website chat';

  @override
  String get channel_messenger => 'Messenger';

  @override
  String get channel_instagram => 'Instagram';

  @override
  String get channel_email => 'Email';

  @override
  String get channel_telegram => 'Telegram';

  @override
  String get channel_sms => 'SMS';

  @override
  String get channel_other => 'Other channel';

  @override
  String get status_open => 'Open';

  @override
  String get status_pending => 'Pending';

  @override
  String get status_waiting => 'Waiting';

  @override
  String get status_snoozed => 'Snoozed';

  @override
  String get status_resolved => 'Resolved';

  @override
  String get status_closed => 'Closed';

  @override
  String get status_ai => 'Handled by AI';

  @override
  String get priority_urgent => 'Urgent';

  @override
  String get priority_high => 'High';

  @override
  String get priority_medium => 'Medium';

  @override
  String get priority_low => 'Low';

  @override
  String get presence_online => 'Available';

  @override
  String get presence_busy => 'Busy';

  @override
  String get presence_away => 'Away';

  @override
  String get role_admin => 'Admin';

  @override
  String get role_supervisor => 'Supervisor';

  @override
  String get role_agent => 'Support agent';

  @override
  String get ownership_mine => 'Assigned to you';

  @override
  String get ownership_unassigned => 'Unassigned';

  @override
  String ownership_colleague(String name) {
    return 'Assigned to $name';
  }

  @override
  String get ownership_ai => 'Handled by AI';

  @override
  String get media_image => 'Photo';

  @override
  String get media_voice => 'Voice message';

  @override
  String get media_file => 'File';

  @override
  String get media_location => 'Location';

  @override
  String get media_album => 'Photo album';

  @override
  String get media_video => 'Video';

  @override
  String get media_contact => 'Contact';

  @override
  String get media_sticker => 'Sticker';

  @override
  String get media_template => 'Template';

  @override
  String get media_email => 'Email';

  @override
  String get media_deleted => 'Deleted message';

  @override
  String get media_unsupported => 'Unsupported message';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_undo => 'Undo';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_close => 'Close';

  @override
  String get common_back => 'Back';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_done => 'Done';

  @override
  String get common_search => 'Search';

  @override
  String get common_clear_search => 'Clear search';

  @override
  String get common_more => 'More';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_you => 'You';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_selected => 'Selected';

  @override
  String get time_now => 'Now';

  @override
  String get time_today => 'Today';

  @override
  String get time_yesterday => 'Yesterday';

  @override
  String time_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String time_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String time_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String duration_minutes_short(int count) {
    return '${count}m';
  }

  @override
  String duration_hours_short(int count) {
    return '${count}h';
  }

  @override
  String duration_days_short(int count) {
    return '${count}d';
  }

  @override
  String waiting_for(String duration) {
    return 'Waiting $duration';
  }

  @override
  String get network_connecting => 'Connecting…';

  @override
  String get network_offline => 'Offline';

  @override
  String get empty_offline_title => 'You\'re offline';

  @override
  String get empty_offline_body =>
      'Check your connection and try again. Your messages will send once you\'re back online.';

  @override
  String a11y_unread_messages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
      zero: 'No unread messages',
    );
    return '$_temp0';
  }

  @override
  String get a11y_notifications_unread => 'Notifications, new items';

  @override
  String get a11y_ai_avatar => 'AI';

  @override
  String get a11y_team_avatar => 'Team';

  @override
  String get a11y_selected => 'Selected';

  @override
  String a11y_priority(String label) {
    return 'Priority: $label';
  }

  @override
  String get time_unit_day => 'd';

  @override
  String get time_unit_hour => 'h';

  @override
  String get time_unit_min => 'm';

  @override
  String get common_increase => 'Increase';

  @override
  String get common_decrease => 'Decrease';

  @override
  String get dash_title => 'Dashboard';

  @override
  String dash_morning(String name) {
    return 'Good morning, $name';
  }

  @override
  String dash_evening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get dash_presence_online_m => 'Available';

  @override
  String get dash_presence_online_f => 'Available';

  @override
  String get dash_presence_busy_m => 'Busy';

  @override
  String get dash_presence_busy_f => 'Busy';

  @override
  String get dash_presence_away => 'Away';

  @override
  String get dash_presence_title => 'Your status';

  @override
  String get dash_presence_until => 'Until…';

  @override
  String get dash_presence_30m => '30 minutes';

  @override
  String get dash_presence_1h => '1 hour';

  @override
  String get dash_presence_eod => 'End of day';

  @override
  String get dash_presence_auto =>
      'You\'ll be set Away after 15 min of inactivity';

  @override
  String dash_presence_until_time(String time) {
    return 'Until $time';
  }

  @override
  String get dash_presence_failed => 'Couldn\'t change your status';

  @override
  String get dash_scope_me => 'Me';

  @override
  String get dash_scope_team => 'My team';

  @override
  String get dash_scope_all => 'Everyone';

  @override
  String get dash_team_picker => 'Choose a team';

  @override
  String get dash_range_today => 'Today';

  @override
  String get dash_range_yesterday => 'Yesterday';

  @override
  String get dash_range_7d => 'Last 7 days';

  @override
  String get dash_range_30d => 'Last 30 days';

  @override
  String get dash_range_title => 'Period';

  @override
  String get dash_open => 'Open conversations';

  @override
  String get dash_awaiting_me => 'Awaiting your reply';

  @override
  String get dash_awaiting_team => 'Awaiting reply';

  @override
  String dash_oldest(String m) {
    return 'Oldest $m';
  }

  @override
  String get dash_none_waiting => 'No one waiting';

  @override
  String get dash_first_response => 'Avg first response';

  @override
  String get dash_minute => 'min';

  @override
  String get dash_ai_reply => 'AI replied';

  @override
  String get dash_of_questions => 'of questions';

  @override
  String get dash_resolved => 'Resolved';

  @override
  String get dash_volume_today => 'Conversations today';

  @override
  String dash_volume_range(String range) {
    return 'Conversations · $range';
  }

  @override
  String dash_total(String n) {
    return '$n conversations';
  }

  @override
  String dash_tooltip(String hour, String n, String ai) {
    return '$hour: $n · $ai by AI';
  }

  @override
  String get dash_legend_all => 'All';

  @override
  String get dash_legend_ai => 'AI';

  @override
  String get dash_no_volume => 'No conversations yet today';

  @override
  String get dash_no_volume_range => 'No conversations in this period';

  @override
  String get dash_team_now => 'Team now';

  @override
  String get dash_see_all => 'See all';

  @override
  String get dash_ai_name => 'AI';

  @override
  String dash_agent_open(String n) {
    return '$n open';
  }

  @override
  String dash_agent_frt(String t) {
    return 'Avg first response today $t';
  }

  @override
  String get dash_agent_view => 'View their conversations';

  @override
  String get dash_redistribute => 'Redistribute';

  @override
  String get dash_redistribute_none => 'No open conversations to redistribute';

  @override
  String get dash_solo => 'You\'re the only one on the team';

  @override
  String get dash_invite => 'Invite a teammate';

  @override
  String dash_ai_impact(String n) {
    return '$n questions answered by AI';
  }

  @override
  String dash_ai_saved(String h) {
    return 'Saved about $h hours of team time';
  }

  @override
  String dash_ai_handoffs(String n) {
    return '$n handoffs';
  }

  @override
  String dash_ai_rating(String p) {
    return '$p% positive';
  }

  @override
  String dash_ai_handling(String n) {
    return 'AI is handling $n now';
  }

  @override
  String get dash_by_channel => 'By channel';

  @override
  String get dash_web_reports => 'Detailed reports on web';

  @override
  String dash_last_updated(String t) {
    return 'Last updated $t';
  }

  @override
  String get dash_load_error => 'Couldn\'t load dashboard';

  @override
  String get dash_card_error => 'Couldn\'t load';

  @override
  String get dash_retry => 'Retry';

  @override
  String get dash_frt_title => 'First response speed';

  @override
  String dash_frt_target(String m) {
    return 'Target: ${m}m';
  }

  @override
  String get dash_frt_lt1 => 'Under 1 min';

  @override
  String get dash_frt_1_5 => '1–5 min';

  @override
  String get dash_frt_5_15 => '5–15 min';

  @override
  String get dash_frt_gt15 => 'Over 15 min';

  @override
  String get dash_frt_note => 'Based on conversations answered by an agent';

  @override
  String get dash_frt_empty => 'No replies yet in this period';

  @override
  String get dash_days_short => 'd';

  @override
  String get dash_hours_short => 'h';

  @override
  String get dash_minutes_short => 'm';

  @override
  String get dash_thousand => 'k';

  @override
  String get dash_onb_title => 'Start receiving conversations';

  @override
  String get dash_onb_wa => 'Connect WhatsApp';

  @override
  String get dash_onb_kb => 'Add knowledge base';

  @override
  String get dash_onb_ai => 'Turn on AI';

  @override
  String get dash_onb_cta => 'Finish setup';

  @override
  String get dash_alert_wa_title => 'WhatsApp is disconnected';

  @override
  String get dash_alert_wa_body => 'Messages won\'t arrive until you reconnect';

  @override
  String get dash_alert_wa_action => 'Reconnect';

  @override
  String dash_alert_sla_title(String n, String sla) {
    return '$n customers waiting over ${sla}m';
  }

  @override
  String get dash_alert_sla_action => 'Reply now';

  @override
  String dash_alert_unassigned_title(String n) {
    return '$n conversations waiting to be claimed';
  }

  @override
  String get dash_alert_view => 'View';

  @override
  String dash_alert_kb_title(String n) {
    return '$n unanswered questions';
  }

  @override
  String get dash_alert_kb_body => 'Add them so the AI answers automatically';

  @override
  String get dash_alert_kb_action => 'Review';

  @override
  String dash_alert_trial_title(String n) {
    return 'Your trial ends in $n days';
  }

  @override
  String get dash_alert_trial_action => 'See plans';

  @override
  String get dash_alert_dismiss => 'Dismiss';

  @override
  String dash_a11y_metric(String label, String value, String aside) {
    return '$label: $value $aside. Tap to view conversations';
  }

  @override
  String dash_a11y_chart(String title, String total, String peak, String n) {
    return '$title: $total. Peak $peak with $n conversations.';
  }

  @override
  String dash_a11y_team(String name, String presence, String n) {
    return '$name, $presence, $n open conversations';
  }

  @override
  String dash_a11y_presence(String status) {
    return 'Your status: $status. Tap to change';
  }

  @override
  String dash_afternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String get dash_period_7d => '7 days';

  @override
  String get dash_period_30d => '30 days';

  @override
  String get dash_nothing_waiting => 'Nothing waiting';

  @override
  String get dash_unit_sec => 'sec';

  @override
  String get dash_unit_hr => 'hr';

  @override
  String get dash_ai_off => 'Off';

  @override
  String get dash_empty => 'No conversations yet';

  @override
  String get dash_connect_wa => 'Connect WhatsApp';

  @override
  String get dash_wa_down => 'WhatsApp disconnected';

  @override
  String dash_offline(String t) {
    return 'Offline · updated $t';
  }

  @override
  String get dash_error => 'Couldn\'t load data';

  @override
  String dash_bar_tip(String n, String slot) {
    return '$n conversations · $slot';
  }

  @override
  String dash_bell_a11y(String n) {
    return 'Notifications, $n unread';
  }

  @override
  String dash_kpi_a11y(String label, String value, String meta) {
    return '$label: $value, $meta';
  }

  @override
  String dash_faster(String p) {
    return '$p% faster';
  }

  @override
  String dash_slower(String p) {
    return '$p% slower';
  }

  @override
  String get dash_vs_previous => 'vs the previous period';

  @override
  String get dash_breakdown_you => 'You';

  @override
  String get dash_breakdown_team => 'Team';

  @override
  String get dash_breakdown_ai => 'AI';

  @override
  String get dash_ai_instant => 'Instant';

  @override
  String dash_more_team(String n) {
    return '$n more';
  }

  @override
  String get inbox_title => 'Conversations';

  @override
  String get inbox_seg_mine => 'Mine';

  @override
  String get inbox_seg_unassigned => 'Unassigned';

  @override
  String get inbox_seg_all => 'All';

  @override
  String get inbox_chip_all => 'All';

  @override
  String get inbox_chip_unread => 'Unread';

  @override
  String get inbox_chip_awaiting => 'Awaiting reply';

  @override
  String get inbox_chip_ai => 'AI replied';

  @override
  String get inbox_chip_snoozed => 'Snoozed';

  @override
  String get inbox_chip_closed => 'Closed';

  @override
  String get inbox_chip_filters => 'Filters';

  @override
  String get inbox_needs_reply => 'Needs your reply';

  @override
  String get inbox_rest => 'Other conversations';

  @override
  String get inbox_see_all => 'See all';

  @override
  String get inbox_show_less => 'Show less';

  @override
  String get inbox_you_prefix => 'You:';

  @override
  String get inbox_draft_prefix => 'Draft:';

  @override
  String get inbox_note_prefix => 'Note:';

  @override
  String get inbox_typing => 'typing…';

  @override
  String get inbox_image => 'Photo';

  @override
  String inbox_voice(String d) {
    return 'Voice message · $d';
  }

  @override
  String get inbox_location => 'Location';

  @override
  String get inbox_sticker => 'Sticker';

  @override
  String get inbox_deleted => 'This message was deleted';

  @override
  String inbox_tag_waiting(String t) {
    return 'Waiting $t';
  }

  @override
  String get inbox_tag_ai_ready => 'Suggestion ready';

  @override
  String get inbox_tag_ai_replied => 'AI replied';

  @override
  String inbox_tag_snoozed(String t) {
    return 'Snoozed until $t';
  }

  @override
  String inbox_tag_window(int h) {
    return 'Window closes in ${h}h';
  }

  @override
  String get inbox_now => 'now';

  @override
  String inbox_min(int n) {
    return '${n}m';
  }

  @override
  String inbox_hour(int n) {
    return '${n}h';
  }

  @override
  String get inbox_yesterday => 'Yesterday';

  @override
  String get inbox_am => 'AM';

  @override
  String get inbox_pm => 'PM';

  @override
  String get inbox_swipe_resolve => 'Resolve';

  @override
  String get inbox_swipe_snooze => 'Snooze';

  @override
  String get inbox_swipe_assign => 'Assign';

  @override
  String get inbox_swipe_claim => 'Claim';

  @override
  String get inbox_resolved => 'Conversation resolved';

  @override
  String inbox_resolved_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations resolved',
      one: '1 conversation resolved',
    );
    return '$_temp0';
  }

  @override
  String get inbox_snoozed_1h => 'Snoozed for 1 hour';

  @override
  String inbox_snoozed_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations snoozed',
      one: 'Conversation snoozed',
    );
    return '$_temp0';
  }

  @override
  String get inbox_undo => 'Undo';

  @override
  String inbox_assigned_to_you(String name) {
    return '$name assigned you a conversation';
  }

  @override
  String get inbox_open => 'Open';

  @override
  String inbox_claimed_by(String name) {
    return 'Claimed by $name';
  }

  @override
  String inbox_new_pill(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new conversations',
      one: '1 new conversation',
    );
    return '$_temp0';
  }

  @override
  String inbox_selected(int n) {
    return '$n selected';
  }

  @override
  String get inbox_select_all => 'Select all';

  @override
  String get inbox_exit_selection => 'Exit selection';

  @override
  String get inbox_mark_read => 'Mark read';

  @override
  String get inbox_mark_unread => 'Mark unread';

  @override
  String inbox_marked_read_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations marked read',
      one: '1 conversation marked read',
    );
    return '$_temp0';
  }

  @override
  String inbox_marked_unread_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations marked unread',
      one: '1 conversation marked unread',
    );
    return '$_temp0';
  }

  @override
  String get inbox_new_conversation => 'New conversation';

  @override
  String get inbox_load_error => 'Couldn\'t load · Retry';

  @override
  String get inbox_end => 'No more conversations';

  @override
  String get inbox_exit_hint => 'Press again to exit';

  @override
  String get inbox_offline_cached => 'Offline — showing the last saved copy';

  @override
  String get inbox_action_failed => 'Couldn\'t complete that. Try again.';

  @override
  String get inbox_tag => 'Tag';

  @override
  String inbox_tag_added(String tag) {
    return 'Tag “$tag” added';
  }

  @override
  String get inbox_priority => 'Priority';

  @override
  String inbox_priority_set(String label) {
    return 'Priority set to $label';
  }

  @override
  String get inbox_archive => 'Archive';

  @override
  String inbox_archived_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations archived',
      one: 'Conversation archived',
    );
    return '$_temp0';
  }

  @override
  String get inbox_clear_all => 'Clear all';

  @override
  String inbox_a11y_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String get inbox_a11y_open_hint => 'Double tap to open the conversation';

  @override
  String inbox_a11y_notifications(int n) {
    return 'Notifications, $n unread';
  }

  @override
  String get inbox_empty_mine_title => 'No conversations assigned to you';

  @override
  String get inbox_empty_mine_body =>
      'Conversations you claim or that are assigned to you will show up here.';

  @override
  String get inbox_empty_mine_action => 'View unassigned';

  @override
  String get inbox_empty_done_title => 'You\'re all caught up';

  @override
  String get inbox_empty_done_body =>
      'Nobody is waiting for your reply right now.';

  @override
  String get inbox_empty_unassigned_title =>
      'No conversations waiting to be claimed';

  @override
  String get inbox_empty_unassigned_body =>
      'AI and your team have everything covered.';

  @override
  String get inbox_empty_new_title => 'No conversations yet';

  @override
  String get inbox_empty_new_body =>
      'Connect WhatsApp to start receiving your customers\' messages.';

  @override
  String get inbox_empty_new_action => 'Connect WhatsApp';

  @override
  String get inbox_empty_filters_title =>
      'No conversations match these filters';

  @override
  String get inbox_empty_filters_action => 'Clear filters';

  @override
  String get inbox_empty_error_title => 'Couldn\'t load conversations';

  @override
  String get inbox_empty_error_body => 'Check your connection and try again.';

  @override
  String get inbox_filters_title => 'Filters';

  @override
  String get inbox_filters_clear => 'Clear';

  @override
  String get inbox_filters_apply => 'Show conversations';

  @override
  String inbox_filters_show(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Show $n conversations',
      one: 'Show 1 conversation',
      zero: 'No conversations',
    );
    return '$_temp0';
  }

  @override
  String get inbox_filters_channel => 'Channel';

  @override
  String get inbox_filters_priority => 'Priority';

  @override
  String get inbox_filters_assignee => 'Assignee';

  @override
  String get inbox_filters_assignee_all => 'All';

  @override
  String get inbox_filters_assignee_me => 'Me';

  @override
  String get inbox_filters_assignee_colleague => 'Specific teammate ▸';

  @override
  String get inbox_filters_assignee_ai => 'AI';

  @override
  String get inbox_filters_assignee_unassigned => 'Unassigned';

  @override
  String get inbox_filters_pick_colleague => 'Choose a teammate';

  @override
  String get inbox_filters_team => 'Team';

  @override
  String get inbox_filters_tags => 'Tags';

  @override
  String get inbox_filters_tags_search => 'Search tags';

  @override
  String get inbox_filters_date => 'Date';

  @override
  String get inbox_filters_date_today => 'Today';

  @override
  String get inbox_filters_date_7d => '7 days';

  @override
  String get inbox_filters_date_30d => '30 days';

  @override
  String get inbox_filters_date_custom => 'Custom ▸';

  @override
  String get inbox_filters_sort => 'Sort';

  @override
  String get inbox_filters_sort_smart => 'Smart (default)';

  @override
  String get inbox_filters_sort_newest => 'Newest';

  @override
  String get inbox_filters_sort_oldest => 'Oldest';

  @override
  String get inbox_filters_sort_waiting => 'Longest waiting';

  @override
  String get kbe_new => 'New question';

  @override
  String get kbe_edit => 'Edit answer';

  @override
  String get kbe_review => 'Review suggestion';

  @override
  String get kbe_save => 'Save';

  @override
  String get kbe_send => 'Send';

  @override
  String kbe_src_unanswered(String n) {
    return 'Asked $n times with no AI answer';
  }

  @override
  String kbe_src_chat(String c, String d) {
    return 'From a chat with $c · $d';
  }

  @override
  String kbe_src_draft(String name, String t) {
    return 'Suggested by $name · $t';
  }

  @override
  String get kbe_src_draft_conv => 'Suggested from a resolved chat';

  @override
  String get kbe_view_convs => 'View conversations';

  @override
  String get kbe_open => 'Open';

  @override
  String get kbe_open_it => 'Open it';

  @override
  String get kbe_question => 'Question';

  @override
  String get kbe_question_ph => 'e.g. Can I return after 30 days?';

  @override
  String get kbe_alts => 'Other ways customers ask';

  @override
  String get kbe_optional => '(optional)';

  @override
  String get kbe_add_alt => '+ Add phrasing';

  @override
  String get kbe_alt_exists => 'This phrasing already exists';

  @override
  String get kbe_alt_limit => 'Up to 15 phrasings, 120 characters each';

  @override
  String get kbe_answer => 'Answer';

  @override
  String get kbe_answer_ph => 'Write the answer as AI should say it…';

  @override
  String kbe_counter(String n) {
    return '$n/2000';
  }

  @override
  String get kbe_ai_draft_tag => 'AI draft — review before saving';

  @override
  String get kbe_tag => 'Tag';

  @override
  String get kbe_tags_title => 'Answer tags';

  @override
  String get kbe_tags_search => 'Search or create a tag';

  @override
  String kbe_tags_create(String name) {
    return 'Create “$name”';
  }

  @override
  String get kbe_tags_primary => 'Primary tag';

  @override
  String get kbe_done => 'Done';

  @override
  String get kbe_improve => 'Improve wording';

  @override
  String get kbe_add_link => 'Add link';

  @override
  String get kbe_link_url => 'URL';

  @override
  String get kbe_link_label => 'Link title (optional)';

  @override
  String get kbe_link_invalid => 'Enter a valid https:// link';

  @override
  String get kbe_insert => 'Insert';

  @override
  String get kbe_cancel => 'Cancel';

  @override
  String kbe_similar(String t) {
    return 'Similar question exists: “$t”';
  }

  @override
  String get kbe_merge_alt => 'Merge as phrasing';

  @override
  String kbe_conflict(String t, String r) {
    return 'May conflict with “$t”: $r';
  }

  @override
  String get kbe_view => 'View';

  @override
  String get kbe_preview => 'Preview: how AI will reply';

  @override
  String get kbe_ai_label => 'AI';

  @override
  String get kbe_writing => 'Writing…';

  @override
  String kbe_tone(String tone) {
    return 'Tone: $tone';
  }

  @override
  String get kbe_conf_high => 'High confidence';

  @override
  String get kbe_conf_med => 'Medium confidence';

  @override
  String get kbe_conf_low => 'Low confidence';

  @override
  String get kbe_low_hint => 'Add phrasings or clarify to raise confidence';

  @override
  String get kbe_try_another => 'Try another question';

  @override
  String get kbe_test_hint => 'Type a question to test';

  @override
  String get kbe_preview_err => 'Preview failed';

  @override
  String get kbe_preview_offline => 'Preview needs a connection';

  @override
  String get kbe_preview_empty =>
      'Complete the question and answer to see a preview';

  @override
  String get kbe_preview_regen => 'Refresh preview';

  @override
  String get kbe_advanced => 'Advanced options';

  @override
  String get kbe_enabled => 'Available to AI';

  @override
  String get kbe_channels => 'Channels';

  @override
  String get kbe_channels_all => 'All channels';

  @override
  String get kbe_expires => 'Valid until';

  @override
  String get kbe_expires_none => 'No end date';

  @override
  String get kbe_expires_clear => 'Remove date';

  @override
  String get kbe_verbatim => 'Send verbatim';

  @override
  String get kbe_verbatim_sub => 'AI sends exactly this text';

  @override
  String get kbe_handoff_after => 'Hand off after answering';

  @override
  String get kbe_internal_notes => 'Internal notes';

  @override
  String get kbe_internal_notes_ph => 'Not used by AI';

  @override
  String kbe_meta(String n, String t, String u) {
    return 'Edited by $n · $t · used $u times';
  }

  @override
  String get kbe_delete => 'Delete answer';

  @override
  String kbe_delete_title(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get kbe_delete_body => 'AI will no longer use it.';

  @override
  String get kbe_deleted => 'Deleted';

  @override
  String get kbe_history => 'Version history';

  @override
  String get kbe_restore => 'Restore this version';

  @override
  String kbe_version_n(String n) {
    return 'Version $n';
  }

  @override
  String get kbe_version_current => 'Current';

  @override
  String get kbe_versions_empty => 'No earlier versions';

  @override
  String get kbe_restored => 'Version restored';

  @override
  String get kbe_restore_failed => 'Couldn\'t restore';

  @override
  String get kbe_err_q => 'Enter the question (min 5 chars)';

  @override
  String get kbe_err_a => 'Enter the answer (min 10 chars)';

  @override
  String get kbe_err_a_long => 'Answer exceeds 2000 characters';

  @override
  String get kbe_err_date => 'Pick a future date';

  @override
  String get kbe_saved_new => 'Answer added · AI will use it now';

  @override
  String get kbe_saved_edit => 'Changes saved';

  @override
  String kbe_saved_unanswered(String n) {
    return 'Added · $n chats were waiting for this';
  }

  @override
  String get kbe_saved_chat => 'Added to knowledge base';

  @override
  String get kbe_proposed => 'Sent for review';

  @override
  String get kbe_approve => 'Approve & publish';

  @override
  String get kbe_approved => 'Answer approved and published';

  @override
  String get kbe_reject => 'Reject';

  @override
  String get kbe_rejected => 'Suggestion rejected';

  @override
  String get kbe_save_err => 'Couldn\'t save';

  @override
  String get kbe_save_forbidden => 'You can\'t save — send it for review';

  @override
  String get kbe_save_offline => 'Saving needs a connection';

  @override
  String get kbe_retry => 'Retry';

  @override
  String get kbe_load_error => 'Couldn\'t load the answer';

  @override
  String kbe_conflict_title(String name) {
    return '$name just edited this answer';
  }

  @override
  String get kbe_view_theirs => 'View theirs';

  @override
  String get kbe_overwrite => 'Save mine over it';

  @override
  String get kbe_restore_draft => 'Unsaved draft — restore it?';

  @override
  String get kbe_restore_btn => 'Restore';

  @override
  String get kbe_restore_ignore => 'Ignore';

  @override
  String get kbe_discard_title => 'Discard changes?';

  @override
  String get kbe_discard_body => 'The answer won\'t be saved.';

  @override
  String get kbe_discard => 'Discard';

  @override
  String get kbe_keep => 'Keep editing';

  @override
  String get kbe_deleted_elsewhere => 'This answer was deleted';

  @override
  String get kbe_close => 'Close';

  @override
  String kbe_a11y_alt(String text) {
    return 'Phrasing: $text, double tap to edit';
  }

  @override
  String get kbe_a11y_alt_delete => 'Delete';

  @override
  String kbe_a11y_ghost(String text) {
    return 'AI-suggested phrasing: $text, tap to add';
  }

  @override
  String get kbe_a11y_save_disabled => 'Complete the question and answer';

  @override
  String get kbe_a11y_dismiss => 'Dismiss warning';

  @override
  String get kbe_media => 'Attachments';

  @override
  String get kbe_media_hint => 'AI sends them with the answer';

  @override
  String get kbe_media_add => 'Add image or voice note';

  @override
  String get kbe_media_image => 'Image';

  @override
  String get kbe_media_voice => 'Voice note';

  @override
  String get kbe_media_with_text => 'With text';

  @override
  String get kbe_media_file_only => 'File only';

  @override
  String get kbe_media_remove => 'Remove';

  @override
  String kbe_media_uploading(int p) {
    return 'Uploading $p%';
  }

  @override
  String get kbe_media_failed => 'Upload failed';

  @override
  String get kbe_media_queued => 'Uploads after saving';

  @override
  String get kbe_media_too_big => 'File larger than 16 MB';

  @override
  String get kbe_media_image_too_big => 'Image larger than 5 MB';

  @override
  String get kbe_media_type_err => 'Choose an image or an audio file';

  @override
  String get kbe_media_upgrade => 'Images and voice notes are on paid plans';

  @override
  String get kbe_media_upgrade_cta => 'View plans';

  @override
  String kbe_media_some_failed(int n) {
    return 'Saved, but $n attachments failed to upload';
  }

  @override
  String get kbe_media_send_mode => 'How it is sent';

  @override
  String get kb_title => 'Knowledge';

  @override
  String kb_search(int n) {
    return 'Search $n entries';
  }

  @override
  String get kb_qa => 'Q&A';

  @override
  String get kb_files => 'Files';

  @override
  String get kb_links => 'Links';

  @override
  String get kb_processing => 'Processing';

  @override
  String kb_unanswered_title(int n) {
    return '$n unanswered questions';
  }

  @override
  String get kb_unanswered_body => 'Customers asked and AI had no answer';

  @override
  String get kb_review => 'Review';

  @override
  String get kb_sort_usage => 'Most used';

  @override
  String get kb_sort_recent => 'Recently updated';

  @override
  String get kb_sort_stale => 'Least recently updated';

  @override
  String get kb_sort_alpha => 'Alphabetical';

  @override
  String get kb_sort_least => 'Least used';

  @override
  String get kb_tags => 'Tags';

  @override
  String kb_used_n(int n) {
    return 'Used $n times';
  }

  @override
  String kb_updated(String t) {
    return 'Updated $t ago';
  }

  @override
  String kb_pages(int n) {
    return '$n pages';
  }

  @override
  String get kb_badge_draft => 'Draft';

  @override
  String get kb_badge_disabled => 'Disabled';

  @override
  String get kb_badge_stale => 'Stale';

  @override
  String get kb_badge_failed => 'Processing failed';

  @override
  String get kb_disable => 'Disable for AI';

  @override
  String get kb_enable => 'Enable';

  @override
  String get kb_edit => 'Edit';

  @override
  String get kb_copy_answer => 'Copy answer';

  @override
  String get kb_delete => 'Delete';

  @override
  String kb_delete_title(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get kb_delete_body => 'AI will no longer use it.';

  @override
  String get kb_deleted => 'Deleted';

  @override
  String kb_drafts(int n) {
    return 'Suggestions to review · $n';
  }

  @override
  String kb_draft_by(String name, String t) {
    return 'Suggested by $name · $t';
  }

  @override
  String get kb_draft_from_conv => 'Suggested from a resolved chat';

  @override
  String get kb_approve => 'Approve';

  @override
  String get kb_reject => 'Reject';

  @override
  String get kb_add_title => 'Add to knowledge base';

  @override
  String get kb_add_qa_sub => 'Fastest and most accurate for AI';

  @override
  String get kb_add_file => 'Upload file';

  @override
  String get kb_add_file_sub =>
      'Many Q&As at once from a JSON file (web panel format)';

  @override
  String get kb_add_link => 'Add link';

  @override
  String get kb_add_link_sub => 'A page from your site, read by AI';

  @override
  String get kb_alt_phrasings => 'Other phrasings';

  @override
  String get kb_answer => 'Answer';

  @override
  String kb_usage_month(int n) {
    return 'Used $n times this month';
  }

  @override
  String kb_positive(int p) {
    return '$p% positive';
  }

  @override
  String kb_last_used(String t) {
    return 'Last used $t';
  }

  @override
  String get kb_recent_uses => 'Recent uses';

  @override
  String kb_meta(String a, String d, String b, String t) {
    return 'Created by $a · $d · Edited by $b $t';
  }

  @override
  String get kb_available_ai => 'Available to AI';

  @override
  String get kb_file_type_err => 'Unsupported file type';

  @override
  String get kb_file_size_err => 'File larger than 10 MB';

  @override
  String kb_uploading(int p) {
    return 'Uploading $p%';
  }

  @override
  String get kb_processing_long => 'Processing… may take a minute';

  @override
  String kb_file_ready(String f, int n) {
    return '\"$f\" is ready · $n answers to review';
  }

  @override
  String get kb_extracted => 'What AI extracted';

  @override
  String get kb_replace => 'Replace file';

  @override
  String get kb_download => 'Download';

  @override
  String get kb_file_failed => 'Couldn\'t read the file';

  @override
  String get kb_fail_encrypted => 'File is password-protected';

  @override
  String get kb_fail_images => 'File contains only images';

  @override
  String get kb_fail_corrupt => 'File is corrupted';

  @override
  String get kb_link_url => 'Page URL';

  @override
  String get kb_link_subpages => 'Include subpages';

  @override
  String get kb_add => 'Add';

  @override
  String kb_last_crawl(String t) {
    return 'Last read $t';
  }

  @override
  String get kb_recrawl => 'Refresh now';

  @override
  String get kb_auto_refresh => 'Auto refresh';

  @override
  String get kb_weekly => 'Weekly';

  @override
  String get kb_monthly => 'Monthly';

  @override
  String get kb_manual => 'Manual';

  @override
  String get kb_unanswered => 'Unanswered questions';

  @override
  String get kb_unanswered_info =>
      'Questions AI couldn\'t answer. Add an answer so it replies next time.';

  @override
  String get kb_sort_frequency => 'Most frequent';

  @override
  String get kb_sort_newest => 'Newest';

  @override
  String kb_asked_n(int n, String t) {
    return 'Asked $n times · last $t';
  }

  @override
  String kb_similar(int k) {
    return '+$k similar wordings';
  }

  @override
  String get kb_ai_draft => 'Suggested draft';

  @override
  String get kb_add_answer => 'Add answer';

  @override
  String get kb_link_existing => 'Link to existing answer';

  @override
  String get kb_ignore => 'Ignore';

  @override
  String get kb_view_convs => 'View conversations';

  @override
  String get kb_suggest_answer => 'Suggest an answer';

  @override
  String get kb_none_unanswered => 'No unanswered questions';

  @override
  String get kb_none_unanswered_body =>
      'AI is finding answers for everything asked.';

  @override
  String get kb_empty_title => 'Start teaching AI about your business';

  @override
  String get kb_empty_body =>
      'Add the top questions your customers ask, with answers.';

  @override
  String get kb_empty_cta => 'Add first question';

  @override
  String get kb_empty_tip => 'We recommend at least 10 questions';

  @override
  String get kb_filter_empty => 'No entries of this type';

  @override
  String get kb_show_all => 'Show all';

  @override
  String get kb_error => 'Couldn\'t load knowledge base';

  @override
  String get kb_retry => 'Retry';

  @override
  String get kb_offline => 'Editing requires internet';

  @override
  String get kb_span_now => 'moments';

  @override
  String kb_span_minutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String kb_span_hours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String kb_span_days(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String kb_span_months(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String kb_span_years(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get kb_web_only => 'This is available on the web dashboard for now';

  @override
  String get kb_menu_ai_settings => 'AI settings';

  @override
  String get kb_menu_tags => 'Manage tags';

  @override
  String get kb_menu_import => 'Import from web';

  @override
  String get kb_sort_by => 'Sort by';

  @override
  String get kb_tags_all => 'All tags';

  @override
  String get kb_tags_apply => 'Apply';

  @override
  String get kb_tags_none => 'No tags yet';

  @override
  String get kb_disabled_done => 'Disabled · AI won\'t use it';

  @override
  String get kb_enabled_done => 'Enabled';

  @override
  String get kb_copied => 'Answer copied';

  @override
  String get kb_approved => 'Approved and published';

  @override
  String get kb_rejected => 'Suggestion rejected';

  @override
  String get kb_ignored => 'Ignored';

  @override
  String kb_linked(String t) {
    return 'Added as a phrasing of \"$t\"';
  }

  @override
  String get kb_pick_answer => 'Choose an answer';

  @override
  String get kb_pick_search => 'Search answers';

  @override
  String kb_uploaded_by(String name, String d) {
    return 'Uploaded by $name · $d';
  }

  @override
  String kb_mb(String n) {
    return '$n MB';
  }

  @override
  String kb_kb(String n) {
    return '$n KB';
  }

  @override
  String get kb_processing_bg =>
      'You can close this; processing continues in the background';

  @override
  String get kb_url_invalid => 'Enter a valid https:// link';

  @override
  String get kb_link_added => 'Link added · reading it now';

  @override
  String get kb_link_pages => 'Pages';

  @override
  String get kb_never_crawled => 'Not read yet';

  @override
  String get kb_recrawl_started => 'Refresh started';

  @override
  String kb_filter_a11y(String label, int n) {
    return '$label, $n, filter';
  }

  @override
  String kb_banner_a11y(int n) {
    return '$n unanswered questions. Review';
  }

  @override
  String get kb_daily_chart => 'Usage over 30 days';

  @override
  String get kb_not_used_yet => 'Not used yet';

  @override
  String get kb_show_less => 'Show less';

  @override
  String get kb_proposed => 'Your suggestion was sent for review';

  @override
  String get kb_save_err => 'Couldn\'t save';

  @override
  String get kb_none_found => 'No results';

  @override
  String get kb_import_title => 'Import from JSON';

  @override
  String get kb_import_hint =>
      'A file with an entries list, each with type, title and body — same format as the web panel.';

  @override
  String get kb_import_pick => 'Choose JSON file';

  @override
  String get kb_import_template => 'Download template';

  @override
  String get kb_importing => 'Importing…';

  @override
  String kb_import_done(int n) {
    return 'Imported $n entries';
  }

  @override
  String kb_import_skipped(int n) {
    return '$n skipped';
  }

  @override
  String kb_import_row_err(int row, String message) {
    return 'Row $row: $message';
  }

  @override
  String get kb_import_failed => 'Import failed';

  @override
  String get kb_import_json_only => 'Choose a .json file';

  @override
  String get kb_template_saved => 'Template saved';

  @override
  String get kb_template_copied => 'Template copied to clipboard';

  @override
  String get kb_media_title => 'Attachments';

  @override
  String kb_media_n(int n) {
    return '$n attachments';
  }

  @override
  String get kb_step_upload => 'File uploaded';

  @override
  String get kb_step_read => 'Reading the document';

  @override
  String get kb_step_prepare => 'Preparing answers';

  @override
  String get kb_processing_hint =>
      'Usually under a minute. You can hide this — we\'ll keep working.';

  @override
  String get kb_hide => 'Hide';

  @override
  String kb_found_answers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'We found $n answers',
      one: 'We found 1 answer',
      zero: 'No answers found',
    );
    return '$_temp0';
  }

  @override
  String get kb_found_review_hint =>
      'Review them and choose what the AI should know.';

  @override
  String get kb_found_admin_hint =>
      'An admin will review them before the AI uses them.';

  @override
  String get kb_review_answers => 'Review answers';

  @override
  String get kb_later => 'Later';

  @override
  String get kb_fail_encrypted_hint =>
      'Remove the password and upload it again.';

  @override
  String get kb_fail_images_hint =>
      'We couldn\'t find readable text. Try a PDF with selectable text or a Word file.';

  @override
  String get kb_fail_corrupt_hint =>
      'Try another file: PDF, Word, TXT or MD, up to 10 MB.';

  @override
  String get kb_fail_no_answers => 'No answers found';

  @override
  String get kb_fail_no_answers_hint =>
      'The document doesn\'t seem to have information customers ask about.';

  @override
  String get kb_fail_ai => 'Couldn\'t read the file right now';

  @override
  String get kb_fail_ai_hint => 'Please try again in a few minutes.';

  @override
  String get kb_fail_quota => 'AI allowance used up';

  @override
  String get kb_fail_quota_hint =>
      'Top up or upgrade your plan to read documents with AI.';

  @override
  String get kb_fail_network => 'No connection';

  @override
  String get kb_fail_network_hint => 'Check your internet and try again.';

  @override
  String get kb_try_another => 'Choose another file';

  @override
  String get kb_review_title => 'Review answers';

  @override
  String kb_review_from(int n, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n answers from $file',
      one: '1 answer from $file',
    );
    return '$_temp0';
  }

  @override
  String get kb_review_hint =>
      'Tick what the AI should know, edit anything that isn\'t quite right, then add.';

  @override
  String kb_review_selected(int n, int total) {
    return '$n of $total selected';
  }

  @override
  String get kb_review_select_all => 'Select all';

  @override
  String get kb_review_clear => 'Clear';

  @override
  String get kb_review_edit => 'Edit';

  @override
  String get kb_review_discard => 'Discard';

  @override
  String kb_review_add(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n answers',
      one: 'Add 1 answer',
      zero: 'Add answers',
    );
    return '$_temp0';
  }

  @override
  String kb_review_adding(int done, int total) {
    return 'Adding $done/$total…';
  }

  @override
  String kb_review_added(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n answers added to the knowledge base',
      one: '1 answer added to the knowledge base',
    );
    return '$_temp0';
  }

  @override
  String kb_review_added_left(int n, int left) {
    return '$n added · $left still to review';
  }

  @override
  String kb_review_partial(int done, int failed) {
    return '$done added, $failed couldn\'t be added. Try again.';
  }

  @override
  String get kb_review_all_done => 'All answers reviewed';

  @override
  String get kb_review_all_done_body =>
      'Nothing left to review from this document.';

  @override
  String kb_file_failed_named(String f) {
    return 'Couldn\'t read \"$f\"';
  }

  @override
  String get kb_add_document => 'Upload a document';

  @override
  String get kb_add_document_sub =>
      'PDF, Word or text. The AI turns it into answers you review.';

  @override
  String get kb_add_ai_badge => 'AI';

  @override
  String get kb_import_another => 'Import another file';

  @override
  String get ntf_title => 'Notifications';

  @override
  String get ntf_read_all => 'Mark all read';

  @override
  String get ntf_read_all_done => 'All marked as read';

  @override
  String get ntf_undo => 'Undo';

  @override
  String get ntf_settings => 'Notification settings';

  @override
  String get ntf_delete_read => 'Delete read';

  @override
  String get ntf_filter_all => 'All';

  @override
  String get ntf_filter_unread => 'Unread';

  @override
  String get ntf_filter_mentions => 'Mentions';

  @override
  String get ntf_filter_assignments => 'Assignments';

  @override
  String get ntf_filter_ai => 'AI';

  @override
  String get ntf_filter_system => 'System';

  @override
  String get ntf_today => 'Today';

  @override
  String get ntf_yesterday => 'Yesterday';

  @override
  String get ntf_this_week => 'This week';

  @override
  String get ntf_older => 'Older';

  @override
  String get ntf_push_off_title => 'Push notifications are off';

  @override
  String get ntf_push_off_body =>
      'Turn them on so you never miss an assigned chat';

  @override
  String get ntf_enable => 'Enable';

  @override
  String get ntf_mark_read => 'Mark as read';

  @override
  String get ntf_mark_unread => 'Mark as unread';

  @override
  String get ntf_mute_type => 'Mute this type';

  @override
  String get ntf_delete => 'Delete';

  @override
  String get ntf_deleted => 'Notification deleted';

  @override
  String get ntf_empty_title => 'No notifications';

  @override
  String get ntf_empty_body =>
      'We\'ll let you know when a chat is assigned to you or your team needs you.';

  @override
  String ntf_empty_filter(String f) {
    return 'No notifications in \"$f\"';
  }

  @override
  String get ntf_show_all => 'Show all';

  @override
  String get ntf_error => 'Couldn\'t load notifications';

  @override
  String get ntf_retry => 'Retry';

  @override
  String get ntf_end => 'No more notifications';

  @override
  String get ntf_retention => 'Notifications are deleted after 90 days';

  @override
  String get ntf_target_gone => 'This conversation is no longer available';

  @override
  String get ntf_claimed_you => 'You claimed it';

  @override
  String ntf_claimed_by(String name) {
    return 'Claimed by $name';
  }

  @override
  String get ntf_approved => 'Approved';

  @override
  String get ntf_rejected => 'Rejected';

  @override
  String ntf_grouped(int n, String name) {
    return '$n new messages from $name';
  }

  @override
  String get ntf_push_private => 'You have a new conversation';

  @override
  String get ntf_t_assigned => 'A new conversation was assigned to you';

  @override
  String ntf_t_claim_needed(int n) {
    return '$n conversations waiting to be claimed';
  }

  @override
  String ntf_t_sla_breach(String customer, String m) {
    return '$customer has been waiting $m for your reply';
  }

  @override
  String ntf_t_transfer_request(String agent) {
    return '$agent asks to take over a conversation';
  }

  @override
  String ntf_t_mention(String agent) {
    return '$agent mentioned you in a note';
  }

  @override
  String get ntf_t_ai_no_answer => 'The AI couldn\'t find an answer';

  @override
  String get ntf_t_ai_handoff => 'The AI handed a conversation to the team';

  @override
  String get ntf_t_ai_low_confidence => 'The AI replied with low confidence';

  @override
  String ntf_t_kb_suggestion(int n) {
    return '$n frequent questions without an answer';
  }

  @override
  String get ntf_t_channel_disconnected => 'WhatsApp disconnected';

  @override
  String get ntf_t_channel_reconnected => 'WhatsApp disconnected and came back';

  @override
  String get ntf_t_channel_quality_low => 'WhatsApp number quality is low';

  @override
  String ntf_t_team_joined(String name) {
    return '$name joined the team';
  }

  @override
  String ntf_t_team_role_changed(String role) {
    return 'Your role changed to $role';
  }

  @override
  String ntf_t_trial_ending(int n) {
    return 'Your trial ends in $n days';
  }

  @override
  String get ntf_t_payment_failed => 'Subscription payment failed';

  @override
  String get ntf_t_plan_limit => 'You\'re close to your AI reply limit';

  @override
  String get ntf_t_app_update => 'A new version is available';

  @override
  String ntf_b_claim_needed(String m) {
    return 'Oldest waiting $m';
  }

  @override
  String ntf_b_ai_no_answer(String topic) {
    return 'A question about $topic. Add the answer so it replies automatically next time.';
  }

  @override
  String ntf_b_ai_low_confidence(String customer) {
    return '$customer · Review the reply';
  }

  @override
  String get ntf_b_kb_suggestion =>
      'Add them to the knowledge base to improve replies';

  @override
  String get ntf_b_channel_disconnected =>
      'Messages won\'t arrive until you reconnect';

  @override
  String ntf_b_channel_reconnected(String m) {
    return 'Down for $m · no messages lost';
  }

  @override
  String get ntf_b_channel_quality_low =>
      'Send fewer bulk messages to avoid restrictions';

  @override
  String ntf_b_team_joined(String role) {
    return 'Role: $role';
  }

  @override
  String ntf_b_team_role_changed(String actor) {
    return 'By $actor';
  }

  @override
  String get ntf_b_trial_ending =>
      'Choose a plan to keep your conversations and AI.';

  @override
  String get ntf_b_payment_failed =>
      'Update your payment method to avoid a service stop';

  @override
  String ntf_b_plan_limit(int p) {
    return 'You\'ve used $p% this month';
  }

  @override
  String ntf_b_app_update(String version) {
    return '$version · Improvements and fixes';
  }

  @override
  String get ntf_a_view => 'View';

  @override
  String get ntf_a_reply => 'Reply now';

  @override
  String get ntf_a_approve => 'Approve';

  @override
  String get ntf_a_reject => 'Reject';

  @override
  String get ntf_a_add_answer => 'Add answer';

  @override
  String get ntf_a_claim => 'Claim';

  @override
  String get ntf_a_review => 'Review';

  @override
  String get ntf_a_reconnect => 'Reconnect';

  @override
  String get ntf_a_plans => 'View plans';

  @override
  String get ntf_a_update => 'Update';

  @override
  String get ntf_a_open => 'Open';

  @override
  String get ntf_more => 'More';

  @override
  String get ntf_dismiss => 'Dismiss';

  @override
  String get ntf_a11y_unread => 'Unread';

  @override
  String ntf_a11y_filter(String f, int n) {
    return '$f, $n unread';
  }

  @override
  String get ntf_muted => 'You won\'t get this type of notification';

  @override
  String get ntf_push_unavailable =>
      'Turn notifications on in your device settings';

  @override
  String get ntf_offline_action => 'This action needs an internet connection';

  @override
  String get ntf_action_failed => 'Couldn\'t complete the action. Try again.';

  @override
  String get ntf_billing_agent_title => 'Billing is managed by an admin';

  @override
  String get ntf_billing_agent_body =>
      'Ask your workspace admin to manage the subscription on the Wavadesk website.';

  @override
  String get profile_title => 'Customer profile';

  @override
  String get profile_add_tag => '+ Tag';

  @override
  String get profile_vip => 'VIP';

  @override
  String get profile_blocked => 'Blocked';

  @override
  String profile_local_time(String time) {
    return '$time their time';
  }

  @override
  String get profile_copied => 'Copied';

  @override
  String get profile_call => 'Call';

  @override
  String get profile_whatsapp => 'WhatsApp';

  @override
  String get profile_note => 'Note';

  @override
  String get profile_block => 'Block';

  @override
  String get profile_unblock => 'Unblock';

  @override
  String get profile_stat_conversations => 'Conversations';

  @override
  String get profile_stat_orders => 'Orders';

  @override
  String get profile_stat_rating => 'Rating';

  @override
  String get profile_stat_first => 'First contact';

  @override
  String get profile_ai_summary => 'AI summary';

  @override
  String get profile_ai_disclaimer => 'Summary may contain mistakes';

  @override
  String get profile_more => 'More';

  @override
  String get profile_notes => 'Team notes';

  @override
  String get profile_add => 'Add';

  @override
  String profile_all_notes(int n) {
    return 'View all notes ($n)';
  }

  @override
  String get profile_no_notes => 'No notes yet';

  @override
  String get profile_first_note => 'Add the first note';

  @override
  String get profile_pin => 'Pin';

  @override
  String get profile_edit => 'Edit';

  @override
  String get profile_delete => 'Delete';

  @override
  String get profile_info => 'Details';

  @override
  String get profile_phone => 'Phone';

  @override
  String get profile_email => 'Email';

  @override
  String get profile_city => 'City';

  @override
  String get profile_language => 'Preferred language';

  @override
  String get profile_timezone => 'Time zone';

  @override
  String get profile_added_by => 'Added by';

  @override
  String get profile_not_set => 'Not set';

  @override
  String get profile_all_info => 'View all details';

  @override
  String get profile_channels => 'Channels';

  @override
  String profile_channel_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations',
      one: '1 conversation',
      zero: 'No conversations',
    );
    return '$_temp0';
  }

  @override
  String get profile_unlink => 'Unlink identity';

  @override
  String get profile_merge => 'Merge with another contact';

  @override
  String get profile_orders => 'Orders';

  @override
  String profile_total_spent(String sum) {
    return 'Total spent: $sum SAR';
  }

  @override
  String get profile_previous => 'Previous conversations';

  @override
  String get profile_all_channels => 'All channels';

  @override
  String profile_closed_by(String date, String name) {
    return '$date · Closed by $name';
  }

  @override
  String profile_ai_replied(String date) {
    return '$date · AI replied';
  }

  @override
  String profile_open_now(String date) {
    return '$date · Open now';
  }

  @override
  String get profile_load_more => 'Load more';

  @override
  String get profile_first_conv => 'This is the first conversation';

  @override
  String get profile_block_cta => 'Block customer';

  @override
  String get profile_block_hint =>
      'You won\'t receive messages from this customer.';

  @override
  String get profile_erase => 'Delete customer data';

  @override
  String profile_visitor(String id) {
    return 'Visitor #$id';
  }

  @override
  String get profile_add_details => 'Add customer details';

  @override
  String get profile_offline => 'Showing last saved version';

  @override
  String get profile_load_error => 'Couldn\'t load profile';

  @override
  String profile_section_error(String section) {
    return 'Couldn\'t load $section';
  }

  @override
  String get profile_retry => 'Retry';

  @override
  String get profile_open_page => 'Open as page';

  @override
  String profile_dialog_label(String name) {
    return 'Customer profile, $name';
  }

  @override
  String get profile_unpin => 'Unpin';

  @override
  String get profile_regenerate => 'Regenerate summary';

  @override
  String profile_note_a11y(String author, String date, String text) {
    return 'Note from $author, $date: $text';
  }

  @override
  String get profile_delete_note_title => 'Delete note?';

  @override
  String get profile_delete_note_body =>
      'This note will be deleted for the whole team.';

  @override
  String profile_action_call_a11y(String name) {
    return 'Call $name';
  }

  @override
  String profile_action_whatsapp_a11y(String name) {
    return 'WhatsApp $name';
  }

  @override
  String profile_action_note_a11y(String name) {
    return 'Add a note about $name';
  }

  @override
  String profile_action_block_a11y(String name) {
    return 'Block $name';
  }

  @override
  String profile_action_unblock_a11y(String name) {
    return 'Unblock $name';
  }

  @override
  String get profile_disabled_no_phone => 'Unavailable, no number';

  @override
  String profile_stats_a11y(
    int conversations,
    String orders,
    String ordersLabel,
    String first,
  ) {
    return '$conversations conversations, $orders $ordersLabel, first contact $first';
  }

  @override
  String profile_order_items(String date, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$date · $_temp0';
  }

  @override
  String profile_amount(String amount) {
    return '$amount SAR';
  }

  @override
  String get profile_order_processing => 'Processing';

  @override
  String get profile_order_shipped => 'Shipped';

  @override
  String get profile_order_delivered => 'Delivered';

  @override
  String get profile_order_cancelled => 'Cancelled';

  @override
  String get profile_view_all => 'See all';

  @override
  String get profile_no_order_link => 'No link for this order';

  @override
  String get profile_lang_ar => 'العربية';

  @override
  String get profile_lang_en => 'English';

  @override
  String profile_tz_value(String tz, String time) {
    return '$tz · $time';
  }

  @override
  String get profile_attr_yes => 'Yes';

  @override
  String get profile_attr_no => 'No';

  @override
  String get profile_unlinked => 'Identity unlinked';

  @override
  String get profile_filter_channel => 'Filter by channel';

  @override
  String get profile_merged => 'This contact was merged';

  @override
  String get profile_more_actions => 'More actions';

  @override
  String get profile_edit_contact => 'Edit customer';

  @override
  String get edit_title => 'Edit customer';

  @override
  String get edit_save => 'Save';

  @override
  String get edit_saved => 'Changes saved';

  @override
  String get edit_failed => 'Couldn\'t save changes. Try again.';

  @override
  String get edit_discard_title => 'Discard changes?';

  @override
  String get edit_discard_body =>
      'Your edits aren\'t saved yet. Leaving now will lose them.';

  @override
  String get edit_discard => 'Discard';

  @override
  String get edit_keep => 'Keep editing';

  @override
  String get edit_name => 'Name';

  @override
  String get edit_phone => 'Phone';

  @override
  String get edit_email => 'Email';

  @override
  String get edit_city => 'City';

  @override
  String get edit_language => 'Preferred language';

  @override
  String get edit_not_set => 'Not set';

  @override
  String get edit_phone_invalid => 'Invalid phone number';

  @override
  String get edit_email_invalid => 'Invalid email format';

  @override
  String get tags_title => 'Tags';

  @override
  String get tags_search => 'Search or create a tag';

  @override
  String tags_create(String q) {
    return 'Create \"$q\"';
  }

  @override
  String get tags_done => 'Done';

  @override
  String get tags_failed => 'Couldn\'t save tags. Try again.';

  @override
  String get tags_remove => 'Remove tag';

  @override
  String get note_new => 'New note';

  @override
  String get note_edit_title => 'Edit note';

  @override
  String get note_placeholder =>
      'What should your team know about this customer…';

  @override
  String get note_pin => 'Pin note';

  @override
  String get note_save => 'Save';

  @override
  String get note_cancel => 'Cancel';

  @override
  String get note_saved => 'Note added';

  @override
  String get note_updated => 'Note updated';

  @override
  String get note_failed => 'Couldn\'t save the note. Try again.';

  @override
  String get call_phone => 'Phone call';

  @override
  String get call_whatsapp => 'WhatsApp call';

  @override
  String get call_copy => 'Copy number';

  @override
  String get call_cancel => 'Cancel';

  @override
  String get call_copied => 'Copied';

  @override
  String get call_failed => 'Couldn\'t open the calling app';

  @override
  String block_title(String name) {
    return 'Block $name?';
  }

  @override
  String get block_body =>
      'You won\'t receive their messages on any channel and open chats will close. You can unblock later.';

  @override
  String get block_reason_label => 'Reason (optional)';

  @override
  String get block_reason_spam => 'Spam';

  @override
  String get block_reason_fraud => 'Fraud';

  @override
  String get block_reason_abuse => 'Abusive';

  @override
  String get block_reason_other => 'Other';

  @override
  String get block_confirm => 'Block';

  @override
  String get block_cancel => 'Cancel';

  @override
  String get block_done => 'Customer blocked';

  @override
  String get block_failed => 'Couldn\'t block the customer. Try again.';

  @override
  String get block_unnamed => 'this customer';

  @override
  String get undo => 'Undo';

  @override
  String get merge_title => 'Merge with another contact';

  @override
  String get merge_search => 'Search by name, phone or email';

  @override
  String get merge_no_results => 'No matching contacts';

  @override
  String get merge_unnamed => 'Unnamed contact';

  @override
  String get merge_into_label => 'Merging into';

  @override
  String get merge_change => 'Change';

  @override
  String get merge_no_conflicts =>
      'No conflicting values — all conversations and notes move to the selected contact.';

  @override
  String get merge_choose_values => 'Choose which values to keep';

  @override
  String get merge_field_name => 'Name';

  @override
  String get merge_field_phone => 'Phone';

  @override
  String get merge_field_email => 'Email';

  @override
  String get merge_field_city => 'City';

  @override
  String get merge_this_contact => 'This contact';

  @override
  String get merge_other_contact => 'Other contact';

  @override
  String get merge_action => 'Merge';

  @override
  String get merge_confirm_title => 'Merging can\'t be undone';

  @override
  String get merge_confirm_body =>
      'Conversations and notes move to the selected contact and this profile is removed.';

  @override
  String get merge_done => 'Contacts merged';

  @override
  String get merge_failed => 'Couldn\'t merge. Try again.';

  @override
  String get erase_title => 'Permanently delete customer data?';

  @override
  String get erase_body =>
      'All of this customer\'s conversations, notes and details will be deleted and can\'t be recovered.';

  @override
  String get erase_type_digits =>
      'Type the last 4 digits of the customer\'s phone to confirm';

  @override
  String erase_type_word(String word) {
    return 'Type \"$word\" to confirm';
  }

  @override
  String get erase_word => 'delete';

  @override
  String get erase_confirm => 'Delete permanently';

  @override
  String get erase_cancel => 'Cancel';

  @override
  String get erase_done => 'Customer data deleted';

  @override
  String get erase_failed => 'Couldn\'t delete the data. Try again.';

  @override
  String get search_placeholder => 'Search customers, messages, or order #';

  @override
  String get search_cancel => 'Cancel';

  @override
  String get search_scope_all => 'All';

  @override
  String get search_scope_contacts => 'Customers';

  @override
  String get search_scope_messages => 'Messages';

  @override
  String get search_scope_kb => 'Knowledge';

  @override
  String get search_scope_conversations => 'Conversations';

  @override
  String get search_filters => 'Filters';

  @override
  String get search_section_contacts => 'Customers';

  @override
  String get search_section_messages => 'Messages';

  @override
  String get search_section_kb => 'Knowledge base';

  @override
  String get search_section_conversations => 'Conversations';

  @override
  String search_see_all(int n) {
    return 'See all ($n)';
  }

  @override
  String get search_best_match => 'Best match';

  @override
  String get search_open_chat => 'Open chat';

  @override
  String get search_profile => 'Profile';

  @override
  String get search_open_badge => 'Open';

  @override
  String search_more_in_conv(int n) {
    return '+$n more in this conversation';
  }

  @override
  String search_kb_usage(int n) {
    return 'Used by AI $n times this month';
  }

  @override
  String get search_insert_reply => 'Insert into reply';

  @override
  String get search_you => 'You:';

  @override
  String get search_note => 'Note:';

  @override
  String search_order(String n) {
    return 'Order $n';
  }

  @override
  String search_tag(String tag) {
    return 'Tag: $tag';
  }

  @override
  String get search_recent => 'Recent searches';

  @override
  String get search_clear => 'Clear';

  @override
  String get search_suggestions => 'Suggestions';

  @override
  String get search_recent_contacts => 'Recently contacted';

  @override
  String get search_tip => 'Search by name, phone, order #, or any word';

  @override
  String search_no_results(String q) {
    return 'No results for \"$q\"';
  }

  @override
  String get search_no_results_body => 'Try another word or check spelling';

  @override
  String get search_clear_filters => 'Clear filters';

  @override
  String get search_in_all => 'Search everything';

  @override
  String search_did_you_mean(String s) {
    return 'Did you mean: $s?';
  }

  @override
  String get search_error => 'Search failed';

  @override
  String get search_retry => 'Retry';

  @override
  String get search_offline => 'Offline — showing saved data only';

  @override
  String get search_local => '(local)';

  @override
  String get search_filter_sender => 'Sender';

  @override
  String get search_filter_contains => 'Contains';

  @override
  String get search_filter_attachments => 'Attachments';

  @override
  String get search_filter_images => 'Images';

  @override
  String get search_filter_voice => 'Voice messages';

  @override
  String search_show_results(int n) {
    return 'Show results ($n)';
  }

  @override
  String get search_field_label => 'Search';

  @override
  String search_filters_n(int n) {
    return 'Filters · $n';
  }

  @override
  String get search_filter_channel => 'Channel';

  @override
  String get search_filter_date => 'Date';

  @override
  String get search_filter_status => 'Conversation status';

  @override
  String get search_filter_assignee => 'Assignee';

  @override
  String get search_date_any => 'Any time';

  @override
  String get search_date_today => 'Today';

  @override
  String get search_date_7 => '7 days';

  @override
  String get search_date_30 => '30 days';

  @override
  String get search_date_custom => 'Custom';

  @override
  String get search_sender_all => 'All';

  @override
  String get search_sender_contact => 'Customer';

  @override
  String get search_sender_me => 'Me';

  @override
  String get search_sender_colleagues => 'Teammates';

  @override
  String get search_sender_ai => 'AI';

  @override
  String get search_sender_notes => 'Internal notes';

  @override
  String get search_status_all => 'All';

  @override
  String get search_status_open => 'Open';

  @override
  String get search_status_resolved => 'Resolved';

  @override
  String get search_assignee_all => 'All';

  @override
  String get search_assignee_me => 'Me';

  @override
  String get search_assignee_colleague => 'Teammate';

  @override
  String get search_sugg_unread => 'Unread';

  @override
  String get search_sugg_awaiting => 'Awaiting reply';

  @override
  String get search_sugg_vip => 'Tag: VIP';

  @override
  String get search_sugg_orders_today => 'Today\'s orders';

  @override
  String search_recent_remove(String q) {
    return 'Remove $q from history';
  }

  @override
  String get search_recents_cleared => 'Search history cleared';

  @override
  String search_results_announce(int n, String parts) {
    return '$n results: $parts';
  }

  @override
  String search_announce_contacts(int n) {
    return '$n customers';
  }

  @override
  String search_announce_messages(int n) {
    return '$n messages';
  }

  @override
  String search_announce_kb(int n) {
    return '$n articles';
  }

  @override
  String search_announce_conversations(int n) {
    return '$n conversations';
  }

  @override
  String search_a11y_message(String name, String time, String text) {
    return 'Message from $name, $time: $text';
  }

  @override
  String get search_last_chat => 'Open last conversation';

  @override
  String get search_new_chat => 'New conversation';

  @override
  String get search_copy_number => 'Copy number';

  @override
  String get search_copied => 'Number copied';

  @override
  String get search_call => 'Call';

  @override
  String get search_section_teammates => 'Teammates';

  @override
  String get search_no_chat_yet =>
      'No previous conversation with this customer';

  @override
  String get search_inserted => 'Answer inserted into the reply';

  @override
  String get search_in_conv_placeholder => 'Search this conversation';

  @override
  String search_in_conv_count(int i, int n) {
    return '$i of $n';
  }

  @override
  String get search_in_conv_action => 'Search in conversation';

  @override
  String get search_in_conv_prev => 'Previous match';

  @override
  String get search_in_conv_next => 'Next match';

  @override
  String get search_in_conv_close => 'Close search';

  @override
  String get startup_unavailable_title => 'We can\'t connect right now';

  @override
  String get startup_unavailable_body =>
      'Wavadesk couldn\'t reach its servers. Make sure you\'re using the latest version of the app, then try again.';

  @override
  String get startup_unavailable_help =>
      'Still not working? Contact us at support@wavadesk.com';

  @override
  String get startup_retry => 'Try again';

  @override
  String get startup_contact_support => 'Contact support';

  @override
  String get startup_dev_hint =>
      'Developer: the API URL or key is missing. Run with --dart-define-from-file=dart_defines/<env>.json or fill assets/config/api.json.';

  @override
  String get wa_title => 'Your WhatsApp';

  @override
  String get wa_refresh => 'Refresh status';

  @override
  String get wa_log => 'Connection log';

  @override
  String get wa_help => 'Help';

  @override
  String get wa_connected => 'Connected';

  @override
  String get wa_connecting => 'Connecting';

  @override
  String get wa_syncing => 'Syncing';

  @override
  String get wa_phone_offline => 'Phone offline';

  @override
  String get wa_disconnected => 'Disconnected';

  @override
  String get wa_restricted => 'Restricted';

  @override
  String get wa_pending => 'Not linked';

  @override
  String get wa_msgs_today => 'messages today';

  @override
  String get wa_quality => 'Number quality';

  @override
  String get wa_q_high => 'High';

  @override
  String get wa_q_med => 'Medium';

  @override
  String get wa_q_low => 'Low';

  @override
  String get wa_stable => 'Stable';

  @override
  String get wa_unstable => 'Unstable';

  @override
  String get wa_linked_since => 'Linked for';

  @override
  String wa_days(String n) {
    return '$n days';
  }

  @override
  String wa_alert_disc_title(String t) {
    return 'Disconnected $t ago';
  }

  @override
  String get wa_alert_disc_body =>
      'Customer messages won\'t arrive until you reconnect';

  @override
  String get wa_reconnect => 'Reconnect';

  @override
  String get wa_alert_phone_title => 'Your phone is offline';

  @override
  String get wa_alert_phone_body =>
      'Make sure WhatsApp is running on the linked phone';

  @override
  String get wa_check_again => 'Check again';

  @override
  String get wa_alert_quality => 'Number quality is low';

  @override
  String get wa_alert_quality_body =>
      'Reduce bulk messages and repetitive content';

  @override
  String get wa_details => 'Details';

  @override
  String wa_alert_limit(String l, String u) {
    return 'Near daily conversation limit ($u/$l)';
  }

  @override
  String get wa_alert_update => 'Update WhatsApp on your phone';

  @override
  String get wa_alert_pending => 'WhatsApp isn\'t linked yet';

  @override
  String get wa_alert_pending_body =>
      'Link your number to start receiving messages';

  @override
  String get wa_connect => 'Connect WhatsApp';

  @override
  String get wa_auto => 'Automatic messages';

  @override
  String get wa_welcome => 'Welcome message';

  @override
  String get wa_away => 'Away message';

  @override
  String get wa_away_ai => 'Handled by AI right now';

  @override
  String get wa_quick => 'Quick replies';

  @override
  String get wa_welcome_delay => 'Welcome delay';

  @override
  String get wa_now => 'Immediately';

  @override
  String get wa_welcome_off => 'Welcome message turned off';

  @override
  String get wa_undo => 'Undo';

  @override
  String get wa_templates => 'Approved templates';

  @override
  String get wa_tpl_marketing => 'Marketing';

  @override
  String get wa_tpl_utility => 'Utility';

  @override
  String get wa_tpl_auth => 'Auth';

  @override
  String get wa_tpl_approved => 'Approved';

  @override
  String get wa_tpl_pending => 'In review';

  @override
  String get wa_tpl_rejected => 'Rejected';

  @override
  String get wa_tpl_manage_web => 'Manage templates on web';

  @override
  String get wa_numbers => 'Numbers';

  @override
  String get wa_add_second => 'Add a second number';

  @override
  String get wa_business_only => 'Available on Business plan';

  @override
  String get wa_upgrade => 'Upgrade';

  @override
  String get wa_add_number => 'Add number';

  @override
  String get wa_watch => 'Watch: how to connect WhatsApp';

  @override
  String wa_watch_sub(String d) {
    return 'Video guide · $d';
  }

  @override
  String get wa_advanced => 'Advanced';

  @override
  String get wa_read_receipts => 'Read receipts to customer';

  @override
  String get wa_mark_read_open => 'Mark read when opened';

  @override
  String get wa_auto_transcribe => 'Auto-transcribe voice messages';

  @override
  String get wa_ignore_groups => 'Ignore group messages';

  @override
  String get wa_blocked => 'Blocked numbers';

  @override
  String get wa_hours => 'Working hours';

  @override
  String get wa_disconnect => 'Disconnect number';

  @override
  String get wa_disc_title => 'Disconnect WhatsApp number?';

  @override
  String get wa_disc_body =>
      'Messages won\'t reach Wavadesk and AI will stop replying. Past chats are kept.';

  @override
  String wa_disc_open(String n) {
    return '$n open chats will stop';
  }

  @override
  String get wa_disc_confirm_label => 'Type the last 4 digits to confirm';

  @override
  String get wa_disc_done => 'Number disconnected';

  @override
  String get wa_connect_title => 'Connect WhatsApp';

  @override
  String wa_step(String i, String n) {
    return 'Step $i of $n';
  }

  @override
  String get wa_by_phone => 'Phone number';

  @override
  String get wa_by_qr => 'QR code';

  @override
  String get wa_get_code => 'Get code';

  @override
  String get wa_copy => 'Copy';

  @override
  String wa_expires_in(String t) {
    return 'Expires in $t';
  }

  @override
  String get wa_steps_pair =>
      'Open WhatsApp → Settings → Linked devices → Link a device → Link with phone number → Enter code';

  @override
  String get wa_open_app => 'Open WhatsApp';

  @override
  String get wa_linked_ok => 'WhatsApp connected';

  @override
  String get wa_syncing_recent => 'Syncing recent chats…';

  @override
  String get wa_back => 'Back';

  @override
  String get wa_back_online => 'Back online · no messages lost';

  @override
  String get wa_code_expired => 'Code expired';

  @override
  String get wa_new_code => 'New code';

  @override
  String get wa_number_taken => 'This number is linked to another workspace';

  @override
  String get wa_watch_video => 'Watch the video';

  @override
  String get wa_welcome_when => 'When to send?';

  @override
  String get wa_trigger_first => 'First message from a new customer';

  @override
  String get wa_trigger_new => 'Every new conversation';

  @override
  String get wa_trigger_24h => 'After 24h of silence';

  @override
  String get wa_buttons => 'Quick buttons';

  @override
  String get wa_ai_after_welcome => 'AI will reply right after the welcome';

  @override
  String get wa_away_outside => 'Outside working hours';

  @override
  String get wa_away_team => 'When the whole team is away';

  @override
  String wa_away_cooldown(String n) {
    return 'Once every ${n}h per customer';
  }

  @override
  String get wa_away_ai_banner =>
      'AI replies after hours — change it in AI settings';

  @override
  String get wa_qr_team => 'Team';

  @override
  String get wa_qr_mine => 'Mine';

  @override
  String get wa_qr_title_f => 'Title';

  @override
  String get wa_qr_shortcut => 'Shortcut';

  @override
  String get wa_qr_text => 'Text';

  @override
  String get wa_qr_shared => 'Shared with team';

  @override
  String get wa_notify_admin => 'Notify admin';

  @override
  String get wa_load_error => 'Couldn\'t load WhatsApp status';

  @override
  String get wa_enable_after => 'Enable after linking';

  @override
  String get wa_more => 'More';

  @override
  String wa_last_updated(String t) {
    return 'Last updated $t';
  }

  @override
  String get wa_copied => 'Copied';

  @override
  String get wa_details_title => 'Connection details';

  @override
  String get wa_d_type => 'Connection type';

  @override
  String get wa_d_type_linked => 'Linked device';

  @override
  String get wa_d_type_cloud => 'Official WhatsApp API';

  @override
  String get wa_d_device => 'Device';

  @override
  String wa_d_wa_business(String v) {
    return 'WhatsApp Business $v';
  }

  @override
  String wa_d_wa_personal(String v) {
    return 'WhatsApp $v';
  }

  @override
  String get wa_d_last_activity => 'Last activity';

  @override
  String get wa_d_sync => 'Sync status';

  @override
  String get wa_d_synced => 'In sync';

  @override
  String get wa_d_number_id => 'Phone number ID';

  @override
  String get wa_d_daily_limit => 'Daily conversation limit';

  @override
  String wa_d_limit_value(String l, String u) {
    return '$u of $l';
  }

  @override
  String get wa_unknown => 'Unknown';

  @override
  String get wa_qs_explain =>
      'Quality reflects how customers reacted to your messages over the last 7 days. Blocks, reports and low engagement lower it.';

  @override
  String get wa_qs_tier => 'Messaging tier';

  @override
  String wa_qs_tier_value(String tier) {
    return '$tier conversations / day';
  }

  @override
  String get wa_qs_trend => 'Last 7 days';

  @override
  String get wa_qs_tips => 'Tips to raise quality';

  @override
  String get wa_qs_tip1 => 'Only message customers who opted in';

  @override
  String get wa_qs_tip2 => 'Personalise messages, avoid repeated text';

  @override
  String get wa_qs_tip3 => 'Make it easy to opt out';

  @override
  String get wa_qs_help => 'WhatsApp Help Center';

  @override
  String get wa_log_connected => 'Connected';

  @override
  String wa_log_connected_by(String name) {
    return 'Connected by $name';
  }

  @override
  String wa_log_disconnected(String d) {
    return 'Disconnected · $d';
  }

  @override
  String get wa_log_reconnected => 'Reconnected';

  @override
  String wa_log_reconnected_by(String name) {
    return 'Reconnected by $name';
  }

  @override
  String wa_log_recovered(String n) {
    return '$n messages recovered';
  }

  @override
  String get wa_reason_phone_offline => 'Phone offline';

  @override
  String get wa_reason_logged_out => 'Logged out';

  @override
  String get wa_reason_update => 'Update';

  @override
  String get wa_log_empty => 'No events in the last 30 days';

  @override
  String get wa_cancel => 'Cancel';

  @override
  String get wa_disc_mismatch => 'Digits don\'t match';

  @override
  String get wa_disc_failed => 'Couldn\'t disconnect';

  @override
  String get wa_notify_sent => 'Admin notified';

  @override
  String get wa_save_failed => 'Couldn\'t save the change';

  @override
  String get wa_retry => 'Retry';

  @override
  String get wa_offline => 'Editing requires internet';

  @override
  String get wa_saved => 'Saved';

  @override
  String get wa_welcome_on => 'Welcome message turned on';

  @override
  String get wa_away_on => 'Away message turned on';

  @override
  String get wa_away_off => 'Away message turned off';

  @override
  String get wa_delay_30s => 'After 30 seconds';

  @override
  String get wa_delay_1m => 'After 1 minute';

  @override
  String get wa_delay_2m => 'After 2 minutes';

  @override
  String get wa_delay_5m => 'After 5 minutes';

  @override
  String get wa_save => 'Save';

  @override
  String get wa_welcome_enable => 'Turn on welcome message';

  @override
  String get wa_away_enable => 'Turn on away message';

  @override
  String get wa_message => 'Message';

  @override
  String get wa_message_hint => 'Write the message…';

  @override
  String get wa_send_when => 'Send';

  @override
  String get wa_buttons_hint => 'Up to 3 buttons, 20 characters each';

  @override
  String get wa_button_add => '+ Add button';

  @override
  String get wa_button_hint => 'Button label';

  @override
  String get wa_preview => 'Preview';

  @override
  String get wa_err_text => 'Write the message (1–1024 characters)';

  @override
  String get wa_err_button => 'Button label longer than 20 characters';

  @override
  String get wa_go_ai => 'AI settings';

  @override
  String get wa_discard_title => 'Discard changes?';

  @override
  String get wa_discard_body => 'Your edits won\'t be saved.';

  @override
  String get wa_discard => 'Discard';

  @override
  String get wa_keep => 'Keep editing';

  @override
  String get wa_qr_new => 'New quick reply';

  @override
  String get wa_qr_edit => 'Edit quick reply';

  @override
  String get wa_qr_search => 'Search replies';

  @override
  String get wa_qr_empty => 'No quick replies yet';

  @override
  String get wa_qr_empty_body => 'Create one and use it by typing / in a chat';

  @override
  String get wa_qr_no_results => 'No results';

  @override
  String get wa_qr_add => 'Add reply';

  @override
  String wa_qr_used(String n) {
    return 'Used $n times';
  }

  @override
  String wa_qr_delete_title(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get wa_qr_delete_body => 'It won\'t appear in the / list anymore.';

  @override
  String get wa_delete => 'Delete';

  @override
  String get wa_qr_deleted => 'Reply deleted';

  @override
  String get wa_qr_delete_failed => 'Couldn\'t delete the reply';

  @override
  String get wa_qr_attach => 'Attach image or file';

  @override
  String get wa_qr_attach_hint => 'Optional · up to 5 MB';

  @override
  String get wa_qr_attach_too_big => 'File larger than 5 MB';

  @override
  String get wa_qr_attach_remove => 'Remove attachment';

  @override
  String get wa_qr_err_title => 'Enter a title';

  @override
  String get wa_qr_err_text => 'Enter the text';

  @override
  String get wa_qr_err_shortcut_empty => 'Enter a shortcut';

  @override
  String get wa_qr_err_shortcut_invalid => 'Use a–z, 0–9, _ and - only';

  @override
  String get wa_qr_err_shortcut_taken => 'This shortcut is taken';

  @override
  String get wa_qr_err_shortcut_long => 'Shortcut is too long';

  @override
  String get wa_qr_saved => 'Reply saved';

  @override
  String get wa_qr_save_failed => 'Couldn\'t save the reply';

  @override
  String get wa_qr_reorder_failed => 'Couldn\'t save the order';

  @override
  String get wa_qr_shared_sub => 'Visible to the whole team';

  @override
  String get wa_qr_readonly => 'Only admins edit team replies';

  @override
  String get wa_tpl_empty => 'No approved templates yet';

  @override
  String get wa_tpl_preview => 'Template preview';

  @override
  String get wa_phone_hint => '5X XXX XXXX';

  @override
  String get wa_err_phone => 'Enter a valid number';

  @override
  String get wa_rate_limited => 'Too many attempts, try again shortly';

  @override
  String get wa_multi_device =>
      'This account doesn\'t support linked devices; update WhatsApp and retry';

  @override
  String get wa_connect_failed => 'Couldn\'t connect, try again';

  @override
  String get wa_network_error => 'No internet connection';

  @override
  String get wa_qr_steps =>
      'On the other phone open WhatsApp → Settings → Linked devices → Link a device → Scan the code';

  @override
  String wa_qr_refresh_in(String s) {
    return 'Refreshes in ${s}s';
  }

  @override
  String get wa_qr_alt =>
      'QR code to link WhatsApp, refreshes every 20 seconds';

  @override
  String get wa_waiting_link => 'Waiting for the code on your phone…';

  @override
  String get wa_change_number => 'Change number';

  @override
  String get wa_phone_tip =>
      'Linking by phone number is easiest on this device — a QR code can\'t be scanned by the same phone.';

  @override
  String get wa_plan_title => 'WhatsApp isn\'t in your plan';

  @override
  String get wa_plan_body =>
      'Upgrade to link a WhatsApp number and receive customer messages';

  @override
  String get wa_view_plans => 'View plans';

  @override
  String get wa_upgrade_info => 'Ask the workspace owner to upgrade';

  @override
  String get wa_blocked_empty => 'No blocked numbers';

  @override
  String get wa_unblock => 'Unblock';

  @override
  String get wa_unblocked => 'Unblocked';

  @override
  String wa_card_a11y(
    String d,
    String n,
    String name,
    String phone,
    String q,
    String status,
  ) {
    return '$name, $phone, $status. $n messages today, number quality $q, linked for $d days';
  }

  @override
  String get wa_save_disabled => 'Complete the required fields';

  @override
  String wa_log_disconnected_by(String name) {
    return 'Disconnected by $name';
  }

  @override
  String get wa_log_connect_started => 'Connection started';

  @override
  String wa_log_connect_started_by(String name) {
    return '$name started connecting';
  }

  @override
  String get wa_already_linked => 'Already linked';

  @override
  String get wa_banned => 'WhatsApp banned this number';

  @override
  String get wa_demo_state => 'Demo state';
}
