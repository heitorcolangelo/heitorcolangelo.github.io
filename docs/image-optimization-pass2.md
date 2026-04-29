# Image Optimization Pass 2

This project already includes a first compression pass for selected large JPEG files.
This document defines a repeatable second pass focused on modern formats, safe fallbacks, and verification.

## Goals

- Reduce transfer size for large visual assets used on high-traffic pages.
- Keep visual quality acceptable for blog content.
- Avoid regressions by preserving fallback formats.

## Strategy

1. Keep original raster format as fallback (`.jpg` / `.png`).
2. Generate a modern counterpart (`.webp`).
3. Prefer modern format where template usage allows it.
4. Validate Lighthouse before and after.

## Candidate Selection

Prioritize files larger than ~120 KB in `assets/images/`:

- `assets/images/abraham.jpg`
- `assets/images/bear.jpg`
- `assets/images/hannah-cover.jpg`
- `assets/images/water.jpg`
- any frequently used cover image above threshold

## Conversion Commands (macOS)

Generate WebP files with ImageMagick:

```bash
brew install imagemagick

magick assets/images/abraham.jpg -quality 78 assets/images/abraham.webp
magick assets/images/bear.jpg -quality 78 assets/images/bear.webp
magick assets/images/hannah-cover.jpg -quality 78 assets/images/hannah-cover.webp
magick assets/images/water.jpg -quality 78 assets/images/water.webp
```

## Fallback Patterns

### Inline image in template

```liquid
<picture>
  <source srcset="{{ '/assets/images/example.webp' | relative_url }}" type="image/webp" />
  <img src="{{ '/assets/images/example.jpg' | relative_url }}" alt="..." />
</picture>
```

### CSS background

Use `image-set` with jpeg fallback:

```css
background-image: image-set(
  url('/assets/images/example.webp') type('image/webp'),
  url('/assets/images/example.jpg') type('image/jpeg')
);
```

If browser support concerns appear, keep plain `url(...)` fallback below `image-set`.

## Verification Checklist

- Run Lighthouse for:
  - home mobile/desktop
  - post mobile/desktop
- Verify visual quality on:
  - homepage hero
  - post cards
  - featured post images
- Confirm no broken image links in browser console.
