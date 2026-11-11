#!/usr/bin/env python3
"""Render the Nothing Kvantum theme offscreen -> previews/qt-dolphin.png, previews/qt-widgets.png

Uses the real Kvantum style plugin with the theme from kvantum/Nothing (via a
private XDG_CONFIG_HOME, so the user's live config is never touched), the real
Nothing icon theme, and Inter as UI font.  Usage: tools/qtwidgets_preview.py [theme]
"""
import os
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME = sys.argv[1] if len(sys.argv) > 1 else "Nothing"

# private config dir: Kvantum/kvantum.kvconfig -> theme, Kvantum/<theme> -> repo copy
cfg = tempfile.mkdtemp(prefix="kvprev-")
os.makedirs(os.path.join(cfg, "Kvantum"))
src = os.path.join(ROOT, "kvantum", THEME)
if os.path.isdir(src):
    os.symlink(src, os.path.join(cfg, "Kvantum", THEME))
with open(os.path.join(cfg, "Kvantum", "kvantum.kvconfig"), "w") as f:
    f.write(f"[General]\ntheme={THEME}\n")
os.environ["XDG_CONFIG_HOME"] = cfg
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ.pop("QT_STYLE_OVERRIDE", None)

from PyQt6.QtCore import QPoint, QSize, Qt  # noqa: E402
from PyQt6.QtGui import QAction, QColor, QFont, QIcon, QPainter, QPixmap  # noqa: E402
from PyQt6.QtWidgets import (  # noqa: E402
    QAbstractItemView, QApplication, QCheckBox, QComboBox, QFrame, QGridLayout, QGroupBox,
    QHBoxLayout, QLabel, QLineEdit, QListView, QListWidget, QListWidgetItem, QMainWindow,
    QMenu, QProgressBar, QPushButton, QRadioButton, QScrollBar, QSlider, QSpinBox, QSplitter,
    QStatusBar, QTabBar, QTabWidget, QToolBar, QToolButton, QToolTip, QTreeWidget,
    QTreeWidgetItem, QVBoxLayout, QWidget)

app = QApplication(sys.argv)
# the session exports QT_STYLE_OVERRIDE=kvantum-dark, which resolves <theme>Dark first
style = QApplication.setStyle("kvantum-dark") or QApplication.setStyle("kvantum")
if style is None:
    sys.exit("kvantum style plugin not available")
app.setPalette(style.standardPalette())
app.setFont(QFont("Inter", 10))
QIcon.setThemeSearchPaths([os.path.expanduser("~/.local/share/icons"), "/usr/share/icons"])
QIcon.setThemeName("Nothing")
OUT = os.path.join(ROOT, "previews")


def hover(w):
    w.setAttribute(Qt.WidgetAttribute.WA_UnderMouse, True)
    return w


def tbtn(icon, checkable=False, checked=False, text=None):
    b = QToolButton()
    b.setIcon(QIcon.fromTheme(icon))
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
    search.addAction(QIcon.fromTheme("edit-find"), QLineEdit.ActionPosition.LeadingPosition)
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
            it = QListWidgetItem(QIcon.fromTheme(ic), name)
            places.addItem(it)
            if name == "Home":
                sel = it
    places.setCurrentItem(sel)

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
        it = QListWidgetItem(QIcon.fromTheme(ic), name)
        it.setTextAlignment(Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop)
        grid.addItem(it)
    grid.item(8).setSelected(True)
    grid.setCurrentRow(8)

    tabs = QTabBar()
    tabs.setDocumentMode(True)
    tabs.setTabsClosable(True)
    tabs.setExpanding(False)
    tabs.addTab(QIcon.fromTheme("user-home"), "Home")
    tabs.addTab(QIcon.fromTheme("folder"), "Projects")
    tabs.addTab(QIcon.fromTheme("folder-download"), "Downloads")
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
    menu.addAction(QIcon.fromTheme("document-open"), "Open")
    menu.addAction(QIcon.fromTheme("tab-new"), "Open in New Tab")
    menu.addSeparator()
    menu.addAction(QIcon.fromTheme("edit-cut"), "Cut")
    act = menu.addAction(QIcon.fromTheme("edit-copy"), "Copy")
    menu.addAction(QIcon.fromTheme("edit-rename"), "Rename…")
    menu.addAction(QIcon.fromTheme("edit-delete"), "Move to Trash")
    menu.addSeparator()
    sub = menu.addMenu(QIcon.fromTheme("document-share"), "Share")
    sub.addAction("Bluetooth")
    c = menu.addAction("Show Hidden Files")
    c.setCheckable(True)
    c.setChecked(True)
    menu.addAction(QIcon.fromTheme("document-properties"), "Properties")
    menu.popup(QPoint(0, 0))
    app.processEvents()
    menu.setActiveAction(act)
    settle()
    pm = composite(win, menu, QPoint(640, 300))
    menu.close()
    pm.save(os.path.join(OUT, "qt-dolphin.png"))


# ── widgets gallery ──────────────────────────────────────────────────────
def gallery():
    w = QWidget()
    w.resize(1000, 700)
    g = QGridLayout(w)
    g.setContentsMargins(24, 24, 24, 24)
    g.setHorizontalSpacing(24)
    g.setVerticalSpacing(14)

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
    row.addWidget(hover(QPushButton("Hover")))
    dis = QPushButton("Disabled")
    dis.setEnabled(False)
    row.addWidget(dis)
    col.addLayout(row)
    row = QHBoxLayout()
    t = QPushButton("Toggled")
    t.setCheckable(True)
    t.setChecked(True)
    row.addWidget(t)
    row.addWidget(QPushButton(QIcon.fromTheme("document-save"), "Save"))
    row.addWidget(tbtn("go-previous"))
    row.addWidget(hover(tbtn("go-next")))
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
        it.setIcon(0, QIcon.fromTheme("folder"))
        for k in range(3):
            ch = QTreeWidgetItem([f"file-{k}.txt", "4 KiB", "Yesterday"])
            ch.setIcon(0, QIcon.fromTheme("text-x-generic"))
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
    g.addLayout(col, 0, 1)

    w.show()
    app.processEvents()
    w.activateWindow()
    le2.setFocus()
    settle()
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
    pm.save(os.path.join(OUT, "qt-widgets.png"))


dolphin()
gallery()
print(os.path.join(OUT, "qt-dolphin.png"))
print(os.path.join(OUT, "qt-widgets.png"))
