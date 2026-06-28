# GitHub Pages (legal & support)

Static pages for App Store **Privacy Policy URL**, **Support URL**, and **Accessibility URL**.

## Enable Pages (one-time)

1. Open [github.com/jacobrozell/Dart-Buddy/settings/pages](https://github.com/jacobrozell/Dart-Buddy/settings/pages)
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `master` (or `main`) · **Folder:** `/docs`
4. Save — site goes live in 1–3 minutes

## URLs (after Pages is enabled)

| Page | English | Deutsch |
|------|---------|---------|
| Home | `https://jacobrozell.github.io/Dart-Buddy/` | `https://jacobrozell.github.io/Dart-Buddy/de/` |
| Privacy Policy | `…/privacy.html` | `…/de/privacy.html` |
| Support | `…/support.html` | `…/de/support.html` |
| Accessibility | `…/accessibility.html` | `…/de/accessibility.html` |

**App Store Connect:** keep English URLs on the primary listing; set **German** Privacy + Support URLs on the **Deutsch** localization to the `/de/…` paths.

**In-app:** Settings → Help & Feedback opens the localized URL when the device language is German and `de` is in the store bundle (`AppLinks.hostedPage`).

Each page has a **language switcher** (English / Deutsch) in the header.

## Local preview

```bash
python3 -m http.server 8080 --directory docs
# http://localhost:8080/privacy.html
# http://localhost:8080/de/privacy.html
```

## Updates

Edit the HTML files, commit, push — Pages redeploys automatically. When English legal copy changes, update the matching `/de/` page and bump both “Last updated” dates.

Future store locales: add `docs/<code>/` using the same pattern (see release plan discussion).
