import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

// =============================================================================
// Manga Demo
//
// Showcases HyperRender's unique CJK capabilities:
//   • Ruby / Furigana annotations (exclusive feature)
//   • Japanese typography with Kinsoku line-breaking
//   • Manga panel layout with flex
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
          unselectedLabelColor: Colors.white,
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

  // NOTE: No body{} rules — HyperRender doesn't apply <body> styles.
  // All padding/background are on explicit wrapper divs.
  // gap replaced by margin-right on children for compatibility.
  static const _html = '''
<style>
  .page { padding: 16px; background: #FFF9F9; }

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
  }
  .header-inner {
    display: flex;
    align-items: center;
  }
  .avatar {
    width: 56px;
    height: 56px;
    background: rgba(255,255,255,0.2);
    border-radius: 50%;
    border: 2px solid rgba(255,255,255,0.6);
    font-size: 26px;
    text-align: center;
    line-height: 56px;
    margin-right: 14px;
    flex-shrink: 0;
  }
  .name-block { flex: 1; }
  .name-ja { font-size: 20px; font-weight: bold; line-height: 2.0; }
  .name-en { font-size: 12px; opacity: 0.8; margin-top: 2px; }
  .rank-badge {
    background: rgba(255,255,255,0.25);
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: bold;
    flex-shrink: 0;
  }

  .profile-body { padding: 16px; }
  .stat-row { margin-bottom: 12px; }
  .stat-chip {
    display: inline-block;
    background: #FFF3E0;
    border: 1px solid #FFCC80;
    border-radius: 20px;
    padding: 3px 10px;
    font-size: 12px;
    color: #E65100;
    margin-right: 6px;
    margin-bottom: 6px;
  }
  .section-title {
    font-size: 13px;
    font-weight: bold;
    color: #B71C1C;
    border-left: 3px solid #B71C1C;
    padding-left: 8px;
    margin: 14px 0 8px;
  }
  .description { font-size: 14px; line-height: 1.9; color: #424242; }
  .ability-list { margin: 0; padding-left: 18px; }
  .ability-list li { font-size: 13px; color: #424242; margin-bottom: 6px; line-height: 1.8; }

  hr { border: none; border-top: 1px solid #F5F5F5; margin: 4px 0 12px; }

  .quote-box {
    background: #FCE4EC;
    border-left: 4px solid #E91E63;
    border-radius: 0 8px 8px 0;
    padding: 10px 14px;
    margin: 12px 0;
    font-style: italic;
    font-size: 14px;
    line-height: 2.0;
    color: #880E4F;
  }
</style>

<div class="page">

<div class="profile-card">
  <div class="profile-header">
    <div class="header-inner">
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
  </div>
  <div class="profile-body">
    <div class="stat-row">
      <span class="stat-chip">年齢 17歳</span>
      <span class="stat-chip">身長 178cm</span>
      <span class="stat-chip">流派：影ノ型</span>
      <span class="stat-chip">斬鬼歴 3年</span>
    </div>
    <hr/>
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
        — <ruby>無数<rt>むすう</rt></ruby>の<ruby>斬撃<rt>ざんげき</rt></ruby>を
        <ruby>同時<rt>どうじ</rt></ruby>に<ruby>放<rt>はな</rt></ruby>つ
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
    <div class="header-inner">
      <div class="avatar" style="line-height: 56px;">🌙</div>
      <div class="name-block">
        <div class="name-ja">
          <ruby>月<rt>つき</rt></ruby><ruby>夜<rt>よ</rt></ruby>
          <ruby>蒼<rt>あお</rt></ruby><ruby>空<rt>そら</rt></ruby>
        </div>
        <div class="name-en">Tsukiyo Sora</div>
      </div>
      <div class="rank-badge">上弦ノ壱</div>
    </div>
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
  .page { padding: 16px; background: #FFFDE7; }

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
  .chapter-title { font-size: 16px; font-weight: bold; color: #212121; margin-bottom: 8px; line-height: 2.2; }
  .chapter-body { font-size: 14px; line-height: 2.0; color: #424242; }

  .sfx-panel {
    background: #212121;
    color: white;
    border-radius: 8px;
    padding: 12px 16px;
    margin: 12px 0;
    text-align: center;
  }
  .sfx-ja { font-size: 26px; color: #FF5252; font-weight: bold; display: block; letter-spacing: 1px; }
  .sfx-en { font-size: 11px; color: #BDBDBD; display: block; margin-top: 2px; }

  .highlight { background: #FFF9C4; padding: 2px 4px; border-radius: 3px; }
</style>

<div class="page">

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

  // NOTE: All layout uses float (not flex) — HyperRender's float engine is
  // rock-solid. Flex with nested children collapses to zero-height panels.
  // Dark background (#212121) is inside the HTML wrapper, not Flutter-level.
  static const _html = '''
