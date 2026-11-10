// Turn every Plasma panel into a floating Nothing dock with only the task
// icons, and drop the stock desktop clocks (the shell draws its own).
// User widgets on the desktop are left untouched.
for (const p of panels()) {
    for (const w of p.widgets()) {
        if (w.type !== "org.kde.plasma.icontasks") w.remove();
    }
    p.location = "bottom";
    p.height = 56;
    p.floating = true;
    p.lengthMode = "fit";
    p.alignment = "center";
    p.hiding = "none";
}
for (const d of desktops()) {
    for (const w of d.widgets()) {
        if (w.type === "org.kde.plasma.digitalclock") w.remove();
    }
}
