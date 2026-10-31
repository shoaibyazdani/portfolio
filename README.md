# Shoaib Latif — portfolio

Single-file portfolio site for Shoaib Latif, QA Automation Lead. JCREA-style layout:
dark pill nav, hero with portrait, services band, experience timeline, the portfolio
row of live products, field notes, and a dark footer.

## What's here

- `index.html` — the whole site. No build step, no CDN, no external requests.
- `assets/` — portrait cutout, live product screenshots, and the small scripts used to
  produce them (`cutout.swift` / `dematte.swift` run Apple Vision on-device to remove
  the portrait background; `ownrs-card.html` composes the Ownrs card art).

## Run it

Open `index.html` in a browser, or serve the folder:

    python3 -m http.server 8000

## The portfolio row

Five live products, screenshotted from the real sites and linked in place:

| Card | Company | Tool |
| --- | --- | --- |
| RHK Properties | AHK Solutions | Playwright |
| Ownrs | AHK Solutions | Playwright |
| OMC UAE | AHK Solutions | Playwright |
| eShaafi | Terafort | Appium |
| Aspire AI | Terafort | Appium |

Filter chips (All / Playwright / Appium / CI/CD / Payments) filter by each card's tags.

## Notes

- Performance: no `backdrop-filter` anywhere and no per-frame JS loops. The marquee is a
  CSS animation paused unless it is on screen; doodles are `visibility: hidden` at rest.
- Motion respects `prefers-reduced-motion`; reduced-transparency and increased-contrast
  are handled too.
- The site is self-contained: no fonts, images or scripts are fetched from the network.
