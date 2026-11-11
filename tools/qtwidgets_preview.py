#!/usr/bin/env python3
"""Render the Nothing Kvantum themes offscreen -> previews/qt-dolphin.png, previews/qt-widgets.png

Uses the real Kvantum style plugin with kvantum/Nothing and kvantum/NothingFiles (via a
private XDG_CONFIG_HOME whose kvantum.kvconfig mirrors the live one, incl. the
[Applications] NothingFiles=dolphin mapping, so the user's config is never touched), the
real Nothing icon theme and Inter.  Each part runs in its own process because Kvantum picks
the theme from the application name once:  the Dolphin mock runs as "dolphin".

Both parts verify their selections: label pixels inside a selected row must contrast with
the selection fill, in an active AND an inactive window (exit status 1 otherwise).
Usage: tools/qtwidgets_preview.py            (runs both parts)
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PART = sys.argv[1] if len(sys.argv) > 1 else None
if PART is None:
    rc = 0
    for part in ("dolphin", "widgets"):
        rc |= subprocess.call([sys.executable, os.path.abspath(__file__), part])
    sys.exit(rc)

cfg = tempfile.mkdtemp(prefix="kvprev-")
os.makedirs(os.path.join(cfg, "Kvantum"))
for t in ("Nothing", "NothingFiles"):
    os.symlink(os.path.join(ROOT, "kvantum", t), os.path.join(cfg, "Kvantum", t))
with open(os.path.join(cfg, "Kvantum", "kvantum.kvconfig"), "w") as f:
    # PREVIEW_NO_APPTHEME=1 reproduces the live bug (Dolphin on the plain theme)
    f.write("[General]\ntheme=Nothing\n" + ("" if os.environ.get("PREVIEW_NO_APPTHEME")
                                             else "\n[Applications]\nNothingFiles=dolphin\n"))
os.environ["XDG_CONFIG_HOME"] = cfg
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ.pop("QT_STYLE_OVERRIDE", None)

from PyQt6.QtCore import QPoint, QSize, Qt  # noqa: E402
from PyQt6.QtGui import QAction, QColor, QFont, QIcon, QPainter, QPixmap  # noqa: E402
from PyQt6.QtCore import QRect  # noqa: E402
from PyQt6.QtGui import QPalette as _QP  # noqa: E402,F401
from PyQt6.QtWidgets import QStyle, QStyledItemDelegate, QStyleOptionViewItem  # noqa: E402
from PyQt6.QtWidgets import (  # noqa: E402
    QAbstractItemView, QApplication, QCheckBox, QComboBox, QFrame, QGridLayout, QGroupBox,
    QHBoxLayout, QLabel, QLineEdit, QListView, QListWidget, QListWidgetItem, QMainWindow,
    QMenu, QProgressBar, QPushButton, QRadioButton, QScrollBar, QSlider, QSpinBox, QSplitter,
    QStatusBar, QTabBar, QTabWidget, QToolBar, QToolButton, QToolTip, QTreeWidget,
    QTreeWidgetItem, QVBoxLayout, QWidget)

app = QApplication(sys.argv)
app.setApplicationName("dolphin" if PART == "dolphin" else "qtwidgets-preview")
# the session exports QT_STYLE_OVERRIDE=kvantum-dark, which resolves <theme>Dark first
style = QApplication.setStyle("kvantum-dark") or QApplication.setStyle("kvantum")
if style is None:
    sys.exit("kvantum style plugin not available")
app.setPalette(style.standardPalette())
app.setFont(QFont("Inter", 10))
QIcon.setThemeSearchPaths([os.path.expanduser("~/.local/share/icons"), "/usr/share/icons"])
QIcon.setThemeName("Nothing")
OUT = os.path.join(ROOT, "previews")

# ── KIconEngine stand-in ─────────────────────────────────────────────────
# KDE apps load icons through KIconEngine, which recolours ".ColorScheme-Text" SVGs from the
# palette (Normal -> Text, Selected -> HighlightedText).  Kvantum asks for QIcon::Selected on
# white pills, so in real Dolphin the glyph turns black.  Plain PyQt has no KIconEngine, so
# emulate it here; otherwise the preview would show light-grey glyphs that KDE never draws.
from PyQt6.QtCore import QByteArray, QRectF  # noqa: E402
from PyQt6.QtGui import QIconEngine, QPalette  # noqa: E402
from PyQt6.QtSvg import QSvgRenderer  # noqa: E402
import re  # noqa: E402

_THEMES = [os.path.expanduser("~/.local/share/icons/Nothing"), "/usr/share/icons/Papirus-Dark",
           "/usr/share/icons/Papirus", "/usr/share/icons/breeze-dark", "/usr/share/icons/hicolor"]
_SMALL = ["22", "22x22", "24", "24x24", "16x16", "scalable", "32x32", "48", "48x48", "64x64"]
_LARGE = ["scalable", "64x64", "48", "48x48", "32x32", "24x24", "24", "22", "22x22", "16x16"]


def _find_svg(name, px=22):
    """Like KIconLoader: per theme (in inheritance order) pick the directory closest to px."""
    for root in _THEMES:
        for sz in (_SMALL if px <= 24 else _LARGE):
            d = os.path.join(root, sz)
            if not os.path.isdir(d):
                continue
            for ctx in sorted(os.listdir(d)):
                f = os.path.join(d, ctx, name + ".svg")
                if os.path.exists(f):
                    return os.path.realpath(f)
    return None


class KdeLikeEngine(QIconEngine):
    def __init__(self, name):
        super().__init__()
        self.name = name
        self.cache = {}

    def clone(self):
        return KdeLikeEngine(self.name)

    def src(self, px):
        path = _find_svg(self.name, px)
        if path not in self.cache:
            with open(path, "rb") as fh:
                self.cache[path] = fh.read().decode("utf-8", "replace")
        return self.cache[path]

    def paint(self, painter, rect, mode, state):
        pal = QApplication.palette()
        col = pal.color(QPalette.ColorRole.HighlightedText if mode == QIcon.Mode.Selected
                        else QPalette.ColorRole.Text).name()
        svg = re.sub(r"\.ColorScheme-Text\s*\{\s*color:\s*#[0-9a-fA-F]+", ".ColorScheme-Text { color:" + col, self.src(rect.height()))
        r = QSvgRenderer(QByteArray(svg.encode()))
        if mode == QIcon.Mode.Disabled:
            painter.setOpacity(0.4)
        r.render(painter, QRectF(rect))

    def pixmap(self, size, mode, state):
        pm = QPixmap(size)
        pm.fill(Qt.GlobalColor.transparent)
        p = QPainter(pm)
        self.paint(p, pm.rect(), mode, state)
        p.end()
        return pm


def kicon(name):
    return QIcon(KdeLikeEngine(name)) if _find_svg(name) else QIcon.fromTheme(name)


class HoverButton(QPushButton):
    """Forced-hover sample: the real style draws it with State_MouseOver (offscreen has no pointer)."""
    def paintEvent(self, e):
        from PyQt6.QtWidgets import QStyle, QStyleOptionButton, QStylePainter
        opt = QStyleOptionButton()
        self.initStyleOption(opt)
        opt.state |= QStyle.StateFlag.State_MouseOver
        opt.styleObject = None  # skip Kvantum's "hover bug" check (QCursor is outside offscreen)
        p = QStylePainter(self)
        p.drawControl(QStyle.ControlElement.CE_PushButton, opt)


class HoverToolButton(QToolButton):
    def paintEvent(self, e):
        from PyQt6.QtWidgets import QStyle, QStyleOptionToolButton, QStylePainter
        opt = QStyleOptionToolButton()
        self.initStyleOption(opt)
        opt.state |= QStyle.StateFlag.State_MouseOver | QStyle.StateFlag.State_Raised
        opt.styleObject = None
        p = QStylePainter(self)
        p.drawComplexControl(QStyle.ComplexControl.CC_ToolButton, opt)


def hover(w):
    """Mark a widget as hovered.  Qt recomputes WA_UnderMouse on show, so force_hover()
    re-applies it after the window is visible (offscreen has no real pointer)."""
    w.setProperty("_force_hover", True)
    return w


def force_hover(root):
    for c in root.findChildren(QWidget):
        if c.property("_force_hover"):
            c.setAttribute(Qt.WidgetAttribute.WA_Hover, True)
            c.setAttribute(Qt.WidgetAttribute.WA_UnderMouse, True)
            c.update()


def tbtn(icon, checkable=False, checked=False, text=None):
    b = QToolButton()
    b.setIcon(kicon(icon))
    b.setIconSize(QSize(22, 22))
    b.setAutoRaise(True)
    if text:
        b.setText(text)
        b.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonTextBesideIcon)
    b.setCheckable(checkable)
    b.setChecked(checked)
    return b


def settle(ms=400):
    """Let Kvantum's state animations finish before grabbing."""
    from PyQt6.QtCore import QElapsedTimer
    t = QElapsedTimer()
    t.start()
    while t.elapsed() < ms:
        app.processEvents()