<div style="padding:12px; background:#EBEBEB;">

  <!-- Page label -->
  <div style="text-align:center; margin-bottom:10px;">
    <span style="background:#B71C1C; color:white; font-size:11px; font-weight:bold; letter-spacing:1.5px; padding:3px 12px; border-radius:20px;">
      影界年代記 ▸ Ch.12 ▸ P.8
    </span>
  </div>

  <!-- ═══ Page 1: White manga page with thick black panel borders ═══ -->
  <div style="background:white; border:3px solid #111; margin-bottom:14px; overflow:hidden;">

    <!-- Row 1: Full-width establishing shot -->
    <div style="background:linear-gradient(180deg,#B3E5FC 0%,#E8F5E9 100%); padding:14px 10px; border-bottom:3px solid #111; min-height:100px;">
      <div style="text-align:center; font-size:48px; padding:4px 0;">🏯</div>
      <div style="background:rgba(0,0,0,0.65); color:#FFF9C4; font-size:11px; padding:5px 8px; border-radius:4px; line-height:1.5; margin-top:6px;">
        <ruby>鬼殺隊<rt>きさつたい</rt></ruby>本部——深夜
      </div>
    </div>

    <!-- Row 2: Left tall panel + right two stacked (float layout) -->
    <div style="overflow:hidden; border-bottom:3px solid #111;">
      <!-- Left: hero close-up -->
      <div style="float:left; width:46%; background:#FCE4EC; padding:10px; min-height:220px; box-sizing:border-box; border-right:3px solid #111;">
        <div style="font-size:44px; text-align:center; margin-bottom:10px;">😤</div>
        <div style="background:white; border:2px solid #111; border-radius:14px; padding:7px 10px; font-size:11px; font-weight:bold; line-height:1.9;">
          「<ruby>来<rt>く</rt></ruby>るがいい……<ruby>上弦<rt>じょうげん</rt></ruby>よ」
        </div>
      </div>
      <!-- Right: two stacked panels -->
      <div style="margin-left:49%;">
        <div style="background:#E3F2FD; padding:10px; min-height:107px; border-bottom:3px solid #111; text-align:center;">
          <div style="font-size:20px; font-weight:900; color:#D32F2F; letter-spacing:2px; padding-top:32px;">ドドドォ！！</div>
        </div>
        <div style="background:#1C2A33; padding:10px; min-height:110px;">
          <div style="font-size:40px; text-align:center; margin-bottom:6px;">😈</div>
          <div style="background:#EF5350; border:2px solid #B71C1C; color:white; border-radius:4px; padding:5px 8px; font-size:11px; font-weight:bold; line-height:1.6;">
            「<ruby>面白<rt>おもしろ</rt></ruby>い……！」
          </div>
        </div>
      </div>
    </div>
    <div style="clear:both;"></div>

    <!-- Row 3: Full-width clash panel -->
    <div style="background:#EDE7F6; padding:14px 10px; text-align:center; min-height:100px;">
      <div style="padding:8px 0;">
        <span style="font-size:28px;">⚔️</span>
        <span style="font-size:21px; font-weight:900; color:#1565C0; letter-spacing:2px; padding:0 8px;">ズバッ！！</span>
        <span style="font-size:28px;">⚔️</span>
      </div>
      <div style="background:white; border:2px solid #111; border-radius:14px; padding:6px 14px; font-size:11px; font-weight:bold; display:inline-block;">
        <ruby>影<rt>かげ</rt></ruby>ノ<ruby>型<rt>かた</rt></ruby>——
        <strong style="color:#B71C1C;"><ruby>漆黒<rt>しっこく</rt></ruby>の<ruby>斬閃<rt>ざんせん</rt></ruby>！！</strong>
      </div>
    </div>

  </div>

  <!-- ═══ Page 2: 3-beat rapid sequence ═══ -->
  <div style="background:white; border:3px solid #111; overflow:hidden;">

    <!-- 3-beat row -->
    <div style="overflow:hidden; border-bottom:3px solid #111;">
      <div style="float:left; width:31%; background:#E8F5E9; padding:8px; min-height:90px; box-sizing:border-box; border-right:3px solid #111; text-align:center;">
        <div style="font-size:28px;">😱</div>
        <div style="background:white; border:2px solid #111; border-radius:10px; padding:4px 6px; font-size:10px; font-weight:bold; margin-top:4px;">「まさか——！」</div>
      </div>
      <div style="float:left; width:33%; background:#FFFDE7; padding:8px; min-height:90px; box-sizing:border-box; border-right:3px solid #111; text-align:center;">
        <div style="font-size:17px; font-weight:900; color:#D32F2F; letter-spacing:2px; padding-top:24px;">バキッ！</div>
      </div>
      <div style="float:right; width:30%; background:#263238; padding:8px; min-height:90px; box-sizing:border-box; text-align:center;">
        <div style="background:white; border:2px dashed #78909C; border-radius:10px; padding:5px 6px; font-size:10px; font-style:italic; color:#424242; margin-top:16px;">
          （<ruby>父<rt>ちち</rt></ruby>さん……）
        </div>
      </div>
    </div>
    <div style="clear:both;"></div>

    <!-- つづく -->
    <div style="background:#B71C1C; padding:18px; text-align:center;">
      <span style="font-size:26px; color:white; font-weight:900; letter-spacing:4px;">つ・づ・く……</span>
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
  .page { padding: 16px; }
  h2 { font-size: 16px; color: #B71C1C; border-bottom: 2px solid #B71C1C; padding-bottom: 6px; margin: 20px 0 12px; }
  h3 { font-size: 13px; color: #757575; font-weight: normal; margin: 0 0 10px; }
  .row { margin-bottom: 14px; background: #FAFAFA; border-radius: 8px; padding: 12px 14px; }
  .label { font-size: 11px; color: #9E9E9E; margin-bottom: 6px; }
  .sample { font-size: 18px; line-height: 3.0; }
  .note { font-size: 12px; color: #B71C1C; margin-top: 6px; }

  /* Side-by-side comparison — two columns using float */
  .comparison { margin-bottom: 14px; overflow: hidden; }
  .comp-box {
    float: left;
    width: 47%;
    background: #F5F5F5;
    border-radius: 8px;
    padding: 10px;
    margin-right: 6%;
    box-sizing: border-box;
  }
  .comp-box:last-child { margin-right: 0; float: right; }
  .comp-clear { clear: both; }
  .comp-title { font-size: 11px; font-weight: bold; margin-bottom: 6px; }
  .comp-title.good { color: #388E3C; }
  .comp-title.bad  { color: #D32F2F; }
  .comp-sample { font-size: 15px; line-height: 2.8; }
  .raw { color: #E53935; font-size: 13px; font-family: monospace; }
</style>

<div class="page">
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
  <div class="sample" style="font-size: 17px; line-height: 3.2; text-align: center; color: #424242;">
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
  <div class="comp-clear"></div>
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
  <div class="label">Chinese — Pinyin annotation</div>
  <div class="sample">
    <ruby>漢字<rt>hàn zì</rt></ruby>是
    <ruby>世界<rt>shì jiè</rt></ruby>上最
    <ruby>古老<rt>gǔ lǎo</rt></ruby>的
    <ruby>文字<rt>wén zì</rt></ruby>之一。
  </div>
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
