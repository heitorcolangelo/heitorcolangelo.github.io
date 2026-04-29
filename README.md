# Heitor Colangelo Blog

Personal blog built with Jekyll and deployed with GitHub Pages.

## Stack

- Jekyll `3.9.x` via Ruby/Bundler
- GitHub Actions workflow at `.github/workflows/jekyll.yml`
- Jasper2/Casper-based theme templates in `_layouts/` and `_includes/`

## Local Development

Prerequisites:

- Ruby `3.1` (see `.ruby-version`)
- Bundler

Install and run:

```bash
bundle install
bundle exec jekyll serve
```

The site will be available at `http://127.0.0.1:4000`.

## Content and Structure

- Posts: `_posts/`
- Authors data: `_data/authors.yml`
- Tags data: `_data/tags.yml`
- Static assets: `assets/`
- Main configuration: `_config.yml`

## Deployment

Deployment is handled by GitHub Actions on pushes to `main` using:

- `.github/workflows/jekyll.yml`

The workflow builds the site and publishes it to GitHub Pages.

## Notes

- This repository is maintained as a personal blog, not as a general Jasper2 theme template.
- Legacy Node/Gulp build tooling has been removed from active use; committed CSS assets in `assets/built/` are used directly.

## License

See `LICENSE` and `GHOST.txt` for upstream and project licensing details.
