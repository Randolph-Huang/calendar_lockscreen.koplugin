墨水屏息屏（锁屏）时显示：**公历日期 + 星期 + 农历（含干支年与节气）**，完全离线、不联网，
自适应任意尺寸 e-ink 屏幕（字号按屏幕高度比例缩放）。锁屏底部另带一句**每日金句**（同样离线、本地语料）。

## 显示内容
<img width="758" height="1024" alt="FileManager_2026-09-16_220140" src="https://github.com/user-attachments/assets/7a247db0-55c2-43e8-b391-f8563e4903aa" />
<img width="758" height="1024" alt="FileManager_2026-09-16_215555" src="https://github.com/user-attachments/assets/0e180e2b-1805-46e4-945f-8cbf72e28252" />
<img width="758" height="1024" alt="FileManager_2026-09-18_185428" src="https://github.com/user-attachments/assets/d4cf6f3e-540d-44ed-99ad-12c6ccaefd40" />


## 以后想换字体和字体大小怎么办

**不用改代码，点菜单就行。** 菜单路径：`菜单 → 日历锁屏 → 字体/金句字号`。

字体文件放哪（放任意一处即可，KOReader 都会扫描）：

- Android：`/sdcard/koreader/fonts/`（和 `plugins/` 同级）、`/sdcard/fonts/`
- Kobo / Kindle / 通用：KOReader 目录下的 `fonts/`（和 `plugins/` 同级）

> 说明：`koreader.log` 里会记录最终选中的字体，形如
> `calendar_lockscreen: using font ./fonts/SourceHanSansSC-Heavy.otf (auto)`，
> 排查时可直接搜 `calendar_lockscreen`。

## 安装

1. 把整个 `calendar_lockscreen.koplugin/` 文件夹（内部含 7 个 `.lua` 文件：`main.lua`、`_meta.lua`、`calendarscreen.lua`、`calfont.lua`、`cal_lunar.lua`、`calquote.lua`、`calcorpus.lua`，以及 4 个语料文件：`poems.txt`、`quotes.txt`、`lines.txt`、`lyrics.txt`）复制到 KOReader 的插件目录。常见位置（放任意一个即可，KOReader 会扫描）：
   - **Kobo**：`/mnt/onboard/.adds/koreader/plugins/`
   - **Kindle**：`/mnt/us/koreader/plugins/`（KOReader 装在 `/mnt/us/koreader` 时）
   - **Android（KOReader App）**：`/sdcard/koreader/plugins/`（数据目录）或 App 私有目录 `Android/data/org.koreader.launcher/files/koreader/plugins/`
   - 通用：KOReader 启动脚本所在目录下的 `plugins/`
   > ⚠️ 必须是名为 `xxx.koplugin` 的**文件夹**，里面直接放 7 个 `.lua` 文件 + 3 个 `.txt` 语料文件。常见错误：①解压后变成 `calendar_lockscreen/`（少了 `.koplugin` 后缀）；②变成 `calendar_lockscreen.koplugin/calendar_lockscreen.koplugin/...`（多套一层父目录）。这两种 KOReader 都不识别。

2. **完全退出并重启 KOReader**（回主界面≠重启，要真的杀掉进程再打开；插件只在启动时加载）。

3. 进入菜单找插件：
   - 主界面点右上角「菜单 / ≡」，在列表中找到 **「日历锁屏」**（通常在「插件」分组下）。
   - 阅读界面同理：阅读时点头像 / 菜单 → 找到「日历锁屏」。

## 使用

- 开启「启用日历锁屏」后，正常合盖/息屏即显示本日历锁屏。
- 唤醒：轻触屏幕或按任意键（与原屏保一致）。
- 菜单项：`启用日历锁屏` / `当前字体：xxx`（只读提示）/ `字体`（选择器）/ `额外加粗` /
  `预览锁屏样式` / `金句类型` / `金句字号` / `换一条金句`。菜单会自动归位到「工具」标签页，不会带「新：」前缀。

## 每日金句（锁屏底部，本地语料库）

金句取自插件内置的、**人工核实过的真实语料库**（`poems.txt` 诗词、`quotes.txt` 名言警句、
`lines.txt` 著名台词、`lyrics.txt` 歌词），**完全本地、零网络、零 Key、断网可用**。
语料库当前规模：诗词 500 条、名言警句 500 条、著名台词 500 条、歌词 20+ 条，均可自行增删（见下）。

