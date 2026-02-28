import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

// =============================================================================
// Manga Demo
//
// Showcases HyperRender's unique CJK capabilities:
//   • Ruby / Furigana annotations (exclusive feature)
//   • Japanese typography with Kinsoku line-breaking
//   • CSS Grid — manga panel layout
//   • RTL text direction
//   • Dense mixed-script content (kanji + kana + romaji)
// =============================================================================

class MangaDemo extends StatefulWidget {
  const MangaDemo({super.key});

  @override
  State<MangaDemo> createState() => _MangaDemoState();
}

class _MangaDemoState extends State<MangaDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Manga & CJK Typography'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 16), text: 'キャラ'),
            Tab(icon: Icon(Icons.menu_book, size: 16), text: 'あらすじ'),
            Tab(icon: Icon(Icons.grid_view, size: 16), text: 'パネル'),
            Tab(icon: Icon(Icons.translate, size: 16), text: 'Furigana'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CharacterTab(),
          _SynopsisTab(),
          _PanelsTab(),
          _FuriganaTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Character profile (キャラ紹介)
// ─────────────────────────────────────────────────────────────────────────────

class _CharacterTab extends StatelessWidget {
  const _CharacterTab();

  static const _html = '''
<style>
  body { font-family: "Noto Sans JP", "Hiragino Sans", sans-serif; margin: 0; padding: 16px; background: #FFF9F9; }

  .profile-card {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 2px 12px rgba(0,0,0,0.1);
    margin-bottom: 20px;
  }
  .profile-header {
    background: linear-gradient(135deg, #B71C1C, #E53935);
    color: white;
    padding: 16px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .avatar {
    width: 64px; height: 64px;
    background: rgba(255,255,255,0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    border: 2px solid rgba(255,255,255,0.6);
  }
  .name-block { flex: 1; }
  .name-ja { font-size: 22px; font-weight: bold; }
  .name-en { font-size: 12px; opacity: 0.8; margin-top: 2px; }
  .rank-badge {
    background: rgba(255,255,255,0.25);
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: bold;
  }

  .profile-body { padding: 16px; }
  .stat-row { display: flex; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
  .stat-chip {
    background: #FFF3E0;
    border: 1px solid #FFCC80;
    border-radius: 20px;
    padding: 3px 10px;
    font-size: 12px;
    color: #E65100;
  }
  .section-title {
    font-size: 13px;
    font-weight: bold;
    color: #B71C1C;
    border-left: 3px solid #B71C1C;
    padding-left: 8px;
    margin: 14px 0 8px;
  }
  .description { font-size: 14px; line-height: 1.7; color: #424242; }
  .ability-list { margin: 0; padding-left: 18px; }
  .ability-list li { font-size: 13px; color: #424242; margin-bottom: 5px; line-height: 1.6; }

  .divider { border: none; border-top: 1px solid #F5F5F5; margin: 4px 0 12px; }

  .quote-box {
    background: #FCE4EC;
    border-left: 4px solid #E91E63;
    border-radius: 0 8px 8px 0;
    padding: 10px 14px;
    margin: 12px 0;
    font-style: italic;
    font-size: 14px;
    color: #880E4F;
  }
</style>

<div class="profile-card">
  <div class="profile-header">
    <div class="avatar">⚔️</div>
    <div class="name-block">
      <div class="name-ja">
        <ruby>影<rt>かげ</rt></ruby><ruby>山<rt>やま</rt></ruby>
        <ruby>烈<rt>れつ</rt></ruby><ruby>士<rt>し</rt></ruby>
      </div>
      <div class="name-en">Kageyama Resshi</div>
    </div>
    <div class="rank-badge">柱 HASHIRA</div>
  </div>
  <div class="profile-body">
    <div class="stat-row">
      <span class="stat-chip">年齢 17歳</span>
      <span class="stat-chip">身長 178cm</span>
      <span class="stat-chip">流派：影ノ型</span>
      <span class="stat-chip">斬鬼歴 3年</span>
    </div>
    <hr class="divider"/>
    <div class="section-title">人物像</div>
    <div class="description">
      <ruby>影山<rt>かげやま</rt></ruby><ruby>烈士<rt>れっし</rt></ruby>は、
      <ruby>漆黒<rt>しっこく</rt></ruby>の<ruby>刀<rt>かたな</rt></ruby>を操る
      <ruby>最年少<rt>さいねんしょう</rt></ruby>の<ruby>柱<rt>はしら</rt></ruby>。
      <ruby>幼少期<rt>ようしょうき</rt></ruby>に<ruby>鬼<rt>おに</rt></ruby>に
      <ruby>家族<rt>かぞく</rt></ruby>を<ruby>奪<rt>うば</rt></ruby>われ、
      その<ruby>悲劇<rt>ひげき</rt></ruby>が彼を<ruby>最強<rt>さいきょう</rt></ruby>の
      <ruby>剣士<rt>けんし</rt></ruby>へと<ruby>変貌<rt>へんぼう</rt></ruby>させた。
    </div>
    <div class="quote-box">
      「<ruby>鬼<rt>おに</rt></ruby>を<ruby>殺<rt>ころ</rt></ruby>すことだけが、
      <ruby>俺<rt>おれ</rt></ruby>の<ruby>存在理由<rt>そんざいりゆう</rt></ruby>だ。」
    </div>
    <div class="section-title">技能・<ruby>呼吸法<rt>こきゅうほう</rt></ruby></div>
    <ul class="ability-list">
      <li>
        <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>
        <ruby>壱<rt>いち</rt></ruby>ノ型：
        <strong><ruby>漆黒<rt>しっこく</rt></ruby>の<ruby>斬閃<rt>ざんせん</rt></ruby></strong>
        — 目に見えない超高速の<ruby>一閃<rt>いっせん</rt></ruby>
      </li>
      <li>
        <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>
        <ruby>弐<rt>に</rt></ruby>ノ型：
        <strong><ruby>千刃乱舞<rt>せんじんらんぶ</rt></ruby></strong>
        — <ruby>無数<rt>むすう</rt></ruby>の<ruby>斬撃<rt>ざんげき</rt></ruby>を<ruby>同時<rt>どうじ</rt></ruby>に<ruby>放<rt>はな</rt></ruby>つ
      </li>
      <li>
        <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>
        <ruby>参<rt>さん</rt></ruby>ノ型：
        <strong><ruby>虚空<rt>こくう</rt></ruby>の<ruby>眼<rt>め</rt></ruby></strong>
        — <ruby>敵<rt>てき</rt></ruby>の<ruby>動き<rt>うごき</rt></ruby>を
        0.001<ruby>秒単位<rt>びょうたんい</rt></ruby>で<ruby>読<rt>よ</rt></ruby>む
      </li>
    </ul>
  </div>
</div>

<div class="profile-card">
  <div class="profile-header" style="background: linear-gradient(135deg, #1A237E, #3949AB);">
    <div class="avatar">🌙</div>
    <div class="name-block">
      <div class="name-ja">
        <ruby>月<rt>つき</rt></ruby><ruby>夜<rt>よ</rt></ruby>
        <ruby>蒼<rt>あお</rt></ruby><ruby>空<rt>そら</rt></ruby>
      </div>
      <div class="name-en">Tsukiyo Sora</div>
    </div>
    <div class="rank-badge">上弦ノ壱</div>
  </div>
  <div class="profile-body">
    <div class="stat-row">
      <span class="stat-chip" style="background:#E3F2FD; border-color:#90CAF9; color:#1565C0;">
        <ruby>血鬼術<rt>けっきじゅつ</rt></ruby>：<ruby>月影<rt>つきかげ</rt></ruby>
      </span>
      <span class="stat-chip" style="background:#E3F2FD; border-color:#90CAF9; color:#1565C0;">
        <ruby>享年<rt>きょうねん</rt></ruby>：不明
      </span>
    </div>
    <div class="description">
      かつては<ruby>人間<rt>にんげん</rt></ruby>であり、
      <ruby>月<rt>つき</rt></ruby>の<ruby>光<rt>ひかり</rt></ruby>のように
      <ruby>冷徹<rt>れいてつ</rt></ruby>な<ruby>知性<rt>ちせい</rt></ruby>を持つ。
      その<ruby>血鬼術<rt>けっきじゅつ</rt></ruby>は
      <ruby>空間<rt>くうかん</rt></ruby>を<ruby>歪<rt>ゆが</rt></ruby>め、
      <ruby>対象<rt>たいしょう</rt></ruby>を<ruby>幻影<rt>げんえい</rt></ruby>に
      <ruby>閉<rt>と</rt></ruby>じ込める。
    </div>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: _html,
      selectable: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Story synopsis (あらすじ)
// ─────────────────────────────────────────────────────────────────────────────

class _SynopsisTab extends StatelessWidget {
  const _SynopsisTab();

  static const _html = '''
<style>
  body { font-family: "Noto Sans JP", "Hiragino Sans", sans-serif; margin: 0; padding: 16px; background: #FFFDE7; }

  h1 { font-size: 20px; color: #B71C1C; margin: 0 0 4px; }
  .series-info { font-size: 12px; color: #757575; margin-bottom: 20px; }
  .series-info strong { color: #424242; }

  .chapter {
    background: white;
    border-radius: 10px;
    padding: 14px 16px;
    margin-bottom: 16px;
    border-left: 4px solid #FF6F00;
    box-shadow: 0 1px 6px rgba(0,0,0,0.07);
  }
  .chapter-number {
    font-size: 11px;
    font-weight: bold;
    color: #FF6F00;
    letter-spacing: 0.5px;
    margin-bottom: 4px;
  }
  .chapter-title { font-size: 16px; font-weight: bold; color: #212121; margin-bottom: 8px; }
  .chapter-body { font-size: 14px; line-height: 1.8; color: #424242; }

  .sfx-panel {
    background: #212121;
    color: white;
    border-radius: 8px;
    padding: 12px 16px;
    margin: 12px 0;
    font-size: 15px;
    font-weight: bold;
    letter-spacing: 1px;
    text-align: center;
  }
  .sfx-ja { font-size: 26px; color: #FF5252; display: block; }
  .sfx-en { font-size: 11px; color: #BDBDBD; display: block; margin-top: 2px; }

  .highlight { background: #FFF9C4; padding: 2px 4px; border-radius: 3px; }
</style>

<h1>影界年代記</h1>
<div class="series-info">
  <strong>作者：</strong>架空 太郎 ／
  <strong>掲載：</strong>週刊架空ジャンプ ／
  <strong>既刊：</strong>23巻
</div>

<div class="chapter">
  <div class="chapter-number">第一話</div>
  <div class="chapter-title">
    <ruby>闇<rt>やみ</rt></ruby>の<ruby>目覚<rt>めざ</rt></ruby>め
  </div>
  <div class="chapter-body">
    <ruby>深夜<rt>しんや</rt></ruby>の<ruby>山道<rt>やまみち</rt></ruby>を
    <ruby>歩<rt>ある</rt></ruby>く<ruby>少年<rt>しょうねん</rt></ruby>、
    <ruby>烈士<rt>れっし</rt></ruby>。
    <ruby>突然<rt>とつぜん</rt></ruby>、<ruby>巨大<rt>きょだい</rt></ruby>な
    <ruby>鬼<rt>おに</rt></ruby>が<ruby>現<rt>あらわ</rt></ruby>れ、
    <ruby>村<rt>むら</rt></ruby>を<ruby>襲<rt>おそ</rt></ruby>う。
  </div>

  <div class="sfx-panel">
    <span class="sfx-ja">ズドォォォン！！</span>
    <span class="sfx-en">BWOOOOM</span>
  </div>

  <div class="chapter-body">
    <ruby>烈士<rt>れっし</rt></ruby>は<ruby>恐怖<rt>きょうふ</rt></ruby>に
    <ruby>震<rt>ふる</rt></ruby>えながらも、
    <span class="highlight"><ruby>亡<rt>な</rt></ruby>き<ruby>父<rt>ちち</rt></ruby>の
    <ruby>形見<rt>かたみ</rt></ruby>の<ruby>刀<rt>かたな</rt></ruby></span>を
    <ruby>握<rt>にぎ</rt></ruby>りしめた。
    「<ruby>逃<rt>に</rt></ruby>げるな……<ruby>俺<rt>おれ</rt></ruby>は
    <ruby>絶対<rt>ぜったい</rt></ruby>に<ruby>逃<rt>に</rt></ruby>げない！」
  </div>
</div>

<div class="chapter" style="border-left-color: #C62828;">
  <div class="chapter-number" style="color: #C62828;">第十二話</div>
  <div class="chapter-title">
    <ruby>上弦<rt>じょうげん</rt></ruby>との<ruby>遭遇<rt>そうぐう</rt></ruby>
  </div>
  <div class="chapter-body">
    <ruby>鬼殺隊<rt>きさつたい</rt></ruby>の
    <ruby>本部<rt>ほんぶ</rt></ruby>に<ruby>突如<rt>とつじょ</rt></ruby>
    <ruby>上弦<rt>じょうげん</rt></ruby>の<ruby>壱<rt>いち</rt></ruby>、
    <ruby>月夜蒼空<rt>つきよそら</rt></ruby>が<ruby>侵入<rt>しんにゅう</rt></ruby>する。
    <ruby>柱<rt>はしら</rt></ruby>たちが<ruby>次々<rt>つぎつぎ</rt></ruby>と
    <ruby>倒<rt>たお</rt></ruby>れていく中、
    <ruby>烈士<rt>れっし</rt></ruby>だけが<ruby>立<rt>た</rt></ruby>ち
    <ruby>向<rt>む</rt></ruby>かう。
  </div>

  <div class="sfx-panel">
    <span class="sfx-ja">シュッ！ ザシュッ！！</span>
    <span class="sfx-en">SLASH! SLASH!</span>
  </div>

  <div class="chapter-body">
    <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>
    <ruby>壱<rt>いち</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>——
    <strong style="color:#B71C1C; font-size:15px;">
      <ruby>漆黒<rt>しっこく</rt></ruby>の<ruby>斬閃<rt>ざんせん</rt></ruby>！！
    </strong>
    <br/><br/>
    <ruby>烈士<rt>れっし</rt></ruby>の<ruby>刀<rt>かたな</rt></ruby>が
    <ruby>光<rt>ひかり</rt></ruby>を<ruby>超<rt>こ</rt></ruby>える
    <ruby>速度<rt>そくど</rt></ruby>で<ruby>振<rt>ふ</rt></ruby>り
    <ruby>下<rt>お</rt></ruby>ろされた。
    だが——<ruby>月夜<rt>つきよ</rt></ruby>は<ruby>笑<rt>わら</rt></ruby>った。
    「<ruby>面白<rt>おもしろ</rt></ruby>い……
    <ruby>人間<rt>にんげん</rt></ruby>にしては。」
  </div>
</div>

<div class="chapter" style="border-left-color: #1A237E;">
  <div class="chapter-number" style="color: #1A237E;">第二十三話（最新）</div>
  <div class="chapter-title">
    <ruby>夜明<rt>よあ</rt></ruby>け前の<ruby>決戦<rt>けっせん</rt></ruby>
  </div>
  <div class="chapter-body">
    <ruby>最終決戦<rt>さいしゅうけっせん</rt></ruby>が
    <ruby>始<rt>はじ</rt></ruby>まる。
    <ruby>烈士<rt>れっし</rt></ruby>は<ruby>仲間<rt>なかま</rt></ruby>の
    <ruby>想<rt>おも</rt></ruby>いを<ruby>背負<rt>せお</rt></ruby>い、
    <ruby>未知<rt>みち</rt></ruby>の<ruby>型<rt>かた</rt></ruby>を
    <ruby>解放<rt>かいほう</rt></ruby>する——
    <strong style="font-size:15px; color:#1A237E;">
      <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>
      <ruby>零<rt>ぜろ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>：
      <ruby>黎明<rt>れいめい</rt></ruby>。
    </strong>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: _html,
      selectable: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Manga panel grid layout (パネル)
// ─────────────────────────────────────────────────────────────────────────────

class _PanelsTab extends StatelessWidget {
  const _PanelsTab();

  static const _html = '''
<style>
  body { margin: 0; padding: 12px; background: #212121; }

  .page-title {
    color: #FF5252;
    font-size: 13px;
    font-weight: bold;
    letter-spacing: 2px;
    text-align: center;
    margin-bottom: 12px;
  }

  /* CSS Grid manga page layout */
  .manga-page {
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: auto;
    gap: 4px;
    background: #000;
    padding: 4px;
    border-radius: 4px;
    margin-bottom: 16px;
  }

  .panel {
    background: #FAFAFA;
    overflow: hidden;
    position: relative;
    min-height: 120px;
    display: flex;
    flex-direction: column;
    justify-content: flex-end;
    padding: 8px;
  }
  .panel-wide { grid-column: span 2; min-height: 160px; }
  .panel-tall { grid-row: span 2; }

  /* Panel backgrounds simulated with solid colors + emoji */
  .panel-action {
    background: #E3F2FD;
    justify-content: center;
    align-items: center;
  }
  .panel-close { background: #FCE4EC; }
  .panel-landscape {
    background: linear-gradient(180deg, #B3E5FC 0%, #E8F5E9 100%);
  }
  .panel-dark { background: #263238; }

  .panel-emoji {
    font-size: 48px;
    text-align: center;
    margin-bottom: 8px;
  }

  /* Speech bubbles */
  .bubble {
    background: white;
    border: 2px solid #212121;
    border-radius: 14px;
    padding: 6px 10px;
    font-size: 11px;
    font-weight: bold;
    color: #212121;
    margin-bottom: 4px;
    line-height: 1.5;
    max-width: 90%;
  }
  .bubble-thought {
    background: white;
    border: 2px dashed #666;
    border-radius: 50%;
    padding: 6px 10px;
    font-size: 10px;
    color: #424242;
    font-style: italic;
  }
  .bubble-scream {
    background: #FF5252;
    border: 2px solid #B71C1C;
    color: white;
    border-radius: 4px;
  }

  /* On-panel sound effects */
  .sfx {
    position: relative;
    font-size: 20px;
    font-weight: 900;
    text-align: center;
    padding: 8px;
    transform: rotate(-5deg);
    display: inline-block;
    letter-spacing: 2px;
  }
  .sfx-red { color: #FF5252; text-shadow: 2px 2px 0 #B71C1C; }
  .sfx-blue { color: #448AFF; text-shadow: 2px 2px 0 #1565C0; }
  .sfx-white { color: white; text-shadow: 2px 2px 0 #000; }

  .caption {
    background: rgba(0,0,0,0.75);
    color: #FFF9C4;
    font-size: 11px;
    padding: 5px 8px;
    border-radius: 4px;
    line-height: 1.5;
  }
</style>

<div class="page-title">影界年代記 ▸ Chapter 12 ▸ Page 8</div>

<div class="manga-page">
  <!-- Panel 1 — wide establishing shot -->
  <div class="panel panel-wide panel-landscape">
    <div style="text-align:center; padding: 20px 0;">
      <span style="font-size:52px;">🏯</span>
    </div>
    <div class="caption">
      <ruby>鬼殺隊<rt>きさつたい</rt></ruby>本部——深夜
    </div>
  </div>

  <!-- Panel 2 — close-up character -->
  <div class="panel panel-close" style="grid-row: span 2;">
    <div class="panel-emoji">😤</div>
    <div class="bubble">
      「<ruby>来<rt>く</rt></ruby>るがいい……
      <ruby>上弦<rt>じょうげん</rt></ruby>よ」
    </div>
  </div>

  <!-- Panel 3 — action -->
  <div class="panel panel-action">
    <div style="text-align:center;">
      <div class="sfx sfx-red">ドドドォ！！</div>
    </div>
  </div>

  <!-- Panel 4 — villain close-up -->
  <div class="panel panel-dark">
    <div class="panel-emoji" style="filter: brightness(1.5);">😈</div>
    <div class="bubble bubble-scream">
      「<ruby>面白<rt>おもしろ</rt></ruby>い……！」
    </div>
  </div>

  <!-- Panel 5 — wide clash -->
  <div class="panel panel-wide panel-action" style="min-height: 140px;">
    <div style="display:flex; justify-content:space-around; align-items:center; padding:12px 0;">
      <span style="font-size:36px;">⚔️</span>
      <div class="sfx sfx-blue" style="font-size:24px;">ズバッ！！</div>
      <span style="font-size:36px; transform:scaleX(-1); display:inline-block;">⚔️</span>
    </div>
    <div style="text-align:center;">
      <div class="bubble" style="display:inline-block;">
        <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>——
        <strong style="color:#B71C1C;">
          <ruby>漆黒<rt>しっこく</rt></ruby>の<ruby>斬閃<rt>ざんせん</rt></ruby>！！
        </strong>
      </div>
    </div>
  </div>
</div>

<div class="manga-page" style="grid-template-columns: 1fr 1fr 1fr;">
  <!-- Three-column row for rapid sequence -->
  <div class="panel" style="min-height:80px; background:#E8F5E9; justify-content:center; align-items:center;">
    <span style="font-size:30px;">😱</span>
    <div class="bubble" style="font-size:10px;">「まさか——！」</div>
  </div>
  <div class="panel" style="min-height:80px; background:#FFF9C4; justify-content:center; align-items:center;">
    <div class="sfx sfx-red" style="font-size:16px;">バキッ！</div>
  </div>
  <div class="panel" style="min-height:80px; background:#212121; justify-content:center; align-items:center;">
    <div class="bubble bubble-thought" style="font-size:10px;">
      （<ruby>父<rt>ちち</rt></ruby>さん……）
    </div>
  </div>

  <!-- Bottom wide panel -->
  <div class="panel panel-wide" style="grid-column: span 3; background:#B71C1C; min-height:100px; justify-content:center; align-items:center;">
    <div class="sfx sfx-white" style="font-size:32px;">
      つ・づ・く……
    </div>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: _html,
      selectable: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Furigana showcase
// ─────────────────────────────────────────────────────────────────────────────

class _FuriganaTab extends StatelessWidget {
  const _FuriganaTab();

  static const _html = '''
<style>
  body { font-family: "Noto Sans JP", "Hiragino Sans", sans-serif; margin: 0; padding: 16px; }
  h2 { font-size: 16px; color: #B71C1C; border-bottom: 2px solid #B71C1C; padding-bottom: 6px; margin: 20px 0 12px; }
  h3 { font-size: 13px; color: #757575; font-weight: normal; margin: 0 0 10px; }
  .row { margin-bottom: 14px; background: #FAFAFA; border-radius: 8px; padding: 12px 14px; }
  .label { font-size: 11px; color: #9E9E9E; margin-bottom: 4px; }
  .sample { font-size: 18px; line-height: 2.8; }
  .note { font-size: 12px; color: #B71C1C; margin-top: 6px; }

  .comparison {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin-bottom: 14px;
  }
  .comp-box { background: #F5F5F5; border-radius: 8px; padding: 10px; }
  .comp-title { font-size: 11px; font-weight: bold; margin-bottom: 6px; }
  .comp-title.good { color: #388E3C; }
  .comp-title.bad  { color: #D32F2F; }
  .comp-sample { font-size: 15px; line-height: 2.5; }
  .raw { color: #E53935; font-size: 13px; font-family: monospace; }
</style>

<h2>Ruby / Furigana Annotations</h2>
<h3>HyperRender exclusive — neither flutter_html nor FWFH support this</h3>

<div class="row">
  <div class="label">Basic furigana (振り仮名)</div>
  <div class="sample">
    <ruby>日本語<rt>にほんご</rt></ruby>は
    <ruby>美<rt>うつく</rt></ruby>しい
    <ruby>言語<rt>げんご</rt></ruby>です。
  </div>
</div>

<div class="row">
  <div class="label">Per-character furigana</div>
  <div class="sample">
    <ruby>東<rt>とう</rt></ruby><ruby>京<rt>きょう</rt></ruby>の
    <ruby>夜<rt>よる</rt></ruby>は
    <ruby>輝<rt>かがや</rt></ruby>いている。
  </div>
</div>

<div class="row">
  <div class="label">Battle technique names (manga style)</div>
  <div class="sample" style="font-weight:bold; color:#B71C1C;">
    <ruby>火焔廻転<rt>かえんかいてん</rt></ruby>の
    <ruby>型<rt>かた</rt></ruby>——
    <ruby>緋色<rt>ひいろ</rt></ruby>の
    <ruby>滅却<rt>めっきゃく</rt></ruby>！！
  </div>
</div>

<div class="row">
  <div class="label">Traditional poem (haiku)</div>
  <div class="sample" style="font-size: 17px; line-height: 3; text-align: center; color: #424242;">
    <ruby>古池<rt>ふるいけ</rt></ruby>や<br/>
    <ruby>蛙<rt>かわず</rt></ruby>
    <ruby>飛<rt>と</rt></ruby>び込む<br/>
    <ruby>水<rt>みず</rt></ruby>の<ruby>音<rt>おと</rt></ruby>
  </div>
  <div class="note" style="color:#757575; text-align:center;">— 松尾芭蕉 (Matsuo Bashō)</div>
</div>

<h2>HyperRender vs Other Libraries</h2>

<div class="comparison">
  <div class="comp-box">
    <div class="comp-title good">✅ HyperRender</div>
    <div class="comp-sample">
      <ruby>剣士<rt>けんし</rt></ruby>が
      <ruby>走<rt>はし</rt></ruby>る
    </div>
    <div class="note">Annotation appears above, aligned to base text</div>
  </div>
  <div class="comp-box" style="background:#FFF3E0;">
    <div class="comp-title bad">❌ flutter_html / FWFH</div>
    <div class="comp-sample raw">剣士けんし が 走はしる</div>
    <div class="note" style="color:#E65100;">
      &lt;rt&gt; shown inline as raw text — broken
    </div>
  </div>
</div>

<div class="row">
  <div class="label">Mixed script (kanji + kana + romaji)</div>
  <div class="sample">
    <ruby>NARUTO<rt>ナルト</rt></ruby>は
    <ruby>忍者<rt>にんじゃ</rt></ruby>の
    <ruby>里<rt>さと</rt></ruby>で
    <ruby>生<rt>う</rt></ruby>まれた。
    <ruby>彼<rt>かれ</rt></ruby>の
    <ruby>夢<rt>ゆめ</rt></ruby>は
    <ruby>火影<rt>ほかげ</rt></ruby>になること。
  </div>
</div>

<div class="row">
  <div class="label">Chinese (Traditional) — Bopomofo annotation</div>
  <div class="sample">
    <ruby>漢字<rt>hàn zì</rt></ruby>是
    <ruby>世界<rt>shì jiè</rt></ruby>上最
    <ruby>古老<rt>gǔ lǎo</rt></ruby>的
    <ruby>文字<rt>wén zì</rt></ruby>之一。
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFB71C1C),
          child: const Text(
            'HyperRender is the only Flutter HTML library that correctly renders <ruby>/<rt>',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: HyperViewer(
            html: _html,
            selectable: true,
          ),
        ),
      ],
    );
  }
}
