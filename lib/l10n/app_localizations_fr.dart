// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String dashboard_greeting(String name) {
    return 'Bonjour, $name 👋';
  }

  @override
  String get dashboard_open => 'Conversations ouvertes';

  @override
  String get dashboard_waiting_sla => 'En attente au-delà du SLA';

  @override
  String get dashboard_view_queue => 'Voir la file';

  @override
  String get dashboard_first_response => '1ère réponse moy.';

  @override
  String get dashboard_resolved_today => 'Résolues aujourd\'hui';

  @override
  String get dashboard_ai_rate => 'Résolues par l\'IA';

  @override
  String get dashboard_csat => 'Satisfaction client';

  @override
  String get dashboard_csat_scale => 'sur 5';

  @override
  String dashboard_vs_yesterday(String delta) {
    return '$delta par rapport à hier';
  }

  @override
  String get dashboard_volume_title => 'Conversations aujourd\'hui';

  @override
  String dashboard_volume_a11y(int total, int peak, String hour) {
    return '$total conversations aujourd\'hui, pic de $peak à $hour';
  }

  @override
  String get dashboard_channels_title => 'Par canal';

  @override
  String get dashboard_ai_usage_title => 'Utilisation de l\'IA';

  @override
  String get dashboard_ai_manage => 'Gérer';

  @override
  String dashboard_ai_usage_value(int used, int quota) {
    return '$used sur $quota réponses ce mois-ci';
  }

  @override
  String get dashboard_team_title => 'L\'équipe en ce moment';

  @override
  String dashboard_team_open(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations',
      one: '1 conversation',
      zero: 'Aucune conversation',
    );
    return '$_temp0';
  }

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_mark_all => 'Tout marquer comme lu';

  @override
  String get notifications_earlier => 'Plus tôt';

  @override
  String get notifications_empty_title => 'Aucune notification pour le moment';

  @override
  String get notifications_empty_body =>
      'Nous vous préviendrons quand une conversation vous sera assignée ou que vous serez mentionné dans une note.';

  @override
  String get knowledge_search => 'Rechercher dans la base de connaissances';

  @override
  String get knowledge_search_hint => 'Rechercher des réponses…';

  @override
  String get knowledge_add => 'Ajouter une réponse';

  @override
  String get knowledge_filter_all => 'Tout';

  @override
  String get knowledge_type_faq => 'FAQ';

  @override
  String get knowledge_type_policy => 'Politiques';

  @override
  String get knowledge_type_product => 'Produits';

  @override
  String get knowledge_type_snippet => 'Extraits';

  @override
  String get knowledge_type_website => 'Site web';

  @override
  String get knowledge_coverage_title => 'Ce que l\'IA sait';

  @override
  String knowledge_coverage_body(int total, int enabled) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total réponses',
      one: '1 réponse',
    );
    return '$_temp0, $enabled activées';
  }

  @override
  String knowledge_coverage_top(String title) {
    return 'Le plus utilisé : $title';
  }

  @override
  String knowledge_used(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utilisée $count fois',
      one: 'Utilisée une fois',
      zero: 'Pas encore utilisée',
    );
    return '$_temp0';
  }

  @override
  String knowledge_updated(String time) {
    return 'Mise à jour $time';
  }

  @override
  String get knowledge_disabled => 'Désactivée';

  @override
  String knowledge_enabled_a11y(String title) {
    return 'Activer « $title »';
  }

  @override
  String get knowledge_empty_title => 'Votre base de connaissances est vide';

  @override
  String get knowledge_empty_body =>
      'Ajoutez des réponses et des politiques pour que l\'IA puisse rédiger des réponses à partir de celles-ci.';

  @override
  String get knowledge_empty_filtered => 'Aucune réponse de ce type';

  @override
  String knowledge_no_results(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get knowledge_edit_title_add => 'Ajouter une réponse';

  @override
  String get knowledge_edit_title_edit => 'Modifier la réponse';

  @override
  String get knowledge_edit_type => 'Type';

  @override
  String get knowledge_edit_question => 'Question';

  @override
  String get knowledge_edit_title_label => 'Titre';

  @override
  String get knowledge_edit_title_hint =>
      'p. ex. Quel est le délai de livraison ?';

  @override
  String get knowledge_edit_body_label => 'Réponse';

  @override
  String get knowledge_edit_body_hint =>
      'Rédigez la réponse telle que vous souhaitez que l\'IA la formule…';

  @override
  String knowledge_edit_counter(int count, int max) {
    return '$count / $max';
  }

  @override
  String get knowledge_edit_keywords => 'Mots-clés';

  @override
  String get knowledge_edit_keywords_hint =>
      'Tapez un mot-clé et appuyez sur Entrée';

  @override
  String get knowledge_edit_keyword_add => 'Ajouter un mot-clé';

  @override
  String get knowledge_edit_enabled => 'Accessible à l\'IA';

  @override
  String get knowledge_edit_enabled_sub =>
      'Désactivée, elle ne sera pas utilisée dans les suggestions';

  @override
  String get knowledge_edit_preview_title => 'Comment l\'IA l\'utilisera';

  @override
  String get knowledge_edit_preview_q => 'La question du client apparaît ici';

  @override
  String get knowledge_edit_preview_a =>
      'Et la réponse suggérée basée sur votre réponse';

  @override
  String get knowledge_edit_error_title => 'Le titre est requis';

  @override
  String get knowledge_edit_error_body =>
      'Rédigez une réponse d\'au moins 10 caractères';

  @override
  String get knowledge_edit_saved => 'Réponse enregistrée';

  @override
  String get knowledge_edit_delete => 'Supprimer la réponse';

  @override
  String get knowledge_edit_delete_title => 'Supprimer cette réponse ?';

  @override
  String get knowledge_edit_delete_body =>
      'L\'IA ne l\'utilisera plus pour suggérer des réponses.';

  @override
  String get knowledge_edit_deleted => 'Réponse supprimée';

  @override
  String get knowledge_edit_discard_title => 'Abandonner les modifications ?';

  @override
  String get knowledge_edit_discard_body =>
      'Vous avez des modifications non enregistrées qui seront perdues si vous quittez maintenant.';

  @override
  String get knowledge_edit_discard_confirm => 'Abandonner et quitter';

  @override
  String get account_section_admin => 'Gestion';

  @override
  String get account_section_app => 'Application';

  @override
  String get account_whatsapp => 'Votre WhatsApp';

  @override
  String get account_whatsapp_connected => 'Connecté';

  @override
  String get account_whatsapp_disconnected => 'Déconnecté';

  @override
  String get account_channels => 'Canaux';

  @override
  String get account_ai_agent => 'Agent IA';

  @override
  String get account_team => 'Équipe & utilisateurs';

  @override
  String get account_subscription => 'Abonnement';

  @override
  String get account_notifications => 'Notifications';

  @override
  String get account_language => 'Langue';

  @override
  String get account_appearance => 'Apparence';

  @override
  String get account_theme_light => 'Clair';

  @override
  String get account_theme_dark => 'Sombre';

  @override
  String get account_theme_system => 'Automatique';

  @override
  String get account_theme_system_sub => 'Suit le réglage de votre appareil';

  @override
  String get account_help => 'Aide & guides';

  @override
  String get account_logout => 'Se déconnecter';

  @override
  String get account_logout_title => 'Se déconnecter ?';

  @override
  String get account_logout_body =>
      'Vous ne recevrez plus de notifications de conversation sur cet appareil jusqu\'à votre prochaine connexion.';

  @override
  String account_version(String version) {
    return 'Wavadesk $version';
  }

  @override
  String get account_network_online => 'En ligne';

  @override
  String get ai_settings_title => 'Agent IA';

  @override
  String get ai_settings_enable => 'Activer l\'agent IA';

  @override
  String get ai_settings_status_on => 'Actif et propose des réponses';

  @override
  String get ai_settings_status_off => 'Désactivé';

  @override
  String ai_settings_usage(int used, int quota) {
    return '$used sur $quota réponses ce mois-ci';
  }

  @override
  String get ai_settings_section_behavior => 'Comportement';

  @override
  String get ai_settings_suggest => 'Suggérer des réponses';

  @override
  String get ai_settings_suggest_sub =>
      'Un brouillon est prêt avant même que vous ouvriez la conversation';

  @override
  String get ai_settings_auto => 'Réponse automatique';

  @override
  String get ai_settings_auto_sub =>
      'Répond aux conversations non assignées sans attendre';

  @override
  String get ai_settings_claimed => 'Répondre après prise en charge';

  @override
  String get ai_settings_claimed_sub =>
      'Continue de répondre après qu\'un agent a pris en charge la conversation';

  @override
  String get ai_settings_handoff => 'Transférer en cas de frustration';

  @override
  String get ai_settings_handoff_sub =>
      'Transmet la conversation à l\'équipe si le client semble mécontent';

  @override
  String get ai_settings_section_tone => 'Ton des réponses';

  @override
  String get ai_settings_tone_friendly => 'Chaleureux';

  @override
  String get ai_settings_tone_friendly_sub => 'Chaleureux et accessible';

  @override
  String get ai_settings_tone_formal => 'Formel';

  @override
  String get ai_settings_tone_formal_sub => 'Poli et professionnel';

  @override
  String get ai_settings_tone_concise => 'Concis';

  @override
  String get ai_settings_tone_concise_sub => 'Phrases courtes et directes';

  @override
  String get ai_settings_section_knowledge => 'Source de connaissances';

  @override
  String get ai_settings_knowledge => 'Réponses activées';

  @override
  String get ai_settings_knowledge_footer =>
      'L\'IA utilise uniquement votre base de connaissances et n\'invente jamais de réponses.';

  @override
  String get whatsapp_title => 'Votre WhatsApp';

  @override
  String get whatsapp_status_connected => 'Connecté';

  @override
  String get whatsapp_status_disconnected => 'Déconnecté';

  @override
  String get whatsapp_since => 'Connecté depuis';

  @override
  String get whatsapp_messages_today => 'Messages aujourd\'hui';

  @override
  String get whatsapp_connected_tip =>
      'Laissez votre téléphone connecté. Si vous vous déconnectez de WhatsApp sur le téléphone, vous devrez scanner le code à nouveau.';

  @override
  String get whatsapp_disconnect => 'Déconnecter';

  @override
  String get whatsapp_disconnect_title => 'Déconnecter WhatsApp ?';

  @override
  String get whatsapp_disconnect_body =>
      'Les messages des clients n\'arriveront plus dans votre boîte de réception jusqu\'à ce que vous reliiez le numéro.';

  @override
  String get whatsapp_qr_a11y => 'Code QR pour relier WhatsApp';

  @override
  String get whatsapp_qr_expires => 'Le code expire dans une minute';

  @override
  String get whatsapp_waiting_scan =>
      'En attente du scan depuis votre téléphone…';

  @override
  String get whatsapp_steps_title => 'Comment relier';

  @override
  String get whatsapp_step1 => 'Ouvrez WhatsApp sur le téléphone professionnel';

  @override
  String get whatsapp_step2 => 'Appuyez sur ⋮ puis « Appareils connectés »';

  @override
  String get whatsapp_step3 => 'Choisissez « Connecter un appareil »';

  @override
  String get whatsapp_step4 => 'Pointez la caméra vers ce code';

  @override
  String get whatsapp_simulate_scan => 'Scanner le code (démo)';

  @override
  String get whatsapp_new_code => 'Générer un nouveau code';

  @override
  String get whatsapp_connected_toast => 'WhatsApp relié avec succès';

  @override
  String get channels_title => 'Canaux';

  @override
  String get channels_section_connected => 'Connectés';

  @override
  String get channels_section_available => 'Disponibles';

  @override
  String get channels_connected => 'Connecté et reçoit des messages';

  @override
  String get channels_not_connected => 'Non relié';

  @override
  String get channels_manage_on_web =>
      'Ce canal se gère depuis le tableau de bord web';

  @override
  String get channels_footer =>
      'Les messages de chaque canal relié arrivent dans une seule boîte de réception.';

  @override
  String get team_title => 'Équipe & utilisateurs';

  @override
  String get team_invite => 'Inviter un collègue';

  @override
  String get team_invite_sent => 'Lien d\'invitation envoyé';

  @override
  String team_section_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get team_section_teams => 'Équipes';

  @override
  String team_you(String name) {
    return '$name (vous)';
  }

  @override
  String team_members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get subscription_title => 'Abonnement';

  @override
  String get subscription_current => 'Formule actuelle';

  @override
  String get subscription_plan_name => 'Professionnel';

  @override
  String get subscription_price => '199 SAR / mois';

  @override
  String subscription_renews(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get subscription_section_usage => 'Utilisation ce mois-ci';

  @override
  String get subscription_ai_replies => 'Réponses IA';

  @override
  String get subscription_agents => 'Utilisateurs';

  @override
  String get subscription_channels => 'Canaux';

  @override
  String subscription_usage(String used, String total) {
    return '$used / $total';
  }

  @override
  String get subscription_upgrade => 'Mettre à niveau la formule';

  @override
  String get subscription_invoices => 'Factures';

  @override
  String get subscription_upgrade_web =>
      'Nous ouvrirons la page de facturation sur le web';

  @override
  String get notif_settings_title => 'Notifications';

  @override
  String get notif_settings_section_push => 'Me notifier quand';

  @override
  String get notif_settings_assigned => 'Une conversation m\'est assignée';

  @override
  String get notif_settings_assigned_sub =>
      'Par un collègue ou une règle de distribution';

  @override
  String get notif_settings_mentions => 'Je suis mentionné dans une note';

  @override
  String get notif_settings_mentions_sub => 'Quand un collègue tape @votre-nom';

  @override
  String get notif_settings_waiting => 'Temps d\'attente dépassé';

  @override
  String get notif_settings_waiting_sub =>
      'Un client attend plus longtemps que l\'objectif';

  @override
  String get notif_settings_section_sound => 'Son';

  @override
  String get notif_settings_sound => 'Son de notification';

  @override
  String get notif_settings_sound_sub =>
      'Jouer un son à l\'arrivée d\'un nouveau message';

  @override
  String get notif_settings_footer =>
      'Vous ne recevrez pas de notifications tant que votre statut est « Absent ».';

  @override
  String get help_title => 'Aide & guides';

  @override
  String get help_section_guides => 'Guides';

  @override
  String get help_topic_claim =>
      'Prendre en charge et assigner des conversations';

  @override
  String get help_topic_ai => 'Comment fonctionnent les suggestions de l\'IA';

  @override
  String get help_topic_whatsapp => 'Relier un numéro WhatsApp';

  @override
  String get help_topic_knowledge => 'Construire votre base de connaissances';

  @override
  String get help_topic_snooze => 'Mettre en pause et résoudre';

  @override
  String get help_section_contact => 'Nous contacter';

  @override
  String get help_contact_chat => 'Discuter avec le support';

  @override
  String get help_contact_chat_sub =>
      'Nous répondons généralement en quelques minutes';

  @override
  String get help_contact_email => 'E-mail';

  @override
  String get help_opening => 'Ouverture…';

  @override
  String get account_load_error => 'Impossible de charger';

  @override
  String subscription_ends(String date) {
    return 'Se termine le $date';
  }

  @override
  String subscription_trial_ends(String date) {
    return 'L\'essai se termine le $date';
  }

  @override
  String get subscription_trial => 'Essai';

  @override
  String get subscription_unlimited => 'Illimité';

  @override
  String get subscription_no_plan => 'Aucune formule';

  @override
  String subscription_per_month(String price) {
    return '$price / mois';
  }

  @override
  String get channels_meta => 'WhatsApp Business (Meta)';

  @override
  String get channels_open_on_web => 'S’ouvre sur le site web';

  @override
  String get channels_open_web_failed => 'Impossible d’ouvrir le site web';

  @override
  String get channels_meta_sub => 'API officielle · s’ouvre sur le site web';

  @override
  String get ai_title => 'Agent IA';

  @override
  String get ai_master_switch => 'Activer l\'IA';

  @override
  String get ai_state_on => 'Activé';

  @override
  String get ai_state_off => 'Désactivé';

  @override
  String get ai_readonly =>
      'Seuls les administrateurs peuvent modifier les paramètres de l\'IA';

  @override
  String ai_hero_answered(String n) {
    return '$n questions';
  }

  @override
  String ai_hero_caption(String h) {
    return 'répondues cette semaine · ~$h heures économisées';
  }

  @override
  String get ai_hero_off => 'L\'IA est désactivée';

  @override
  String get ai_hero_off_body =>
      'Activez-la pour répondre à partir de votre base de connaissances';

  @override
  String get ai_hero_ready => 'Prêt à fonctionner';

  @override
  String get ai_hero_ready_body =>
      'N\'a pas encore répondu — testez-la d\'abord';

  @override
  String ai_hero_a11y(String n) {
    return '$n questions répondues cette semaine, voir les performances';
  }

  @override
  String ai_usage(String p) {
    return '$p % des réponses de ce mois utilisées';
  }

  @override
  String get ai_ready_title => 'Avant la mise en service';

  @override
  String ai_ready_kb(String n) {
    return 'La base de connaissances contient au moins 10 réponses ($n/10)';
  }

  @override
  String get ai_ready_hours => 'Horaires de travail définis';

  @override
  String get ai_ready_handoff => 'Règle de transfert activée';

  @override
  String get ai_ready_tested => 'Agent testé';

  @override
  String get ai_ready_done => 'Terminé';

  @override
  String get ai_ready_missing => 'Non terminé';

  @override
  String get ai_mode => 'Fonctionnement';

  @override
  String get ai_mode_suggest => 'Suggestion';

  @override
  String get ai_mode_suggest_sub => 'L’IA rédige, l’agent envoie';

  @override
  String get ai_mode_auto => 'Autonome';

  @override
  String get ai_mode_auto_sub => 'L’IA répond automatiquement';

  @override
  String get ai_mode_after => 'Hors horaires uniquement';

  @override
  String get ai_mode_after_sub =>
      'Répond automatiquement hors des horaires de travail';

  @override
  String get ai_mode_after_sub2 => 'et suggère pendant les horaires';

  @override
  String get ai_mode_needs_hours =>
      'Définissez d\'abord les horaires de travail';

  @override
  String get ai_mode_needs_ready =>
      'Terminez d\'abord la liste de contrôle de préparation';

  @override
  String get ai_recommended => 'Recommandé';

  @override
  String ai_mode_changed(String mode) {
    return 'Changé en « $mode »';
  }

  @override
  String get ai_undo => 'Annuler';

  @override
  String get ai_tone => 'Ton';

  @override
  String get ai_tone_friendly => 'Amical';

  @override
  String get ai_tone_formal => 'Formel';

  @override
  String get ai_tone_concise => 'Concis';

  @override
  String get ai_tone_sample_friendly =>
      'Bonjour Noura ! La livraison à Dammam coûte 25 SAR, gratuite au-delà de 300. Elle arrive en 2–3 jours !';

  @override
  String get ai_tone_sample_formal =>
      'Bienvenue. La livraison à Dammam coûte 25 SAR et est gratuite pour les commandes supérieures à 300 SAR, sous 2–3 jours ouvrables.';

  @override
  String get ai_tone_sample_concise =>
      'Livraison à Dammam 25 SAR (gratuite au-delà de 300) · 2–3 jours.';

  @override
  String get ai_use_name => 'Utiliser le nom du client';

  @override
  String get ai_rules => 'Règles';

  @override
  String get ai_hours => 'Horaires de travail';

  @override
  String get ai_hours_24 => '24 heures';

  @override
  String get ai_hours_unset => 'Non défini';

  @override
  String get ai_handoff => 'Transfert à un agent';

  @override
  String get ai_handoff_sub =>
      'En cas de demande d\'un humain, de réclamation ou de paiement';

  @override
  String get ai_language => 'Langue de réponse';

  @override
  String get ai_lang_customer => 'Langue du client';

  @override
  String get ai_lang_customer_sub => 'Détectée par message';

  @override
  String get ai_lang_ar => 'Toujours en arabe';

  @override
  String get ai_lang_en => 'Toujours en anglais';

  @override
  String get ai_lang_style => 'Style';

  @override
  String get ai_lang_msa => 'Arabe standard simple';

  @override
  String get ai_lang_saudi => 'Dialecte saoudien neutre';

  @override
  String get ai_handoff_msg => 'Message de transfert';

  @override
  String get ai_handoff_msg_default =>
      'Je vous mets en relation avec un collègue, un instant s\'il vous plaît.';

  @override
  String get ai_var_customer => 'Nom du client';

  @override
  String get ai_var_return => 'Heure de retour';

  @override
  String get ai_save => 'Enregistrer';

  @override
  String get ai_delay => 'Délai de réponse automatique';

  @override
  String get ai_delay_instant => 'Immédiat';

  @override
  String get ai_delay_30s => 'Après 30 s';

  @override
  String get ai_delay_1m => 'Après 1 min';

  @override
  String get ai_delay_2m => 'Après 2 min';

  @override
  String get ai_delay_note =>
      'Ce délai laisse la priorité aux agents en réponse automatique';

  @override
  String get ai_perf => 'Performances';

  @override
  String get ai_perf_resolution => 'Résolues sans transfert';

  @override
  String get ai_perf_rating => 'Avis positifs';

  @override
  String get ai_perf_unanswered => 'Questions sans réponse';

  @override
  String get ai_perf_detail => 'Voir les performances détaillées';

  @override
  String get ai_perf_week => 'Cette semaine';

  @override
  String get ai_perf_answered => 'Répondues';

  @override
  String get ai_perf_handoffs => 'Transferts';

  @override
  String get ai_perf_reasons => 'Principaux motifs de transfert';

  @override
  String get ai_perf_sources => 'Sources les plus utilisées';

  @override
  String get ai_perf_none => 'Aucune donnée pour l\'instant';

  @override
  String get ai_reason_human_request => 'A demandé un humain';

  @override
  String get ai_reason_complaint => 'Réclamation';

  @override
  String get ai_reason_payment => 'Paiement ou remboursement';

  @override
  String get ai_reason_no_answer => 'Aucune réponse trouvée';

  @override
  String get ai_reason_low_confidence => 'Faible confiance';

  @override
  String get ai_reason_after_replies => 'Réponses sans résolution';

  @override
  String ai_reason_keyword(String word) {
    return 'Mot-clé : $word';
  }

  @override
  String get ai_reason_other => 'Autre';

  @override
  String get ai_advanced => 'Avancé';

  @override
  String get ai_channels => 'Canaux activés';

  @override
  String get ai_channels_none => 'Aucun canal';

  @override
  String get ai_channel_whatsapp => 'WhatsApp';

  @override
  String get ai_channel_web => 'Site web';

  @override
  String get ai_channel_messenger => 'Messenger';

  @override
  String get ai_instructions => 'Instructions supplémentaires';

  @override
  String get ai_instructions_ph =>
      'ex. Ne mentionnez pas les prix de gros ; demandez toujours le numéro de commande avant les questions de livraison';

  @override
  String get ai_instructions_empty => 'Aucune';

  @override
  String get ai_outside_kb => 'Répondre en dehors de la base de connaissances';

  @override
  String get ai_outside_kb_sub =>
      'Non recommandé — peut donner des informations inexactes';

  @override
  String get ai_confidence => 'Seuil de confiance pour l\'envoi automatique';

  @override
  String get ai_conf_low => 'Faible';

  @override
  String get ai_conf_med => 'Moyen';

  @override
  String get ai_conf_high => 'Élevé';

  @override
  String get ai_conf_low_sub =>
      'Envoie automatiquement la plupart des réponses';

  @override
  String get ai_conf_med_sub => 'Équilibre entre rapidité et précision';

  @override
  String get ai_conf_high_sub =>
      'N\'envoie que les réponses certaines ; le reste est suggéré ou transféré';

  @override
  String get ai_team_styles => 'Styles de réécriture de l\'équipe';

  @override
  String get ai_style_add => 'Ajouter un style';

  @override
  String get ai_style_name => 'Nom du style';

  @override
  String get ai_style_instruction => 'Instruction';

  @override
  String get ai_style_delete => 'Supprimer';

  @override
  String get ai_styles_empty => 'Aucun style pour l\'instant';

  @override
  String get ai_audit => 'Journal des modifications';

  @override
  String ai_audit_row(String fields) {
    return 'Modifié : $fields';
  }

  @override
  String get ai_audit_empty => 'Aucune modification pour l\'instant';

  @override
  String get ai_test => 'Tester l\'agent dans une conversation d\'exemple';

  @override
  String get ai_test_title => 'Conversation de test';

  @override
  String get ai_test_sub => 'Ne sera envoyé à aucun client';

  @override
  String get ai_test_info =>
      'Vous êtes le client. Essayez de vraies questions de clients.';

  @override
  String get ai_test_why => 'Pourquoi cette réponse ?';

  @override
  String ai_test_handoff(String reason) {
    return 'Dans une vraie conversation, ceci serait transféré à l\'équipe : $reason';
  }

  @override
  String get ai_test_reset => 'Redémarrer';

  @override
  String get ai_test_channel => 'Changer de canal';

  @override
  String get ai_test_p1 => 'Combien coûte la livraison ?';

  @override
  String get ai_test_p2 => 'Je veux retourner ma commande';

  @override
  String get ai_test_p3 => 'Quels sont vos horaires d\'ouverture ?';

  @override
  String get ai_test_p4 => 'Je veux parler à quelqu\'un';

  @override
  String get ai_test_hint => 'Tapez votre question en tant que client…';

  @override
  String get ai_test_label => 'IA';

  @override
  String get ai_test_error => 'Impossible d\'obtenir une réponse. Réessayez.';

  @override
  String get ai_test_unsaved =>
      'Vous avez des modifications non enregistrées des horaires de travail';

  @override
  String get ai_why_sources => 'Sources';

  @override
  String get ai_why_no_sources =>
      'Aucune source de la base de connaissances utilisée';

  @override
  String get ai_why_confidence => 'Confiance';

  @override
  String get ai_why_rule => 'Règle';

  @override
  String get ai_why_tone => 'Ton';

  @override
  String get ai_off_title => 'Désactiver l\'IA ?';

  @override
  String get ai_off_body =>
      'Elle arrêtera de répondre et de suggérer. Les conversations qu\'elle gère seront transférées à l\'équipe.';

  @override
  String ai_off_handling(String n) {
    return 'Gère actuellement $n conversations';
  }

  @override
  String get ai_off_confirm => 'Désactiver';

  @override
  String get ai_cancel => 'Annuler';

  @override
  String get ai_kb_first_title =>
      'Ajoutez d\'abord votre base de connaissances';

  @override
  String get ai_kb_first_body =>
      'L\'IA ne répond qu\'à partir de vos informations. Ajoutez au moins 10 réponses.';

  @override
  String get ai_kb_add => 'Ajouter des réponses';

  @override
  String get ai_enable_suggest => 'Activer en mode suggestion uniquement';

  @override
  String get ai_auto_title => 'L\'IA répondra directement aux clients';

  @override
  String get ai_auto_b1 =>
      'Répond uniquement à partir de votre base de connaissances';

  @override
  String get ai_auto_b2 => 'Transfère selon vos règles';

  @override
  String get ai_auto_b3 => 'Vous pouvez la désactiver à tout moment';

  @override
  String get ai_auto_tested => 'J\'ai testé l\'agent';

  @override
  String get ai_auto_try => 'Essayer maintenant';

  @override
  String get ai_auto_confirm => 'Activer la réponse automatique';

  @override
  String get ai_outside_title =>
      'Autoriser les réponses en dehors de la base de connaissances ?';

  @override
  String get ai_outside_body =>
      'L\'IA peut donner des informations incorrectes sur vos produits ou vos prix.';

  @override
  String get ai_allow => 'Autoriser';

  @override
  String get ai_plan_off => 'L\'IA n\'est pas disponible avec votre forfait';

  @override
  String get ai_view_plans => 'Voir les forfaits';

  @override
  String ai_quota_out(String date) {
    return 'Quota mensuel de réponses atteint — suggestion uniquement jusqu\'au $date';
  }

  @override
  String get ai_save_failed => 'Impossible d\'enregistrer la modification';

  @override
  String get ai_retry => 'Réessayer';

  @override
  String ai_conflict(String name) {
    return '$name vient de modifier les paramètres';
  }

  @override
  String get ai_conflict_anon =>
      'Quelqu\'un d\'autre vient de modifier les paramètres';

  @override
  String get ai_offline =>
      'Une connexion internet est nécessaire pour modifier';

  @override
  String get ai_load_error => 'Impossible de charger les paramètres de l\'IA';

  @override
  String get ai_saved => 'Enregistré';

  @override
  String get ai_hours_247 => 'Ouvert 24h/24 et 7j/7';

  @override
  String get ai_hours_closed => 'Fermé';

  @override
  String get ai_hours_add_range => '+ Créneau';

  @override
  String get ai_hours_copy_all => 'Copier pour tous les jours';

  @override
  String get ai_hours_timezone => 'Fuseau horaire';

  @override
  String get ai_hours_holidays => 'Jours fériés';

  @override
  String get ai_hours_err_order =>
      'L\'heure de fin doit être après l\'heure de début';

  @override
  String get ai_hours_err_overlap => 'Les créneaux se chevauchent';

  @override
  String get ai_hours_err_max => '2 créneaux maximum';

  @override
  String get ai_hours_start => 'De';

  @override
  String get ai_hours_end => 'À';

  @override
  String get ai_hours_discard => 'Annuler les modifications ?';

  @override
  String get ai_hours_discard_body =>
      'Vous n\'avez pas enregistré les horaires de travail.';

  @override
  String get ai_hours_discard_confirm => 'Annuler';

  @override
  String get ai_day_sat => 'Samedi';

  @override
  String get ai_day_sun => 'Dimanche';

  @override
  String get ai_day_mon => 'Lundi';

  @override
  String get ai_day_tue => 'Mardi';

  @override
  String get ai_day_wed => 'Mercredi';

  @override
  String get ai_day_thu => 'Jeudi';

  @override
  String get ai_day_fri => 'Vendredi';

  @override
  String get ai_ho_intro =>
      'L\'IA transfère automatiquement la conversation à l\'équipe quand :';

  @override
  String get ai_ho_human => 'Le client demande à parler à une personne';

  @override
  String get ai_ho_always => 'Toujours activé';

  @override
  String get ai_ho_complaint => 'Réclamation ou client mécontent';

  @override
  String get ai_ho_payment => 'Sujet de paiement ou de remboursement';

  @override
  String get ai_ho_no_answer => 'Aucune réponse dans la base de connaissances';

  @override
  String get ai_ho_low_conf => 'Faible confiance dans la réponse';

  @override
  String ai_ho_after_n(String n) {
    return 'Après $n réponses sans résolution';
  }

  @override
  String get ai_ho_keywords => 'Mots spécifiques';

  @override
  String get ai_ho_keyword_add => 'Ajouter un mot…';

  @override
  String get ai_ho_target => 'Transférer à ?';

  @override
  String get ai_ho_target_unassigned =>
      'Non attribué (premier à la prendre en charge)';

  @override
  String get ai_ho_target_team => 'Une équipe spécifique';

  @override
  String get ai_ho_target_last => 'Dernier agent ayant aidé le client';

  @override
  String get ai_ho_after_hours => 'Hors horaires de travail';

  @override
  String get ai_ho_tell_return =>
      'Indiquer au client quand vous serez de retour';

  @override
  String get ai_ho_notify => 'Transférer et notifier l\'équipe';

  @override
  String get ai_mode_hybrid => 'Hybride';

  @override
  String get ai_mode_hybrid_sub => 'Automatique jusqu’au mot-clé d’escalade';

  @override
  String get ai_replies => 'Réponses';

  @override
  String get ai_suggestions => 'Suggestions par message';

  @override
  String get ai_suggestions_sub =>
      'Nombre de suggestions de réponse proposées à chaque fois.';

  @override
  String get ai_reply_claimed => 'Répondre quand un agent a la conversation';

  @override
  String get ai_reply_claimed_sub =>
      'Désactivé : l’IA se tait dès qu’une personne prend la conversation.';

  @override
  String get ai_keywords => 'Mots-clés de transfert';

  @override
  String get ai_keywords_sub =>
      'Quand un client écrit l’un de ces mots, la conversation passe à une personne.';

  @override
  String get ai_keywords_none => 'Aucun';

  @override
  String ai_keywords_count(int n) {
    return '$n mots';
  }

  @override
  String get ai_keywords_empty => 'Aucun mot-clé pour l’instant.';

  @override
  String get ai_keywords_hint => 'Ajoutez un mot, ex. responsable';

  @override
  String get ai_keywords_add => 'Ajouter';

  @override
  String get ai_keywords_remove => 'Retirer';

  @override
  String get ai_answer_source => 'Source des réponses';

  @override
  String get ai_answer_source_kb => 'Base de connaissances';

  @override
  String get ai_answer_source_kb_sub =>
      'L’IA répond à partir de votre base de connaissances.';

  @override
  String get ai_answer_source_flow => 'Organisation du bot';

  @override
  String get ai_answer_source_flow_sub =>
      'L’IA suit le parcours du bot créé sur le web.';

  @override
  String get ai_lang_fr => 'Français';

  @override
  String get ai_lang_es => 'Espagnol';

  @override
  String get ai_lang_pt => 'Portugais';

  @override
  String get ai_lang_de => 'Allemand';

  @override
  String get ai_lang_it => 'Italien';

  @override
  String get ai_mode_off => 'Désactivé';

  @override
  String get ai_mode_off_sub => 'IA désactivée';

  @override
  String get ai_mode_auto_info =>
      'En mode autonome, l’IA envoie les réponses directement. Les mots-clés d’escalade mettent l’IA en pause et alertent les agents.';

  @override
  String get ai_mode_set_on_web => 'À régler sur le site pour l’instant';

  @override
  String get ai_mode_hybrid_on_web =>
      'Choisissez « Hybride » sur le site, puis revenez.';

  @override
  String get rw_title => 'Améliorer la réponse';

  @override
  String get rw_subtitle => 'Choisissez un style et l\'IA la reformulera';

  @override
  String get rw_original => 'Votre texte original';

  @override
  String get rw_edit => 'Modifier';

  @override
  String get rw_more => 'Plus';

  @override
  String get rw_selection_hint => 'Seule la partie sélectionnée sera remplacée';

  @override
  String get rw_style_professional => 'Plus professionnel';

  @override
  String get rw_style_shorter => 'Plus court';

  @override
  String get rw_style_friendlier => 'Plus chaleureux';

  @override
  String get rw_style_apology => 'Excuse';

  @override
  String get rw_style_fix => 'Corriger l\'orthographe';

  @override
  String get rw_style_to_en => 'Traduire en anglais';

  @override
  String get rw_style_to_ar => 'Traduire en arabe';

  @override
  String get rw_style_more => 'Plus';

  @override
  String get rw_style_formal => 'Très formel';

  @override
  String get rw_style_saudi => 'Dialecte saoudien';

  @override
  String get rw_style_msa => 'Arabe standard moderne';

  @override
  String get rw_style_greeting =>
      'Ajouter une salutation et une formule de politesse';

  @override
  String get rw_style_bullets => 'Transformer en liste à puces';

  @override
  String get rw_style_sales => 'Plus persuasif';

  @override
  String get rw_style_simple => 'Plus simple et plus clair';

  @override
  String get rw_team_styles => 'Les styles de votre équipe';

  @override
  String rw_customer_prefers(String language) {
    return 'Le client préfère le $language';
  }

  @override
  String get rw_result => 'Formulation suggérée';

  @override
  String get rw_writing => 'Reformulation…';

  @override
  String get rw_streaming => 'Rédaction…';

  @override
  String get rw_edited => 'Modifié manuellement';

  @override
  String get rw_name_added => 'Nom du client ajouté';

  @override
  String get rw_fact_warning =>
      'À vérifier : l\'IA a ajouté des informations absentes de votre réponse';

  @override
  String rw_chars(int n, String delta) {
    return '$n caractères ($delta)';
  }

  @override
  String get rw_over_limit => 'Plus long que ce que permet le canal';

  @override
  String get rw_show_diff => 'Afficher les modifications';

  @override
  String get rw_hide_diff => 'Masquer les modifications';

  @override
  String get rw_use => 'Utiliser cette réponse';

  @override
  String get rw_use_as_is => 'Utiliser tel quel';

  @override
  String get rw_rerun => 'Reformuler à nouveau';

  @override
  String get rw_regenerate => 'Une autre version';

  @override
  String get rw_max_versions => 'Nombre maximal de tentatives atteint';

  @override
  String get rw_no_change =>
      'Votre réponse est déjà bonne — aucune modification';

  @override
  String get rw_error => 'Impossible de reformuler';

  @override
  String get rw_retry => 'Réessayer';

  @override
  String rw_rate_limited(int n) {
    return 'Limite d\'utilisation atteinte, réessayez dans $n s';
  }

  @override
  String get rw_plan_limit =>
      'La reformulation n\'est pas disponible avec votre formule';

  @override
  String get rw_view_plans => 'Voir les formules';

  @override
  String get rw_blocked => 'Ce texte ne peut pas être reformulé';

  @override
  String get rw_offline => 'Connexion Internet requise';

  @override
  String get rw_too_long => 'Texte trop long pour être reformulé (2 000 max)';

  @override
  String get rw_empty_hint =>
      'Écrivez d\'abord une réponse ou utilisez la suggestion IA';

  @override
  String get rw_toolbar => 'Améliorer avec l\'IA';

  @override
  String get rw_lang_ar => 'Arabe';

  @override
  String get rw_lang_en => 'Anglais';

  @override
  String get rw_copy => 'Copier';

  @override
  String get rw_copied => 'Copié';

  @override
  String rw_a11y_ready(String text) {
    return 'Formulation suggérée prête : $text';
  }

  @override
  String get rw_a11y_cached => 'Générée';

  @override
  String rw_a11y_version(int i, int n) {
    return 'Version $i sur $n';
  }

  @override
  String get rw_a11y_prev => 'Précédent';

  @override
  String get rw_a11y_next => 'Suivant';

  @override
  String get rw_a11y_edit_result =>
      'Appuyez pour modifier la formulation, appui long pour copier';

  @override
  String get as_title => 'Attribuer la conversation';

  @override
  String as_title_bulk(int n) {
    return 'Attribuer $n conversations';
  }

  @override
  String as_current(String name) {
    return 'Actuel : $name';
  }

  @override
  String get as_search => 'Rechercher un coéquipier ou une équipe';

  @override
  String as_no_results(String q) {
    return 'Aucun résultat pour « $q »';
  }

  @override
  String get as_filter_all => 'Tous';

  @override
  String as_filter_available(int n) {
    return 'Disponibles ($n)';
  }

  @override
  String get as_filter_my_team => 'Mon équipe';

  @override
  String get as_suggested => 'Suggérés';

  @override
  String get as_teammates => 'Coéquipiers';

  @override
  String get as_teams => 'Équipes';

  @override
  String get as_ai_section => 'IA';

  @override
  String get as_me => 'Moi';

  @override
  String get as_badge_current => 'Actuel';

  @override
  String get as_badge_capacity => 'À la limite';

  @override
  String get as_online_m => 'Disponible';

  @override
  String get as_online_f => 'Disponible';

  @override
  String get as_busy_m => 'Occupé';

  @override
  String get as_busy_f => 'Occupée';

  @override
  String get as_away => 'Absent';

  @override
  String as_last_seen(String t) {
    return 'Vu pour la dernière fois il y a $t';
  }

  @override
  String as_open_count(int n) {
    return '$n conversations ouvertes';
  }

  @override
  String as_members(int n) {
    return '$n membres';
  }

  @override
  String as_available_count(int n) {
    return '$n disponibles';
  }

  @override
  String get as_routing_least => 'Attribué au membre le moins occupé';

  @override
  String get as_routing_rr => 'Répartition tournante';

  @override
  String get as_routing_manual => 'Reste dans la file d\'attente de l\'équipe';

  @override
  String get as_team_none_available =>
      'Personne n\'est disponible — elle attendra dans la file d\'attente de l\'équipe';

  @override
  String get as_ai_name => 'Agent IA';

  @override
  String get as_ai_sub => 'Répond automatiquement et transfère si nécessaire';

  @override
  String get as_ai_unavailable => 'La base de connaissances est trop limitée';

  @override
  String get as_reason_handled => 'A déjà échangé avec ce client';

  @override
  String get as_reason_handled_f => 'A déjà échangé avec ce client';

  @override
  String as_reason_skill(String skill) {
    return 'Expert en $skill';
  }

  @override
  String as_reason_skill_f(String skill) {
    return 'Experte en $skill';
  }

  @override
  String get as_reason_least => 'Le moins occupé';

  @override
  String get as_note => 'Note pour le coéquipier (facultatif)';

  @override
  String get as_note_q1 => 'Le client a besoin d\'une réponse rapide';

  @override
  String get as_note_q2 => 'Problème de paiement';

  @override
  String get as_note_q3 => 'Relancer demain';

  @override
  String get as_pick => 'Choisissez un coéquipier ou une équipe';

  @override
  String as_assign_to(String name) {
    return 'Attribuer à $name';
  }

  @override
  String get as_claim => 'Prendre en charge la conversation';

  @override
  String get as_assign_ai => 'Attribuer à l\'IA';

  @override
  String as_assign_bulk_to(int n, String name) {
    return 'Attribuer $n à $name';
  }

  @override
  String get as_unassign => 'Retirer l\'attribution (retour à non attribuée)';

  @override
  String get as_busy_hint => 'Occupé — la réponse peut être retardée';

  @override
  String get as_busy_hint_f => 'Occupée — la réponse peut être retardée';

  @override
  String get as_away_hint => 'Absent — il sera notifié';

  @override
  String get as_away_hint_f => 'Absente — elle sera notifiée';

  @override
  String as_capacity_reached(int max) {
    return 'Au maximum ($max)';
  }

  @override
  String get as_unavailable => 'Non attribuable';

  @override
  String as_taken_live(String name) {
    return '$name vient de la prendre';
  }

  @override
  String as_reassign_to(String name) {
    return 'Réattribuer à $name';
  }

  @override
  String get as_offline => 'L\'attribution nécessite une connexion internet';

  @override
  String get as_none_available => 'Aucun coéquipier disponible';

  @override
  String get as_show_all => 'Afficher tout';

  @override
  String as_done(String name) {
    return 'Attribuée à $name';
  }

  @override
  String as_done_bulk(int ok, int n) {
    return '$ok sur $n attribuées';
  }

  @override
  String get as_show_errors => 'Voir les erreurs';

  @override
  String get as_undo => 'Annuler';

  @override
  String get as_forbidden => 'Vous ne pouvez pas attribuer à ce coéquipier';

  @override
  String get as_error => 'Impossible d\'attribuer. Réessayez.';

  @override
  String get as_retry => 'Réessayer';

  @override
  String as_event_assigned(String name) {
    return 'Vous avez attribué ceci à $name';
  }

  @override
  String as_event_undo(String actor) {
    return '$actor a annulé l\'attribution';
  }

  @override
  String get as_resolved_live => 'La conversation a été résolue';

  @override
  String as_queued_team(String team) {
    return 'En attente dans la file de l\'équipe $team';
  }

  @override
  String get as_unassigned_done => 'La conversation n\'est plus attribuée';

  @override
  String as_errors_title(int n) {
    return '$n n\'ont pas pu être attribuées';
  }

  @override
  String get as_err_same => 'Déjà attribuée à cette personne';

  @override
  String get as_err_resolved => 'La conversation est résolue';

  @override
  String get as_err_state => 'Le responsable a changé';

  @override
  String get as_err_generic => 'Erreur inattendue';

  @override
  String as_expand_team(String team) {
    return 'Afficher les membres de $team';
  }

  @override
  String get as_a11y_selected => 'sélectionné';

  @override
  String get as_load_error => 'Impossible de charger les coéquipiers';

  @override
  String get login_title => 'Content de vous revoir';

  @override
  String get login_subtitle =>
      'Connectez-vous pour suivre les conversations de vos clients, où que vous soyez.';

  @override
  String get login_identifier_label => 'E-mail ou téléphone';

  @override
  String get login_identifier_hint => 'name@company.com';

  @override
  String get login_password_label => 'Mot de passe';

  @override
  String get login_password_show => 'Afficher le mot de passe';

  @override
  String get login_password_hide => 'Masquer le mot de passe';

  @override
  String get login_forgot => 'Mot de passe oublié ?';

  @override
  String get login_submit => 'Se connecter';

  @override
  String get login_or => 'ou';

  @override
  String get login_biometric_face => 'Se connecter avec Face ID';

  @override
  String get login_biometric_finger =>
      'Se connecter avec l\'empreinte digitale';

  @override
  String get login_biometric_reason => 'Connectez-vous à Wavadesk';

  @override
  String get login_biometric_locked =>
      'L\'authentification biométrique est temporairement verrouillée. Utilisez votre mot de passe.';

  @override
  String get login_no_account => 'Vous n\'avez pas de compte ?';

  @override
  String get login_start_trial => 'Commencer un essai gratuit de 7 jours';

  @override
  String get login_offline => 'Aucune connexion internet';

  @override
  String get login_err_invalid => 'E-mail ou mot de passe incorrect.';

  @override
  String get login_err_disabled =>
      'Ce compte est désactivé. Contactez l\'administrateur de votre espace de travail.';

  @override
  String get login_err_suspended =>
      'L\'abonnement de l\'espace de travail est suspendu.';

  @override
  String get login_manage_subscription => 'Gérer l\'abonnement';

  @override
  String login_err_locked(String time) {
    return 'Trop de tentatives. Réessayez dans $time.';
  }

  @override
  String get login_err_network =>
      'Connexion impossible. Vérifiez votre connexion internet et réessayez.';

  @override
  String get login_err_server =>
      'Un problème est survenu de notre côté. Réessayez dans quelques instants.';

  @override
  String get login_retry => 'Réessayer';

  @override
  String get login_val_identifier_required =>
      'Saisissez votre e-mail ou téléphone';

  @override
  String get login_val_email_invalid => 'Format d\'e-mail invalide';

  @override
  String get login_val_phone_invalid => 'Numéro de téléphone invalide';

  @override
  String get login_val_password_required => 'Saisissez votre mot de passe';

  @override
  String get login_val_password_short => 'Au moins 8 caractères';

  @override
  String get login_bio_sheet_title =>
      'Connectez-vous plus vite la prochaine fois';

  @override
  String get login_bio_sheet_body =>
      'Utilisez Face ID au lieu de votre mot de passe.';

  @override
  String get login_bio_sheet_body_finger =>
      'Utilisez votre empreinte digitale au lieu de votre mot de passe.';

  @override
  String get login_bio_sheet_enable => 'Activer Face ID';

  @override
  String get login_bio_sheet_enable_finger => 'Activer l\'empreinte digitale';

  @override
  String get login_bio_sheet_later => 'Plus tard';

  @override
  String get auth_coming_soon_title => 'Bientôt disponible';

  @override
  String get auth_forgot_placeholder =>
      'La récupération de mot de passe arrivera dans une prochaine mise à jour.';

  @override
  String auth_forgot_placeholder_for(String identifier) {
    return 'La récupération de mot de passe pour $identifier arrivera dans une prochaine mise à jour.';
  }

  @override
  String get auth_2fa_title => 'Code de vérification';

  @override
  String get auth_2fa_placeholder =>
      'La saisie du code de validation en deux étapes arrivera dans une prochaine mise à jour.';

  @override
  String get auth_workspace_title => 'Choisir un espace de travail';

  @override
  String get auth_workspace_placeholder =>
      'Votre compte appartient à plusieurs espaces de travail. La sélection arrivera dans une prochaine mise à jour.';

  @override
  String get chat_ai_suggestion => 'Suggestion IA';

  @override
  String chat_ai_source(String title) {
    return 'Source : $title';
  }

  @override
  String get chat_ai_send => 'Envoyer';

  @override
  String get chat_ai_edit => 'Modifier';

  @override
  String get chat_ai_more => 'Plus';

  @override
  String get chat_ai_low_conf => 'À vérifier avant l\'envoi';

  @override
  String get chat_ai_writing => 'Rédaction de la suggestion…';

  @override
  String get chat_ai_no_answer =>
      'L\'IA n\'a trouvé aucune réponse dans la base de connaissances';

  @override
  String get chat_ai_add_answer => 'Ajouter une réponse';

  @override
  String get chat_ai_ready_pill => 'Suggestion prête';

  @override
  String get chat_placeholder => 'Écrivez une réponse…';

  @override
  String get chat_note_placeholder =>
      'Note pour votre équipe — le client ne la verra pas';

  @override
  String get chat_mode_reply => 'Réponse';

  @override
  String get chat_mode_note => 'Note interne';

  @override
  String get chat_attach_media => 'Photo/Vidéo';

  @override
  String get chat_attach_camera => 'Appareil photo';

  @override
  String get chat_attach_file => 'Fichier';

  @override
  String get chat_attach_location => 'Position';

  @override
  String get chat_attach_quick => 'Réponses rapides';

  @override
  String get chat_attach_template => 'Modèle WhatsApp';

  @override
  String get chat_attach_product => 'Produit';

  @override
  String get chat_record_cancel_hint => 'Glisser pour annuler';

  @override
  String get chat_claim => 'Prendre en charge la conversation';

  @override
  String get chat_assign_colleague => 'Attribuer à un collègue';

  @override
  String chat_viewing_now(String name) {
    return '$name consulte cette conversation en ce moment';
  }

  @override
  String get chat_waiting_claim => 'En attente d\'être prise en charge';

  @override
  String chat_claimed_before(String name) {
    return '$name l\'a prise en charge en premier';
  }

  @override
  String chat_ro_colleague(String name) {
    return 'Attribuée à $name';
  }

  @override
  String get chat_ro_request => 'Demander le transfert';

  @override
  String get chat_ro_resolved => 'Conversation résolue';

  @override
  String get chat_reopen => 'Rouvrir';

  @override
  String get chat_ro_ai => 'L\'IA gère cette conversation';

  @override
  String get chat_take_over => 'Reprendre';

  @override
  String get chat_ro_blocked => 'Ce contact est bloqué';

  @override
  String get chat_unblock => 'Débloquer';

  @override
  String get chat_ro_past => 'Conversation passée — lecture seule';

  @override
  String get chat_banner_offline =>
      'Hors ligne — les messages s\'envoient à la reconnexion';

  @override
  String get chat_banner_window_closed =>
      'Fenêtre de 24 heures fermée — seuls les modèles approuvés sont disponibles';

  @override
  String get chat_choose_template => 'Choisir un modèle';

  @override
  String chat_banner_window_soon(String t) {
    return 'La fenêtre de réponse se ferme dans $t';
  }

  @override
  String get chat_banner_channel_down =>
      'WhatsApp déconnecté — les messages ne seront pas livrés';

  @override
  String get chat_reconnect => 'Se reconnecter';

  @override
  String chat_snoozed_until(String t) {
    return 'Mise en pause jusqu\'à $t';
  }

  @override
  String get chat_unsnooze => 'Annuler la pause';

  @override
  String get composer_attach => 'Joindre';

  @override
  String get composer_send => 'Envoyer';

  @override
  String get composer_send_note => 'Envoyer la note';

  @override
  String get composer_record => 'Maintenir pour enregistrer un message vocal';

  @override
  String get composer_recording => 'Enregistrement';

  @override
  String get composer_record_stop => 'Arrêter';

  @override
  String get composer_record_send => 'Envoyer l\'enregistrement';

  @override
  String get composer_record_cancelled => 'Enregistrement annulé';

  @override
  String get composer_record_locked => 'Enregistrement mains libres';

  @override
  String get composer_record_slide_up =>
      'Glisser vers le haut pour verrouiller';

  @override
  String get composer_ai_rewrite => 'Améliorer la réponse avec l\'IA';

  @override
  String get composer_saved_replies => 'Réponses enregistrées';

  @override
  String get composer_field_label => 'Écrire une réponse';

  @override
  String get composer_note_field_label => 'Écrire une note interne';

  @override
  String get composer_template => 'Modèle';

  @override
  String get composer_template_only =>
      'Fenêtre fermée — envoyez un modèle approuvé';

  @override
  String composer_colleague_typing_note(String name) {
    return '$name rédige une note…';
  }

  @override
  String composer_colleague_viewing(String name) {
    return '$name consulte aussi';
  }

  @override
  String get composer_quick_title => 'Réponses rapides';

  @override
  String get composer_quick_empty => 'Aucune réponse rapide correspondante';

  @override
  String get composer_mention_title => 'Mentionner un collègue';

  @override
  String composer_reply_to(String name) {
    return 'En réponse à $name';
  }

  @override
  String get composer_cancel_reply => 'Annuler la réponse';

  @override
  String get composer_remove_attachment => 'Supprimer la pièce jointe';

  @override
  String composer_uploading(int percent) {
    return 'Envoi $percent %';
  }

  @override
  String get composer_customer => 'Client';

  @override
  String get composer_location_sample => 'Al Malqa, Riyad';

  @override
  String get aicard_close => 'Réduire la suggestion';

  @override
  String get aicard_regenerate => 'Régénérer la suggestion';

  @override
  String get aicard_less => 'Moins';

  @override
  String get aicard_open_pill => 'Afficher la suggestion IA';

  @override
  String claimbar_waiting_minutes(int n) {
    return '$n min';
  }

  @override
  String claimbar_viewers_more(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres',
      one: '1 autre',
    );
    return '$name et $_temp0 consultent cette conversation';
  }

  @override
  String get readonly_take_instead => 'Reprendre à la place';

  @override
  String get readonly_add_note => 'Ajouter une note interne';

  @override
  String get banner_connecting => 'Connexion…';

  @override
  String get composer_mic_denied =>
      'Autorisez l\'accès au microphone dans les réglages pour enregistrer des messages vocaux.';

  @override
  String get composer_record_failed =>
      'Impossible d\'enregistrer. Veuillez réessayer.';

  @override
  String get composer_record_delete => 'Supprimer l\'enregistrement';

  @override
  String get chat_ai_suggest_pill => 'Suggérer une réponse';

  @override
  String composer_file_too_big(String names) {
    return 'Trop volumineux : $names. Photos 5 Mo max, vidéos et audio 16 Mo, documents 10 Mo.';
  }

  @override
  String composer_file_type(String names) {
    return 'Ce type de fichier ne peut pas être envoyé : $names';
  }

  @override
  String get composer_upload_failed => 'Échec de l’envoi';

  @override
  String get composer_upload_retry => 'Réessayer l’envoi';

  @override
  String sys_called(String actor) {
    return '$actor a appelé le client';
  }

  @override
  String get sys_called_me => 'Vous avez appelé le client';

  @override
  String get snooze_title => 'Mettre la conversation en pause';

  @override
  String get snooze_one_hour => 'Dans 1 heure';

  @override
  String get snooze_three_hours => 'Dans 3 heures';

  @override
  String get snooze_tomorrow => 'Demain 9 h';

  @override
  String get snooze_next_week => 'La semaine prochaine';

  @override
  String get snooze_custom => 'Personnalisé';

  @override
  String sys_claimed(String actor) {
    return '$actor a pris en charge la conversation';
  }

  @override
  String get sys_claimed_me => 'Vous avez pris en charge la conversation';

  @override
  String sys_assigned(String actor, String target) {
    return '$actor a attribué la conversation à $target';
  }

  @override
  String sys_assigned_me(String target) {
    return 'Vous avez attribué la conversation à $target';
  }

  @override
  String sys_unassigned(String actor) {
    return '$actor a libéré la conversation';
  }

  @override
  String get sys_unassigned_me => 'Vous avez libéré la conversation';

  @override
  String sys_ai_handoff(String reason) {
    return 'L\'IA a transféré la conversation à l\'équipe : $reason';
  }

  @override
  String sys_ai_paused(String actor) {
    return '$actor a mis l\'IA en pause pour cette conversation';
  }

  @override
  String get sys_ai_paused_me =>
      'Vous avez mis l\'IA en pause pour cette conversation';

  @override
  String sys_ai_resumed(String actor) {
    return '$actor a réactivé l\'IA pour cette conversation';
  }

  @override
  String get sys_ai_resumed_me =>
      'Vous avez réactivé l\'IA pour cette conversation';

  @override
  String sys_resolved(String actor) {
    return '$actor a résolu la conversation';
  }

  @override
  String get sys_resolved_me => 'Vous avez résolu la conversation';

  @override
  String get sys_reopened => 'La conversation a été rouverte';

  @override
  String sys_snoozed(String actor, String time) {
    return '$actor a mis la conversation en pause jusqu\'à $time';
  }

  @override
  String sys_snoozed_me(String time) {
    return 'Vous avez mis la conversation en pause jusqu\'à $time';
  }

  @override
  String sys_priority(String actor, String value) {
    return '$actor a changé la priorité à $value';
  }

  @override
  String sys_priority_me(String value) {
    return 'Vous avez changé la priorité à $value';
  }

  @override
  String sys_tag_added(String actor, String tag) {
    return '$actor a ajouté l\'étiquette « $tag »';
  }

  @override
  String sys_tag_added_me(String tag) {
    return 'Vous avez ajouté l\'étiquette « $tag »';
  }

  @override
  String get sys_window_closed =>
      'La fenêtre de réponse de 24 heures s\'est fermée';

  @override
  String sys_blocked(String actor) {
    return '$actor a bloqué ce contact';
  }

  @override
  String get sys_blocked_me => 'Vous avez bloqué ce contact';

  @override
  String sys_unblocked(String actor) {
    return '$actor a débloqué ce contact';
  }

  @override
  String get sys_unblocked_me => 'Vous avez débloqué ce contact';

  @override
  String sys_started(String channel) {
    return 'Conversation démarrée sur $channel';
  }

  @override
  String get msgaction_add_to_profile => 'Ajouter au profil client';

  @override
  String get msgaction_added_to_profile => 'Note ajoutée au profil client';

  @override
  String chat_new_messages(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouveaux messages',
      one: '1 nouveau message',
    );
    return '$_temp0';
  }

  @override
  String get chat_ai_reply_label => 'Réponse IA';

  @override
  String chat_note_label(String name) {
    return 'Note interne · $name';
  }

  @override
  String get chat_failed => 'Non envoyé';

  @override
  String get chat_retry => 'Réessayer';

  @override
  String get chat_delete => 'Supprimer';

  @override
  String get chat_edited => 'modifié';

  @override
  String get chat_deleted => 'Ce message a été supprimé';

  @override
  String get chat_unsupported =>
      'Message non pris en charge — ouvrir dans WhatsApp';

  @override
  String get chat_transcribe => 'Transcrire';

  @override
  String bubble_template_label(String name) {
    return 'Modèle : $name';
  }

  @override
  String get bubble_show_all => 'Afficher tout';

  @override
  String get bubble_show_less => 'Afficher moins';

  @override
  String get bubble_save_contact => 'Enregistrer';

  @override
  String get bubble_contact_saved => 'Contact enregistré';

  @override
  String get bubble_play => 'Lire le message vocal';

  @override
  String get bubble_pause => 'Mettre en pause le message vocal';

  @override
  String bubble_speed(String speed) {
    return 'Vitesse de lecture $speed';
  }

  @override
  String bubble_voice_summary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Message vocal, $n secondes',
      one: 'Message vocal, 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String bubble_image_from(String name) {
    return 'Photo de $name';
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
    return 'Vidéo $duration';
  }

  @override
  String get bubble_play_video => 'Lire la vidéo';

  @override
  String get bubble_video_unavailable =>
      'L\'aperçu vidéo n\'est pas disponible dans les données d\'exemple';

  @override
  String get bubble_download => 'Télécharger le fichier';

  @override
  String get bubble_downloaded => 'Fichier téléchargé';

  @override
  String get bubble_open_maps => 'Ouvrir la position dans les plans';

  @override
  String get bubble_transcribing => 'Transcription en cours…';

  @override
  String get bubble_transcript => 'Transcription';

  @override
  String get bubble_delivery_sending => 'Envoi en cours';

  @override
  String get bubble_delivery_sent => 'Envoyé';

  @override
  String get bubble_delivery_delivered => 'Distribué';

  @override
  String get bubble_delivery_read => 'Lu';

  @override
  String bubble_reply_to(String name) {
    return 'Répondre à $name';
  }

  @override
  String get bubble_viewer_share => 'Partager';

  @override
  String get bubble_viewer_save => 'Enregistrer';

  @override
  String get bubble_viewer_sample =>
      'Il s\'agit d\'une image d\'exemple qui ne peut être ni partagée ni enregistrée';

  @override
  String bubble_reactions(String emojis) {
    return 'Réactions : $emojis';
  }

  @override
  String get chatlist_jump_latest => 'Aller au dernier message';

  @override
  String get chatlist_loading_older => 'Chargement des messages plus anciens';

  @override
  String get chatlist_typing => 'en train d\'écrire…';

  @override
  String get msgaction_reply => 'Répondre';

  @override
  String get msgaction_copy => 'Copier';

  @override
  String get msgaction_copied => 'Message copié';

  @override
  String get msgaction_forward => 'Transférer';

  @override
  String get msgaction_forward_soon => 'Le transfert arrive bientôt';

  @override
  String get msgaction_save_kb => 'Enregistrer dans la base de connaissances';

  @override
  String get msgaction_info => 'Infos';

  @override
  String get msgaction_info_title => 'Informations sur le message';

  @override
  String get msgaction_info_sent => 'Envoyé à';

  @override
  String get msgaction_info_status => 'Statut';

  @override
  String get msgaction_info_channel => 'Canal';

  @override
  String get msgaction_info_via => 'Envoyé via';

  @override
  String get msgaction_via_manual => 'Saisi manuellement';

  @override
  String get msgaction_via_ai_suggestion => 'Suggestion de l\'IA';

  @override
  String get msgaction_via_ai_edited => 'Suggestion de l\'IA modifiée';

  @override
  String get msgaction_via_quick_reply => 'Réponse rapide';

  @override
  String get msgaction_via_template => 'Modèle approuvé';

  @override
  String get msgaction_delete_title => 'Supprimer le message ?';

  @override
  String get msgaction_delete_body =>
      'Le message sera supprimé pour tout le monde si le canal le permet. Cette action est irréversible.';

  @override
  String get msgaction_rate => 'Évaluer la réponse';

  @override
  String get msgaction_rate_up => 'Réponse utile';

  @override
  String get msgaction_rate_down => 'Réponse inutile';

  @override
  String get msgaction_rated => 'Merci — l\'IA apprendra de votre évaluation';

  @override
  String get msgaction_more_reactions => 'Plus de réactions';

  @override
  String get msgaction_pick_reaction => 'Choisir une réaction';

  @override
  String msgaction_react(String emoji) {
    return 'Réagir $emoji';
  }

  @override
  String get bubble_file_sending => 'Envoi en cours, réessayez dans un instant';

  @override
  String get bubble_file_unavailable =>
      'Ce fichier n’est pas disponible sur le téléphone';

  @override
  String bubble_saved(String name) {
    return 'Enregistré : $name';
  }

  @override
  String get bubble_save_failed =>
      'Impossible de télécharger le fichier. Réessayez.';

  @override
  String get bubble_open_file => 'Ouvrir';

  @override
  String get bubble_tap_retry => 'Touchez pour réessayer';

  @override
  String get bubble_photo_fetching => 'Récupération de la photo…';

  @override
  String get bubble_photo_unavailable => 'Photo indisponible';

  @override
  String get chatscreen_load_failed =>
      'Impossible de charger cette conversation';

  @override
  String get chatscreen_not_found =>
      'Nous n\'avons pas trouvé cette conversation';

  @override
  String get chatscreen_action_failed => 'Action impossible. Réessayez.';

  @override
  String chatscreen_taken_from_me(String name) {
    return 'La conversation a été attribuée à $name';
  }

  @override
  String chatscreen_claimed_by(String name) {
    return 'Prise en charge par $name';
  }

  @override
  String chatscreen_transfer_note(String name) {
    return '@$name Pourriez-vous me transférer cette conversation pour que je puisse m\'en occuper ?';
  }

  @override
  String chatscreen_transfer_sent(String name) {
    return 'Demande de transfert envoyée à $name';
  }

  @override
  String get chatscreen_takeover_title =>
      'Reprendre la conversation d\'un coéquipier ?';

  @override
  String chatscreen_takeover_body(String name) {
    return 'La conversation vous sera attribuée à la place de $name, qui en sera informé(e).';
  }

  @override
  String get chatscreen_takeover_confirm => 'Reprendre';

  @override
  String get chat_online => 'En ligne';

  @override
  String chat_last_seen(String time) {
    return 'Vu pour la dernière fois $time';
  }

  @override
  String get chat_typing => 'en train d\'écrire…';

  @override
  String get chat_assigned_you => 'Attribuée à vous';

  @override
  String chat_assigned_to(String name) {
    return 'Attribuée à $name';
  }

  @override
  String get chat_unassigned => 'Non attribuée';

  @override
  String get chat_ai_handling => 'Prise en charge par l\'IA';

  @override
  String get chat_resolve => 'Résoudre la conversation';

  @override
  String get chat_resolved_toast => 'Conversation résolue';

  @override
  String get chat_undo => 'Annuler';

  @override
  String chatbar_browsing(String page) {
    return 'Navigation : $page';
  }

  @override
  String chatbar_back_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Retour, $n autres conversations non lues',
      one: 'Retour, 1 autre conversation non lue',
    );
    return '$_temp0';
  }

  @override
  String chatbar_open_profile(String name) {
    return 'Ouvrir le profil de $name';
  }

  @override
  String get chatbar_call => 'Appeler';

  @override
  String get chatbar_more => 'Actions de la conversation';

  @override
  String get chatbar_call_phone => 'Appel téléphonique';

  @override
  String get chatbar_call_whatsapp => 'Appel WhatsApp';

  @override
  String get chatbar_call_failed =>
      'Impossible de démarrer un appel sur cet appareil';

  @override
  String strip_snoozed_until(String t) {
    return 'Mise en pause jusqu\'à $t';
  }

  @override
  String strip_order(String ref) {
    return 'Commande $ref';
  }

  @override
  String get strip_no_store_integration =>
      'Aucune intégration boutique pour le moment';

  @override
  String get strip_add_tag => 'Étiquette';

  @override
  String get snoozepick_subtitle =>
      'La conversation revient dans votre liste à cette heure';

  @override
  String get templates_title => 'Modèles approuvés';

  @override
  String get templates_subtitle => 'Modèles WhatsApp approuvés par Meta';

  @override
  String get templates_empty => 'Aucun modèle approuvé pour le moment';

  @override
  String get templates_sent => 'Modèle envoyé';

  @override
  String get actions_assign => 'Attribuer';

  @override
  String get actions_change_owner => 'Attribuer / changer de responsable';

  @override
  String get actions_unassign => 'Libérer la conversation';

  @override
  String get actions_unassigned_toast => 'Déplacée vers Non attribuées';

  @override
  String get actions_snooze => 'Mettre en pause';

  @override
  String get actions_snoozed_toast => 'Conversation mise en pause';

  @override
  String get actions_priority => 'Priorité';

  @override
  String get actions_tag => 'Ajouter une étiquette';

  @override
  String get actions_tag_subtitle =>
      'Choisissez des étiquettes ou créez-en une nouvelle';

  @override
  String get actions_tag_new_hint => 'Nouvelle étiquette';

  @override
  String get actions_tag_add => 'Ajouter une étiquette';

  @override
  String get actions_ai_pause =>
      'Mettre l\'IA en pause pour cette conversation';

  @override
  String get actions_ai_resume => 'Activer l\'IA pour cette conversation';

  @override
  String get actions_ai_paused_toast =>
      'IA mise en pause pour cette conversation';

  @override
  String get actions_ai_resumed_toast => 'IA activée pour cette conversation';

  @override
  String get actions_mark_unread => 'Marquer comme non lue';

  @override
  String get actions_export => 'Exporter la conversation';

  @override
  String get actions_export_note => 'Note interne';

  @override
  String get actions_exported_toast =>
      'Texte de la conversation copié — collez-le où vous voulez';

  @override
  String get actions_block => 'Bloquer le contact';

  @override
  String get actions_unblock => 'Débloquer le contact';

  @override
  String actions_block_title(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get actions_block_body =>
      'Vous ne recevrez plus de messages de ce contact et la conversation sera fermée. Vous pourrez le débloquer plus tard.';

  @override
  String get actions_blocked_toast => 'Contact bloqué';

  @override
  String get actions_unblocked_toast => 'Contact débloqué';

  @override
  String get close_title => 'Clôturer la conversation';

  @override
  String get close_subtitle =>
      'Un titre court aide votre équipe à la retrouver.';

  @override
  String get close_field_label => 'Titre';

  @override
  String get close_field_hint => 'ex. Question sur la livraison';

  @override
  String get close_ai_writing => 'Rédaction d’un titre par l’IA…';

  @override
  String get close_ai_suggest => 'Suggérer un titre';

  @override
  String get close_ai_again => 'Suggérer un autre titre';

  @override
  String get close_ai_unavailable =>
      'Impossible de suggérer un titre pour le moment. Vous pouvez en saisir un.';

  @override
  String get close_hint =>
      'Le client peut réécrire ; un nouveau message rouvre la conversation.';

  @override
  String get close_confirm => 'Clôturer la conversation';

  @override
  String get claim_button => 'Prendre en charge la conversation';

  @override
  String get claim_button_hint =>
      'Elle vous sera attribuée et vous pourrez répondre';

  @override
  String get claim_region => 'Prendre en charge la conversation';

  @override
  String get claim_assign_colleague => 'Attribuer à un collègue';

  @override
  String get claim_ai_takeover => 'Laisser l\'IA s\'en charger';

  @override
  String get claim_ai_takeover_done =>
      'La conversation a été transférée à l\'agent IA';

  @override
  String get claim_waiting => 'En attente de prise en charge';

  @override
  String claim_viewer_one_f(String name) {
    return '$name consulte cette conversation en ce moment';
  }

  @override
  String claim_viewer_one_m(String name) {
    return '$name consulte cette conversation en ce moment';
  }

  @override
  String claim_viewer_two(String a, String b) {
    return '$a et $b consultent cette conversation';
  }

  @override
  String claim_viewer_many(String a, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$a et $n autres personnes consultent cette conversation',
      one: '$a et 1 autre personne consultent cette conversation',
    );
    return '$_temp0';
  }

  @override
  String claim_viewing_since_sec(int n) {
    return 'il y a $n s';
  }

  @override
  String claim_viewing_since_min(String t) {
    return 'il y a $t';
  }

  @override
  String claim_wait_sec(int n) {
    return '$n s';
  }

  @override
  String claim_wait_min(int n) {
    return '$n min';
  }

  @override
  String claim_wait_hm(int h, int m) {
    return '$h h $m min';
  }

  @override
  String claim_a11y_wait_sec(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'En attente depuis $n secondes',
      one: 'En attente depuis 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_min(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'En attente depuis $n minutes',
      one: 'En attente depuis 1 minute',
    );
    return '$_temp0';
  }

  @override
  String claim_a11y_wait_hm(int h, int m) {
    return 'En attente depuis $h heures $m minutes';
  }

  @override
  String get claim_success_event => 'Vous avez pris en charge la conversation';

  @override
  String claim_conflict(String name) {
    return '$name l\'a prise en charge en premier';
  }

  @override
  String claim_taken_live(String name) {
    return '$name a pris en charge cette conversation';
  }

  @override
  String claim_assigned_to_you(String name) {
    return '$name vous l\'a attribuée';
  }

  @override
  String claim_resolved_live(String name) {
    return '$name a résolu la conversation';
  }

  @override
  String get claim_network_error =>
      'Impossible de prendre en charge. Vérifiez votre connexion et réessayez.';

  @override
  String get claim_retry => 'Réessayer';

  @override
  String get claim_forbidden =>
      'Vous n\'avez pas la permission de prendre en charge cette conversation';

  @override
  String claim_team_only(String team) {
    return 'Cette conversation appartient à $team';
  }

  @override
  String get claim_offline_hint =>
      'La prise en charge nécessite une connexion internet';

  @override
  String claim_capacity_hint(int n, int max) {
    return 'Vous avez $n conversations ouvertes (limite $max)';
  }

  @override
  String get claim_capacity_reached =>
      'Vous avez atteint votre limite de conversations';

  @override
  String get claim_away_title => 'Votre statut : Absent';

  @override
  String get claim_away_body =>
      'La prise en charge changera votre statut en Disponible.';

  @override
  String get claim_away_confirm => 'Prendre en charge et passer en Disponible';

  @override
  String claim_capacity_title(int n) {
    return 'Vous avez $n conversations ouvertes';
  }

  @override
  String get claim_capacity_body => 'En prendre en charge une de plus ?';

  @override
  String get claim_capacity_confirm => 'Prendre en charge quand même';

  @override
  String get claim_cancel => 'Annuler';

  @override
  String claim_assigned_toast(String name) {
    return 'Attribuée à $name';
  }

  @override
  String get claim_undo => 'Annuler';

  @override
  String get claim_reply_placeholder =>
      'Écrivez pour prendre en charge et répondre…';

  @override
  String get claim_short => 'Prendre en charge';

  @override
  String claim_handoff_event(String reason) {
    return 'L\'IA a transféré ceci à l\'équipe : $reason';
  }

  @override
  String get claim_reason_payment => 'Problème de paiement';

  @override
  String get claim_reason_human => 'A demandé un humain';

  @override
  String get claim_reason_complaint => 'Réclamation';

  @override
  String get claim_reason_no_answer => 'Question sans réponse';

  @override
  String get claim_reason_refund => 'Demande de remboursement';

  @override
  String get claim_reason_other => 'Autre';

  @override
  String get claim_push_title => 'Nouvelle conversation en attente';

  @override
  String get claim_push_action => 'Prendre en charge';

  @override
  String claim_push_success(String customer) {
    return 'Vous avez pris en charge la conversation avec $customer';
  }

  @override
  String get actions_add_note => 'Ajouter une note interne';

  @override
  String claim_a11y_wait_span(String t) {
    return 'En attente depuis $t';
  }

  @override
  String get conversations_segment_mine => 'Les miennes';

  @override
  String get conversations_segment_unassigned => 'Non attribuées';

  @override
  String get conversations_segment_all => 'Toutes';

  @override
  String get conversations_filter_all => 'Toutes';

  @override
  String get conversations_filter_unread => 'Non lues';

  @override
  String get conversations_filter_awaiting => 'En attente de réponse';

  @override
  String get conversations_filter_ai => 'Répondu par l\'IA';

  @override
  String get conversations_filter_closed => 'Fermées';

  @override
  String get conversations_filter_more => 'Filtres';

  @override
  String get conversations_channel_any => 'Tous les canaux';

  @override
  String get conversations_priority_any => 'Toutes les priorités';

  @override
  String get conversations_notifications => 'Notifications';

  @override
  String get conversations_new_message => 'Nouveau message';

  @override
  String get conversations_exit_selection => 'Quitter la sélection';

  @override
  String conversations_selected_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get conversations_bulk_assign => 'Attribuer la sélection';

  @override
  String get conversations_bulk_resolve => 'Résoudre la sélection';

  @override
  String conversations_bulk_resolved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations résolues',
      one: '1 conversation résolue',
    );
    return '$_temp0';
  }

  @override
  String get conversations_resolved_snack => 'Conversation résolue';

  @override
  String get conversations_empty_mine_title =>
      'Aucune conversation ne vous est attribuée';

  @override
  String get conversations_empty_mine_body =>
      'Prenez-en une en charge depuis Non attribuées pour commencer à répondre.';

  @override
  String get conversations_empty_mine_action => 'Afficher les non attribuées';

  @override
  String get conversations_empty_filters_title =>
      'Aucune conversation ne correspond aux filtres';

  @override
  String get conversations_empty_filters_body =>
      'Essayez de modifier ou de réinitialiser les filtres pour tout afficher.';

  @override
  String get conversations_empty_filters_action => 'Réinitialiser les filtres';

  @override
  String get conversations_empty_done_title => 'Vous êtes à jour';

  @override
  String get conversations_empty_done_body =>
      'Rien ne nécessite votre attention pour l\'instant. Nous vous préviendrons à l\'arrivée d\'un nouveau message.';

  @override
  String get tile_you_prefix => 'Vous : ';

  @override
  String get tile_ai_reply => 'Réponse IA';

  @override
  String get tile_ai_ready => 'Suggestion prête';

  @override
  String get tile_typing => 'En train d\'écrire…';

  @override
  String tile_snoozed_until(String time) {
    return 'Mise en pause jusqu\'à $time';
  }

  @override
  String tile_media_with_duration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String get tile_swipe_resolve => 'Résoudre';

  @override
  String get tile_swipe_snooze => 'Mettre en pause';

  @override
  String get tile_swipe_assign => 'Attribuer';

  @override
  String get filters_title => 'Filtres';

  @override
  String get filters_channel => 'Canal';

  @override
  String get filters_status => 'Statut';

  @override
  String get filters_priority => 'Priorité';

  @override
  String get filters_assignee => 'Attribué à';

  @override
  String get filters_assignee_all => 'Tout le monde';

  @override
  String get filters_assignee_me => 'Moi';

  @override
  String get filters_assignee_colleague => 'Un collègue';

  @override
  String get filters_assignee_ai => 'IA';

  @override
  String get filters_assignee_unassigned => 'Non attribuée';

  @override
  String get filters_date => 'Date';

  @override
  String get filters_date_any => 'N\'importe quand';

  @override
  String get filters_date_today => 'Aujourd\'hui';

  @override
  String get filters_date_7 => '7 jours';

  @override
  String get filters_date_30 => '30 jours';

  @override
  String get filters_date_custom => 'Personnalisé';

  @override
  String get filters_tags => 'Étiquettes';

  @override
  String filters_show(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count conversations',
      one: 'Afficher 1 conversation',
      zero: 'Aucune conversation',
    );
    return '$_temp0';
  }

  @override
  String get newmsg_title => 'Nouveau message';

  @override
  String get newmsg_subtitle =>
      'Démarrez une conversation WhatsApp avec un modèle approuvé';

  @override
  String get newmsg_name => 'Nom du client';

  @override
  String get newmsg_name_hint => 'Facultatif';

  @override
  String get newmsg_phone => 'Numéro de mobile';

  @override
  String get newmsg_phone_hint => '+966 5x xxx xxxx';

  @override
  String get newmsg_phone_error =>
      'Entrez un numéro de mobile valide avec l\'indicatif du pays';

  @override
  String get newmsg_template => 'Modèle';

  @override
  String get newmsg_template_error => 'Choisissez un modèle approuvé à envoyer';

  @override
  String get newmsg_send => 'Envoyer le modèle';

  @override
  String get app_name => 'Wavadesk';

  @override
  String get tab_conversations => 'Conversations';

  @override
  String get tab_dashboard => 'Tableau de bord';

  @override
  String get tab_knowledge => 'Connaissances';

  @override
  String get tab_account => 'Compte';

  @override
  String get channel_whatsapp => 'WhatsApp';

  @override
  String get channel_web => 'Chat du site';

  @override
  String get channel_messenger => 'Messenger';

  @override
  String get channel_instagram => 'Instagram';

  @override
  String get channel_email => 'E-mail';

  @override
  String get channel_telegram => 'Telegram';

  @override
  String get channel_sms => 'SMS';

  @override
  String get channel_other => 'Autre canal';

  @override
  String get status_open => 'Ouverte';

  @override
  String get status_pending => 'En attente du client';

  @override
  String get status_waiting => 'En attente de réponse';

  @override
  String get status_snoozed => 'Reportée';

  @override
  String get status_resolved => 'Résolue';

  @override
  String get status_closed => 'Fermée';

  @override
  String get status_ai => 'Prise en charge par l\'IA';

  @override
  String get priority_urgent => 'Urgente';

  @override
  String get priority_high => 'Élevée';

  @override
  String get priority_medium => 'Moyenne';

  @override
  String get priority_low => 'Faible';

  @override
  String get presence_online => 'Disponible';

  @override
  String get presence_busy => 'Occupé';

  @override
  String get presence_away => 'Absent';

  @override
  String get role_admin => 'Administrateur';

  @override
  String get role_supervisor => 'Superviseur';

  @override
  String get role_agent => 'Agent du support';

  @override
  String get ownership_mine => 'Attribuée à vous';

  @override
  String get ownership_unassigned => 'Non attribuée';

  @override
  String ownership_colleague(String name) {
    return 'Attribuée à $name';
  }

  @override
  String get ownership_ai => 'Prise en charge par l\'IA';

  @override
  String get media_image => 'Photo';

  @override
  String get media_voice => 'Message vocal';

  @override
  String get media_file => 'Fichier';

  @override
  String get media_location => 'Position';

  @override
  String get media_album => 'Album photo';

  @override
  String get media_video => 'Vidéo';

  @override
  String get media_contact => 'Contact';

  @override
  String get media_sticker => 'Autocollant';

  @override
  String get media_template => 'Modèle';

  @override
  String get media_email => 'E-mail';

  @override
  String get media_deleted => 'Message supprimé';

  @override
  String get media_unsupported => 'Message non pris en charge';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_undo => 'Annuler';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_back => 'Retour';

  @override
  String get common_clear => 'Effacer';

  @override
  String get common_done => 'Terminé';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_clear_search => 'Effacer la recherche';

  @override
  String get common_more => 'Plus';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_confirm => 'Confirmer';

  @override
  String get common_you => 'Vous';

  @override
  String get common_loading => 'Chargement…';

  @override
  String get common_selected => 'Sélectionné';

  @override
  String get time_now => 'Maintenant';

  @override
  String get time_today => 'Aujourd\'hui';

  @override
  String get time_yesterday => 'Hier';

  @override
  String time_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String time_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String time_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String duration_minutes_short(int count) {
    return '$count min';
  }

  @override
  String duration_hours_short(int count) {
    return '$count h';
  }

  @override
  String duration_days_short(int count) {
    return '$count j';
  }

  @override
  String waiting_for(String duration) {
    return 'En attente depuis $duration';
  }

  @override
  String get network_connecting => 'Connexion en cours…';

  @override
  String get network_offline => 'Hors ligne';

  @override
  String get empty_offline_title => 'Vous êtes hors ligne';

  @override
  String get empty_offline_body =>
      'Vérifiez votre connexion et réessayez. Vos messages seront envoyés dès que vous serez de nouveau en ligne.';

  @override
  String a11y_unread_messages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non lus',
      one: '1 message non lu',
      zero: 'Aucun message non lu',
    );
    return '$_temp0';
  }

  @override
  String get a11y_notifications_unread => 'Notifications, nouveaux éléments';

  @override
  String get a11y_ai_avatar => 'IA';

  @override
  String get a11y_team_avatar => 'Équipe';

  @override
  String get a11y_selected => 'Sélectionné';

  @override
  String a11y_priority(String label) {
    return 'Priorité : $label';
  }

  @override
  String get time_unit_day => 'j';

  @override
  String get time_unit_hour => 'h';

  @override
  String get time_unit_min => 'min';

  @override
  String get common_increase => 'Augmenter';

  @override
  String get common_decrease => 'Diminuer';

  @override
  String get dash_title => 'Tableau de bord';

  @override
  String dash_morning(String name) {
    return 'Bonjour, $name';
  }

  @override
  String dash_evening(String name) {
    return 'Bonsoir, $name';
  }

  @override
  String get dash_presence_online_m => 'Disponible';

  @override
  String get dash_presence_online_f => 'Disponible';

  @override
  String get dash_presence_busy_m => 'Occupé';

  @override
  String get dash_presence_busy_f => 'Occupée';

  @override
  String get dash_presence_away => 'Absent';

  @override
  String get dash_presence_title => 'Votre statut';

  @override
  String get dash_presence_until => 'Jusqu\'à…';

  @override
  String get dash_presence_30m => '30 minutes';

  @override
  String get dash_presence_1h => '1 heure';

  @override
  String get dash_presence_eod => 'Fin de journée';

  @override
  String get dash_presence_auto =>
      'Vous passerez en « Absent » après 15 min d\'inactivité';

  @override
  String dash_presence_until_time(String time) {
    return 'Jusqu\'à $time';
  }

  @override
  String get dash_presence_failed => 'Impossible de modifier votre statut';

  @override
  String get dash_scope_me => 'Moi';

  @override
  String get dash_scope_team => 'Mon équipe';

  @override
  String get dash_scope_all => 'Tout le monde';

  @override
  String get dash_team_picker => 'Choisir une équipe';

  @override
  String get dash_range_today => 'Aujourd\'hui';

  @override
  String get dash_range_yesterday => 'Hier';

  @override
  String get dash_range_7d => '7 derniers jours';

  @override
  String get dash_range_30d => '30 derniers jours';

  @override
  String get dash_range_title => 'Période';

  @override
  String get dash_open => 'Conversations ouvertes';

  @override
  String get dash_awaiting_me => 'En attente de votre réponse';

  @override
  String get dash_awaiting_team => 'En attente de réponse';

  @override
  String dash_oldest(String m) {
    return 'La plus ancienne $m';
  }

  @override
  String get dash_none_waiting => 'Personne en attente';

  @override
  String get dash_first_response => '1ère réponse moy.';

  @override
  String get dash_minute => 'min';

  @override
  String get dash_ai_reply => 'Répondu par l\'IA';

  @override
  String get dash_of_questions => 'des questions';

  @override
  String get dash_resolved => 'Résolues';

  @override
  String get dash_volume_today => 'Conversations aujourd\'hui';

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
    return '$hour : $n · $ai par l\'IA';
  }

  @override
  String get dash_legend_all => 'Toutes';

  @override
  String get dash_legend_ai => 'IA';

  @override
  String get dash_no_volume =>
      'Aucune conversation aujourd\'hui pour l\'instant';

  @override
  String get dash_no_volume_range => 'Aucune conversation sur cette période';

  @override
  String get dash_team_now => 'L\'équipe en ce moment';

  @override
  String get dash_see_all => 'Voir tout';

  @override
  String get dash_ai_name => 'IA';

  @override
  String dash_agent_open(String n) {
    return '$n ouvertes';
  }

  @override
  String dash_agent_frt(String t) {
    return '1ère réponse moy. aujourd\'hui $t';
  }

  @override
  String get dash_agent_view => 'Voir ses conversations';

  @override
  String get dash_redistribute => 'Redistribuer';

  @override
  String get dash_redistribute_none =>
      'Aucune conversation ouverte à redistribuer';

  @override
  String get dash_solo => 'Vous êtes seul dans l\'équipe';

  @override
  String get dash_invite => 'Inviter un collègue';

  @override
  String dash_ai_impact(String n) {
    return '$n questions répondues par l\'IA';
  }

  @override
  String dash_ai_saved(String h) {
    return 'Environ $h heures de temps d\'équipe économisées';
  }

  @override
  String dash_ai_handoffs(String n) {
    return '$n transferts';
  }

  @override
  String dash_ai_rating(String p) {
    return '$p % positif';
  }

  @override
  String dash_ai_handling(String n) {
    return 'L\'IA gère actuellement $n';
  }

  @override
  String get dash_by_channel => 'Par canal';

  @override
  String get dash_web_reports => 'Rapports détaillés sur le web';

  @override
  String dash_last_updated(String t) {
    return 'Dernière mise à jour $t';
  }

  @override
  String get dash_load_error => 'Impossible de charger le tableau de bord';

  @override
  String get dash_card_error => 'Impossible de charger';

  @override
  String get dash_retry => 'Réessayer';

  @override
  String get dash_frt_title => 'Vitesse de première réponse';

  @override
  String dash_frt_target(String m) {
    return 'Objectif : $m min';
  }

  @override
  String get dash_frt_lt1 => 'Moins de 1 min';

  @override
  String get dash_frt_1_5 => '1 à 5 min';

  @override
  String get dash_frt_5_15 => '5 à 15 min';

  @override
  String get dash_frt_gt15 => 'Plus de 15 min';

  @override
  String get dash_frt_note =>
      'Basé sur les conversations répondues par un agent';

  @override
  String get dash_frt_empty =>
      'Aucune réponse pour l\'instant sur cette période';

  @override
  String get dash_days_short => 'j';

  @override
  String get dash_hours_short => 'h';

  @override
  String get dash_minutes_short => 'min';

  @override
  String get dash_thousand => 'k';

  @override
  String get dash_onb_title => 'Commencez à recevoir des conversations';

  @override
  String get dash_onb_wa => 'Connecter WhatsApp';

  @override
  String get dash_onb_kb => 'Ajouter une base de connaissances';

  @override
  String get dash_onb_ai => 'Activer l\'IA';

  @override
  String get dash_onb_cta => 'Terminer la configuration';

  @override
  String get dash_alert_wa_title => 'WhatsApp est déconnecté';

  @override
  String get dash_alert_wa_body =>
      'Les messages n\'arriveront pas tant que vous ne vous reconnectez pas';

  @override
  String get dash_alert_wa_action => 'Se reconnecter';

  @override
  String dash_alert_sla_title(String n, String sla) {
    return '$n clients en attente depuis plus de $sla min';
  }

  @override
  String get dash_alert_sla_action => 'Répondre maintenant';

  @override
  String dash_alert_unassigned_title(String n) {
    return '$n conversations en attente d\'être prises en charge';
  }

  @override
  String get dash_alert_view => 'Voir';

  @override
  String dash_alert_kb_title(String n) {
    return '$n questions sans réponse';
  }

  @override
  String get dash_alert_kb_body =>
      'Ajoutez-les pour que l\'IA réponde automatiquement';

  @override
  String get dash_alert_kb_action => 'Examiner';

  @override
  String dash_alert_trial_title(String n) {
    return 'Votre essai se termine dans $n jours';
  }

  @override
  String get dash_alert_trial_action => 'Voir les formules';

  @override
  String get dash_alert_dismiss => 'Ignorer';

  @override
  String dash_a11y_metric(String label, String value, String aside) {
    return '$label : $value $aside. Appuyez pour voir les conversations';
  }

  @override
  String dash_a11y_chart(String title, String total, String peak, String n) {
    return '$title : $total. Pic de $peak avec $n conversations.';
  }

  @override
  String dash_a11y_team(String name, String presence, String n) {
    return '$name, $presence, $n conversations ouvertes';
  }

  @override
  String dash_a11y_presence(String status) {
    return 'Votre statut : $status. Appuyez pour changer';
  }

  @override
  String get inbox_title => 'Conversations';

  @override
  String get inbox_seg_mine => 'Les miennes';

  @override
  String get inbox_seg_unassigned => 'Non attribuées';

  @override
  String get inbox_seg_all => 'Toutes';

  @override
  String get inbox_chip_all => 'Toutes';

  @override
  String get inbox_chip_unread => 'Non lues';

  @override
  String get inbox_chip_awaiting => 'En attente de réponse';

  @override
  String get inbox_chip_ai => 'Réponse de l\'IA';

  @override
  String get inbox_chip_snoozed => 'En pause';

  @override
  String get inbox_chip_closed => 'Fermées';

  @override
  String get inbox_chip_filters => 'Filtres';

  @override
  String get inbox_needs_reply => 'Nécessite votre réponse';

  @override
  String get inbox_rest => 'Autres conversations';

  @override
  String get inbox_see_all => 'Tout voir';

  @override
  String get inbox_show_less => 'Afficher moins';

  @override
  String get inbox_you_prefix => 'Vous :';

  @override
  String get inbox_draft_prefix => 'Brouillon :';

  @override
  String get inbox_note_prefix => 'Note :';

  @override
  String get inbox_typing => 'en train d\'écrire…';

  @override
  String get inbox_image => 'Photo';

  @override
  String inbox_voice(String d) {
    return 'Message vocal · $d';
  }

  @override
  String get inbox_location => 'Position';

  @override
  String get inbox_sticker => 'Autocollant';

  @override
  String get inbox_deleted => 'Ce message a été supprimé';

  @override
  String inbox_tag_waiting(String t) {
    return 'En attente depuis $t';
  }

  @override
  String get inbox_tag_ai_ready => 'Suggestion prête';

  @override
  String get inbox_tag_ai_replied => 'Réponse de l\'IA';

  @override
  String inbox_tag_snoozed(String t) {
    return 'En pause jusqu\'à $t';
  }

  @override
  String inbox_tag_window(int h) {
    return 'Fenêtre fermée dans $h h';
  }

  @override
  String get inbox_now => 'maintenant';

  @override
  String inbox_min(int n) {
    return '$n min';
  }

  @override
  String inbox_hour(int n) {
    return '$n h';
  }

  @override
  String get inbox_yesterday => 'Hier';

  @override
  String get inbox_am => 'AM';

  @override
  String get inbox_pm => 'PM';

  @override
  String get inbox_swipe_resolve => 'Résoudre';

  @override
  String get inbox_swipe_snooze => 'Mettre en pause';

  @override
  String get inbox_swipe_assign => 'Attribuer';

  @override
  String get inbox_swipe_claim => 'Prendre en charge';

  @override
  String get inbox_resolved => 'Conversation résolue';

  @override
  String inbox_resolved_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations résolues',
      one: '1 conversation résolue',
    );
    return '$_temp0';
  }

  @override
  String get inbox_snoozed_1h => 'Mise en pause pour 1 heure';

  @override
  String inbox_snoozed_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations mises en pause',
      one: 'Conversation mise en pause',
    );
    return '$_temp0';
  }

  @override
  String get inbox_undo => 'Annuler';

  @override
  String inbox_assigned_to_you(String name) {
    return '$name vous a attribué une conversation';
  }

  @override
  String get inbox_open => 'Ouvrir';

  @override
  String inbox_claimed_by(String name) {
    return 'Prise en charge par $name';
  }

  @override
  String inbox_new_pill(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouvelles conversations',
      one: '1 nouvelle conversation',
    );
    return '$_temp0';
  }

  @override
  String inbox_selected(int n) {
    return '$n sélectionnée(s)';
  }

  @override
  String get inbox_select_all => 'Tout sélectionner';

  @override
  String get inbox_exit_selection => 'Quitter la sélection';

  @override
  String get inbox_mark_read => 'Marquer comme lue';

  @override
  String get inbox_mark_unread => 'Marquer comme non lue';

  @override
  String inbox_marked_read_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations marquées comme lues',
      one: '1 conversation marquée comme lue',
    );
    return '$_temp0';
  }

  @override
  String inbox_marked_unread_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations marquées comme non lues',
      one: '1 conversation marquée comme non lue',
    );
    return '$_temp0';
  }

  @override
  String get inbox_new_conversation => 'Nouvelle conversation';

  @override
  String get inbox_load_error => 'Chargement impossible · Réessayer';

  @override
  String get inbox_end => 'Plus aucune conversation';

  @override
  String get inbox_exit_hint => 'Appuyez à nouveau pour quitter';

  @override
  String get inbox_offline_cached =>
      'Hors ligne — affichage de la dernière copie enregistrée';

  @override
  String get inbox_action_failed => 'Action impossible. Réessayez.';

  @override
  String get inbox_tag => 'Étiquette';

  @override
  String inbox_tag_added(String tag) {
    return 'Étiquette « $tag » ajoutée';
  }

  @override
  String get inbox_priority => 'Priorité';

  @override
  String inbox_priority_set(String label) {
    return 'Priorité définie sur $label';
  }

  @override
  String get inbox_archive => 'Archiver';

  @override
  String inbox_archived_n(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations archivées',
      one: 'Conversation archivée',
    );
    return '$_temp0';
  }

  @override
  String get inbox_clear_all => 'Tout effacer';

  @override
  String inbox_a11y_unread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages non lus',
      one: '1 message non lu',
    );
    return '$_temp0';
  }

  @override
  String get inbox_a11y_open_hint =>
      'Appuyez deux fois pour ouvrir la conversation';

  @override
  String inbox_a11y_notifications(int n) {
    return 'Notifications, $n non lue(s)';
  }

  @override
  String get inbox_empty_mine_title =>
      'Aucune conversation ne vous est attribuée';

  @override
  String get inbox_empty_mine_body =>
      'Les conversations que vous prenez en charge ou qui vous sont attribuées apparaîtront ici.';

  @override
  String get inbox_empty_mine_action => 'Voir les non attribuées';

  @override
  String get inbox_empty_done_title => 'Vous êtes à jour';

  @override
  String get inbox_empty_done_body =>
      'Personne n\'attend votre réponse pour le moment.';

  @override
  String get inbox_empty_unassigned_title =>
      'Aucune conversation en attente de prise en charge';

  @override
  String get inbox_empty_unassigned_body =>
      'L\'IA et votre équipe gèrent tout.';

  @override
  String get inbox_empty_new_title => 'Aucune conversation pour l\'instant';

  @override
  String get inbox_empty_new_body =>
      'Connectez WhatsApp pour commencer à recevoir les messages de vos clients.';

  @override
  String get inbox_empty_new_action => 'Connecter WhatsApp';

  @override
  String get inbox_empty_filters_title =>
      'Aucune conversation ne correspond à ces filtres';

  @override
  String get inbox_empty_filters_action => 'Effacer les filtres';

  @override
  String get inbox_empty_error_title =>
      'Impossible de charger les conversations';

  @override
  String get inbox_empty_error_body => 'Vérifiez votre connexion et réessayez.';

  @override
  String get inbox_filters_title => 'Filtres';

  @override
  String get inbox_filters_clear => 'Effacer';

  @override
  String get inbox_filters_apply => 'Afficher les conversations';

  @override
  String inbox_filters_show(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Afficher $n conversations',
      one: 'Afficher 1 conversation',
      zero: 'Aucune conversation',
    );
    return '$_temp0';
  }

  @override
  String get inbox_filters_channel => 'Canal';

  @override
  String get inbox_filters_priority => 'Priorité';

  @override
  String get inbox_filters_assignee => 'Attribué à';

  @override
  String get inbox_filters_assignee_all => 'Tous';

  @override
  String get inbox_filters_assignee_me => 'Moi';

  @override
  String get inbox_filters_assignee_colleague => 'Coéquipier spécifique ▸';

  @override
  String get inbox_filters_assignee_ai => 'IA';

  @override
  String get inbox_filters_assignee_unassigned => 'Non attribué';

  @override
  String get inbox_filters_pick_colleague => 'Choisir un coéquipier';

  @override
  String get inbox_filters_team => 'Équipe';

  @override
  String get inbox_filters_tags => 'Étiquettes';

  @override
  String get inbox_filters_tags_search => 'Rechercher des étiquettes';

  @override
  String get inbox_filters_date => 'Date';

  @override
  String get inbox_filters_date_today => 'Aujourd\'hui';

  @override
  String get inbox_filters_date_7d => '7 jours';

  @override
  String get inbox_filters_date_30d => '30 jours';

  @override
  String get inbox_filters_date_custom => 'Personnalisé ▸';

  @override
  String get inbox_filters_sort => 'Trier';

  @override
  String get inbox_filters_sort_smart => 'Intelligent (par défaut)';

  @override
  String get inbox_filters_sort_newest => 'Plus récentes';

  @override
  String get inbox_filters_sort_oldest => 'Plus anciennes';

  @override
  String get inbox_filters_sort_waiting =>
      'En attente depuis le plus longtemps';

  @override
  String get kbe_new => 'Nouvelle question';

  @override
  String get kbe_edit => 'Modifier la réponse';

  @override
  String get kbe_review => 'Vérifier la suggestion';

  @override
  String get kbe_save => 'Enregistrer';

  @override
  String get kbe_send => 'Envoyer';

  @override
  String kbe_src_unanswered(String n) {
    return 'Posée $n fois sans réponse de l\'IA';
  }

  @override
  String kbe_src_chat(String c, String d) {
    return 'Depuis une conversation avec $c · $d';
  }

  @override
  String kbe_src_draft(String name, String t) {
    return 'Suggérée par $name · $t';
  }

  @override
  String get kbe_src_draft_conv =>
      'Suggérée à partir d\'une conversation résolue';

  @override
  String get kbe_view_convs => 'Voir les conversations';

  @override
  String get kbe_open => 'Ouvrir';

  @override
  String get kbe_open_it => 'Ouvrir';

  @override
  String get kbe_question => 'Question';

  @override
  String get kbe_question_ph =>
      'ex. Puis-je retourner un article après 30 jours ?';

  @override
  String get kbe_alts => 'Autres façons dont les clients demandent';

  @override
  String get kbe_optional => '(facultatif)';

  @override
  String get kbe_add_alt => '+ Ajouter une formulation';

  @override
  String get kbe_alt_exists => 'Cette formulation existe déjà';

  @override
  String get kbe_alt_limit =>
      'Jusqu\'à 15 formulations, 120 caractères chacune';

  @override
  String get kbe_answer => 'Réponse';

  @override
  String get kbe_answer_ph =>
      'Écrivez la réponse telle que l\'IA doit la dire…';

  @override
  String kbe_counter(String n) {
    return '$n/2000';
  }

  @override
  String get kbe_ai_draft_tag =>
      'Brouillon de l\'IA — à vérifier avant d\'enregistrer';

  @override
  String get kbe_tag => 'Étiquette';

  @override
  String get kbe_tags_title => 'Étiquettes de la réponse';

  @override
  String get kbe_tags_search => 'Rechercher ou créer une étiquette';

  @override
  String kbe_tags_create(String name) {
    return 'Créer « $name »';
  }

  @override
  String get kbe_tags_primary => 'Étiquette principale';

  @override
  String get kbe_done => 'Terminé';

  @override
  String get kbe_improve => 'Améliorer la formulation';

  @override
  String get kbe_add_link => 'Ajouter un lien';

  @override
  String get kbe_link_url => 'URL';

  @override
  String get kbe_link_label => 'Titre du lien (facultatif)';

  @override
  String get kbe_link_invalid => 'Saisissez un lien https:// valide';

  @override
  String get kbe_insert => 'Insérer';

  @override
  String get kbe_cancel => 'Annuler';

  @override
  String kbe_similar(String t) {
    return 'Une question similaire existe : « $t »';
  }

  @override
  String get kbe_merge_alt => 'Fusionner comme formulation';

  @override
  String kbe_conflict(String t, String r) {
    return 'Peut entrer en conflit avec « $t » : $r';
  }

  @override
  String get kbe_view => 'Voir';

  @override
  String get kbe_preview => 'Aperçu : comment l\'IA répondra';

  @override
  String get kbe_ai_label => 'IA';

  @override
  String get kbe_writing => 'Rédaction en cours…';

  @override
  String kbe_tone(String tone) {
    return 'Ton : $tone';
  }

  @override
  String get kbe_conf_high => 'Confiance élevée';

  @override
  String get kbe_conf_med => 'Confiance moyenne';

  @override
  String get kbe_conf_low => 'Confiance faible';

  @override
  String get kbe_low_hint =>
      'Ajoutez des formulations ou précisez pour augmenter la confiance';

  @override
  String get kbe_try_another => 'Essayer une autre question';

  @override
  String get kbe_test_hint => 'Saisissez une question pour tester';

  @override
  String get kbe_preview_err => 'Échec de l\'aperçu';

  @override
  String get kbe_preview_offline => 'L\'aperçu nécessite une connexion';

  @override
  String get kbe_preview_empty =>
      'Complétez la question et la réponse pour voir un aperçu';

  @override
  String get kbe_preview_regen => 'Actualiser l\'aperçu';

  @override
  String get kbe_advanced => 'Options avancées';

  @override
  String get kbe_enabled => 'Disponible pour l\'IA';

  @override
  String get kbe_channels => 'Canaux';

  @override
  String get kbe_channels_all => 'Tous les canaux';

  @override
  String get kbe_expires => 'Valable jusqu\'au';

  @override
  String get kbe_expires_none => 'Pas de date de fin';

  @override
  String get kbe_expires_clear => 'Supprimer la date';

  @override
  String get kbe_verbatim => 'Envoyer mot pour mot';

  @override
  String get kbe_verbatim_sub => 'L\'IA envoie exactement ce texte';

  @override
  String get kbe_handoff_after => 'Transférer après la réponse';

  @override
  String get kbe_internal_notes => 'Notes internes';

  @override
  String get kbe_internal_notes_ph => 'Non utilisées par l\'IA';

  @override
  String kbe_meta(String n, String t, String u) {
    return 'Modifiée par $n · $t · utilisée $u fois';
  }

  @override
  String get kbe_delete => 'Supprimer la réponse';

  @override
  String kbe_delete_title(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get kbe_delete_body => 'L\'IA ne l\'utilisera plus.';

  @override
  String get kbe_deleted => 'Supprimée';

  @override
  String get kbe_history => 'Historique des versions';

  @override
  String get kbe_restore => 'Restaurer cette version';

  @override
  String kbe_version_n(String n) {
    return 'Version $n';
  }

  @override
  String get kbe_version_current => 'Actuelle';

  @override
  String get kbe_versions_empty => 'Aucune version antérieure';

  @override
  String get kbe_restored => 'Version restaurée';

  @override
  String get kbe_restore_failed => 'Impossible de restaurer';

  @override
  String get kbe_err_q => 'Saisissez la question (5 caractères minimum)';

  @override
  String get kbe_err_a => 'Saisissez la réponse (10 caractères minimum)';

  @override
  String get kbe_err_a_long => 'La réponse dépasse 2000 caractères';

  @override
  String get kbe_err_date => 'Choisissez une date future';

  @override
  String get kbe_saved_new =>
      'Réponse ajoutée · l\'IA l\'utilisera dès maintenant';

  @override
  String get kbe_saved_edit => 'Modifications enregistrées';

  @override
  String kbe_saved_unanswered(String n) {
    return 'Ajoutée · $n conversations l\'attendaient';
  }

  @override
  String get kbe_saved_chat => 'Ajoutée à la base de connaissances';

  @override
  String get kbe_proposed => 'Envoyée pour vérification';

  @override
  String get kbe_approve => 'Approuver et publier';

  @override
  String get kbe_approved => 'Réponse approuvée et publiée';

  @override
  String get kbe_reject => 'Rejeter';

  @override
  String get kbe_rejected => 'Suggestion rejetée';

  @override
  String get kbe_save_err => 'Impossible d\'enregistrer';

  @override
  String get kbe_save_forbidden =>
      'Vous ne pouvez pas enregistrer — envoyez-la pour vérification';

  @override
  String get kbe_save_offline => 'L\'enregistrement nécessite une connexion';

  @override
  String get kbe_retry => 'Réessayer';

  @override
  String get kbe_load_error => 'Impossible de charger la réponse';

  @override
  String kbe_conflict_title(String name) {
    return '$name vient de modifier cette réponse';
  }

  @override
  String get kbe_view_theirs => 'Voir la sienne';

  @override
  String get kbe_overwrite => 'Enregistrer la mienne à la place';

  @override
  String get kbe_restore_draft => 'Brouillon non enregistré — le restaurer ?';

  @override
  String get kbe_restore_btn => 'Restaurer';

  @override
  String get kbe_restore_ignore => 'Ignorer';

  @override
  String get kbe_discard_title => 'Abandonner les modifications ?';

  @override
  String get kbe_discard_body => 'La réponse ne sera pas enregistrée.';

  @override
  String get kbe_discard => 'Abandonner';

  @override
  String get kbe_keep => 'Continuer la modification';

  @override
  String get kbe_deleted_elsewhere => 'Cette réponse a été supprimée';

  @override
  String get kbe_close => 'Fermer';

  @override
  String kbe_a11y_alt(String text) {
    return 'Formulation : $text, double-tapez pour modifier';
  }

  @override
  String get kbe_a11y_alt_delete => 'Supprimer';

  @override
  String kbe_a11y_ghost(String text) {
    return 'Formulation suggérée par l\'IA : $text, appuyez pour ajouter';
  }

  @override
  String get kbe_a11y_save_disabled => 'Complétez la question et la réponse';

  @override
  String get kbe_a11y_dismiss => 'Ignorer l\'avertissement';

  @override
  String get kbe_media => 'Pièces jointes';

  @override
  String get kbe_media_hint => 'L\'IA les envoie avec la réponse';

  @override
  String get kbe_media_add => 'Ajouter une image ou une note vocale';

  @override
  String get kbe_media_image => 'Image';

  @override
  String get kbe_media_voice => 'Note vocale';

  @override
  String get kbe_media_with_text => 'Avec le texte';

  @override
  String get kbe_media_file_only => 'Fichier seul';

  @override
  String get kbe_media_remove => 'Retirer';

  @override
  String kbe_media_uploading(int p) {
    return 'Envoi $p %';
  }

  @override
  String get kbe_media_failed => 'Échec de l\'envoi';

  @override
  String get kbe_media_queued => 'Envoi après l\'enregistrement';

  @override
  String get kbe_media_too_big => 'Fichier de plus de 16 Mo';

  @override
  String get kbe_media_image_too_big => 'Image de plus de 5 Mo';

  @override
  String get kbe_media_type_err => 'Choisissez une image ou un fichier audio';

  @override
  String get kbe_media_upgrade =>
      'Les images et notes vocales sont réservées aux forfaits payants';

  @override
  String get kbe_media_upgrade_cta => 'Voir les forfaits';

  @override
  String kbe_media_some_failed(int n) {
    return 'Enregistrée, mais $n pièces jointes n\'ont pas pu être envoyées';
  }

  @override
  String get kbe_media_send_mode => 'Comment elle est envoyée';

  @override
  String get kb_title => 'Base de connaissances';

  @override
  String kb_search(int n) {
    return 'Rechercher parmi $n entrées';
  }

  @override
  String get kb_qa => 'Q&R';

  @override
  String get kb_files => 'Fichiers';

  @override
  String get kb_links => 'Liens';

  @override
  String get kb_processing => 'Traitement';

  @override
  String kb_unanswered_title(int n) {
    return '$n questions sans réponse';
  }

  @override
  String get kb_unanswered_body =>
      'Des clients ont posé une question sans que l\'IA ait de réponse';

  @override
  String get kb_review => 'Vérifier';

  @override
  String get kb_sort_usage => 'Les plus utilisées';

  @override
  String get kb_sort_recent => 'Mises à jour récemment';

  @override
  String get kb_sort_stale => 'Mises à jour il y a longtemps';

  @override
  String get kb_sort_alpha => 'Alphabétique';

  @override
  String get kb_sort_least => 'Les moins utilisées';

  @override
  String get kb_tags => 'Étiquettes';

  @override
  String kb_used_n(int n) {
    return 'Utilisée $n fois';
  }

  @override
  String kb_updated(String t) {
    return 'Mise à jour il y a $t';
  }

  @override
  String kb_pages(int n) {
    return '$n pages';
  }

  @override
  String get kb_badge_draft => 'Brouillon';

  @override
  String get kb_badge_disabled => 'Désactivée';

  @override
  String get kb_badge_stale => 'Obsolète';

  @override
  String get kb_badge_failed => 'Échec du traitement';

  @override
  String get kb_disable => 'Désactiver pour l\'IA';

  @override
  String get kb_enable => 'Activer';

  @override
  String get kb_edit => 'Modifier';

  @override
  String get kb_copy_answer => 'Copier la réponse';

  @override
  String get kb_delete => 'Supprimer';

  @override
  String kb_delete_title(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get kb_delete_body => 'L\'IA ne l\'utilisera plus.';

  @override
  String get kb_deleted => 'Supprimée';

  @override
  String kb_drafts(int n) {
    return 'Suggestions à vérifier · $n';
  }

  @override
  String kb_draft_by(String name, String t) {
    return 'Suggérée par $name · $t';
  }

  @override
  String get kb_draft_from_conv =>
      'Suggérée à partir d\'une conversation résolue';

  @override
  String get kb_approve => 'Approuver';

  @override
  String get kb_reject => 'Rejeter';

  @override
  String get kb_add_title => 'Ajouter à la base de connaissances';

  @override
  String get kb_add_qa_sub => 'Le plus rapide et le plus précis pour l\'IA';

  @override
  String get kb_add_file => 'Importer un fichier';

  @override
  String get kb_add_file_sub =>
      'Plusieurs questions-réponses d’un coup depuis un fichier JSON (format du panneau web)';

  @override
  String get kb_add_link => 'Ajouter un lien';

  @override
  String get kb_add_link_sub => 'Une page de votre site, lue par l\'IA';

  @override
  String get kb_alt_phrasings => 'Autres formulations';

  @override
  String get kb_answer => 'Réponse';

  @override
  String kb_usage_month(int n) {
    return 'Utilisée $n fois ce mois-ci';
  }

  @override
  String kb_positive(int p) {
    return '$p % positif';
  }

  @override
  String kb_last_used(String t) {
    return 'Dernière utilisation $t';
  }

  @override
  String get kb_recent_uses => 'Utilisations récentes';

  @override
  String kb_meta(String a, String d, String b, String t) {
    return 'Créée par $a · $d · Modifiée par $b $t';
  }

  @override
  String get kb_available_ai => 'Disponible pour l\'IA';

  @override
  String get kb_file_type_err => 'Type de fichier non pris en charge';

  @override
  String get kb_file_size_err => 'Fichier de plus de 10 Mo';

  @override
  String kb_uploading(int p) {
    return 'Envoi $p %';
  }

  @override
  String get kb_processing_long =>
      'Traitement en cours… cela peut prendre une minute';

  @override
  String kb_file_ready(String f, int n) {
    return '« $f » est prêt · $n réponses à vérifier';
  }

  @override
  String get kb_extracted => 'Ce que l\'IA a extrait';

  @override
  String get kb_replace => 'Remplacer le fichier';

  @override
  String get kb_download => 'Télécharger';

  @override
  String get kb_file_failed => 'Impossible de lire le fichier';

  @override
  String get kb_fail_encrypted => 'Le fichier est protégé par un mot de passe';

  @override
  String get kb_fail_images => 'Le fichier ne contient que des images';

  @override
  String get kb_fail_corrupt => 'Le fichier est corrompu';

  @override
  String get kb_link_url => 'URL de la page';

  @override
  String get kb_link_subpages => 'Inclure les sous-pages';

  @override
  String get kb_add => 'Ajouter';

  @override
  String kb_last_crawl(String t) {
    return 'Dernière lecture $t';
  }

  @override
  String get kb_recrawl => 'Actualiser maintenant';

  @override
  String get kb_auto_refresh => 'Actualisation automatique';

  @override
  String get kb_weekly => 'Hebdomadaire';

  @override
  String get kb_monthly => 'Mensuelle';

  @override
  String get kb_manual => 'Manuelle';

  @override
  String get kb_unanswered => 'Questions sans réponse';

  @override
  String get kb_unanswered_info =>
      'Questions auxquelles l\'IA n\'a pas pu répondre. Ajoutez une réponse pour qu\'elle réponde la prochaine fois.';

  @override
  String get kb_sort_frequency => 'Les plus fréquentes';

  @override
  String get kb_sort_newest => 'Les plus récentes';

  @override
  String kb_asked_n(int n, String t) {
    return 'Posée $n fois · dernière $t';
  }

  @override
  String kb_similar(int k) {
    return '+$k formulations similaires';
  }

  @override
  String get kb_ai_draft => 'Brouillon suggéré';

  @override
  String get kb_add_answer => 'Ajouter une réponse';

  @override
  String get kb_link_existing => 'Associer à une réponse existante';

  @override
  String get kb_ignore => 'Ignorer';

  @override
  String get kb_view_convs => 'Voir les conversations';

  @override
  String get kb_suggest_answer => 'Suggérer une réponse';

  @override
  String get kb_none_unanswered => 'Aucune question sans réponse';

  @override
  String get kb_none_unanswered_body =>
      'L\'IA trouve une réponse à tout ce qui est demandé.';

  @override
  String get kb_empty_title => 'Commencez à enseigner votre activité à l\'IA';

  @override
  String get kb_empty_body =>
      'Ajoutez les principales questions de vos clients, avec leurs réponses.';

  @override
  String get kb_empty_cta => 'Ajouter la première question';

  @override
  String get kb_empty_tip => 'Nous recommandons au moins 10 questions';

  @override
  String get kb_filter_empty => 'Aucune entrée de ce type';

  @override
  String get kb_show_all => 'Tout afficher';

  @override
  String get kb_error => 'Impossible de charger la base de connaissances';

  @override
  String get kb_retry => 'Réessayer';

  @override
  String get kb_offline => 'La modification nécessite une connexion internet';

  @override
  String get kb_span_now => 'à l\'instant';

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
      other: '$n heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String kb_span_days(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String kb_span_months(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String kb_span_years(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String get kb_web_only =>
      'Cette fonctionnalité est pour l\'instant disponible sur le tableau de bord web';

  @override
  String get kb_menu_ai_settings => 'Paramètres IA';

  @override
  String get kb_menu_tags => 'Gérer les étiquettes';

  @override
  String get kb_menu_import => 'Importer depuis le web';

  @override
  String get kb_sort_by => 'Trier par';

  @override
  String get kb_tags_all => 'Toutes les étiquettes';

  @override
  String get kb_tags_apply => 'Appliquer';

  @override
  String get kb_tags_none => 'Aucune étiquette pour le moment';

  @override
  String get kb_disabled_done => 'Désactivée · l\'IA ne l\'utilisera pas';

  @override
  String get kb_enabled_done => 'Activée';

  @override
  String get kb_copied => 'Réponse copiée';

  @override
  String get kb_approved => 'Approuvée et publiée';

  @override
  String get kb_rejected => 'Suggestion rejetée';

  @override
  String get kb_ignored => 'Ignorée';

  @override
  String kb_linked(String t) {
    return 'Ajoutée comme formulation de « $t »';
  }

  @override
  String get kb_pick_answer => 'Choisir une réponse';

  @override
  String get kb_pick_search => 'Rechercher une réponse';

  @override
  String kb_uploaded_by(String name, String d) {
    return 'Importé par $name · $d';
  }

  @override
  String kb_mb(String n) {
    return '$n Mo';
  }

  @override
  String kb_kb(String n) {
    return '$n Ko';
  }

  @override
  String get kb_processing_bg =>
      'Vous pouvez fermer cette fenêtre ; le traitement continue en arrière-plan';

  @override
  String get kb_url_invalid => 'Saisissez un lien https:// valide';

  @override
  String get kb_link_added => 'Lien ajouté · lecture en cours';

  @override
  String get kb_link_pages => 'Pages';

  @override
  String get kb_never_crawled => 'Pas encore lu';

  @override
  String get kb_recrawl_started => 'Actualisation lancée';

  @override
  String kb_filter_a11y(String label, int n) {
    return '$label, $n, filtre';
  }

  @override
  String kb_banner_a11y(int n) {
    return '$n questions sans réponse. Vérifier';
  }

  @override
  String get kb_daily_chart => 'Utilisation sur 30 jours';

  @override
  String get kb_not_used_yet => 'Pas encore utilisée';

  @override
  String get kb_show_less => 'Afficher moins';

  @override
  String get kb_proposed => 'Votre suggestion a été envoyée pour vérification';

  @override
  String get kb_save_err => 'Impossible d\'enregistrer';

  @override
  String get kb_none_found => 'Aucun résultat';

  @override
  String get kb_import_title => 'Importer depuis un fichier JSON';

  @override
  String get kb_import_hint =>
      'Un fichier avec une liste d\'entrées, chacune avec un type, un titre et un contenu — même format que le panneau web.';

  @override
  String get kb_import_pick => 'Choisir un fichier JSON';

  @override
  String get kb_import_template => 'Télécharger le modèle';

  @override
  String get kb_importing => 'Importation…';

  @override
  String kb_import_done(int n) {
    return '$n entrées importées';
  }

  @override
  String kb_import_skipped(int n) {
    return '$n ignorées';
  }

  @override
  String kb_import_row_err(int row, String message) {
    return 'Ligne $row : $message';
  }

  @override
  String get kb_import_failed => 'Échec de l\'importation';

  @override
  String get kb_import_json_only => 'Choisissez un fichier .json';

  @override
  String get kb_template_saved => 'Modèle enregistré';

  @override
  String get kb_template_copied => 'Modèle copié dans le presse-papiers';

  @override
  String get kb_media_title => 'Pièces jointes';

  @override
  String kb_media_n(int n) {
    return '$n pièces jointes';
  }

  @override
  String get kb_step_upload => 'Fichier envoyé';

  @override
  String get kb_step_read => 'Lecture du document';

  @override
  String get kb_step_prepare => 'Préparation des réponses';

  @override
  String get kb_processing_hint =>
      'En général moins d’une minute. Vous pouvez masquer cette fenêtre, nous continuons.';

  @override
  String get kb_hide => 'Masquer';

  @override
  String kb_found_answers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nous avons trouvé $n réponses',
      one: 'Nous avons trouvé 1 réponse',
      zero: 'Aucune réponse trouvée',
    );
    return '$_temp0';
  }

  @override
  String get kb_found_review_hint =>
      'Vérifiez-les et choisissez ce que l’IA doit savoir.';

  @override
  String get kb_found_admin_hint =>
      'Un administrateur les vérifiera avant que l’IA ne les utilise.';

  @override
  String get kb_review_answers => 'Vérifier les réponses';

  @override
  String get kb_later => 'Plus tard';

  @override
  String get kb_fail_encrypted_hint =>
      'Retirez le mot de passe et envoyez-le à nouveau.';

  @override
  String get kb_fail_images_hint =>
      'Aucun texte lisible trouvé. Essayez un PDF avec du texte sélectionnable ou un fichier Word.';

  @override
  String get kb_fail_corrupt_hint =>
      'Essayez un autre fichier : PDF, Word, TXT ou MD, 10 Mo maximum.';

  @override
  String get kb_fail_no_answers => 'Aucune réponse trouvée';

  @override
  String get kb_fail_no_answers_hint =>
      'Le document ne semble pas contenir d’informations demandées par les clients.';

  @override
  String get kb_fail_ai => 'Impossible de lire le fichier pour le moment';

  @override
  String get kb_fail_ai_hint => 'Veuillez réessayer dans quelques minutes.';

  @override
  String get kb_fail_quota => 'Quota IA épuisé';

  @override
  String get kb_fail_quota_hint =>
      'Rechargez ou changez d’offre pour lire des documents avec l’IA.';

  @override
  String get kb_fail_network => 'Pas de connexion';

  @override
  String get kb_fail_network_hint => 'Vérifiez votre connexion et réessayez.';

  @override
  String get kb_try_another => 'Choisir un autre fichier';

  @override
  String get kb_review_title => 'Vérifier les réponses';

  @override
  String kb_review_from(int n, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n réponses issues de $file',
      one: '1 réponse issue de $file',
    );
    return '$_temp0';
  }

  @override
  String get kb_review_hint =>
      'Cochez ce que l’IA doit savoir, corrigez si besoin, puis ajoutez.';

  @override
  String kb_review_selected(int n, int total) {
    return '$n sur $total sélectionnées';
  }

  @override
  String get kb_review_select_all => 'Tout sélectionner';

  @override
  String get kb_review_clear => 'Tout désélectionner';

  @override
  String get kb_review_edit => 'Modifier';

  @override
  String get kb_review_discard => 'Supprimer';

  @override
  String kb_review_add(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ajouter $n réponses',
      one: 'Ajouter 1 réponse',
      zero: 'Ajouter les réponses',
    );
    return '$_temp0';
  }

  @override
  String kb_review_adding(int done, int total) {
    return 'Ajout $done/$total…';
  }

  @override
  String kb_review_added(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n réponses ajoutées à la base de connaissances',
      one: '1 réponse ajoutée à la base de connaissances',
    );
    return '$_temp0';
  }

  @override
  String kb_review_added_left(int n, int left) {
    return '$n ajoutées · $left restent à vérifier';
  }

  @override
  String kb_review_partial(int done, int failed) {
    return '$done ajoutées, $failed n’ont pas pu l’être. Réessayez.';
  }

  @override
  String get kb_review_all_done => 'Toutes les réponses ont été vérifiées';

  @override
  String get kb_review_all_done_body =>
      'Plus rien à vérifier pour ce document.';

  @override
  String kb_file_failed_named(String f) {
    return 'Impossible de lire « $f »';
  }

  @override
  String get kb_add_document => 'Importer un document';

  @override
  String get kb_add_document_sub =>
      'PDF, Word ou texte. L’IA le transforme en réponses à vérifier.';

  @override
  String get kb_add_ai_badge => 'IA';

  @override
  String get kb_import_another => 'Importer un autre fichier';

  @override
  String get ntf_title => 'Notifications';

  @override
  String get ntf_read_all => 'Tout marquer comme lu';

  @override
  String get ntf_read_all_done => 'Tout a été marqué comme lu';

  @override
  String get ntf_undo => 'Annuler';

  @override
  String get ntf_settings => 'Paramètres de notification';

  @override
  String get ntf_delete_read => 'Supprimer les notifications lues';

  @override
  String get ntf_filter_all => 'Toutes';

  @override
  String get ntf_filter_unread => 'Non lues';

  @override
  String get ntf_filter_mentions => 'Mentions';

  @override
  String get ntf_filter_assignments => 'Attributions';

  @override
  String get ntf_filter_ai => 'IA';

  @override
  String get ntf_filter_system => 'Système';

  @override
  String get ntf_today => 'Aujourd\'hui';

  @override
  String get ntf_yesterday => 'Hier';

  @override
  String get ntf_this_week => 'Cette semaine';

  @override
  String get ntf_older => 'Plus anciennes';

  @override
  String get ntf_push_off_title => 'Les notifications push sont désactivées';

  @override
  String get ntf_push_off_body =>
      'Activez-les pour ne jamais manquer une conversation qui vous est attribuée';

  @override
  String get ntf_enable => 'Activer';

  @override
  String get ntf_mark_read => 'Marquer comme lu';

  @override
  String get ntf_mark_unread => 'Marquer comme non lu';

  @override
  String get ntf_mute_type => 'Désactiver ce type';

  @override
  String get ntf_delete => 'Supprimer';

  @override
  String get ntf_deleted => 'Notification supprimée';

  @override
  String get ntf_empty_title => 'Aucune notification';

  @override
  String get ntf_empty_body =>
      'Nous vous préviendrons quand une conversation vous sera attribuée ou si votre équipe a besoin de vous.';

  @override
  String ntf_empty_filter(String f) {
    return 'Aucune notification dans « $f »';
  }

  @override
  String get ntf_show_all => 'Afficher tout';

  @override
  String get ntf_error => 'Impossible de charger les notifications';

  @override
  String get ntf_retry => 'Réessayer';

  @override
  String get ntf_end => 'Aucune autre notification';

  @override
  String get ntf_retention =>
      'Les notifications sont supprimées après 90 jours';

  @override
  String get ntf_target_gone => 'Cette conversation n\'est plus disponible';

  @override
  String get ntf_claimed_you => 'Vous l\'avez prise en charge';

  @override
  String ntf_claimed_by(String name) {
    return 'Prise en charge par $name';
  }

  @override
  String get ntf_approved => 'Approuvé';

  @override
  String get ntf_rejected => 'Rejeté';

  @override
  String ntf_grouped(int n, String name) {
    return '$n nouveaux messages de $name';
  }

  @override
  String get ntf_push_private => 'Vous avez une nouvelle conversation';

  @override
  String get ntf_t_assigned => 'Une nouvelle conversation vous a été attribuée';

  @override
  String ntf_t_claim_needed(int n) {
    return '$n conversations en attente d\'être prises en charge';
  }

  @override
  String ntf_t_sla_breach(String customer, String m) {
    return '$customer attend votre réponse depuis $m';
  }

  @override
  String ntf_t_transfer_request(String agent) {
    return '$agent demande à reprendre une conversation';
  }

  @override
  String ntf_t_mention(String agent) {
    return '$agent vous a mentionné dans une note';
  }

  @override
  String get ntf_t_ai_no_answer => 'L\'IA n\'a pas trouvé de réponse';

  @override
  String get ntf_t_ai_handoff =>
      'L\'IA a transféré une conversation à l\'équipe';

  @override
  String get ntf_t_ai_low_confidence =>
      'L\'IA a répondu avec un faible niveau de confiance';

  @override
  String ntf_t_kb_suggestion(int n) {
    return '$n questions fréquentes sans réponse';
  }

  @override
  String get ntf_t_channel_disconnected => 'WhatsApp déconnecté';

  @override
  String get ntf_t_channel_reconnected =>
      'WhatsApp s\'est déconnecté puis reconnecté';

  @override
  String get ntf_t_channel_quality_low =>
      'La qualité du numéro WhatsApp est faible';

  @override
  String ntf_t_team_joined(String name) {
    return '$name a rejoint l\'équipe';
  }

  @override
  String ntf_t_team_role_changed(String role) {
    return 'Votre rôle est devenu $role';
  }

  @override
  String ntf_t_trial_ending(int n) {
    return 'Votre essai se termine dans $n jours';
  }

  @override
  String get ntf_t_payment_failed => 'Le paiement de l\'abonnement a échoué';

  @override
  String get ntf_t_plan_limit =>
      'Vous approchez de votre limite de réponses IA';

  @override
  String get ntf_t_app_update => 'Une nouvelle version est disponible';

  @override
  String ntf_b_claim_needed(String m) {
    return 'La plus ancienne attend depuis $m';
  }

  @override
  String ntf_b_ai_no_answer(String topic) {
    return 'Une question sur $topic. Ajoutez la réponse pour qu\'elle réponde automatiquement la prochaine fois.';
  }

  @override
  String ntf_b_ai_low_confidence(String customer) {
    return '$customer · Vérifiez la réponse';
  }

  @override
  String get ntf_b_kb_suggestion =>
      'Ajoutez-les à la base de connaissances pour améliorer les réponses';

  @override
  String get ntf_b_channel_disconnected =>
      'Les messages ne vous parviendront pas jusqu\'à la reconnexion';

  @override
  String ntf_b_channel_reconnected(String m) {
    return 'Hors service pendant $m · aucun message perdu';
  }

  @override
  String get ntf_b_channel_quality_low =>
      'Envoyez moins de messages groupés pour éviter les restrictions';

  @override
  String ntf_b_team_joined(String role) {
    return 'Rôle : $role';
  }

  @override
  String ntf_b_team_role_changed(String actor) {
    return 'Par $actor';
  }

  @override
  String get ntf_b_trial_ending =>
      'Choisissez un forfait pour conserver vos conversations et l\'IA.';

  @override
  String get ntf_b_payment_failed =>
      'Mettez à jour votre moyen de paiement pour éviter une interruption du service';

  @override
  String ntf_b_plan_limit(int p) {
    return 'Vous avez utilisé $p % ce mois-ci';
  }

  @override
  String ntf_b_app_update(String version) {
    return '$version · Améliorations et corrections';
  }

  @override
  String get ntf_a_view => 'Voir';

  @override
  String get ntf_a_reply => 'Répondre maintenant';

  @override
  String get ntf_a_approve => 'Approuver';

  @override
  String get ntf_a_reject => 'Rejeter';

  @override
  String get ntf_a_add_answer => 'Ajouter une réponse';

  @override
  String get ntf_a_claim => 'Prendre en charge';

  @override
  String get ntf_a_review => 'Vérifier';

  @override
  String get ntf_a_reconnect => 'Reconnecter';

  @override
  String get ntf_a_plans => 'Voir les forfaits';

  @override
  String get ntf_a_update => 'Mettre à jour';

  @override
  String get ntf_a_open => 'Ouvrir';

  @override
  String get ntf_more => 'Plus';

  @override
  String get ntf_dismiss => 'Ignorer';

  @override
  String get ntf_a11y_unread => 'Non lu';

  @override
  String ntf_a11y_filter(String f, int n) {
    return '$f, $n non lues';
  }

  @override
  String get ntf_muted => 'Vous ne recevrez plus ce type de notification';

  @override
  String get ntf_push_unavailable =>
      'Activez les notifications dans les paramètres de votre appareil';

  @override
  String get ntf_offline_action =>
      'Cette action nécessite une connexion internet';

  @override
  String get ntf_action_failed =>
      'Impossible d\'effectuer l\'action. Réessayez.';

  @override
  String get ntf_billing_agent_title =>
      'La facturation est gérée par un administrateur';

  @override
  String get ntf_billing_agent_body =>
      'Demandez à l\'administrateur de votre espace de travail de gérer l\'abonnement sur le site web de Wavadesk.';

  @override
  String get profile_title => 'Profil client';

  @override
  String get profile_add_tag => '+ Étiquette';

  @override
  String get profile_vip => 'VIP';

  @override
  String get profile_blocked => 'Bloqué';

  @override
  String profile_local_time(String time) {
    return '$time, heure locale du client';
  }

  @override
  String get profile_copied => 'Copié';

  @override
  String get profile_call => 'Appeler';

  @override
  String get profile_whatsapp => 'WhatsApp';

  @override
  String get profile_note => 'Note';

  @override
  String get profile_block => 'Bloquer';

  @override
  String get profile_unblock => 'Débloquer';

  @override
  String get profile_stat_conversations => 'Conversations';

  @override
  String get profile_stat_orders => 'Commandes';

  @override
  String get profile_stat_rating => 'Note';

  @override
  String get profile_stat_first => 'Premier contact';

  @override
  String get profile_ai_summary => 'Résumé de l\'IA';

  @override
  String get profile_ai_disclaimer => 'Le résumé peut contenir des erreurs';

  @override
  String get profile_more => 'Plus';

  @override
  String get profile_notes => 'Notes de l\'équipe';

  @override
  String get profile_add => 'Ajouter';

  @override
  String profile_all_notes(int n) {
    return 'Voir toutes les notes ($n)';
  }

  @override
  String get profile_no_notes => 'Aucune note pour l\'instant';

  @override
  String get profile_first_note => 'Ajouter la première note';

  @override
  String get profile_pin => 'Épingler';

  @override
  String get profile_edit => 'Modifier';

  @override
  String get profile_delete => 'Supprimer';

  @override
  String get profile_info => 'Détails';

  @override
  String get profile_phone => 'Téléphone';

  @override
  String get profile_email => 'E-mail';

  @override
  String get profile_city => 'Ville';

  @override
  String get profile_language => 'Langue préférée';

  @override
  String get profile_timezone => 'Fuseau horaire';

  @override
  String get profile_added_by => 'Ajouté par';

  @override
  String get profile_not_set => 'Non défini';

  @override
  String get profile_all_info => 'Voir tous les détails';

  @override
  String get profile_channels => 'Canaux';

  @override
  String profile_channel_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations',
      one: '1 conversation',
      zero: 'Aucune conversation',
    );
    return '$_temp0';
  }

  @override
  String get profile_unlink => 'Dissocier l\'identité';

  @override
  String get profile_merge => 'Fusionner avec un autre contact';

  @override
  String get profile_orders => 'Commandes';

  @override
  String profile_total_spent(String sum) {
    return 'Total dépensé : $sum SAR';
  }

  @override
  String get profile_previous => 'Conversations précédentes';

  @override
  String get profile_all_channels => 'Tous les canaux';

  @override
  String profile_closed_by(String date, String name) {
    return '$date · Fermée par $name';
  }

  @override
  String profile_ai_replied(String date) {
    return '$date · Réponse de l\'IA';
  }

  @override
  String profile_open_now(String date) {
    return '$date · Ouverte actuellement';
  }

  @override
  String get profile_load_more => 'Charger plus';

  @override
  String get profile_first_conv => 'C\'est la première conversation';

  @override
  String get profile_block_cta => 'Bloquer le client';

  @override
  String get profile_block_hint =>
      'Vous ne recevrez plus de messages de ce client.';

  @override
  String get profile_erase => 'Supprimer les données du client';

  @override
  String profile_visitor(String id) {
    return 'Visiteur n° $id';
  }

  @override
  String get profile_add_details => 'Ajouter les informations du client';

  @override
  String get profile_offline => 'Affichage de la dernière version enregistrée';

  @override
  String get profile_load_error => 'Impossible de charger le profil';

  @override
  String profile_section_error(String section) {
    return 'Impossible de charger $section';
  }

  @override
  String get profile_retry => 'Réessayer';

  @override
  String get profile_open_page => 'Ouvrir en page entière';

  @override
  String profile_dialog_label(String name) {
    return 'Profil client, $name';
  }

  @override
  String get profile_unpin => 'Désépingler';

  @override
  String get profile_regenerate => 'Régénérer le résumé';

  @override
  String profile_note_a11y(String author, String date, String text) {
    return 'Note de $author, $date : $text';
  }

  @override
  String get profile_delete_note_title => 'Supprimer la note ?';

  @override
  String get profile_delete_note_body =>
      'Cette note sera supprimée pour toute l\'équipe.';

  @override
  String profile_action_call_a11y(String name) {
    return 'Appeler $name';
  }

  @override
  String profile_action_whatsapp_a11y(String name) {
    return 'Contacter $name par WhatsApp';
  }

  @override
  String profile_action_note_a11y(String name) {
    return 'Ajouter une note sur $name';
  }

  @override
  String profile_action_block_a11y(String name) {
    return 'Bloquer $name';
  }

  @override
  String profile_action_unblock_a11y(String name) {
    return 'Débloquer $name';
  }

  @override
  String get profile_disabled_no_phone => 'Indisponible, aucun numéro';

  @override
  String profile_stats_a11y(
    int conversations,
    String orders,
    String ordersLabel,
    String first,
  ) {
    return '$conversations conversations, $orders $ordersLabel, premier contact $first';
  }

  @override
  String profile_order_items(String date, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles',
      one: '1 article',
    );
    return '$date · $_temp0';
  }

  @override
  String profile_amount(String amount) {
    return '$amount SAR';
  }

  @override
  String get profile_order_processing => 'En cours';

  @override
  String get profile_order_shipped => 'Expédiée';

  @override
  String get profile_order_delivered => 'Livrée';

  @override
  String get profile_order_cancelled => 'Annulée';

  @override
  String get profile_view_all => 'Tout voir';

  @override
  String get profile_no_order_link => 'Aucun lien pour cette commande';

  @override
  String get profile_lang_ar => 'العربية';

  @override
  String get profile_lang_en => 'English';

  @override
  String profile_tz_value(String tz, String time) {
    return '$tz · $time';
  }

  @override
  String get profile_attr_yes => 'Oui';

  @override
  String get profile_attr_no => 'Non';

  @override
  String get profile_unlinked => 'Identité dissociée';

  @override
  String get profile_filter_channel => 'Filtrer par canal';

  @override
  String get profile_merged => 'Ce contact a été fusionné';

  @override
  String get profile_more_actions => 'Plus d\'actions';

  @override
  String get profile_edit_contact => 'Modifier le client';

  @override
  String get edit_title => 'Modifier le client';

  @override
  String get edit_save => 'Enregistrer';

  @override
  String get edit_saved => 'Modifications enregistrées';

  @override
  String get edit_failed =>
      'Impossible d\'enregistrer les modifications. Réessayez.';

  @override
  String get edit_discard_title => 'Abandonner les modifications ?';

  @override
  String get edit_discard_body =>
      'Vos modifications ne sont pas encore enregistrées. Si vous quittez maintenant, elles seront perdues.';

  @override
  String get edit_discard => 'Abandonner';

  @override
  String get edit_keep => 'Continuer la modification';

  @override
  String get edit_name => 'Nom';

  @override
  String get edit_phone => 'Téléphone';

  @override
  String get edit_email => 'E-mail';

  @override
  String get edit_city => 'Ville';

  @override
  String get edit_language => 'Langue préférée';

  @override
  String get edit_not_set => 'Non défini';

  @override
  String get edit_phone_invalid => 'Numéro de téléphone invalide';

  @override
  String get edit_email_invalid => 'Format d\'e-mail invalide';

  @override
  String get tags_title => 'Étiquettes';

  @override
  String get tags_search => 'Rechercher ou créer une étiquette';

  @override
  String tags_create(String q) {
    return 'Créer « $q »';
  }

  @override
  String get tags_done => 'Terminé';

  @override
  String get tags_failed =>
      'Impossible d\'enregistrer les étiquettes. Réessayez.';

  @override
  String get tags_remove => 'Retirer l\'étiquette';

  @override
  String get note_new => 'Nouvelle note';

  @override
  String get note_edit_title => 'Modifier la note';

  @override
  String get note_placeholder =>
      'Ce que votre équipe devrait savoir sur ce client…';

  @override
  String get note_pin => 'Épingler la note';

  @override
  String get note_save => 'Enregistrer';

  @override
  String get note_cancel => 'Annuler';

  @override
  String get note_saved => 'Note ajoutée';

  @override
  String get note_updated => 'Note mise à jour';

  @override
  String get note_failed => 'Impossible d\'enregistrer la note. Réessayez.';

  @override
  String get call_phone => 'Appel téléphonique';

  @override
  String get call_whatsapp => 'Appel WhatsApp';

  @override
  String get call_copy => 'Copier le numéro';

  @override
  String get call_cancel => 'Annuler';

  @override
  String get call_copied => 'Copié';

  @override
  String get call_failed => 'Impossible d\'ouvrir l\'application d\'appel';

  @override
  String block_title(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get block_body =>
      'Vous ne recevrez plus leurs messages sur aucun canal et les conversations ouvertes seront fermées. Vous pourrez débloquer plus tard.';

  @override
  String get block_reason_label => 'Motif (facultatif)';

  @override
  String get block_reason_spam => 'Spam';

  @override
  String get block_reason_fraud => 'Fraude';

  @override
  String get block_reason_abuse => 'Abus';

  @override
  String get block_reason_other => 'Autre';

  @override
  String get block_confirm => 'Bloquer';

  @override
  String get block_cancel => 'Annuler';

  @override
  String get block_done => 'Client bloqué';

  @override
  String get block_failed => 'Impossible de bloquer le client. Réessayez.';

  @override
  String get block_unnamed => 'ce client';

  @override
  String get undo => 'Annuler';

  @override
  String get merge_title => 'Fusionner avec un autre contact';

  @override
  String get merge_search => 'Rechercher par nom, téléphone ou e-mail';

  @override
  String get merge_no_results => 'Aucun contact correspondant';

  @override
  String get merge_unnamed => 'Contact sans nom';

  @override
  String get merge_into_label => 'Fusion vers';

  @override
  String get merge_change => 'Changer';

  @override
  String get merge_no_conflicts =>
      'Aucune valeur en conflit — toutes les conversations et notes seront transférées vers le contact sélectionné.';

  @override
  String get merge_choose_values => 'Choisissez les valeurs à conserver';

  @override
  String get merge_field_name => 'Nom';

  @override
  String get merge_field_phone => 'Téléphone';

  @override
  String get merge_field_email => 'E-mail';

  @override
  String get merge_field_city => 'Ville';

  @override
  String get merge_this_contact => 'Ce contact';

  @override
  String get merge_other_contact => 'Autre contact';

  @override
  String get merge_action => 'Fusionner';

  @override
  String get merge_confirm_title => 'La fusion est irréversible';

  @override
  String get merge_confirm_body =>
      'Les conversations et notes sont transférées vers le contact sélectionné et ce profil est supprimé.';

  @override
  String get merge_done => 'Contacts fusionnés';

  @override
  String get merge_failed => 'Impossible de fusionner. Réessayez.';

  @override
  String get erase_title => 'Supprimer définitivement les données du client ?';

  @override
  String get erase_body =>
      'Toutes les conversations, notes et informations de ce client seront supprimées et ne pourront pas être récupérées.';

  @override
  String get erase_type_digits =>
      'Saisissez les 4 derniers chiffres du téléphone du client pour confirmer';

  @override
  String erase_type_word(String word) {
    return 'Saisissez « $word » pour confirmer';
  }

  @override
  String get erase_word => 'supprimer';

  @override
  String get erase_confirm => 'Supprimer définitivement';

  @override
  String get erase_cancel => 'Annuler';

  @override
  String get erase_done => 'Données du client supprimées';

  @override
  String get erase_failed => 'Impossible de supprimer les données. Réessayez.';

  @override
  String get search_placeholder =>
      'Rechercher des clients, des messages ou un numéro de commande';

  @override
  String get search_cancel => 'Annuler';

  @override
  String get search_scope_all => 'Tout';

  @override
  String get search_scope_contacts => 'Clients';

  @override
  String get search_scope_messages => 'Messages';

  @override
  String get search_scope_kb => 'Connaissances';

  @override
  String get search_scope_conversations => 'Conversations';

  @override
  String get search_filters => 'Filtres';

  @override
  String get search_section_contacts => 'Clients';

  @override
  String get search_section_messages => 'Messages';

  @override
  String get search_section_kb => 'Base de connaissances';

  @override
  String get search_section_conversations => 'Conversations';

  @override
  String search_see_all(int n) {
    return 'Tout voir ($n)';
  }

  @override
  String get search_best_match => 'Meilleure correspondance';

  @override
  String get search_open_chat => 'Ouvrir la conversation';

  @override
  String get search_profile => 'Profil';

  @override
  String get search_open_badge => 'Ouverte';

  @override
  String search_more_in_conv(int n) {
    return '+$n de plus dans cette conversation';
  }

  @override
  String search_kb_usage(int n) {
    return 'Utilisée par l\'IA $n fois ce mois-ci';
  }

  @override
  String get search_insert_reply => 'Insérer dans la réponse';

  @override
  String get search_you => 'Vous :';

  @override
  String get search_note => 'Note :';

  @override
  String search_order(String n) {
    return 'Commande $n';
  }

  @override
  String search_tag(String tag) {
    return 'Étiquette : $tag';
  }

  @override
  String get search_recent => 'Recherches récentes';

  @override
  String get search_clear => 'Effacer';

  @override
  String get search_suggestions => 'Suggestions';

  @override
  String get search_recent_contacts => 'Contactés récemment';

  @override
  String get search_tip =>
      'Recherchez par nom, téléphone, numéro de commande ou tout autre mot';

  @override
  String search_no_results(String q) {
    return 'Aucun résultat pour « $q »';
  }

  @override
  String get search_no_results_body =>
      'Essayez un autre mot ou vérifiez l\'orthographe';

  @override
  String get search_clear_filters => 'Effacer les filtres';

  @override
  String get search_in_all => 'Rechercher partout';

  @override
  String search_did_you_mean(String s) {
    return 'Vouliez-vous dire : $s ?';
  }

  @override
  String get search_error => 'La recherche a échoué';

  @override
  String get search_retry => 'Réessayer';

  @override
  String get search_offline =>
      'Hors ligne — affichage des données enregistrées uniquement';

  @override
  String get search_local => '(local)';

  @override
  String get search_filter_sender => 'Expéditeur';

  @override
  String get search_filter_contains => 'Contient';

  @override
  String get search_filter_attachments => 'Pièces jointes';

  @override
  String get search_filter_images => 'Images';

  @override
  String get search_filter_voice => 'Messages vocaux';

  @override
  String search_show_results(int n) {
    return 'Afficher les résultats ($n)';
  }

  @override
  String get search_field_label => 'Rechercher';

  @override
  String search_filters_n(int n) {
    return 'Filtres · $n';
  }

  @override
  String get search_filter_channel => 'Canal';

  @override
  String get search_filter_date => 'Date';

  @override
  String get search_filter_status => 'Statut de la conversation';

  @override
  String get search_filter_assignee => 'Attribué à';

  @override
  String get search_date_any => 'À tout moment';

  @override
  String get search_date_today => 'Aujourd\'hui';

  @override
  String get search_date_7 => '7 jours';

  @override
  String get search_date_30 => '30 jours';

  @override
  String get search_date_custom => 'Personnalisé';

  @override
  String get search_sender_all => 'Tous';

  @override
  String get search_sender_contact => 'Client';

  @override
  String get search_sender_me => 'Moi';

  @override
  String get search_sender_colleagues => 'Coéquipiers';

  @override
  String get search_sender_ai => 'IA';

  @override
  String get search_sender_notes => 'Notes internes';

  @override
  String get search_status_all => 'Tous';

  @override
  String get search_status_open => 'Ouverte';

  @override
  String get search_status_resolved => 'Résolue';

  @override
  String get search_assignee_all => 'Tous';

  @override
  String get search_assignee_me => 'Moi';

  @override
  String get search_assignee_colleague => 'Coéquipier';

  @override
  String get search_sugg_unread => 'Non lues';

  @override
  String get search_sugg_awaiting => 'En attente de réponse';

  @override
  String get search_sugg_vip => 'Étiquette : VIP';

  @override
  String get search_sugg_orders_today => 'Commandes du jour';

  @override
  String search_recent_remove(String q) {
    return 'Supprimer $q de l\'historique';
  }

  @override
  String get search_recents_cleared => 'Historique de recherche effacé';

  @override
  String search_results_announce(int n, String parts) {
    return '$n résultats : $parts';
  }

  @override
  String search_announce_contacts(int n) {
    return '$n clients';
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
    return 'Message de $name, $time : $text';
  }

  @override
  String get search_last_chat => 'Ouvrir la dernière conversation';

  @override
  String get search_new_chat => 'Nouvelle conversation';

  @override
  String get search_copy_number => 'Copier le numéro';

  @override
  String get search_copied => 'Numéro copié';

  @override
  String get search_call => 'Appeler';

  @override
  String get search_section_teammates => 'Coéquipiers';

  @override
  String get search_no_chat_yet =>
      'Aucune conversation précédente avec ce client';

  @override
  String get search_inserted => 'Réponse insérée dans le message';

  @override
  String get search_in_conv_placeholder => 'Rechercher dans cette conversation';

  @override
  String search_in_conv_count(int i, int n) {
    return '$i sur $n';
  }

  @override
  String get search_in_conv_action => 'Rechercher dans la conversation';

  @override
  String get search_in_conv_prev => 'Résultat précédent';

  @override
  String get search_in_conv_next => 'Résultat suivant';

  @override
  String get search_in_conv_close => 'Fermer la recherche';

  @override
  String get startup_unavailable_title =>
      'Impossible de se connecter pour le moment';

  @override
  String get startup_unavailable_body =>
      'Wavadesk n\'a pas pu contacter ses serveurs. Assurez-vous d\'utiliser la dernière version de l\'application, puis réessayez.';

  @override
  String get startup_unavailable_help =>
      'Toujours bloqué ? Contactez-nous à support@wavadesk.com';

  @override
  String get startup_retry => 'Réessayer';

  @override
  String get startup_contact_support => 'Contacter le support';

  @override
  String get startup_dev_hint =>
      'Développeur : l\'URL ou la clé API est manquante. Lancez avec --dart-define-from-file=dart_defines/<env>.json ou remplissez assets/config/api.json.';

  @override
  String get wa_title => 'Votre WhatsApp';

  @override
  String get wa_refresh => 'Actualiser le statut';

  @override
  String get wa_log => 'Journal de connexion';

  @override
  String get wa_help => 'Aide';

  @override
  String get wa_connected => 'Connecté';

  @override
  String get wa_connecting => 'Connexion en cours';

  @override
  String get wa_syncing => 'Synchronisation';

  @override
  String get wa_phone_offline => 'Téléphone hors ligne';

  @override
  String get wa_disconnected => 'Déconnecté';

  @override
  String get wa_restricted => 'Restreint';

  @override
  String get wa_pending => 'Non lié';

  @override
  String get wa_msgs_today => 'messages aujourd\'hui';

  @override
  String get wa_quality => 'Qualité du numéro';

  @override
  String get wa_q_high => 'Élevée';

  @override
  String get wa_q_med => 'Moyenne';

  @override
  String get wa_q_low => 'Faible';

  @override
  String get wa_stable => 'Stable';

  @override
  String get wa_unstable => 'Instable';

  @override
  String get wa_linked_since => 'Lié depuis';

  @override
  String wa_days(String n) {
    return '$n jours';
  }

  @override
  String wa_alert_disc_title(String t) {
    return 'Déconnecté depuis $t';
  }

  @override
  String get wa_alert_disc_body =>
      'Les messages des clients ne vous parviendront pas jusqu\'à la reconnexion';

  @override
  String get wa_reconnect => 'Reconnecter';

  @override
  String get wa_alert_phone_title => 'Votre téléphone est hors ligne';

  @override
  String get wa_alert_phone_body =>
      'Vérifiez que WhatsApp est actif sur le téléphone lié';

  @override
  String get wa_check_again => 'Vérifier à nouveau';

  @override
  String get wa_alert_quality => 'La qualité du numéro est faible';

  @override
  String get wa_alert_quality_body =>
      'Réduisez les messages groupés et le contenu répétitif';

  @override
  String get wa_details => 'Détails';

  @override
  String wa_alert_limit(String l, String u) {
    return 'Proche de la limite quotidienne de conversations ($u/$l)';
  }

  @override
  String get wa_alert_update => 'Mettez à jour WhatsApp sur votre téléphone';

  @override
  String get wa_alert_pending => 'WhatsApp n\'est pas encore lié';

  @override
  String get wa_alert_pending_body =>
      'Liez votre numéro pour commencer à recevoir des messages';

  @override
  String get wa_connect => 'Connecter WhatsApp';

  @override
  String get wa_auto => 'Messages automatiques';

  @override
  String get wa_welcome => 'Message de bienvenue';

  @override
  String get wa_away => 'Message d\'absence';

  @override
  String get wa_away_ai => 'Géré par l\'IA pour le moment';

  @override
  String get wa_quick => 'Réponses rapides';

  @override
  String get wa_welcome_delay => 'Délai du message de bienvenue';

  @override
  String get wa_now => 'Immédiatement';

  @override
  String get wa_welcome_off => 'Message de bienvenue désactivé';

  @override
  String get wa_undo => 'Annuler';

  @override
  String get wa_templates => 'Modèles approuvés';

  @override
  String get wa_tpl_marketing => 'Marketing';

  @override
  String get wa_tpl_utility => 'Utilitaire';

  @override
  String get wa_tpl_auth => 'Authentification';

  @override
  String get wa_tpl_approved => 'Approuvé';

  @override
  String get wa_tpl_pending => 'En cours de révision';

  @override
  String get wa_tpl_rejected => 'Rejeté';

  @override
  String get wa_tpl_manage_web => 'Gérer les modèles sur le web';

  @override
  String get wa_numbers => 'Numéros';

  @override
  String get wa_add_second => 'Ajouter un second numéro';

  @override
  String get wa_business_only => 'Disponible avec le forfait Business';

  @override
  String get wa_upgrade => 'Mettre à niveau';

  @override
  String get wa_add_number => 'Ajouter un numéro';

  @override
  String get wa_watch => 'Regarder : comment connecter WhatsApp';

  @override
  String wa_watch_sub(String d) {
    return 'Guide vidéo · $d';
  }

  @override
  String get wa_advanced => 'Avancé';

  @override
  String get wa_read_receipts => 'Accusés de lecture pour le client';

  @override
  String get wa_mark_read_open => 'Marquer comme lu à l\'ouverture';

  @override
  String get wa_auto_transcribe =>
      'Transcrire automatiquement les messages vocaux';

  @override
  String get wa_ignore_groups => 'Ignorer les messages de groupe';

  @override
  String get wa_blocked => 'Numéros bloqués';

  @override
  String get wa_hours => 'Heures d\'ouverture';

  @override
  String get wa_disconnect => 'Déconnecter le numéro';

  @override
  String get wa_disc_title => 'Déconnecter le numéro WhatsApp ?';

  @override
  String get wa_disc_body =>
      'Les messages ne parviendront plus à Wavadesk et l\'IA arrêtera de répondre. Les conversations passées sont conservées.';

  @override
  String wa_disc_open(String n) {
    return '$n conversations ouvertes seront interrompues';
  }

  @override
  String get wa_disc_confirm_label =>
      'Saisissez les 4 derniers chiffres pour confirmer';

  @override
  String get wa_disc_done => 'Numéro déconnecté';

  @override
  String get wa_connect_title => 'Connecter WhatsApp';

  @override
  String wa_step(String i, String n) {
    return 'Étape $i sur $n';
  }

  @override
  String get wa_by_phone => 'Numéro de téléphone';

  @override
  String get wa_by_qr => 'Code QR';

  @override
  String get wa_get_code => 'Obtenir le code';

  @override
  String get wa_copy => 'Copier';

  @override
  String wa_expires_in(String t) {
    return 'Expire dans $t';
  }

  @override
  String get wa_steps_pair =>
      'Ouvrez WhatsApp → Paramètres → Appareils liés → Lier un appareil → Lier avec un numéro de téléphone → Saisissez le code';

  @override
  String get wa_open_app => 'Ouvrir WhatsApp';

  @override
  String get wa_linked_ok => 'WhatsApp connecté';

  @override
  String get wa_syncing_recent => 'Synchronisation des conversations récentes…';

  @override
  String get wa_back => 'Retour';

  @override
  String get wa_back_online => 'De nouveau en ligne · aucun message perdu';

  @override
  String get wa_code_expired => 'Code expiré';

  @override
  String get wa_new_code => 'Nouveau code';

  @override
  String get wa_number_taken =>
      'Ce numéro est lié à un autre espace de travail';

  @override
  String get wa_watch_video => 'Regarder la vidéo';

  @override
  String get wa_welcome_when => 'Quand envoyer ?';

  @override
  String get wa_trigger_first => 'Premier message d\'un nouveau client';

  @override
  String get wa_trigger_new => 'Chaque nouvelle conversation';

  @override
  String get wa_trigger_24h => 'Après 24h de silence';

  @override
  String get wa_buttons => 'Boutons rapides';

  @override
  String get wa_ai_after_welcome =>
      'L\'IA répondra juste après le message de bienvenue';

  @override
  String get wa_away_outside => 'Hors des heures d\'ouverture';

  @override
  String get wa_away_team => 'Quand toute l\'équipe est absente';

  @override
  String wa_away_cooldown(String n) {
    return 'Une fois toutes les ${n}h par client';
  }

  @override
  String get wa_away_ai_banner =>
      'L\'IA répond en dehors des heures — modifiez-le dans les paramètres IA';

  @override
  String get wa_qr_team => 'Équipe';

  @override
  String get wa_qr_mine => 'Les miennes';

  @override
  String get wa_qr_title_f => 'Titre';

  @override
  String get wa_qr_shortcut => 'Raccourci';

  @override
  String get wa_qr_text => 'Texte';

  @override
  String get wa_qr_shared => 'Partagée avec l\'équipe';

  @override
  String get wa_notify_admin => 'Notifier l\'administrateur';

  @override
  String get wa_load_error => 'Impossible de charger le statut WhatsApp';

  @override
  String get wa_enable_after => 'Activer après la liaison';

  @override
  String get wa_more => 'Plus';

  @override
  String wa_last_updated(String t) {
    return 'Dernière mise à jour $t';
  }

  @override
  String get wa_copied => 'Copié';

  @override
  String get wa_details_title => 'Détails de la connexion';

  @override
  String get wa_d_type => 'Type de connexion';

  @override
  String get wa_d_type_linked => 'Appareil lié';

  @override
  String get wa_d_type_cloud => 'API officielle WhatsApp';

  @override
  String get wa_d_device => 'Appareil';

  @override
  String wa_d_wa_business(String v) {
    return 'WhatsApp Business $v';
  }

  @override
  String wa_d_wa_personal(String v) {
    return 'WhatsApp $v';
  }

  @override
  String get wa_d_last_activity => 'Dernière activité';

  @override
  String get wa_d_sync => 'Statut de synchronisation';

  @override
  String get wa_d_synced => 'Synchronisé';

  @override
  String get wa_d_number_id => 'ID du numéro de téléphone';

  @override
  String get wa_d_daily_limit => 'Limite quotidienne de conversations';

  @override
  String wa_d_limit_value(String l, String u) {
    return '$u sur $l';
  }

  @override
  String get wa_unknown => 'Inconnu';

  @override
  String get wa_qs_explain =>
      'La qualité reflète la réaction des clients à vos messages au cours des 7 derniers jours. Les blocages, signalements et le faible engagement la réduisent.';

  @override
  String get wa_qs_tier => 'Palier de messagerie';

  @override
  String wa_qs_tier_value(String tier) {
    return '$tier conversations / jour';
  }

  @override
  String get wa_qs_trend => '7 derniers jours';

  @override
  String get wa_qs_tips => 'Conseils pour améliorer la qualité';

  @override
  String get wa_qs_tip1 =>
      'N\'envoyez des messages qu\'aux clients ayant donné leur accord';

  @override
  String get wa_qs_tip2 =>
      'Personnalisez les messages, évitez les textes répétitifs';

  @override
  String get wa_qs_tip3 => 'Facilitez le désabonnement';

  @override
  String get wa_qs_help => 'Centre d\'aide WhatsApp';

  @override
  String get wa_log_connected => 'Connecté';

  @override
  String wa_log_connected_by(String name) {
    return 'Connecté par $name';
  }

  @override
  String wa_log_disconnected(String d) {
    return 'Déconnecté · $d';
  }

  @override
  String get wa_log_reconnected => 'Reconnecté';

  @override
  String wa_log_reconnected_by(String name) {
    return 'Reconnecté par $name';
  }

  @override
  String wa_log_recovered(String n) {
    return '$n messages récupérés';
  }

  @override
  String get wa_reason_phone_offline => 'Téléphone hors ligne';

  @override
  String get wa_reason_logged_out => 'Déconnecté de la session';

  @override
  String get wa_reason_update => 'Mise à jour';

  @override
  String get wa_log_empty => 'Aucun événement au cours des 30 derniers jours';

  @override
  String get wa_cancel => 'Annuler';

  @override
  String get wa_disc_mismatch => 'Les chiffres ne correspondent pas';

  @override
  String get wa_disc_failed => 'Impossible de déconnecter';

  @override
  String get wa_notify_sent => 'Administrateur notifié';

  @override
  String get wa_save_failed => 'Impossible d\'enregistrer la modification';

  @override
  String get wa_retry => 'Réessayer';

  @override
  String get wa_offline => 'La modification nécessite une connexion internet';

  @override
  String get wa_saved => 'Enregistré';

  @override
  String get wa_welcome_on => 'Message de bienvenue activé';

  @override
  String get wa_away_on => 'Message d\'absence activé';

  @override
  String get wa_away_off => 'Message d\'absence désactivé';

  @override
  String get wa_delay_30s => 'Après 30 secondes';

  @override
  String get wa_delay_1m => 'Après 1 minute';

  @override
  String get wa_delay_2m => 'Après 2 minutes';

  @override
  String get wa_delay_5m => 'Après 5 minutes';

  @override
  String get wa_save => 'Enregistrer';

  @override
  String get wa_welcome_enable => 'Activer le message de bienvenue';

  @override
  String get wa_away_enable => 'Activer le message d\'absence';

  @override
  String get wa_message => 'Message';

  @override
  String get wa_message_hint => 'Écrivez le message…';

  @override
  String get wa_send_when => 'Envoyer';

  @override
  String get wa_buttons_hint => 'Jusqu\'à 3 boutons, 20 caractères chacun';

  @override
  String get wa_button_add => '+ Ajouter un bouton';

  @override
  String get wa_button_hint => 'Libellé du bouton';

  @override
  String get wa_preview => 'Aperçu';

  @override
  String get wa_err_text => 'Écrivez le message (1 à 1024 caractères)';

  @override
  String get wa_err_button => 'Le libellé du bouton dépasse 20 caractères';

  @override
  String get wa_go_ai => 'Paramètres IA';

  @override
  String get wa_discard_title => 'Abandonner les modifications ?';

  @override
  String get wa_discard_body => 'Vos modifications ne seront pas enregistrées.';

  @override
  String get wa_discard => 'Abandonner';

  @override
  String get wa_keep => 'Continuer la modification';

  @override
  String get wa_qr_new => 'Nouvelle réponse rapide';

  @override
  String get wa_qr_edit => 'Modifier la réponse rapide';

  @override
  String get wa_qr_search => 'Rechercher des réponses';

  @override
  String get wa_qr_empty => 'Aucune réponse rapide pour le moment';

  @override
  String get wa_qr_empty_body =>
      'Créez-en une et utilisez-la en tapant / dans une conversation';

  @override
  String get wa_qr_no_results => 'Aucun résultat';

  @override
  String get wa_qr_add => 'Ajouter une réponse';

  @override
  String wa_qr_used(String n) {
    return 'Utilisée $n fois';
  }

  @override
  String wa_qr_delete_title(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get wa_qr_delete_body => 'Elle n\'apparaîtra plus dans la liste /.';

  @override
  String get wa_delete => 'Supprimer';

  @override
  String get wa_qr_deleted => 'Réponse supprimée';

  @override
  String get wa_qr_delete_failed => 'Impossible de supprimer la réponse';

  @override
  String get wa_qr_attach => 'Joindre une image ou un fichier';

  @override
  String get wa_qr_attach_hint => 'Facultatif · jusqu\'à 5 Mo';

  @override
  String get wa_qr_attach_too_big => 'Fichier de plus de 5 Mo';

  @override
  String get wa_qr_attach_remove => 'Supprimer la pièce jointe';

  @override
  String get wa_qr_err_title => 'Saisissez un titre';

  @override
  String get wa_qr_err_text => 'Saisissez le texte';

  @override
  String get wa_qr_err_shortcut_empty => 'Saisissez un raccourci';

  @override
  String get wa_qr_err_shortcut_invalid =>
      'Utilisez uniquement a–z, 0–9, _ et -';

  @override
  String get wa_qr_err_shortcut_taken => 'Ce raccourci est déjà utilisé';

  @override
  String get wa_qr_err_shortcut_long => 'Le raccourci est trop long';

  @override
  String get wa_qr_saved => 'Réponse enregistrée';

  @override
  String get wa_qr_save_failed => 'Impossible d\'enregistrer la réponse';

  @override
  String get wa_qr_reorder_failed => 'Impossible d\'enregistrer l\'ordre';

  @override
  String get wa_qr_shared_sub => 'Visible par toute l\'équipe';

  @override
  String get wa_qr_readonly =>
      'Seuls les administrateurs modifient les réponses d\'équipe';

  @override
  String get wa_tpl_empty => 'Aucun modèle approuvé pour le moment';

  @override
  String get wa_tpl_preview => 'Aperçu du modèle';

  @override
  String get wa_phone_hint => '5X XXX XXXX';

  @override
  String get wa_err_phone => 'Saisissez un numéro valide';

  @override
  String get wa_rate_limited => 'Trop de tentatives, réessayez dans un instant';

  @override
  String get wa_multi_device =>
      'Ce compte ne prend pas en charge les appareils liés ; mettez à jour WhatsApp et réessayez';

  @override
  String get wa_connect_failed => 'Connexion impossible, réessayez';

  @override
  String get wa_network_error => 'Aucune connexion internet';

  @override
  String get wa_qr_steps =>
      'Sur l\'autre téléphone, ouvrez WhatsApp → Paramètres → Appareils liés → Lier un appareil → Scannez le code';

  @override
  String wa_qr_refresh_in(String s) {
    return 'Actualisation dans ${s}s';
  }

  @override
  String get wa_qr_alt =>
      'Code QR pour lier WhatsApp, actualisé toutes les 20 secondes';

  @override
  String get wa_waiting_link => 'En attente du code sur votre téléphone…';

  @override
  String get wa_change_number => 'Changer de numéro';

  @override
  String get wa_phone_tip =>
      'La liaison par numéro de téléphone est la plus simple sur cet appareil — un code QR ne peut pas être scanné par le même téléphone.';

  @override
  String get wa_plan_title => 'WhatsApp n\'est pas inclus dans votre forfait';

  @override
  String get wa_plan_body =>
      'Passez à un forfait supérieur pour lier un numéro WhatsApp et recevoir les messages des clients';

  @override
  String get wa_view_plans => 'Voir les forfaits';

  @override
  String get wa_upgrade_info =>
      'Demandez au propriétaire de l\'espace de travail de mettre à niveau';

  @override
  String get wa_blocked_empty => 'Aucun numéro bloqué';

  @override
  String get wa_unblock => 'Débloquer';

  @override
  String get wa_unblocked => 'Débloqué';

  @override
  String wa_card_a11y(
    String d,
    String n,
    String name,
    String phone,
    String q,
    String status,
  ) {
    return '$name, $phone, $status. $n messages aujourd\'hui, qualité du numéro $q, lié depuis $d jours';
  }

  @override
  String get wa_save_disabled => 'Complétez les champs obligatoires';

  @override
  String wa_log_disconnected_by(String name) {
    return 'Déconnecté par $name';
  }

  @override
  String get wa_log_connect_started => 'Connexion démarrée';

  @override
  String wa_log_connect_started_by(String name) {
    return '$name a démarré la connexion';
  }

  @override
  String get wa_already_linked => 'Déjà lié';

  @override
  String get wa_banned => 'WhatsApp a banni ce numéro';

  @override
  String get wa_demo_state => 'État de démonstration';
}