**金句类型**：菜单 → `金句类型`，可选 `诗词` / `名言警句` / `著名台词` / `歌词` / `随机`（默认）。
切换类型后，当天的金句立即换成对应类型（同样的日期 + 类型永远显示同一句）。
- `随机` 在「诗词 + 名言警句」里挑（**不含歌词**，避免歌词的双行格式与其他单行类型混排）。
- `歌词` 支持两种写法：纯中文歌词单行显示；或 `外文 | 中文` 写成两行（第一行外文、第二行中文）。
  详见 `lyrics.txt` 顶部的格式说明，改文件重启 KOReader 即生效，不用动代码。

**金句字号**：菜单 → `金句字号`，可选 `6–14`（间隔 1，默认 `12`）。只改锁屏底部金句的字体大小，
不影响日历其他文字。

**显示规则**：金句最多显示 **两行**。单行类型（诗词 / 名言警句 / 著名台词 / 随机）过长时自动折成两行，
第二行仍放不下则在末尾加省略号「…」。`歌词` 的两行（外文 / 中文）各自独立截断，互不影响。

**换一条金句**：菜单 → `换一条金句`，从语料库里换一句今天的内容（无需联网）；
如果锁屏正在预览中，会实时重绘显示新句。

## 息屏时自动全刷（消除残影）

**内置功能，始终开启（无开关）。** 息屏时先把整屏刷白一次（一次全刷/闪屏），再画出日历 —— 这样上一页的文字不会
以浅灰残影的形式透在日历底下。

## 文件说明

- `main.lua`：插件主体。钩住 KOReader 屏保入口 `Screensaver:show` / `setup` 与
  `ScreenSaverWidget:init`：启用时把屏保内容替换为日历、强制屏保模式、并在**上屏前刷白整屏**
  以消除残影（选择 `ScreenSaverWidget:init` 作为钩子点，是因为它恰好运行在
  `Screensaver:show()` 切完竖屏之后、`UIManager:show()` 画日历之前）；并注册菜单、字体选择器与预览。
- `calendarscreen.lua`：锁屏画面 widget，按屏幕比例自适应字号，含状态栏 / 年月 / 号数 / 星期 / 农历 / 细线，
  以及底部的每日金句（最多两行：单行类型过长则折行、第二行末尾加省略号；`歌词` 两行各自独立截断）。`refreshQuote()` 用于「换一条」时即时重绘可见锁屏。
- `calfont.lua`：字体发现与选择。扫描 KOReader 字体目录、按字重/中文覆盖度排名、
  读写"用户选定字体"设置、逐级回退到自带字体。
- `cal_lunar.lua`：农历、干支、节气算法（纯 Lua，离线，1900–2100）。
- `calcorpus.lua`：本地语料库加载器。用 `debug.getinfo` 定位自身目录，读取
  `poems.txt` / `quotes.txt` / `lines.txt` / `lyrics.txt`；按 djb2 哈希做「日期确定性」选句
  （同日期永远选同一句）；`lines.txt` 解析为「台词 + 出处」结构（出处保留在数据中但不显示在锁屏）；
  `lyrics.txt` 支持两种写法——纯中文单行，或 `外文 | 中文` 两行（解析为 foreign / cn 两段，渲染时外文在上、中文在下）；
  文件缺失/为空时回退内置保底。
- `calquote.lua`：每日金句逻辑。从 `calcorpus` 本地选句（不再联网、不用 AI），按
  「日期 + 类型」缓存，`换一条金句` 通过偏移量走到语料库下一句并实时重绘可见锁屏；
  自动剥离句子首尾引号；金句类型含 `诗词 / 名言警句 / 著名台词 / 歌词 / 随机`
  （`随机` 只在诗词 + 名言警句里挑，不含歌词）；`金句字号` 读写 `6–14` 的字号设置（默认 12）。
- `poems.txt` / `quotes.txt` / `lines.txt` / `lyrics.txt`：用户可编辑的语料文件（格式见上「每日金句」）。
- `_meta.lua`：插件元信息。
