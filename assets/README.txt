Portrait slot
-------------
portrait.png  — the cut-out used by the hero and the why-hire card.
                Drop a replacement with the same name and both update.

source-orange.png / portrait-navy.png — the current photo and its cut-out
                                        (orange blazer, transparent already)
source-navy.png / portrait-navy.png   — the earlier navy-suit photo

If a replacement photo still has a background, cut it out on-device
(same model Preview uses for "Remove Background"):

    swift cutout.swift <input> portrait.png

Trim transparent margins with trim.swift, and alphacheck.swift tells you
whether a PNG is really transparent before you trust it.
