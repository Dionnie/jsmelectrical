# JSM Electrical: company and site brief

From the live site https://jsmelectrical.com.au/ (read 2026-10-21); its full copy is in `docs/content/`, one file per page. Facts marked (FB) and (IG) are from JSM's Facebook and Instagram (read 2026-10-22; everything they showed, and how far to trust them: `docs/facebook.md`, `docs/instagram.md`). `[gap: …]` = not on the live site: ask the user, never guess.

## Business

- Name: JSM Electrical. Legal name: JSM Electrical Pty Ltd (IG display name). ABN: [gap: not on the site; ABR searches for "JSM Electrical" and "JSM Electrical Pty Ltd" (2026-10-22) show no Geelong match].
- Founded 2023. Electrical maintenance and service repair company based in Geelong, Victoria.
- REC 34685 (IG bio; not on the site or Facebook). [gap: verify on Energy Safe Victoria's register; insurance and accreditations]
- Testing: a Fluke 1672 multifunction tester since June 2026, for digital test and commissioning reports (IG).
- Owner and team: "Jack", named in both Facebook reviews and the Instagram bio; the email is jack@. Cooper works the NT community jobs, and Tom was a first-year apprentice in August 2024 (IG). Hiring an A-grade electrician and a 3rd/4th-year apprentice (IG, May 2026). [gap: full names, roles, team size]
- Phone: 0429 400 287. Email: jack@jsmelectrical.com.au. Address: the site shows only "Geelong, Victoria"; Facebook lists 6 Cameron Court, Clifton Springs VIC 3222, on the Bellarine (FB). [gap: OK to show the street address on the site? It may be a home address]
- Hours: [gap: none stated on the site or Facebook; the contact form offers call-back windows 9am–7pm].
- Emergency or after-hours: [gap: "emergency repairs" is listed for business and commercial only; no after-hours terms].
- Service area: Geelong, the Bellarine Peninsula (Portarlington named) and the Surf Coast; also rural and remote jobs across Australia.
- Remote work (FIFO), mostly community telecommunications (IG, FB):
  - Mornington Island, QLD (Aug 2024): internet and phone to every home;
  - Hope Vale and Wujal Wujal, Cape York, QLD (June 2025): a 15m radio tower and service calls;
  - Elcho Island (Galiwinku), NT (Aug 2025): wireless access points;
  - Groote Eylandt, NT (Nov 2025): communication booths, solar and maintenance.

  Instagram story highlights also name NSW and WA.
- Vehicle: a white Toyota Hilux single-cab ute with a roof rack. Door: the chrome "HILUX 2.7 VVT-i" badge, the JSM Electrical logo and "0429 400 287" (from the user, 2026-10-22). Facebook also shows a white van with the logo (cover photo) and a white tray-back ute with the door logo.

## Services

Live menu order; priority: [gap]. Copy for each: `docs/content/<file>`.

- Business and Commercial: `business-and-commercial.md`
- Industrial: `industrial.md`
- Homes: `homes.md`
- Renovations: `renovations.md`
- Underground: `underground.md`

Facebook posts (May 2025) also push LED lighting and signage for shops and commercial spaces: "Electrical and Lighting Services for Businesses" (FB).

Instagram shows work the site never names (IG):
- new builds with builders (temporary poles, fit-outs);
- pools and garden lighting;
- gate motors;
- sports, billboard and feature lighting;
- office LED fit-outs;
- sheds, farms and equine work (horse walkers, paddock light towers);
- tiny homes.

The revamp regroups all of this into five services named after the customer: Homes; Renovations & new builds; Business & commercial; Rural & industrial; Remote & telecommunications. The groups, their web addresses and redirects are in `docs/design.md`, "Services". [gap: JSM to confirm the grouping]

## Positioning and voice

- Tagline, values and "why choose us": `docs/content/home.md`, `docs/content/about-us.md`.
- Customers: homeowners and renovators, businesses and shops, industrial sites, telecommunications and public infrastructure. Also builders: OneBuild Geelong, Prebble Constructions and Mittabuild tag JSM in their posts (IG).
- Voice: professional, safety- and quality-led, Australian English. Words to use or avoid: [gap].
- Testimonials and reviews: none on the site. Facebook has two recommendations, both praising Jack (FB):
  - Liam D. (about 2024–25): professional, accommodating and knowledgeable;
  - Jamie N., "the Zuri Team" (1 April 2025): professional, detailed and friendly, left everything clean and tidy, highly recommends.

  [gap: the reviewers' OK to quote them on the site, and how to name them]

## Site

- Pages: one file each in `docs/content/`, with the live URL, title tag and meta description; keep or redirect those URLs, and keep our 301s from `/homes-2/`, `/industrial-2/` and `/services/…`. Header and footer: `docs/content/site-wide.md`.
- Main call to action: a free project consultation, by the contact form (`docs/content/contact-us.md`), email or phone.
- Brand: monochrome. `#000000` primary and accent, `#373737` secondary, `#555555` text, greys `#AAAAAA` `#CCCCCC`, white. Headings Electrolize (500/600), body Poppins (400; 500 accent, 700 display).
- Logo: live `wp-content/uploads/2026/10/JSM-Eletrical-Logo.png` (the same 189×80 image as the old `2025/01/Block.png`, re-uploaded with alt text); favicon `wp-content/uploads/2025/04/favicon-256@2x.png`. The original logo is two-colour: black, with grey `#9F9F9F` on the J's tick and the M's diagonal (as on the ute door); the live header shows it all white, so the grey is lost there. Source files: [gap]. Our rebuilt set, with every variant: `docs/assets/logo/`, overview `docs/logo.html`.
- Social: the live site links Facebook and Instagram (Twitter and YouTube icons removed, 2026-10-22). Facebook: https://www.facebook.com/profile.php?id=61574767686775 (131 followers; links only to the website). Instagram: https://www.instagram.com/jsm.electrical_/ (367 followers, 25 posts; no website link in the bio).
- Photos on Facebook (FB): about 19, a dozen of real work: the Cape York radio tower, a solar and comms cabinet, the team in hi-vis, a shop fit-out with track lighting, a shed and a garage with hexagon LED lighting, rooftop antenna work, and the vehicles. Instagram has about 20 jobs with places and dates: `docs/instagram.md`. [gap: full-size originals from JSM; these could replace the stock service images]
- Live stack: WordPress with Elementor Pro on a Hello Elementor child theme, Site Kit (Google Analytics), Cloudflare; built by Global Webforce.

## Live-site faults

Rechecked on 2026-10-22, after our fixes to the live site.

Fixed: everything from the original review.
- `/homes-2/` and `/industrial-2/` 301 to `/homes-and-residential/` and `/industrial/`; `/services/…` addresses 301 to the pages.
- Homepage "Learn More" and footer links go straight to the service pages (no SVG icon files).
- Meta descriptions on Contact Us, Privacy Policy and Terms of Use.
- Privacy Policy: "[Insert Link…]" gone; "Last updated: 22 October 2026"; numbered sections; a Cookies section (Google Analytics, reCAPTCHA, Cloudflare, with Google privacy and opt-out links).
- Logo: `JSM-Eletrical-Logo.png` with alt "JSM Electrical".
- Copy: "Portarlington"; "electrical advice"; the Homes page's second "Electrical Repairs" is now "Upgrades and Modernisations".
- The sample "Hello world!" post is gone (404).
- Social icons: Facebook and Instagram link to the real pages; Twitter and YouTube are gone.
- Hidden code: the only email, phone and map on any page are JSM's (jack@, 0429 400 287, a Geelong pin), and the structured data names only JSM.

Minor follow-ups (not urgent):
- Privacy Policy, "Collection of Personal Information": lists only name, phone and email, but the form also asks for address, city, state, best time to call and a message.
- Privacy Policy, cookie list: `_ga_*` shows as "ga *" (the underscores were lost when pasting), and there's a space before the full stop after each of the three Google links.
- Optional: the other seven pages' meta descriptions are weak ("repairs etc."); replacements were drafted on 2026-10-22.
- Nit: the new logo file is named `JSM-Eletrical-Logo.png` (missing "c").
