import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/wd_api.dart';
import '../../../../core/utils/analytics.dart';

/// External destinations of the WhatsApp screen.
abstract final class WaLinks {
  static String get _origin => apiBaseUrl.isNotEmpty ? apiBaseUrl : 'https://app.wavadesk.com';

  /// "شاهد: كيف تربط واتساب" — there is no in-app Video Theater yet, so the
  /// guide opens externally. Replace with the real video id when published.
  static const howToVideo = 'https://www.youtube.com/results?search_query=wavadesk+%D8%B1%D8%A8%D8%B7+%D9%88%D8%A7%D8%AA%D8%B3%D8%A7%D8%A8';
  static const howToVideoLength = '1:45';
  static const helpCenter = 'https://wavadesk.com/help';
  static const whatsAppHelpCenter = 'https://faq.whatsapp.com/';

  static Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  static Future<void> video() {
    Analytics.log('wa_video_open');
    return _open(howToVideo);
  }

  static Future<void> help() => _open(helpCenter);
  static Future<void> whatsAppHelp() => _open(whatsAppHelpCenter);
  static Future<void> templatesOnWeb() => _open('$_origin/tenant-admin/whatsapp-official');
  static Future<void> billing(String? upgradeUrl) => _open(upgradeUrl ?? '$_origin/tenant-admin/billing');

  /// `whatsapp://` deep link (pairing-code step). Falls back to the store page.
  static Future<void> openWhatsApp() async {
    final ok = await launchUrl(Uri.parse('whatsapp://'), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok) await _open('https://wa.me/');
  }
}