def composite(base, popup, pos):
    pm = base.grab()
    p = QPainter(pm)
    p.drawPixmap(pos, popup.grab())
    p.end()
    return pm


# ── selection contrast check ──────────────────────────────────────────────
def check_selection(img, rect, label):
    """In a selected row, count pixels of the fill colour vs pixels far from it (= label/glyph).
    Fails if the label is invisible (no pixel differs strongly from the fill)."""
    from collections import Counter
    px = Counter(img.pixelColor(x, y).name() for x in range(rect.left() + 2, rect.right() - 2)
                 for y in range(rect.top() + 2, rect.bottom() - 2))
    fill = QColor(px.most_common(1)[0][0])
    far = sum(n for c, n in px.items() if abs(QColor(c).lightness() - fill.lightness()) > 110)
    ok = far > 40
    print(f"  {label}: fill {fill.name()}, label pixels {far} -> {'OK' if ok else 'INVISIBLE'}")
    if not ok:
        FAIL.append(label)


class DolphinDelegate(QStyledItemDelegate):
    """Paints like Dolphin's KStandardItemListWidget (kitemlistwidget.cpp / kstandarditemlistwidget.cpp,
    release/26.04): style PE_PanelItemViewItem with State_Selected (+State_Active only when the window is
    active and the view focused), then a Normal-mode icon and the label in QPalette::Text --
    Dolphin does NOT use HighlightedText for selected items (only while pressed)."""
    def __init__(self, view, icons_layout=False):
        super().__init__(view)
        self.view = view
        self.icons = icons_layout

    def paint(self, p, option, index):
        o = QStyleOptionViewItem(option)
        sel = bool(option.state & QStyle.StateFlag.State_Selected)
        o.state = QStyle.StateFlag.State_Enabled | QStyle.StateFlag.State_Item
        if sel:
            o.state |= QStyle.StateFlag.State_Selected
            if self.view.isActiveWindow() and self.view.hasFocus():
                o.state |= QStyle.StateFlag.State_Active
        if sel or (option.state & QStyle.StateFlag.State_MouseOver):
            if not sel:
                o.state |= QStyle.StateFlag.State_MouseOver
            self.view.style().drawPrimitive(QStyle.PrimitiveElement.PE_PanelItemViewItem, o, p, self.view)
        icon = index.data(Qt.ItemDataRole.DecorationRole)
        text = index.data(Qt.ItemDataRole.DisplayRole) or ""
        r = option.rect
        group = (QPalette.ColorGroup.Active if self.view.isActiveWindow() and self.view.hasFocus()
                 else QPalette.ColorGroup.Inactive)
        if not (index.flags() & Qt.ItemFlag.ItemIsEnabled):
            p.setPen(QColor("#8e8e8e"))
        else:
            p.setPen(option.palette.color(group, QPalette.ColorRole.Text))
        isz = self.view.iconSize()
        if self.icons:
            if icon:
                icon.paint(p, QRect(r.center().x() - isz.width() // 2, r.top() + 8, isz.width(), isz.height()))
            p.drawText(QRect(r.left() + 4, r.top() + 12 + isz.height(), r.width() - 8, 40),
                       Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop | Qt.TextFlag.TextWordWrap, text)
        else:
            x = r.left() + 10
            if icon:
                icon.paint(p, QRect(x, r.center().y() - isz.height() // 2, isz.width(), isz.height()))
                x += isz.width() + 10
            p.drawText(QRect(x, r.top(), r.right() - x, r.height()), Qt.AlignmentFlag.AlignVCenter, text)

    def sizeHint(self, option, index):
        return QSize(120, 132) if self.icons else QSize(200, 36)


def places_panel(delegate):
    lv = QListWidget()
    lv.setFrameShape(QFrame.Shape.NoFrame)
    lv.setIconSize(QSize(20, 20))
    for ic, name in (("user-home", "Home"), ("user-desktop", "Desktop"), ("folder-download", "Downloads")):
        lv.addItem(QListWidgetItem(kicon(ic), name))
    if delegate:
        lv.setItemDelegate(DolphinDelegate(lv))
    lv.setCurrentRow(0)
    return lv


def window_states(delegate, title):
    """Two copies of a Places-like panel: one in the active, focused window, one in an inactive window."""
    out = []
    inactive = QWidget()
    inactive.resize(230, 130)
    QVBoxLayout(inactive).addWidget(places_panel(delegate))
    active = QWidget()
    active.resize(230, 130)
    lv = places_panel(delegate)
    QVBoxLayout(active).addWidget(lv)
    inactive.show()
    active.show()
    active.activateWindow()
    lv.setFocus()
    settle()
    for w, state in ((active, "active"), (inactive, "inactive")):
        view = w.findChild(QListWidget)
        img = w.grab().toImage()
        rect = view.visualItemRect(view.item(0)).translated(view.viewport().mapTo(w, QPoint(0, 0)))
        check_selection(img, rect, f"{title} {state} window ({'active' if w.isActiveWindow() else 'inactive'})")
        out.append((state, w.grab()))
    return out


def strip(parts, title):
    """Label + the active/inactive panels side by side, for compositing into a preview."""
    W = sum(pm.width() for _, pm in parts) + 16 * (len(parts) + 1)
    pm = QPixmap(W, 160)
    pm.fill(QColor("#000"))
    p = QPainter(pm)
    p.setPen(QColor("#8e8e8e"))
    p.setFont(QFont("Space Mono", 8))
    x = 16
    for state, sub in parts:
        p.drawText(x, 14, f"{title} · {state} window".upper())
        p.drawPixmap(x, 22, sub)
        x += sub.width() + 16
    p.end()
    return pm


def stack(top, bottom):
    pm = QPixmap(max(top.width(), bottom.width()), top.height() + bottom.height())
    pm.fill(QColor("#000"))
    p = QPainter(pm)
    p.drawPixmap(0, 0, top)
    p.drawPixmap(0, top.height(), bottom)
    p.end()
    return pm


# ── Dolphin mock ─────────────────────────────────────────────────────────
def dolphin():
    win = QMainWindow()
    win.resize(1180, 720)
    win.setWindowTitle("Home — Dolphin")

    tb = QToolBar()
    tb.setMovable(False)
    tb.setIconSize(QSize(22, 22))
    win.addToolBar(tb)
    tb.addWidget(tbtn("go-previous"))
    tb.addWidget(tbtn("go-next"))
    # breadcrumb location bar (KUrlNavigator-like: flat crumbs on a field)
    crumbs = QFrame()
    crumbs.setObjectName("crumbs")
    cl = QHBoxLayout(crumbs)
    cl.setContentsMargins(4, 0, 4, 0)
    cl.setSpacing(0)
    for i, name in enumerate(["/", "home", "baron", "Projects"]):
        b = QToolButton()
        b.setText(name)
        b.setAutoRaise(True)
        cl.addWidget(b)
        if i < 3:
            a = QToolButton()
            a.setArrowType(Qt.ArrowType.RightArrow)
            a.setAutoRaise(True)
            a.setFixedWidth(16)
            cl.addWidget(a)
    cl.addStretch(1)
    loc = QLineEdit()
    loc.setMinimumWidth(460)
    lay = QHBoxLayout(loc)
    lay.setContentsMargins(6, 0, 6, 0)
    lay.addWidget(crumbs)
    tb.addWidget(loc)
    sp = QWidget()
    sp.setFixedWidth(12)
    tb.addWidget(sp)
    tb.addWidget(tbtn("view-list-icons", True, True))
    tb.addWidget(tbtn("view-list-text", True))
    tb.addWidget(tbtn("view-list-details", True))
    spacer = QWidget()
    spacer.setSizePolicy(spacer.sizePolicy().horizontalPolicy().Expanding,
                         spacer.sizePolicy().verticalPolicy().Preferred)
    tb.addWidget(spacer)
    search = QLineEdit()
    search.setPlaceholderText("Search…")
    search.addAction(kicon("edit-find"), QLineEdit.ActionPosition.LeadingPosition)
    search.setMinimumWidth(220)
    tb.addWidget(search)
    tb.addWidget(hover(tbtn("split")))
    tb.addWidget(tbtn("application-menu"))

    # places panel
    places = QListWidget()
    places.setFrameShape(QFrame.Shape.NoFrame)
    places.setIconSize(QSize(20, 20))
    places.setMinimumWidth(210)
    places.setMaximumWidth(230)
    sections = [("Places", [("user-home", "Home"), ("user-desktop", "Desktop"),
                            ("folder-documents", "Documents"), ("folder-download", "Downloads"),
                            ("folder-music", "Music"), ("folder-pictures", "Pictures"),
                            ("folder-videos", "Videos"), ("user-trash", "Trash")]),
                ("Remote", [("folder-network", "Network")]),
                ("Devices", [("drive-harddisk", "ROOT"), ("drive-removable-media", "USB stick")])]
    sel = None
    for title, items in sections:
        h = QListWidgetItem(title)
        h.setFlags(Qt.ItemFlag.NoItemFlags)
        f = QFont("Inter", 9)
        h.setFont(f)
        h.setForeground(QColor("#8e8e8e"))
        places.addItem(h)
        for ic, name in items:
            it = QListWidgetItem(kicon(ic), name)
            places.addItem(it)
            if name == "Home":
                sel = it
    places.setCurrentItem(sel)
    places.setItemDelegate(DolphinDelegate(places))

    # icon grid
    grid = QListWidget()
    grid.setViewMode(QListView.ViewMode.IconMode)
    grid.setFrameShape(QFrame.Shape.NoFrame)
    grid.setIconSize(QSize(80, 80))
    grid.setGridSize(QSize(128, 132))
    grid.setResizeMode(QListView.ResizeMode.Adjust)
    grid.setMovement(QListView.Movement.Static)
    grid.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)
    grid.setWordWrap(True)
    files = [("folder-desktop", "Desktop"), ("folder-documents", "Documents"),
             ("folder-download", "Downloads"), ("folder-music", "Music"),
             ("folder-pictures", "Pictures"), ("folder-videos", "Videos"),
             ("folder-publicshare", "Public"), ("folder-templates", "Templates"),
             ("folder", "Projects"), ("folder-games", "Games"), ("folder-git", "dotfiles"),
             ("text-x-generic", "notes.txt"), ("image-png", "wallpaper.png"),
             ("application-pdf", "invoice.pdf")]
    for ic, name in files:
        it = QListWidgetItem(kicon(ic), name)
        it.setTextAlignment(Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop)
        grid.addItem(it)
    grid.item(8).setSelected(True)
    grid.setCurrentRow(8)
    grid.setItemDelegate(DolphinDelegate(grid, icons_layout=True))

    tabs = QTabBar()
    tabs.setDocumentMode(True)
    tabs.setTabsClosable(True)
    tabs.setExpanding(False)
    tabs.addTab(kicon("user-home"), "Home")
    tabs.addTab(kicon("folder"), "Projects")
    tabs.addTab(kicon("folder-download"), "Downloads")
    tabs.setCurrentIndex(1)

    right = QWidget()
    rl = QVBoxLayout(right)
    rl.setContentsMargins(0, 0, 0, 0)
    rl.setSpacing(4)
    rl.addWidget(tabs)
    rl.addWidget(grid, 1)

    split = QSplitter()
    split.addWidget(places)
    split.addWidget(right)
    split.setStretchFactor(1, 1)
    win.setCentralWidget(split)

    sb = QStatusBar()
    win.setStatusBar(sb)
    sb.addWidget(QLabel("1 folder selected  ·  14 items"))
    zoom = QSlider(Qt.Orientation.Horizontal)
    zoom.setRange(0, 16)
    zoom.setValue(9)
    zoom.setFixedWidth(140)
    cap = QProgressBar()
    cap.setValue(62)
    cap.setFormat("212 GiB free")
    cap.setFixedWidth(180)
    sb.addPermanentWidget(cap)
    sb.addPermanentWidget(zoom)

    win.show()
    settle()

    menu = QMenu(win)
    menu.addAction(kicon("document-open"), "Open")
    menu.addAction(kicon("tab-new"), "Open in New Tab")
    menu.addSeparator()
    menu.addAction(kicon("edit-cut"), "Cut")
    act = menu.addAction(kicon("edit-copy"), "Copy")
    menu.addAction(kicon("edit-rename"), "Rename…")
    menu.addAction(kicon("edit-delete"), "Move to Trash")
    menu.addSeparator()
    sub = menu.addMenu(kicon("document-share"), "Share")
    sub.addAction("Bluetooth")
    c = menu.addAction("Show Hidden Files")
    c.setCheckable(True)
    c.setChecked(True)
    menu.addAction(kicon("document-properties"), "Properties")
    menu.popup(QPoint(0, 0))
    app.processEvents()
    menu.setActiveAction(sub.menuAction())
    settle()
    pm = composite(win, menu, QPoint(640, 300))
    menu.close()
    img = pm.toImage()
    for view, item, label in ((places, sel, "Dolphin mock: Places 'Home'"),
                              (grid, grid.item(8), "Dolphin mock: icon tile 'Projects'")):
        rect = view.visualItemRect(item).translated(view.viewport().mapTo(win, QPoint(0, 0)))
        check_selection(img, rect, label)
    pm = stack(pm, strip(window_states(True, "Dolphin places"), "Dolphin places"))
    pm.save(os.path.join(OUT, "qt-dolphin.png"))


# ── widgets gallery ──────────────────────────────────────────────────────
def gallery():
    w = QWidget()
    w.resize(1000, 700)
    g = QGridLayout(w)
    g.setContentsMargins(24, 24, 24, 24)
    # leave the grid's spacing to the style: unequal h/v spacing makes the nested
    # row layouts inherit -1 and collapse to 0px gaps (a harness bug, not the theme's)
    g.setColumnMinimumWidth(1, 24)

    def label(t):
        lab = QLabel(t.upper())
        lab.setFont(QFont("Space Mono", 8))
        lab.setStyleSheet("color:#8e8e8e; letter-spacing:1px")
        return lab

    # column 0
    col = QVBoxLayout()
    col.addWidget(label("Buttons"))
    row = QHBoxLayout()
    d = QPushButton("Default")
    d.setDefault(True)
    row.addWidget(d)
    row.addWidget(QPushButton("Normal"))
    row.addWidget(HoverButton("Hover"))
    dis = QPushButton("Disabled")
    dis.setEnabled(False)
    row.addWidget(dis)
    col.addLayout(row)
    row = QHBoxLayout()
    t = QPushButton("Toggled")
    t.setCheckable(True)
    t.setChecked(True)
    row.addWidget(t)
    row.addWidget(QPushButton(kicon("document-save"), "Save"))
    row.addWidget(tbtn("go-previous"))
    hb = HoverToolButton()
    hb.setIcon(kicon("go-next"))
    hb.setIconSize(QSize(22, 22))
    hb.setAutoRaise(True)
    row.addWidget(hb)
    row.addWidget(tbtn("view-list-icons", True, True))
    row.addStretch(1)
    col.addLayout(row)

    col.addWidget(label("Fields"))
    le = QLineEdit()
    le.setPlaceholderText("Placeholder text")
    col.addWidget(le)
    le2 = QLineEdit("Focused field")
    col.addWidget(le2)
    row = QHBoxLayout()
    cb = QComboBox()
    cb.addItems(["Icons", "Compact", "Details"])
    row.addWidget(cb)
    ecb = QComboBox()
    ecb.setEditable(True)
    ecb.addItems(["Editable combo"])
    row.addWidget(ecb)
    sp = QSpinBox()
    sp.setValue(42)
    row.addWidget(sp)
    col.addLayout(row)

    col.addWidget(label("Choices"))
    row = QHBoxLayout()
    for text, chk in (("Checked", True), ("Unchecked", False)):
        c = QCheckBox(text)
        c.setChecked(chk)
        row.addWidget(c)
    tri = QCheckBox("Partial")
    tri.setTristate(True)
    tri.setCheckState(Qt.CheckState.PartiallyChecked)
    row.addWidget(tri)
    col.addLayout(row)
    row = QHBoxLayout()
    r1 = QRadioButton("Selected")
    r1.setChecked(True)
    row.addWidget(r1)
    row.addWidget(QRadioButton("Other"))
    rd = QRadioButton("Disabled")
    rd.setEnabled(False)
    row.addWidget(rd)
    col.addLayout(row)

    col.addWidget(label("Slider · Progress"))
    s = QSlider(Qt.Orientation.Horizontal)
    s.setValue(60)
    col.addWidget(s)
    pb = QProgressBar()
    pb.setValue(45)
    col.addWidget(pb)
    pb2 = QProgressBar()
    pb2.setValue(80)
    pb2.setTextVisible(False)
    col.addWidget(pb2)
    col.addStretch(1)
    g.addLayout(col, 0, 0)

    # column 1
    col = QVBoxLayout()
    col.addWidget(label("Tabs"))
    tw = QTabWidget()
    for n in ("General", "Network", "Display"):
        page = QWidget()
        pl = QVBoxLayout(page)
        gb = QGroupBox("Group box")
        gl = QVBoxLayout(gb)
        gl.addWidget(QCheckBox("Option inside a card"))
        pl.addWidget(gb)
        tw.addTab(page, n)
    tw.setFixedHeight(150)
    col.addWidget(tw)

    col.addWidget(label("Tree · header"))
    tree = QTreeWidget()
    tree.setHeaderLabels(["Name", "Size", "Modified"])
    tree.setAlternatingRowColors(False)
    tree.setRootIsDecorated(True)
    for n, sz in (("Documents", "12 items"), ("Pictures", "340 items"), ("Music", "88 items")):
        it = QTreeWidgetItem([n, sz, "Today"])
        it.setIcon(0, kicon("folder"))
        for k in range(3):
            ch = QTreeWidgetItem([f"file-{k}.txt", "4 KiB", "Yesterday"])
            ch.setIcon(0, kicon("text-x-generic"))
            it.addChild(ch)
        tree.addTopLevelItem(it)
    tree.expandItem(tree.topLevelItem(1))
    tree.setCurrentItem(tree.topLevelItem(1).child(1))
    tree.setColumnWidth(0, 200)
    col.addWidget(tree, 1)

    row = QHBoxLayout()
    for orient in (Qt.Orientation.Vertical,):
        sbv = QScrollBar(orient)
        sbv.setRange(0, 100)
        sbv.setPageStep(30)
        sbv.setValue(20)
        sbv.setFixedHeight(120)
        row.addWidget(sbv)
    sbh = QScrollBar(Qt.Orientation.Horizontal)
    sbh.setRange(0, 100)
    sbh.setPageStep(25)
    sbh.setValue(50)
    row.addWidget(sbh, 1, Qt.AlignmentFlag.AlignVCenter)
    tip_anchor = QPushButton("Hover me")
    row.addWidget(tip_anchor)
    col.addWidget(label("Scrollbars · tooltip"))
    col.addLayout(row)
    g.addLayout(col, 0, 2)

    w.show()
    app.processEvents()
    w.activateWindow()
    le2.setFocus()
    settle()
    force_hover(w)  # right before grab: event processing would clear it again
    pm = w.grab()
    QToolTip.showText(tip_anchor.mapToGlobal(QPoint(0, 0)), "Tooltip in a #1a1a1a pill", tip_anchor)
    app.processEvents()
    tips = [x for x in app.topLevelWidgets() if x.inherits("QTipLabel") and x.isVisible()]
    p = QPainter(pm)
    if tips:
        tp = tips[0].grab()
        p.drawPixmap(tip_anchor.mapTo(w, QPoint(-tp.width() + tip_anchor.width(), -tp.height() - 8)), tp)
    # an open combo popup is not grab-able; draw the menu style instead
    p.end()
    pm = stack(pm, strip(window_states(False, "QListView"), "QListView"))
    pm.save(os.path.join(OUT, "qt-widgets.png"))


FAIL = []
if PART == "dolphin":
    dolphin()
    print(os.path.join(OUT, "qt-dolphin.png"))
else:
    gallery()
    print(os.path.join(OUT, "qt-widgets.png"))
for f in FAIL:
    print("FAIL:", f)
sys.exit(1 if FAIL else 0)
