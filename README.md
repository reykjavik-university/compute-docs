# SciComp @ RU website

These are the sources for the Scientific Computer at Reykjavík University website. Introductions for contributing are below:

### Contributions

Please open a pull request.

### Setup and local testing

This site is built with [MkDocs](https://www.mkdocs.org/). Content is written in Markdown.

To test locally, 

 - Clone the repo using `git clone https://github.com/reykjavik-university/compute-docs.git`
 - Create a Python virtual environment and install the following packages: `mkdocs`, `mkdocs-blogging-plugin`.
 - All content is in Markdown files within `docs/`.
 - Run `mkdocs build` to generate the HTML pages, which you will find in `site/`.
 - Run `mkdocs serve` to run a local server, and follow the instructions printer in the terminal to access the local version of the site.
