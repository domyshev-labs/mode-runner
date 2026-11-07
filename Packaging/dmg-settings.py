"""Finder layout for the release DMG, generated without Finder automation."""
from pathlib import Path

application = Path(defines["app"]).resolve()
format = "UDZO"
files = [str(application), (defines["readme"], "Read Me.txt")]
symlinks = {"Applications": "/Applications"}
background = defines["background"]
icon = str(application / "Contents/Resources/AppIcon.icns")
# Do not set hide_extensions on the app: FinderInfo changes invalidate its signature.
window_rect = ((180, 180), (640, 480))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
arrange_by = None
grid_spacing = 80
icon_size = 96
text_size = 13
label_pos = "bottom"
icon_locations = {
    application.name: (168, 208),
    "Applications": (472, 208),
    "Read Me.txt": (544, 400),
}
