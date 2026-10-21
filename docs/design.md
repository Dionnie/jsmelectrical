# JSM Electrical: revamp design

The design system for the new site. This file holds the rules and tokens; `docs/design.html` is the working prototype that implements them (open it at `https://jsmelectrical.test/docs/design.html`). If the two disagree, this file wins and the prototype gets fixed. Page copy: `docs/content/`. Business facts and content gaps: `docs/company.md`.

## Direction

- **Booking first, with the wow.** The visitor is often a homeowner who isn't confident online and just wants an electrician. Every page answers three questions fast: can JSM do my job, do they cover my area, and how do I book. The look still has to impress the owners, who like their current site's big photos and ute hero.
- **Image-rich and real.** JSM's own ute photo fills the hero; their photos, and close-up crops of them, fill the "On the job" mosaic. Stock photos only stand in on the service cards.
- **Professional and local.** Black and white like the ute and the clad sheds, with soil and eucalyptus green from the landscape. The logo's slanted M shows up as a detail: the kicker slash, the dark section's slanted top edge, the photo wipe.
- **Calm motion.** Things animate once as they arrive. Nothing loops or moves on its own afterwards.

## Usability rules

Every design decision is checked against these:

1. **One primary action everywhere: book.** The green button always says "Book an electrician", "Book this" or "Book online". The secondary action is always the phone call. Never more than two actions side by side.
2. **Booking starts on the first screen.** A quick booking bar overlaps the bottom of the hero. Picking a service there, or on any service card, opens the booking form at step 2 with that service already chosen.
3. **The phone number is always one tap away:**
   - in the header;
   - in the hero;
   - in the booking bar ("Not sure? Call us");
   - on the "Not sure what you need?" card;
   - on the booking card;
   - in the footer;
   - on phones, in a fixed Call / Book bar that hides while the booking form is on screen.
