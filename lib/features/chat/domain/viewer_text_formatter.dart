import '../../../core/models/models.dart';
import '../../../l10n/app_localizations.dart';

/// Viewing-row text (Claim spec §4.2.1).
class ViewerText {
  const ViewerText(this.text, {this.boldName});

  final String text;

  /// First viewer's name, rendered bold in `textPrimary`.
  final String? boldName;
}

abstract final class ViewerTextFormatter {
  static String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

  /// [viewers] must exclude the signed-in agent. Gender comes from the API
  /// (`f` / `m`); unknown → masculine form.
  static ViewerText format(List<Agent> viewers, AppLocalizations l) {
    if (viewers.isEmpty) return ViewerText(l.claim_waiting);
    final a = _first(viewers.first.name);
    if (viewers.length == 1) {
      return ViewerText(viewers.first.gender == 'f' ? l.claim_viewer_one_f(a) : l.claim_viewer_one_m(a), boldName: a);
    }
    if (viewers.length == 2) {
      return ViewerText(l.claim_viewer_two(a, _first(viewers[1].name)), boldName: a);
    }
    return ViewerText(l.claim_viewer_many(a, viewers.length - 1), boldName: a);
  }
}
