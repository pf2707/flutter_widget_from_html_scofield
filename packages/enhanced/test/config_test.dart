import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_widget_from_html_core/src/internal/tsh_widget.dart';
import 'package:html/dom.dart' as dom;

import '../../fwfh_url_launcher/test/_.dart' as fwfh_url_launcher;
import '_.dart' as helper;

Future<String> explain(WidgetTester t, HtmlWidget hw) =>
    helper.explain(t, null, hw: hw);

void main() {
  group('buildAsync', () {
    Future<String?> explain(
      WidgetTester tester,
      String html, {
      bool? buildAsync,
    }) =>
        tester.runAsync(() => helper.explain(tester, null,
            hw: HtmlWidget(
              html,
              buildAsync: buildAsync,
              key: helper.hwKey,
            )));

    testWidgets('uses FutureBuilder', (WidgetTester tester) async {
      const html = 'Foo';
      final explained = await explain(tester, html, buildAsync: true);
      expect(explained, equals('[FutureBuilder:[RichText:(:$html)]]'));
    });

    testWidgets('skips FutureBuilder', (WidgetTester tester) async {
      const html = 'Foo';
      final explained = await explain(tester, html, buildAsync: false);
      expect(explained, equals('[RichText:(:$html)]'));
    });

    testWidgets('uses FutureBuilder automatically', (tester) async {
      final html = 'Foo' * kShouldBuildAsync;
      final explained = await explain(tester, html);
      expect(explained, equals('[FutureBuilder:[RichText:(:$html)]]'));
    });
  });

  group('buildAsyncBuilder', () {
    Future<String?> explain(
      WidgetTester tester,
      String html, {
      AsyncWidgetBuilder<Widget>? buildAsyncBuilder,
      required bool withData,
    }) =>
        tester.runAsync(() => helper.explain(tester, null,
            buildFutureBuilderWithData: withData,
            hw: HtmlWidget(
              html,
              buildAsync: true,
              buildAsyncBuilder: buildAsyncBuilder,
              key: helper.hwKey,
            )));

    group('default', () {
      testWidgets('renders data', (WidgetTester tester) async {
        const html = 'Foo';
        final explained = await explain(tester, html, withData: true);
        expect(explained, equals('[FutureBuilder:[RichText:(:$html)]]'));
      });

      testWidgets('renders CircularProgressIndicator', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        const html = 'Foo';
        final explained = await explain(tester, html, withData: false);
        expect(
            explained,
            equals('[FutureBuilder:'
                '[Center:child='
                '[Padding:(8,8,8,8),child='
                '[CircularProgressIndicator]'
                ']]]'));
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('renders CupertinoActivityIndicator', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        const html = 'Foo';
        final explained = await explain(tester, html, withData: false);
        expect(
            explained,
            equals('[FutureBuilder:'
                '[Center:child='
                '[Padding:(8,8,8,8),child='
                '[CupertinoActivityIndicator]'
                ']]]'));
        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('custom', () {
      Widget buildAsyncBuilder(
              BuildContext context, AsyncSnapshot<Widget> snapshot) =>
          snapshot.data ?? const Text('No data');

      testWidgets('renders data', (WidgetTester tester) async {
        const html = 'Foo';
        final explained = await explain(
          tester,
          html,
          buildAsyncBuilder: buildAsyncBuilder,
          withData: true,
        );
        expect(explained, equals('[FutureBuilder:[RichText:(:$html)]]'));
      });

      testWidgets('renders indicator', (WidgetTester tester) async {
        const html = 'Foo';
        final explained = await explain(
          tester,
          html,
          buildAsyncBuilder: buildAsyncBuilder,
          withData: false,
        );
        expect(explained, equals('[FutureBuilder:[Text:No data]]'));
      });
    });
  });

  group('enableCaching', () {
    Future<String?> explain(
      WidgetTester tester,
      String html, {
      Uri? baseUrl,
      bool? buildAsync,
      required bool enableCaching,
      Color hyperlinkColor = const Color.fromRGBO(0, 0, 255, 1),
      RebuildTriggers? rebuildTriggers,
      TextStyle? textStyle,
      bool webView = false,
      bool webViewJs = true,
    }) =>
        helper.explain(tester, null,
            hw: HtmlWidget(
              html,
              baseUrl: baseUrl,
              buildAsync: buildAsync,
              enableCaching: enableCaching,
              hyperlinkColor: hyperlinkColor,
              key: helper.hwKey,
              rebuildTriggers: rebuildTriggers,
              textStyle: textStyle ?? const TextStyle(),
              webView: webView,
              webViewJs: webViewJs,
            ));

    void _expect(Widget? built1, Widget? built2, Matcher matcher) {
      final widget1 = (built1! as TshWidget).child;
      final widget2 = (built2! as TshWidget).child;
      expect(widget1 == widget2, matcher);
    }

    testWidgets('caches built widget tree', (WidgetTester tester) async {
      const html = 'Foo';
      final explained = await explain(tester, html, enableCaching: true);
      expect(explained, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, enableCaching: true);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isTrue);
    });

    testWidgets('rebuild new html', (WidgetTester tester) async {
      const html1 = 'Foo';
      const html2 = 'Bar';

      final explained1 = await explain(tester, html1, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));

      final explained2 = await explain(tester, html2, enableCaching: true);
      expect(explained2, equals('[RichText:(:Bar)]'));
    });

    testWidgets('rebuild new baseUrl', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(
        tester,
        html,
        baseUrl: Uri.http('domain.com', ''),
        enableCaching: true,
      );
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new buildAsync', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, buildAsync: false, enableCaching: true);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new enableCaching', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, enableCaching: false);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new hyperlinkColor', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(
        tester,
        html,
        enableCaching: true,
        hyperlinkColor: const Color.fromRGBO(255, 0, 0, 1),
      );
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new rebuildTriggers', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(
        tester,
        html,
        enableCaching: true,
        rebuildTriggers: RebuildTriggers([1]),
      );
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(
        tester,
        html,
        enableCaching: true,
        rebuildTriggers: RebuildTriggers([2]),
      );
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new textStyle', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));

      final explained2 = await explain(
        tester,
        html,
        enableCaching: true,
        textStyle: const TextStyle(fontSize: 20),
      );
      expect(explained2, equals('[RichText:(@20.0:Foo)]'));
    });

    testWidgets('rebuild new webView', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, enableCaching: true, webView: true);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('rebuild new webViewJs', (tester) async {
      const html = 'Foo';

      final explained1 = await explain(tester, html, enableCaching: true);
      expect(explained1, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, enableCaching: true, webViewJs: false);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });

    testWidgets('skips caching', (WidgetTester tester) async {
      const html = 'Foo';
      final explained = await explain(tester, html, enableCaching: false);
      expect(explained, equals('[RichText:(:Foo)]'));
      final built1 = helper.buildCurrentState();

      await explain(tester, html, enableCaching: false);
      final built2 = helper.buildCurrentState();
      _expect(built1, built2, isFalse);
    });
  });

  group('baseUrl', () {
    final baseUrl = Uri.parse('http://base.com/path/');
    const html = '<img src="image.png" alt="image dot png" />';

    testWidgets('renders without value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[RichText:(:image dot png)]'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final explained = await explain(
        tester,
        HtmlWidget(html, baseUrl: baseUrl, key: helper.hwKey),
      );
      expect(
          explained,
          equals('[CssSizing:height≥0.0,height=auto,width≥0.0,width=auto,child='
              '[Image:image=CachedNetworkImageProvider("http://base.com/path/image.png", scale: 1.0),'
              'semanticLabel=image dot png'
              ']]'));
    });
  });

  group('customStylesBuilder', () {
    const html = 'Hello <span class="name">World</span>!';

    testWidgets('renders without value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[RichText:(:Hello World!)]'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final explained = await explain(
        tester,
        HtmlWidget(
          html,
          customStylesBuilder: (e) =>
              e.classes.contains('name') ? {'color': 'red'} : null,
          key: helper.hwKey,
        ),
      );
      expect(explained, equals('[RichText:(:Hello (#FFFF0000:World)(:!))]'));
    });
  });

  group('customWidgetBuilder', () {
    Widget? customWidgetBuilder(dom.Element element) => const Text('Bar');
    const html = '<span>Foo</span>';

    testWidgets('renders without value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[RichText:(:Foo)]'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final explained = await explain(
        tester,
        HtmlWidget(
          html,
          customWidgetBuilder: customWidgetBuilder,
          key: helper.hwKey,
        ),
      );
      expect(explained, equals('[Text:Bar]'));
    });
  });

  group('customWidgetBuilder (VIDEO)', () {
    Widget? customWidgetBuilder(dom.Element e) =>
        e.localName == 'video' ? const Text('Bar') : null;
    const src = 'http://domain.com/video.mp4';
    const html = 'Foo <video width="21" height="9"><source src="$src"></video>';

    testWidgets('renders without value', (WidgetTester tester) async {
      final explained =
          await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(
          explained,
          equals('[Column:children='
              '[RichText:(:Foo)],'
              '[VideoPlayer:url=http://domain.com/video.mp4,aspectRatio=2.33,autoResize=false]'
              ']'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final e = await explain(
        tester,
        HtmlWidget(
          html,
          customWidgetBuilder: customWidgetBuilder,
          key: helper.hwKey,
        ),
      );
      expect(e, equals('[Column:children=[RichText:(:Foo)],[Text:Bar]]'));
    });
  });

  group('hyperlinkColor', () {
    const hyperlinkColor = Color.fromRGBO(255, 0, 0, 1);
    const html = '<a>Foo</a>';

    testWidgets('renders without value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[RichText:(#FF123456+u:Foo)]'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final explained = await explain(
        tester,
        HtmlWidget(html, hyperlinkColor: hyperlinkColor, key: helper.hwKey),
      );
      expect(explained, equals('[RichText:(#FFFF0000+u:Foo)]'));
    });
  });

  group('onTapUrl', () {
    setUp(fwfh_url_launcher.mockSetup);
    tearDown(fwfh_url_launcher.mockTearDown);

    testWidgets('triggers callback (returns void)', (tester) async {
      const href = 'returns-void';
      final urls = <String>[];

      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>', onTapUrl: urls.add),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(urls, equals(const [href]));
      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const []));
    });

    testWidgets('triggers callback (returns false)', (tester) async {
      const href = 'returns-false';
      final urls = <String>[];

      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>', onTapUrl: (url) {
          urls.add(url);
          return false;
        }),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(urls, equals(const [href]));
      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const [href]));
    });

    testWidgets('triggers callback (returns true)', (tester) async {
      const href = 'returns-true';
      final urls = <String>[];

      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>', onTapUrl: (url) {
          urls.add(url);
          return true;
        }),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(urls, equals(const [href]));
      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const []));
    });

    testWidgets('triggers callback (async false)', (tester) async {
      const href = 'async-false';
      final urls = <String>[];

      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>', onTapUrl: (url) async {
          urls.add(url);
          return false;
        }),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(urls, equals(const [href]));
      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const [href]));
    });

    testWidgets('triggers callback (async true)', (tester) async {
      const href = 'async-true';
      final urls = <String>[];

      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>', onTapUrl: (url) async {
          urls.add(url);
          return true;
        }),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(urls, equals(const [href]));
      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const []));
    });

    testWidgets('default handler', (WidgetTester tester) async {
      const href = 'default';
      await explain(
        tester,
        HtmlWidget('<a href="$href">Tap me</a>'),
      );
      await tester.pumpAndSettle();
      expect(await helper.tapText(tester, 'Tap me'), equals(1));

      expect(fwfh_url_launcher.mockGetLaunchUrls(), equals(const [href]));
    });
  });

  group('textStyle', () {
    const html = 'Foo';

    testWidgets('renders without value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[RichText:(:Foo)]'));
    });

    testWidgets('renders with value', (WidgetTester tester) async {
      final e = await explain(
        tester,
        HtmlWidget(
          html,
          key: helper.hwKey,
          textStyle: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
      expect(e, equals('[RichText:(+i:Foo)]'));
    });
  });

  group('webView', () {
    const webViewSrc = 'http://domain.com';
    const html = '<iframe src="$webViewSrc"></iframe>';
    const webViewDefaultAspectRatio = '1.78';

    testWidgets('renders false value', (WidgetTester tester) async {
      final e = await explain(tester, HtmlWidget(html, key: helper.hwKey));
      expect(e, equals('[GestureDetector:child=[Text:$webViewSrc]]'));
    });

    testWidgets('renders true value', (WidgetTester tester) async {
      final explained = await explain(
          tester,
          HtmlWidget(
            html,
            key: helper.hwKey,
            webView: true,
          ));
      expect(
          explained,
          equals('[WebView:'
              'url=$webViewSrc,'
              'aspectRatio=$webViewDefaultAspectRatio,'
              'autoResize=true'
              ']'));
    });

    group('webViewDebuggingEnabled', () {
      testWidgets('renders true value', (WidgetTester tester) async {
        final explained = await explain(
            tester,
            HtmlWidget(
              html,
              key: helper.hwKey,
              webView: true,
              webViewDebuggingEnabled: true,
            ));
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true,'
                'debuggingEnabled=true'
                ']'));
      });

      testWidgets('renders false value', (WidgetTester tester) async {
        final explained = await explain(
          tester,
          HtmlWidget(html, key: helper.hwKey, webView: true),
        );
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true'
                ']'));
      });
    });

    group('webViewJs', () {
      testWidgets('renders true value', (WidgetTester tester) async {
        final explained = await explain(
          tester,
          HtmlWidget(html, key: helper.hwKey, webView: true),
        );
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true'
                ']'));
      });

      testWidgets('renders false value', (WidgetTester tester) async {
        final explained = await explain(
            tester,
            HtmlWidget(
              html,
              key: helper.hwKey,
              webView: true,
              webViewJs: false,
            ));
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'js=false'
                ']'));
      });
    });

    group('webViewMediaPlaybackAlwaysAllow', () {
      testWidgets('renders true value', (WidgetTester tester) async {
        final explained = await explain(
            tester,
            HtmlWidget(
              html,
              key: helper.hwKey,
              webView: true,
              webViewMediaPlaybackAlwaysAllow: true,
            ));
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true,'
                'mediaPlaybackAlwaysAllow=true'
                ']'));
      });

      testWidgets('renders false value', (WidgetTester tester) async {
        final explained = await explain(
          tester,
          HtmlWidget(html, key: helper.hwKey, webView: true),
        );
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true'
                ']'));
      });
    });

    group('webViewUserAgent', () {
      testWidgets('renders string', (WidgetTester tester) async {
        final explained = await explain(
            tester,
            HtmlWidget(
              html,
              key: helper.hwKey,
              webView: true,
              webViewUserAgent: 'Foo',
            ));
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true,'
                'userAgent=Foo'
                ']'));
      });

      testWidgets('renders null value', (WidgetTester tester) async {
        final explained = await explain(
          tester,
          HtmlWidget(html, key: helper.hwKey, webView: true),
        );
        expect(
            explained,
            equals('[WebView:'
                'url=$webViewSrc,'
                'aspectRatio=$webViewDefaultAspectRatio,'
                'autoResize=true'
                ']'));
      });
    });
  });
}
