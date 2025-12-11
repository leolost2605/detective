# Activating by just running the flatpak command takes almost a second (~ 700ms) whereas
# using dbus directly runs in < 100ms
# We can't use dbus-send because that doesn't support empty vardicts (or vardicts at all?)

import dbus

bus_name = 'io.github.leolost2605.detective'
interface_name = 'org.freedesktop.Application'
object_path = '/io/github/leolost2605/detective'

app = dbus.SessionBus().get_object(bus_name, object_path)
app.Activate([], dbus_interface=interface_name)
