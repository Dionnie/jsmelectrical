# JSM Electrical: company and site brief

From the live site https://jsmelectrical.com.au/ (read 2026-10-21); its full copy is in `docs/content/`, one file per page. `[gap: …]` = not on the live site: ask the user, never guess.

## Business

- Name: JSM Electrical. Legal name, entity type, ABN: [gap: not on the site; an ABR search for "JSM Electrical" shows no Geelong match].
- Founded 2023. Electrical maintenance and service repair company based in Geelong, Victoria.
- Licences, REC number, insurance, accreditations: [gap: none on the site].
- Owner and team: [gap: no names on the site; the email is jack@].
- Phone: 0429 400 287. Email: jack@jsmelectrical.com.au. Address: [gap: site shows only "Geelong, Victoria"].
- Hours: [gap: none stated; the contact form offers call-back windows 9am–7pm].
- Emergency or after-hours: [gap: "emergency repairs" is listed for business and commercial only; no after-hours terms].
- Service area: Geelong, the Bellarine Peninsula (Portarlington named) and the Surf Coast; also rural and remote jobs across Australia.

## Services

Live menu order; priority: [gap]. Copy for each: `docs/content/<file>`.

- Business and Commercial: `business-and-commercial.md`
- Industrial: `industrial.md`
- Homes: `homes.md`
- Renovations: `renovations.md`
- Underground: `underground.md`

## Positioning and voice

- Tagline, values and "why choose us": `docs/content/home.md`, `docs/content/about-us.md`.
- Customers: homeowners and renovators, businesses and shops, industrial sites, telecommunications and public infrastructure.
- Voice: professional, safety- and quality-led, Australian English. Words to use or avoid: [gap].
- Testimonials and reviews: [gap: none on the site].

## Site

- Pages: one file each in `docs/content/`, with the live URL, title tag and meta description; keep or redirect those URLs. Header and footer: `docs/content/site-wide.md`.
- Main call to action: a free project consultation, by the contact form (`docs/content/contact-us.md`), email or phone.
- Brand: monochrome. `#000000` primary and accent, `#373737` secondary, `#555555` text, greys `#AAAAAA` `#CCCCCC`, white. Headings Electrolize (500/600), body Poppins (400; 500 accent, 700 display).
- Logo: live `wp-content/uploads/2025/01/Block.png`; favicon `wp-content/uploads/2025/04/favicon-256@2x.png`. Source files: [gap] (the revamp uses a traced vector: `docs/design.md`).
- Social: Facebook, Twitter, YouTube are listed without links: [gap: URLs, or drop them].
- Live stack: WordPress with Elementor Pro on a Hello Elementor child theme, Site Kit (Google Analytics), Cloudflare; built by Global Webforce.

## Live-site faults to fix in the rebuild

- Footer service links use `/services/…`: Industrial and Homes redirect to SVG icon files, and the rest redirect to the pages.
- Privacy Policy still has "[Insert Link to Google Analytics Privacy Policy]", no cookie section and no date.
- No meta description on Contact Us, Privacy Policy or Terms of Use.
- WordPress's sample "Hello world!" post is still published at `/hello-world/`.
- Copy typos: "Portalington", "electrical advise"; the Homes page has "Electrical Repairs" twice (the second is upgrades).
- Logo has no alt text.
