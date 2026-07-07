# Shotput for Brainrot — Localization Helpers
#
# UEFN's UI widgets accept the `message` type rather than raw strings. `message`
# values must be produced by a function marked `<localizes>`. This tiny helper
# wraps an arbitrary string into a message so gameplay code can build dynamic HUD
# text (coin counts, distances, etc.) without a separate loc table per string.
#
# For a shipping title you would replace these with proper localized string tables.

using { /Verse.org/Simulation }

# Wrap a runtime string into a localizable message for UI widgets.
ToMessage<public><localizes>(Value:string):message = "{Value}"
