import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simple_icons/simple_icons.dart';

import 'wd_svg_icons.dart';

/// Every icon in the app, by meaning (Icon Library §5–§7). Screens use these
/// names only — never `LucideIcons` / `SimpleIcons` / `Icons` directly — so
/// swapping a glyph is a one-line change here.
///
/// Design icons first: every meaning that has an SVG in `assets/icons/`
/// (exported from the mockup) uses it via [WdSvgIcons] — [AppIcon] draws it
/// and handles RTL flipping. Lucide is the fallback for meanings the design
/// set lacks (its `…Dir` variants flip under RTL by themselves); brand logos
/// stay Simple Icons and never mirror (§3).
abstract final class AppIcons {
  // ---- 6.1 Navigation & structure -------------------------------------------
  static const IconData back = WdSvgIcons.back;
  static const IconData chevronForward = WdSvgIcons.chevron;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData close = WdSvgIcons.close;
  static const IconData more = WdSvgIcons.more;
  static const IconData moreHorizontal = LucideIcons.ellipsis;
  static const IconData menu = LucideIcons.menu;
  static const IconData externalLink = WdSvgIcons.arrow;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowDown = LucideIcons.arrowDown;

  // ---- 6.2 Tab bar ------------------------------------------------------------
  static const IconData tabInbox = WdSvgIcons.chat;
  static const IconData tabDashboard = WdSvgIcons.grid;
  static const IconData tabKnowledge = WdSvgIcons.book;
  static const IconData tabAccount = WdSvgIcons.user;

  // ---- 6.3 Inbox, search & filters -------------------------------------------
  static const IconData search = WdSvgIcons.search;
  static const IconData filter = WdSvgIcons.filter;
  static const IconData sort = LucideIcons.arrowDownUp;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData unassigned = LucideIcons.userRoundX;
  static const IconData mine = LucideIcons.userRoundCheck;
  static const IconData pin = LucideIcons.pin;
  static const IconData archive = WdSvgIcons.archive;
  static const IconData star = WdSvgIcons.star;
  static const IconData history = LucideIcons.history;
  static const IconData tag = WdSvgIcons.tag;
  static const IconData hash = LucideIcons.hash;

  // ---- 6.4 Chat & composer ----------------------------------------------------
  static const IconData send = WdSvgIcons.send;
  static const IconData attach = WdSvgIcons.attach;
  static const IconData mic = WdSvgIcons.mic;
  static const IconData stop = LucideIcons.square;
  static const IconData camera = LucideIcons.camera;
  static const IconData image = WdSvgIcons.image;
  static const IconData file = WdSvgIcons.file;
  static const IconData video = LucideIcons.video;
  static const IconData location = LucideIcons.mapPin;
  static const IconData emoji = LucideIcons.smile;
  static const IconData quickReply = LucideIcons.zap;
  static const IconData note = WdSvgIcons.note;
  static const IconData reply = LucideIcons.replyDir;
  static const IconData forward = LucideIcons.forwardDir;
  static const IconData copy = LucideIcons.copy;
  static const IconData delete = LucideIcons.trash2;
  static const IconData sent = WdSvgIcons.check;
  static const IconData delivered = WdSvgIcons.checks;
  static const IconData read = WdSvgIcons.checks;
  static const IconData pending = WdSvgIcons.clock;
  static const IconData failed = WdSvgIcons.alert;
  static const IconData retry = LucideIcons.rotateCw;
  static const IconData download = LucideIcons.download;
  static const IconData play = WdSvgIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData call = WdSvgIcons.phone;
  static const IconData translate = LucideIcons.languages;

  // ---- 6.5 AI -------------------------------------------------------------------
  /// The only AI symbol (labels, hero, improve wording, suggestions).
  static const IconData ai = WdSvgIcons.ai;
  static const IconData aiAgent = LucideIcons.bot;
  static const IconData rewrite = LucideIcons.wandSparkles;
  static const IconData regenerate = WdSvgIcons.redo;
  static const IconData thumbsUp = LucideIcons.thumbsUp;
  static const IconData thumbsDown = LucideIcons.thumbsDown;
  static const IconData preview = WdSvgIcons.eye;
  static const IconData shorter = LucideIcons.minimize2;
  static const IconData formal = LucideIcons.briefcase;
  static const IconData friendly = LucideIcons.smilePlus;
  static const IconData spellcheck = LucideIcons.spellCheck;
  static const IconData bullets = LucideIcons.list;

  // ---- 6.6 Conversation actions & status --------------------------------------
  static const IconData claim = LucideIcons.hand;
  static const IconData assign = WdSvgIcons.userPlus;
  static const IconData transfer = LucideIcons.arrowLeftRight;
  static const IconData resolve = LucideIcons.circleCheck;
  static const IconData reopen = LucideIcons.rotateCcw;
  static const IconData snooze = LucideIcons.alarmClock;
  static const IconData priority = LucideIcons.flag;
  static const IconData mute = LucideIcons.bellOff;
  static const IconData block = WdSvgIcons.block;
  static const IconData undo = LucideIcons.undo2Dir;

  // ---- 6.7 Customer profile ---------------------------------------------------
  static const IconData customer = WdSvgIcons.user;
  static const IconData phone = WdSvgIcons.phone;
  static const IconData email = LucideIcons.mail;
  static const IconData city = LucideIcons.mapPin;
  static const IconData orders = LucideIcons.shoppingBag;
  static const IconData shipping = LucideIcons.truck;
  static const IconData package = LucideIcons.package;
  static const IconData payment = LucideIcons.creditCard;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData notes = LucideIcons.notebookPen;
  static const IconData vip = LucideIcons.crown;
  static const IconData rating = WdSvgIcons.star;

