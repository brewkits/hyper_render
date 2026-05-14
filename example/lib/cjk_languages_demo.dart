import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

// =============================================================================
// CJK Languages Demo
//
// Showcases HyperRender rendering real-world CJK content:
//   • Simplified Chinese (简体中文) — tech article, table, blockquote
//   • Traditional Chinese (繁體中文) — classical literature, poetry
//   • Korean (한국어) — news article, definition list, mixed Latin/Hangul
// =============================================================================

class CjkLanguagesDemo extends StatefulWidget {
  const CjkLanguagesDemo({super.key});

  @override
  State<CjkLanguagesDemo> createState() => _CjkLanguagesDemoState();
}

class _CjkLanguagesDemoState extends State<CjkLanguagesDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('中文 · 繁體 · 한국어'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '简体中文'),
            Tab(text: '繁體中文'),
            Tab(text: '한국어'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SimplifiedChineseTab(),
          _TraditionalChineseTab(),
          _KoreanTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Simplified Chinese (简体中文)
// ─────────────────────────────────────────────────────────────────────────────

class _SimplifiedChineseTab extends StatelessWidget {
  const _SimplifiedChineseTab();

  static const _html = '''
<div style="font-family: sans-serif; line-height: 1.8; color: #333;">

  <div style="background: linear-gradient(135deg, #1565C0, #0D47A1);
              padding: 24px 20px; border-radius: 12px; margin-bottom: 28px; box-shadow: 0 4px 12px rgba(21,101,192,0.15);">
    <h1 style="color: white; margin: 0; font-size: 24px; font-weight: 700;">Flutter 跨平台开发指南</h1>
    <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0; font-size: 15px;">
      技术深度解析 · 2024年版
    </p>
  </div>

  <h2 style="color: #1565C0; font-size: 20px; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E3F2FD;">一、核心优势</h2>
  <p style="margin: 0 0 20px 0; font-size: 16px;">
    Flutter 是由 Google 开发的开源 UI 框架，可以从<strong>单一代码库</strong>构建适用于
    移动端、Web 和桌面的精美原生编译应用。与传统的跨平台方案不同，Flutter 使用自己的
    渲染引擎 <em>Skia / Impeller</em>，完全不依赖平台原生控件。
  </p>

  <blockquote style="border-left: 4px solid #1565C0; margin: 0 0 24px 0;
                     padding: 16px 20px; background: #E3F2FD; border-radius: 0 8px 8px 0;">
    <p style="margin: 0; font-style: italic; color: #0D47A1; font-size: 16px;">
      "一次编写，到处运行——这不再只是口号，Flutter 让它成为现实。"
    </p>
    <p style="margin: 12px 0 0 0; font-size: 14px; color: #1565C0;">— Google 开发者大会，2023</p>
  </blockquote>

  <h2 style="color: #1565C0; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E3F2FD;">二、主要特性对比</h2>
  <div style="margin-bottom: 24px;">
    <table style="width: 100%; border-collapse: collapse; font-size: 14px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
      <tr style="background: #1565C0; color: white;">
        <th style="padding: 12px 10px; text-align: left;">框架</th>
        <th style="padding: 12px 10px; text-align: center;">热重载</th>
        <th style="padding: 12px 10px; text-align: center;">渲染引擎</th>
        <th style="padding: 12px 10px; text-align: center;">性能</th>
      </tr>
      <tr style="background: #E3F2FD;">
        <td style="padding: 12px 10px; font-weight: bold; color: #1565C0;">Flutter</td>
        <td style="padding: 12px 10px; text-align: center;">✅ 亚秒级</td>
        <td style="padding: 12px 10px; text-align: center;">自研 Impeller</td>
        <td style="padding: 12px 10px; text-align: center; color: #2E7D32;">⭐⭐⭐⭐⭐</td>
      </tr>
      <tr style="background: white; border-bottom: 1px solid #EEEEEE;">
        <td style="padding: 12px 10px; font-weight: bold;">React Native</td>
        <td style="padding: 12px 10px; text-align: center;">✅ Fast Refresh</td>
        <td style="padding: 12px 10px; text-align: center;">平台原生</td>
        <td style="padding: 12px 10px; text-align: center; color: #F57C00;">⭐⭐⭐⭐</td>
      </tr>
      <tr style="background: #F5F5F5;">
        <td style="padding: 12px 10px; font-weight: bold;">Xamarin</td>
        <td style="padding: 12px 10px; text-align: center;">⚠️ 有限</td>
        <td style="padding: 12px 10px; text-align: center;">平台原生</td>
        <td style="padding: 12px 10px; text-align: center; color: #F57C00;">⭐⭐⭐</td>
      </tr>
    </table>
  </div>

  <h2 style="color: #1565C0; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E3F2FD;">三、Dart 语言示例</h2>
  <pre style="background: #1E1E2E; color: #CDD6F4; padding: 16px; border-radius: 10px;
              font-size: 14px; overflow: auto; line-height: 1.6; margin-bottom: 24px;"><code>// 异步编程示例
Future&lt;void&gt; 加载用户数据() async {
  try {
    final 数据 = await 网络请求('/api/用户');
    setState(() =&gt; 用户列表 = 数据);
  } catch (错误) {
    print('加载失败: \$错误');
  }
}</code></pre>

  <h2 style="color: #1565C0; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E3F2FD;">四、生态系统</h2>
  <ul style="margin: 0 0 24px 0; padding-left: 24px; line-height: 2.2; font-size: 16px;">
    <li><strong>pub.dev</strong> — 超过 30,000 个开源 package</li>
    <li><strong>Flutter DevTools</strong> — 强大的性能分析和调试工具</li>
    <li><strong>Firebase</strong> — 完整的后端服务集成</li>
    <li><strong>Platform Channels</strong> — 无缝调用原生 iOS / Android API</li>
    <li><strong>Widget 测试</strong> — 完整的 UI 自动化测试支持</li>
  </ul>

  <div style="background: #E8F5E9; border-left: 4px solid #4CAF50; border-radius: 0 8px 8px 0;
              padding: 16px 20px; margin-top: 32px; box-shadow: 0 2px 8px rgba(76,175,80,0.1);">
    <p style="margin: 0; color: #1B5E20; font-size: 15px; line-height: 1.6;">
      💡 <strong>小贴士：</strong>在中文排版中，HyperRender 会自动处理汉字间距、
      标点禁则规则（禁止在行首出现句号、逗号等标点），以及中英文混排时的间距优化。
    </p>
  </div>

</div>
''';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: HyperViewer(html: _html, selectable: true),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Traditional Chinese (繁體中文)
// ─────────────────────────────────────────────────────────────────────────────

class _TraditionalChineseTab extends StatelessWidget {
  const _TraditionalChineseTab();

  static const _html = '''
<div style="font-family: sans-serif; line-height: 2.0; color: #333;">

  <div style="background: linear-gradient(135deg, #880E4F, #6A1B4D);
              padding: 24px 20px; border-radius: 12px; margin-bottom: 28px; box-shadow: 0 4px 12px rgba(136,14,79,0.15);">
    <h1 style="color: white; margin: 0; font-size: 24px; letter-spacing: 2px; font-weight: 700;">古典文學選粹</h1>
    <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0; font-size: 14px; letter-spacing: 1px;">
      唐詩 · 宋詞 · 古文名篇
    </p>
  </div>

  <h2 style="color: #880E4F; font-size: 19px; letter-spacing: 1px; margin: 0 0 16px 0; padding-bottom: 8px; border-bottom: 1px solid #FCE4EC;">
    〈靜夜思〉— 李白
  </h2>
  <div style="background: #FCE4EC; border-radius: 0 12px 12px 0; padding: 24px 20px; margin-bottom: 32px;
              border-left: 4px solid #C2185B;">
    <p style="font-size: 22px; letter-spacing: 4px; line-height: 2.6; margin: 0;
              text-align: center; color: #1A1A1A;">
      床前明月光，<br/>
      疑是地上霜。<br/>
      舉頭望明月，<br/>
      低頭思故鄉。
    </p>
    <p style="margin: 20px 0 0 0; font-size: 14px; color: #880E4F; text-align: right;">
      —— 唐 · 李白（701—762年）
    </p>
  </div>

  <h2 style="color: #880E4F; font-size: 19px; letter-spacing: 1px; margin: 0 0 16px 0; padding-bottom: 8px; border-bottom: 1px solid #FCE4EC;">
    〈水調歌頭〉— 蘇軾
  </h2>
  <div style="background: #F3E5F5; border-radius: 0 12px 12px 0; padding: 24px 20px; margin-bottom: 32px;
              border-left: 4px solid #7B1FA2;">
    <p style="font-size: 18px; letter-spacing: 3px; line-height: 2.6; margin: 0; color: #1A1A1A;">
      明月幾時有？把酒問青天。<br/>
      不知天上宮闕，今夕是何年。<br/>
      我欲乘風歸去，又恐瓊樓玉宇，<br/>
      高處不勝寒。<br/>
      起舞弄清影，何似在人間。
    </p>
    <p style="margin: 16px 0 4px; font-size: 18px; letter-spacing: 3px; line-height: 2.6; color: #1A1A1A;">
      轉朱閣，低綺戶，照無眠。<br/>
      不應有恨，何事長向別時圓？<br/>
      人有悲歡離合，月有陰晴圓缺，<br/>
      此事古難全。<br/>
      但願人長久，千里共嬋娟。
    </p>
    <p style="margin: 20px 0 0 0; font-size: 14px; color: #7B1FA2; text-align: right;">
      —— 宋 · 蘇軾（1037—1101年）
    </p>
  </div>

  <h2 style="color: #880E4F; font-size: 19px; letter-spacing: 1px; margin: 0 0 16px 0; padding-bottom: 8px; border-bottom: 1px solid #FCE4EC;">
    古文經典注釋
  </h2>
  <div style="margin-bottom: 24px;">
    <table style="width: 100%; border-collapse: collapse; font-size: 15px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
      <tr style="background: #880E4F; color: white;">
        <th style="padding: 12px 10px; text-align: left;">詞語</th>
        <th style="padding: 12px 10px; text-align: left;">注音</th>
        <th style="padding: 12px 10px; text-align: left;">釋義</th>
      </tr>
      <tr style="background: #FCE4EC;">
        <td style="padding: 12px 10px; font-weight: bold; font-size: 17px;">嬋娟</td>
        <td style="padding: 12px 10px; color: #C2185B;">chán juān</td>
        <td style="padding: 12px 10px;">美好、指月亮；亦喻思念之人</td>
      </tr>
      <tr style="background: white; border-bottom: 1px solid #F8BBD0;">
        <td style="padding: 12px 10px; font-weight: bold; font-size: 17px;">瓊樓玉宇</td>
        <td style="padding: 12px 10px; color: #C2185B;">qióng lóu yù yǔ</td>
        <td style="padding: 12px 10px;">形容仙境中美麗的宮殿樓閣</td>
      </tr>
      <tr style="background: #FCE4EC;">
        <td style="padding: 12px 10px; font-weight: bold; font-size: 17px;">綺戶</td>
        <td style="padding: 12px 10px; color: #C2185B;">qǐ hù</td>
        <td style="padding: 12px 10px;">雕刻精美的門窗；泛指華麗的居所</td>
      </tr>
    </table>
  </div>

  <div style="background: #F3E5F5; border-left: 4px solid #8E24AA; border-radius: 0 8px 8px 0;
              padding: 16px 20px; margin-top: 32px; box-shadow: 0 2px 8px rgba(142,36,170,0.1);">
    <p style="margin: 0; color: #4A148C; font-size: 15px; line-height: 1.8;">
      📖 <strong>排版說明：</strong>HyperRender 支援繁體中文的正確渲染，包含
      標點符號禁則（避頭尾規則）、全形標點與半形英數混排間距，以及
      高密度漢字文本的精確換行計算。
    </p>
  </div>

</div>
''';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: HyperViewer(html: _html, selectable: true),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Korean (한국어)
// ─────────────────────────────────────────────────────────────────────────────

class _KoreanTab extends StatelessWidget {
  const _KoreanTab();

  static const _html = '''
<div style="font-family: sans-serif; line-height: 1.9; color: #333;">

  <div style="background: linear-gradient(135deg, #004D40, #00695C);
              padding: 24px 20px; border-radius: 12px; margin-bottom: 28px; box-shadow: 0 4px 12px rgba(0,77,64,0.15);">
    <h1 style="color: white; margin: 0; font-size: 24px; font-weight: 700;">모바일 앱 개발 트렌드</h1>
    <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0; font-size: 15px;">
      2024년 기술 동향 분석 리포트
    </p>
  </div>

  <h2 style="color: #004D40; font-size: 20px; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E0F2F1;">📱 크로스플랫폼의 부상</h2>
  <p style="margin: 0 0 20px 0; font-size: 16px;">
    최근 몇 년간 <strong>크로스플랫폼 개발 프레임워크</strong>가 급격히 성장했습니다.
    Flutter, React Native, Kotlin Multiplatform 등의 프레임워크가 iOS와 Android를 동시에
    지원하면서 개발 비용을 크게 줄일 수 있게 되었습니다.
  </p>

  <blockquote style="border-left: 4px solid #00897B; margin: 0 0 24px 0;
                     padding: 16px 20px; background: #E0F2F1; border-radius: 0 8px 8px 0;">
    <p style="margin: 0; color: #004D40; font-style: italic; font-size: 16px;">
      "Flutter는 단순한 프레임워크가 아니라, 새로운 방식의 UI 패러다임입니다.
       Dart 언어의 성능과 Hot Reload의 편의성이 결합되어 생산성을 극대화합니다."
    </p>
    <p style="margin: 12px 0 0 0; font-size: 14px; color: #00897B;">— Google I/O 2024</p>
  </blockquote>

  <h2 style="color: #004D40; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E0F2F1;">📊 주요 프레임워크 비교</h2>
  <div style="margin-bottom: 24px;">
    <table style="width: 100%; border-collapse: collapse; font-size: 14px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
      <tr style="background: #004D40; color: white;">
        <th style="padding: 12px 10px; text-align: left;">프레임워크</th>
        <th style="padding: 12px 10px; text-align: center;">언어</th>
        <th style="padding: 12px 10px; text-align: center;">성능</th>
        <th style="padding: 12px 10px; text-align: center;">학습 난이도</th>
      </tr>
      <tr style="background: #E0F2F1;">
        <td style="padding: 12px 10px; font-weight: bold; color: #004D40;">Flutter</td>
        <td style="padding: 12px 10px; text-align: center;">Dart</td>
        <td style="padding: 12px 10px; text-align: center; color: #2E7D32;">매우 우수</td>
        <td style="padding: 12px 10px; text-align: center;">중간</td>
      </tr>
      <tr style="background: white; border-bottom: 1px solid #EEEEEE;">
        <td style="padding: 12px 10px; font-weight: bold;">React Native</td>
        <td style="padding: 12px 10px; text-align: center;">JavaScript</td>
        <td style="padding: 12px 10px; text-align: center; color: #F57C00;">우수</td>
        <td style="padding: 12px 10px; text-align: center;">낮음</td>
      </tr>
      <tr style="background: #E0F2F1;">
        <td style="padding: 12px 10px; font-weight: bold;">KMP</td>
        <td style="padding: 12px 10px; text-align: center;">Kotlin</td>
        <td style="padding: 12px 10px; text-align: center; color: #2E7D32;">네이티브 수준</td>
        <td style="padding: 12px 10px; text-align: center;">높음</td>
      </tr>
    </table>
  </div>

  <h2 style="color: #004D40; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E0F2F1;">🔑 핵심 용어 설명</h2>
  <dl style="margin: 0 0 24px 0; padding: 0;">
    <div style="background: #E0F2F1; border-radius: 8px; padding: 16px 18px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.03);">
      <dt style="font-weight: bold; color: #004D40; font-size: 16px; margin-bottom: 6px;">
        위젯 트리 (Widget Tree)
      </dt>
      <dd style="margin: 0; color: #333; font-size: 15px;">
        Flutter의 UI 구성 요소들이 계층적으로 배치된 구조입니다.
        모든 것이 위젯으로 이루어지며, 부모-자식 관계로 화면을 구성합니다.
      </dd>
    </div>
    <div style="border: 1px solid #B2DFDB; border-radius: 8px; padding: 16px 18px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.03);">
      <dt style="font-weight: bold; color: #004D40; font-size: 16px; margin-bottom: 6px;">
        상태 관리 (State Management)
      </dt>
      <dd style="margin: 0; color: #333; font-size: 15px;">
        앱의 데이터 흐름을 관리하는 기술로, Riverpod, Bloc, Provider 등 다양한
        솔루션이 존재합니다. 규모에 따라 적절한 방식을 선택해야 합니다.
      </dd>
    </div>
    <div style="background: #E0F2F1; border-radius: 8px; padding: 16px 18px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.03);">
      <dt style="font-weight: bold; color: #004D40; font-size: 16px; margin-bottom: 6px;">
        핫 리로드 (Hot Reload)
      </dt>
      <dd style="margin: 0; color: #333; font-size: 15px;">
        코드 변경 사항을 앱을 재시작하지 않고 즉시 반영하는 기능입니다.
        개발 생산성을 획기적으로 향상시켜줍니다.
      </dd>
    </div>
  </dl>

  <h2 style="color: #004D40; font-size: 20px; margin: 32px 0 12px 0; padding-bottom: 8px; border-bottom: 1px solid #E0F2F1;">✅ 개발 체크리스트</h2>
  <ul style="margin: 0 0 24px 0; padding-left: 24px; line-height: 2.2; font-size: 16px;">
    <li>앱 아키텍처 설계 및 상태 관리 방식 결정</li>
    <li>디자인 시스템 및 컴포넌트 라이브러리 구축</li>
    <li>CI/CD 파이프라인 설정 (GitHub Actions, Codemagic)</li>
    <li>접근성 (Accessibility) 지원 — 스크린리더, 고대비 모드</li>
    <li>다국어 지원 (i18n) — 한국어, 영어, 일본어, 중국어</li>
    <li>앱스토어 제출 및 심사 대응 전략</li>
  </ul>

  <div style="background: #E0F2F1; border-left: 4px solid #00897B; border-radius: 0 8px 8px 0;
              padding: 16px 20px; margin-top: 32px; box-shadow: 0 2px 8px rgba(0,137,123,0.1);">
    <p style="margin: 0; color: #004D40; font-size: 15px; line-height: 1.8;">
      💡 <strong>렌더링 참고:</strong> HyperRender는 한글 자모 분리 없이 음절 단위로
      올바르게 줄 바꿈을 처리하며, 영문·숫자·한글 혼용 문서에서도
      자연스러운 간격과 줄 나눔을 유지합니다.
    </p>
  </div>

</div>
''';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: HyperViewer(html: _html, selectable: true),
        ),
      ),
    );
  }
}
