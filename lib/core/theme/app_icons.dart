import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One outline icon family for all UI (Lucide, default stroke) — §12.2.
/// Directional icons use the `…Dir` variants, which mirror under RTL (§2.7).
/// Brand glyphs (channels) come from Font Awesome Brands and never mirror.
abstract final class AppIcons {
  // Directional (mirror in RTL). Lucide glyphs are drawn for LTR, so
  // "back" points to the start edge.
  static const IconData back = LucideIcons.arrowLeftDir;
  static const IconData chevronEnd = LucideIcons.chevronRightDir;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData send = LucideIcons.sendHorizontalDir;
  static const IconData reply = LucideIcons.replyDir;
  static const IconData undo = LucideIcons.undo2Dir;
  static const IconData jumpDown = LucideIcons.arrowDown;

  // Tabs
  static const IconData conversations = LucideIcons.messagesSquare;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData knowledge = LucideIcons.bookOpen;
  static const IconData account = LucideIcons.circleUser;

  // Actions
  static const IconData sparkle = LucideIcons.sparkles;
  static const IconData claim = LucideIcons.check;
  static const IconData assign = LucideIcons.userPlus;
  static const IconData snooze = LucideIcons.alarmClock;
  static const IconData moon = LucideIcons.moon;
  static const IconData video = LucideIcons.video;
  static const IconData album = LucideIcons.images;
  static const IconData contactCard = LucideIcons.contact;
  static const IconData template = LucideIcons.layoutTemplate;
  static const IconData download = LucideIcons.download;
  static const IconData thumbsUp = LucideIcons.thumbsUp;
  static const IconData thumbsDown = LucideIcons.thumbsDown;
  static const IconData forward = LucideIcons.forward;
  static const IconData saveToKb = LucideIcons.bookPlus;
  static const IconData share = LucideIcons.share2;
  static const IconData unblock = LucideIcons.lockOpen;
  static const IconData unassign = LucideIcons.userMinus;
  static const IconData aiOff = LucideIcons.botOff;
  static const IconData stop = LucideIcons.circleStop;
  static const IconData mention = LucideIcons.atSign;
  static const IconData addReaction = LucideIcons.smilePlus;
  static const IconData phoneCall = LucideIcons.phoneCall;
  static const IconData pin = LucideIcons.pin;
  static const IconData pinOff = LucideIcons.pinOff;
  static const IconData bag = LucideIcons.shoppingBag;
  static const IconData maximize = LucideIcons.maximize;
  static const IconData filterX = LucideIcons.funnelX;
  static const IconData archive = LucideIcons.archive;
  static const IconData mailOpen = LucideIcons.mailOpen;
  static const IconData sticker = LucideIcons.sticker;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData resolve = LucideIcons.circleCheck;
  static const IconData search = LucideIcons.search;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsOff = LucideIcons.bellOff;
  static const IconData plus = LucideIcons.plus;
  static const IconData mic = LucideIcons.mic;
  static const IconData close = LucideIcons.x;
  static const IconData more = LucideIcons.ellipsisVertical;
  static const IconData call = LucideIcons.phone;
  static const IconData edit = LucideIcons.pencil;
  static const IconData compose = LucideIcons.squarePen;
  static const IconData regenerate = LucideIcons.refreshCw;
  static const IconData wand = LucideIcons.wandSparkles;
  static const IconData note = LucideIcons.stickyNote;
  static const IconData tag = LucideIcons.tag;
  static const IconData flag = LucideIcons.flag;
  static const IconData block = LucideIcons.ban;
  static const IconData export = LucideIcons.download;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData copy = LucideIcons.copy;
  static const IconData delete = LucideIcons.trash2;
  static const IconData logout = LucideIcons.logOutDir;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData alertTriangle = LucideIcons.triangleAlert;
  static const IconData scanFace = LucideIcons.scanFace;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData lock = LucideIcons.lock;
  static const IconData mail = LucideIcons.mail;
  static const IconData user = LucideIcons.userRound;
  static const IconData users = LucideIcons.users;
  static const IconData userCheck = LucideIcons.userRoundCheck;
  static const IconData transfer = LucideIcons.arrowLeftRight;
  static const IconData info = LucideIcons.info;
  static const IconData alert = LucideIcons.circleAlert;
  static const IconData check = LucideIcons.check;
  static const IconData checkDouble = LucideIcons.checkCheck;
  static const IconData clock = LucideIcons.clock;
  static const IconData hourglass = LucideIcons.hourglass;
  static const IconData history = LucideIcons.history;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData wifiOff = LucideIcons.wifiOff;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;
  static const IconData bot = LucideIcons.bot;
  static const IconData zap = LucideIcons.zap;
  static const IconData lightbulb = LucideIcons.lightbulb;
  static const IconData star = LucideIcons.star;
  static const IconData link = LucideIcons.link;
  static const IconData smile = LucideIcons.smile;

  // AI Rewrite styles
  static const IconData briefcase = LucideIcons.briefcase;
  static const IconData minus = LucideIcons.minus;
  static const IconData heartHandshake = LucideIcons.heartHandshake;
  static const IconData spellCheck = LucideIcons.spellCheck;
  static const IconData redo = LucideIcons.redo2;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;

  // Media
  static const IconData image = LucideIcons.image;
  static const IconData camera = LucideIcons.camera;
  static const IconData file = LucideIcons.fileText;
  static const IconData location = LucideIcons.mapPin;
  static const IconData attach = LucideIcons.paperclip;
  static const IconData voice = LucideIcons.audioLines;
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;

  // Settings
  static const IconData channels = LucideIcons.plug;
  static const IconData subscription = LucideIcons.creditCard;
  static const IconData language = LucideIcons.languages;
  static const IconData appearance = LucideIcons.sunMoon;
  static const IconData help = LucideIcons.circleHelp;
  static const IconData shield = LucideIcons.shield;
  static const IconData qrCode = LucideIcons.qrCode;
  static const IconData smartphone = LucideIcons.smartphone;
  static const IconData globe = LucideIcons.globe;
  static const IconData chart = LucideIcons.chartColumn;
  static const IconData headphones = LucideIcons.headphones;

  // Channel glyphs
  static const IconData whatsapp = FontAwesomeIcons.whatsapp;
  static const IconData messenger = FontAwesomeIcons.facebookMessenger;
  static const IconData instagram = FontAwesomeIcons.instagram;
  static const IconData telegram = FontAwesomeIcons.telegram;
  static const IconData webChat = LucideIcons.messageCircle;
  static const IconData email = LucideIcons.mail;
  static const IconData sms = LucideIcons.messageSquareText;
  static const IconData otherChannel = LucideIcons.plug;
}
