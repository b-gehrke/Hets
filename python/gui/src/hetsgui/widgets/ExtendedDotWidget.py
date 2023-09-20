import logging

import gi
import xdot
from gi.repository import Gtk, GObject, Gdk

from xdot.ui import DotWidget


class ExtendedDotWidget(DotWidget):
    __gtype_name__ = "ExtendedDotWidget"

    __gsignals__ = {
        "node-right-click": (GObject.SIGNAL_RUN_FIRST, None, (str, object)),
        "edge-right-click": (GObject.SIGNAL_RUN_FIRST, None, (str, str, object))
    }

    _logger = logging.getLogger(__name__)

    dotcode = GObject.Property(type=str)

    def __init__(self):
        super().__init__()

        self.connect("notify::dotcode", self.on_dotcode_changed)

    def on_dotcode_changed(self, widget, param):
        dotcode = self.dotcode.encode("utf8")

        self.set_dotcode(dotcode)

    def on_key_press_event(self, widget, event):
        # Disable functionality like quitting on q, focusing search widget with f etc.
        if event.keyval < Gdk.KEY_a or event.keyval > Gdk.KEY_z:
            super().on_key_press_event(widget, event)

    def on_click(self, element, event):
        if element is None:
            jump = self.get_jump(event.x, event.y)
            element = jump.item if jump is not None else None

        if element is None:
            return True

        if event.button == 3:  # on right click
            self._logger.debug("Right click on %s", element)
            if isinstance(element, xdot.ui.elements.Node):
                node_id = element.id.decode("utf-8")

                self.emit("node-right-click", node_id, event)
            elif isinstance(element, xdot.ui.elements.Edge):
                src_id, dst_id = element.src.id.decode("utf-8"), element.dst.id.decode("utf-8")

                self.emit("edge-right-click", src_id, dst_id, event)

        return True