4. **Few choices at a time (Hick's law):**
   - four nav links;
   - six options in the booking bar and in the service cards: the five services plus "Not sure";
   - a booking form in three short steps.
5. **No surprises:**
   - no auto-advancing carousels or tabs;
   - no scroll-jacking or hover-only menus.
6. **Easy to read and tap:**
   - body text 17px, inputs 17px;
   - buttons and controls at least 52px tall (46px for the small card buttons);
   - labels above fields;
   - white text on photos only over a dark gradient.
7. **Plain words:**
   - "Book an electrician", not "Schedule a project consultation";
   - errors say what to do.
8. **Honest:** no promises the business hasn't made. Response times, after-hours work, licences and reviews stay `[gap: …]` until confirmed.

## Assets

| File | What it is |
|---|---|
| `docs/assets/logo.svg` | Vector logo (`currentColor`). "JSM" traced from the live PNG; "ELECTRICAL" rebuilt from its measured rectangles. [gap: the original logo source files] |
| `docs/assets/logo.png` | Live logo, 189×80, white on transparent. Too small for large use |
| `docs/assets/favicon.png` | Live favicon, 256×256 |
| `docs/assets/photo-ute-viaduct.jpg` | JSM ute with the door logo, on a rural site (1920×1080). Hero; also cropped for the mosaic |
| `docs/assets/photo-ute-tools.jpg` | JSM ute with the canopy open and tools on the shelves (1440×810). Mosaic and the booking background |

**Logo sizes.**
- **Header:** 150–186px wide (132px on phones). White over the hero photo; black once the header turns solid.
- **Footer:** white, 200–260px wide.
- **Ute illustration:** on the door, with the phone number.
- **Watermarks:** faint, on dark surfaces only.

Never use it as a giant hero graphic.

**Photo crops.** The mosaic reuses the two photos with CSS: the tile sets `--x`, `--y` (the focal point, as `object-position` and `transform-origin`) and `--z` (zoom). The door logo is at about 85% / 69% of `photo-ute-viaduct.jpg`; the tools shelf is at about 80% / 45% of `photo-ute-tools.jpg`. [gap: more JSM job photos would replace the stock service images]

## Tokens

| Token | Value | Use |
|---|---|---|
| `ink` | `#141414` | Headings, logo, dark section, footer |
| `text` | `#23211D` | Body text |
| `muted` | `#5F5A51` | Secondary text (6:1 on `bone`) |
| `bone` | `#F4F1EA` | Page background, solid header |
| `sand` | `#EAE4D7` | Alternate sections |
| `line` | `#DCD4C4` | Borders, field outlines |
| `white` | `#FFFFFF` | Cards, booking bar, form |
| `gum` | `#2E4A36` | Primary buttons, links, selected choices (white text 10:1) |
| `gum-2` | `#223829` | Button hover |
| `gum-tint` | `#E3EADF` | Selected choice background, hover on booking options |
| `sage` / `sage-light` | `#8FA382` / `#C9D3BF` | Accents on dark and on photos |
| `soil` / `clay` | `#6B4E37` / `#A9825F` | Kickers, `[gap: …]` tags |
| `error` | `#A3361F` | Error text and borders (6:1 on white) |
| `shade` | `rgb(12,14,12)` | Photo overlays: 80% at the text edge, fading to clear over the ute |
| `on-dark` / `on-dark-muted` | `#EDEAE3` / `#A9A59C` | Text on `ink` |

**Type.** Archivo for headings (width 108–112% echoes the wide "ELECTRICAL"); Inter for everything else.

| Role | Font | Size |
|---|---|---|
| H1 (hero) | Archivo 780 | `clamp(2.4rem, 4.8vw, 4.2rem)` / 1.02, max 18ch |
| H2 | Archivo 750 | `clamp(1.9rem, 3.4vw, 2.8rem)` / 1.08 |
| H3, card titles | Archivo 700–750 | 19–26px |
| Kicker | Archivo 700, uppercase | 12.5px, tracking .2em, green slash first |
| Body, inputs | Inter 400 | 17px / 1.6 |
| Supporting text | Inter 400 | 14.5–15.5px |
| Buttons, labels | Inter 600 | 15–17px |

**Layout.** Container 1200px; gutter `clamp(16px, 4vw, 40px)`; section padding `clamp(64px, 8vw, 112px)`; header 96px (76px on phones). Breakpoints: 1000 (nav becomes a "Menu" button; the booking bar stacks), 960 (columns stack), 760 (phone hero and the fixed bar), 600, 520, 420.

**Shape.** Radius 6px on buttons and fields, 14–16px on cards, photos, the booking bar and the form. The dark section has a slanted top edge, rising left to right (`--slant`, 28–64px).

## Page: home

1. **Header:**
   - logo, Services, How it works, Areas, Contact, "Call us 0429 400 287", "Book an electrician";
   - transparent with white text over the hero, solid `bone` once scrolled;
   - below 1000px, a labelled "Menu" button.
2. **Hero:**
   - the JSM ute photo, full screen (88svh, max 820px), easing in from a slight zoom;
   - kicker "Geelong · Bellarine · Surf Coast";
   - H1 "Reliable electricians for homes, businesses and beyond." (the live tagline, made personal);
   - one line on what JSM does, plus "your first consultation is free";
   - "Book an electrician" and "Call 0429 400 287", with three ticks below.

   On phones the photo is a band at the top, with the ute and door logo in view, fading into dark behind the text.
3. **Quick booking bar:** a white card overlapping the hero's bottom edge: "Book in about a minute", five service buttons and a dark "Not sure? Call us".
4. **What we can help with:** five photo cards (title on the photo, one line, "Book this") and a dark "Not sure what you need?" card with the phone number and a watermark logo.
5. **How it works:** three numbered steps: tell us what you need, we call you back, free consultation.
6. **On the job:** a mosaic of JSM's own photos:
   - the ute with its tools;
   - a crop of the door logo;
   - a crop of the tools shelf;
   - a green "Need an electrician? Book now" tile.

   The tiles wipe in along the M's slant.
7. **Why choose us (dark):**
   - three facts: 2023 founded, 5 services, 3 home regions;
   - four reasons: qualified team, safety first, on time, remote sites too;
   - a watermark logo.
8. **We come to you:** service areas as pins, "Not sure if we cover your area? Call", then a full-width panorama. The ute drives in once, past the Geelong, Bellarine and Surf Coast road signs, and parks by the farmhouse.
9. **Reviews:** placeholder until real reviews exist. [gap: reviews]
10. **Book an electrician:**
    - over a dark photo of the ute's tools;
    - the call card, email, location and hours on the left;
    - the form on the right.

    [gap: hours]
11. **Footer:** white logo, services, contact (phone first), company links, REC and ABN. [gap: REC, ABN, social links]

Service pages (one template): a photo hero with the service name and "Book this service"; what's included (from `docs/content/<service>.md`); photos; the booking form with the service preselected.

## Booking form

A three-step form on a white card, with a progress bar ("Step 2 of 3 · Your details").

| Step | Asks | Notes |
|---|---|---|
| 1. Service | Homes, Business & commercial, Industrial, Renovation, Underground, Not sure yet | Big radio cards; picking one moves to step 2 |
| 2. Your details | Name, phone, suburb (required); email (optional) | Shows the chosen service with a "Change" link |
| 3. Call-back time | Morning 9–12, Afternoon 12–3, Late afternoon 3–5, Evening 5–7; optional message | Times from the live form |

- **Errors:** checked on "Next", shown under each field in plain words, and focus moves to the first problem.
- **Confirmation:** names the person, the number and the time, and repeats the phone number.

**Differences from the live form**, for the business to confirm:
- email is optional;
- one "suburb" field replaces address, city and state.

[gap: where submissions are sent, and whether email should stay required]

## Motion

All one-off, on arrival:

- **Hero:** the photo eases from 112% to 100% over 2.6s; the kicker, headline, text, buttons and ticks rise in with a 0.12s stagger.
- **Sections:** fade up 18px once as they enter (0.8s, `cubic-bezier(.16,1,.3,1)`).
- **Mosaic:** tiles wipe in left to right behind a slanted edge (1.3s, 0.12s stagger).
- **Ute:** drives in once (3.2s, easing out) with turning wheels and a little dust, then stays parked.
- **Hover:** colour, border and shadow only, plus a 2–3px lift on cards and a slow zoom on photos.
- **Reduced motion:** everything shows its end state, and the ute is already parked.

## Accessibility

- 3px gum focus outline on everything interactive.
- Each form step is a `fieldset` with a `legend`. Step changes and errors are announced through a polite live region, and errors are linked to their fields with `aria-describedby`.
- White text on photos always sits over a gradient of at least 55% `shade`.
- Phone and email are real links everywhere. The menu button has a visible label ("Menu" / "Close").
- Content photos and crops have descriptive alt text; decorative stock photos and watermarks are hidden from screen readers. The ute illustration has an SVG `<title>`.

## Build notes (WordPress)

- Tokens go into `theme.json` (palette slugs as named above; Archivo and Inter self-hosted through `fontFace`; the type sizes and spacing).
- The logo is an inline SVG symbol in the theme (header, ute illustration, footer, watermarks), never the PNG.
- Each home section becomes a block pattern. The quick booking bar, the ute illustration and the booking form are small blocks with their own script, loaded only where used.
- The booking form needs a real handler: a form plugin or a few lines of site code that email the request and save it. Ask before adding a plugin.
- Real photos go through the Media Library, resized and served as WebP; the hero photo needs a large size (about 1920px) and is not lazy-loaded.
