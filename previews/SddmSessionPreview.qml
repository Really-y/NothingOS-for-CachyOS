import QtQuick
// SDDM login: single user (avatar in the pill), failed login + caps lock, session menu open.
SddmMock { users: 1; message: "Login failed"; capsLock: true; menuOpen: true }
