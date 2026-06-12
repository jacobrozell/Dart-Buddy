# GitHub Pages (legal & support)

Static pages for App Store **Privacy Policy URL**, **Support URL**, and **Accessibility URL**.

## Enable Pages (one-time)

1. Open [github.com/jacobrozell/Dart-Buddy/settings/pages](https://github.com/jacobrozell/Dart-Buddy/settings/pages)
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `master` (or `main`) · **Folder:** `/docs`
4. Save — site goes live in 1–3 minutes

## URLs (after Pages is enabled)

| Page | URL |
|------|-----|
| Home | `https://jacobrozell.github.io/Dart-Buddy/` |
| Privacy Policy | `https://jacobrozell.github.io/Dart-Buddy/privacy.html` |
| Support | `https://jacobrozell.github.io/Dart-Buddy/support.html` |
| Accessibility | `https://jacobrozell.github.io/Dart-Buddy/accessibility.html` |

Use the **Privacy Policy** and **Support** URLs in App Store Connect. Add the **Accessibility** URL under App → App Accessibility (optional; also linked in-app from Settings).

## Local preview

Open `docs/privacy.html` in a browser, or:

```bash
python3 -m http.server 8080 --directory docs
# http://localhost:8080/privacy.html
```

## Updates

Edit the HTML files, commit, push — Pages redeploys automatically. Bump the “Last updated” date when practices change (especially Firebase or online features).
