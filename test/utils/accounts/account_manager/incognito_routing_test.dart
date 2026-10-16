import 'dart:io';

import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/accounts/account_manager/account_mgr.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

LoginAccount _account(int mid) => LoginAccount(
  BiliCookieJar.fromJson({
    'DedeUserID': '$mid',
    'bili_jct': 'csrf-$mid',
    'SESSDATA': 'session-$mid',
  }),
  'access-$mid',
  null,
);

void main() {
  late Directory tempDir;
  late LoginAccount mainAccount;
  late LoginAccount recommendAccount;
  late LoginAccount videoAccount;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('piliplus-incognito-test-');
    Hive.init(tempDir.path);
    GStorage.regAdapter();
    GStorage.setting = await Hive.openBox('setting');
    GStorage.localCache = await Hive.openBox('localCache');
    GStorage.video = await Hive.openBox('video');
  });

  setUp(() {
    mainAccount = _account(1001);
    recommendAccount = _account(1002);
    videoAccount = _account(1003);
    Accounts.accountMode[AccountType.main.index] = mainAccount;
    Accounts.accountMode[AccountType.recommend.index] = recommendAccount;
    Accounts.accountMode[AccountType.video.index] = videoAccount;
    Accounts.accountMode[AccountType.heartbeat.index] = AnonymousAccount();
  });

  tearDown(() {
    for (final type in AccountType.values) {
      Accounts.accountMode[type.index] = AnonymousAccount();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'incognito anonymizes search and video URL requests, not the main account',
    () {
      final cookiesBefore = mainAccount.cookieJar.toJson();

      expect(
        AccountManager.findAccountFor(Api.searchArchive),
        isA<AnonymousAccount>(),
      );
      expect(
        AccountManager.findAccountFor(Api.liveSearch),
        isA<AnonymousAccount>(),
      );
      expect(
        AccountManager.findAccountFor(Api.ugcUrl),
        isA<AnonymousAccount>(),
      );
      expect(
        AccountManager.findAccountFor(Api.tvPlayUrl),
        isA<AnonymousAccount>(),
      );
      expect(
        AccountManager.findAccountFor(Api.heartBeat),
        isA<AnonymousAccount>(),
      );
      expect(
        AccountManager.findAccountFor(Api.historyReport),
        isA<AnonymousAccount>(),
      );
      expect(Accounts.isAnonymity, isTrue);
      expect(Accounts.passiveAccessKey(AccountType.recommend), isNull);
      expect(Accounts.passiveAccessKey(AccountType.video), isNull);
      expect(
        AccountManager.findAccountFor(Api.feedDislike),
        same(recommendAccount),
      );
      expect(
        AccountManager.findAccountFor(Api.liveFeedback),
        same(recommendAccount),
      );
      expect(AccountManager.findAccountFor('/unclassified'), same(mainAccount));
      expect(Accounts.main, same(mainAccount));
      expect(mainAccount.cookieJar.toJson(), equals(cookiesBefore));
    },
  );

  test('outside incognito, configured recommendation and video accounts remain active', () {
    Accounts.accountMode[AccountType.heartbeat.index] = mainAccount;

    expect(Accounts.isAnonymity, isFalse);
    expect(
      Accounts.passiveAccessKey(AccountType.recommend),
      recommendAccount.accessKey,
    );
    expect(
      Accounts.passiveAccessKey(AccountType.video),
      videoAccount.accessKey,
    );
    expect(
      AccountManager.findAccountFor(Api.searchArchive),
      same(recommendAccount),
    );
    expect(AccountManager.findAccountFor(Api.ugcUrl), same(videoAccount));
  });
}
