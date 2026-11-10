import QtQuick
// Lock screen with the prompt open: typed password, error + caps lock line, media card.
LockscreenMock {
    showPrompt: true
    typed: "hunter22"
    notification: "Unlocking failed"
    media: ({ track: "Dots & Lines", artist: "Glyph Ensemble", playing: true })
}