  // ---- 6.8 Dashboard & stats --------------------------------------------------
  static const IconData stats = LucideIcons.chartColumn;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;
  static const IconData responseTime = LucideIcons.timer;
  static const IconData team = WdSvgIcons.users;
  static const IconData waiting = LucideIcons.hourglass;
  static const IconData open = LucideIcons.messageCircleMore;
  static const IconData resolved = LucideIcons.circleCheckBig;
  static const IconData satisfaction = LucideIcons.heart;

  // ---- 6.9 Knowledge base -----------------------------------------------------
  static const IconData kb = WdSvgIcons.book;
  static const IconData qa = WdSvgIcons.qa;
  static const IconData kbFile = WdSvgIcons.file;
  static const IconData kbLink = WdSvgIcons.link;
  static const IconData upload = LucideIcons.upload;
  static const IconData unanswered = LucideIcons.circleHelp;
  static const IconData draft = LucideIcons.pencilLine;
  static const IconData edit = WdSvgIcons.edit;
  static const IconData add = WdSvgIcons.add;
  static const IconData merge = LucideIcons.merge;
  static const IconData versions = LucideIcons.history;

  // ---- 6.10 Notifications -----------------------------------------------------
  static const IconData bell = WdSvgIcons.bell;
  static const IconData bellDot = LucideIcons.bellDot;
  static const IconData mention = LucideIcons.atSign;
  static const IconData newMessage = LucideIcons.messageSquarePlus;
  static const IconData assignedToYou = LucideIcons.userRoundCheck;
  static const IconData slaBreach = LucideIcons.alarmClock;
  static const IconData markAllRead = WdSvgIcons.checks;
  static const IconData settings = LucideIcons.settings;

  // ---- 6.11 Channels & connection (UI icons; logos below) ---------------------
  static const IconData webChat = WdSvgIcons.globe;
  static const IconData connected = LucideIcons.wifi;
  static const IconData disconnected = LucideIcons.wifiOff;
  static const IconData qr = LucideIcons.qrCode;
  static const IconData device = LucideIcons.smartphone;
  static const IconData pairing = LucideIcons.keyRound;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData disconnect = LucideIcons.unplug;
  static const IconData templates = LucideIcons.layoutTemplate;
  static const IconData welcome = LucideIcons.handHeart;
  static const IconData away = LucideIcons.moon;

  // ---- 6.12 Account, auth & settings ------------------------------------------
  static const IconData lock = WdSvgIcons.lock;
  static const IconData password = LucideIcons.keyRound;
  static const IconData showPassword = WdSvgIcons.eye;
  static const IconData hidePassword = LucideIcons.eyeOff;
  static const IconData faceId = WdSvgIcons.faceId;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData workspace = LucideIcons.building2;
  static const IconData language = WdSvgIcons.globe;
  static const IconData theme = WdSvgIcons.theme;
  static const IconData themeDark = LucideIcons.moon;
  static const IconData notificationsSettings = LucideIcons.bellRing;
  static const IconData security = LucideIcons.shieldCheck;
  static const IconData billing = LucideIcons.creditCard;
  static const IconData help = LucideIcons.lifeBuoy;
  static const IconData tutorial = LucideIcons.circlePlay;
  static const IconData logout = WdSvgIcons.logout;
  static const IconData upgrade = LucideIcons.gem;
  static const IconData availability = LucideIcons.circleDot;

  // ---- 6.13 Feedback & system -------------------------------------------------
  static const IconData success = LucideIcons.circleCheck;
  static const IconData error = LucideIcons.circleX;
  static const IconData warning = WdSvgIcons.alert;
  static const IconData info = LucideIcons.info;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData empty = LucideIcons.inbox;
  static const IconData loadingFailed = LucideIcons.refreshCcw;

  // ---- §7 Channel logos (Simple Icons; never mirrored or recolored) -----------
  static const IconData whatsapp = SimpleIcons.whatsapp;
  static const IconData messenger = SimpleIcons.messenger;
  static const IconData instagram = SimpleIcons.instagram;
  static const IconData telegram = SimpleIcons.telegram;
  static const IconData sms = LucideIcons.messageSquareText;
  static const IconData otherChannel = LucideIcons.plug;

  // ---- App-specific (not in §6; Lucide, same family) --------------------------
  /// A conversation / message in general (not the Inbox tab).
  static const IconData conversation = WdSvgIcons.chat;
  static const IconData channels = LucideIcons.plug;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData compose = LucideIcons.squarePen;
  static const IconData unassign = LucideIcons.userMinus;
  static const IconData unblock = LucideIcons.lockOpen;
  static const IconData pinOff = LucideIcons.pinOff;
  static const IconData aiOff = LucideIcons.botOff;
  static const IconData album = LucideIcons.images;
  static const IconData contactCard = LucideIcons.contact;
  static const IconData sticker = LucideIcons.sticker;
  static const IconData voice = LucideIcons.audioLines;
  static const IconData saveToKb = LucideIcons.bookPlus;
  static const IconData share = LucideIcons.share2;
  static const IconData export = LucideIcons.download;
  static const IconData addReaction = LucideIcons.smilePlus;
  static const IconData phoneCall = LucideIcons.phoneCall;
  static const IconData maximize = LucideIcons.maximize;
  static const IconData filterX = LucideIcons.funnelX;
  static const IconData mailOpen = LucideIcons.mailOpen;
  static const IconData minus = LucideIcons.minus;
  static const IconData redo = WdSvgIcons.redo;
  static const IconData lightbulb = LucideIcons.lightbulb;
  static const IconData headphones = LucideIcons.headphones;
  static const IconData link = WdSvgIcons.link;
  static const IconData globe = WdSvgIcons.globe;
  static const IconData clock = WdSvgIcons.clock;
  static const IconData check = WdSvgIcons.check;
}
