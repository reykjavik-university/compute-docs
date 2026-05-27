# SciComp @ RU website

These are the sources for the Scientific Computer at Reykjavík University website at https://scicomp.ru.is/. Instructions for contributing are below:

### Contributions

This website is meant to collect useful information for all people at RU who do scientific computing or use HPC clusters. Contributions, such as guides, tutorials, and links to useful resources, are very welcome.

If you intend to contribute, ask in our Discord chat first. Contributions can be made through a pull request.

### Setup and local testing

This site is built with [MkDocs](https://www.mkdocs.org/). Content is written in Markdown.

Steps to contribute, and test the site locally:

 - Fork this repository and check it out locally using `git clone`.
 - Create a Python virtual environment and install the required packages. For most people, the following commands will work:
     ```
     python3 -m venv .venv
     source .venv/bin/activate
     pip install -r requirements.txt
     ```
   Note that you will need to activate the virtual environment using `source .venv/bin/activate` every time you open a new terminal window to work on this project.
 - Run `mkdocs build` to generate the static HTML pages, which you will find in `site/`.
 - More conveniently, run `mkdocs serve` to run a local server and auto-refresh the generated site as you edit Markdown files.
 - Make sure that you create a new branch for your pull request (i.e. do not base the pull request on your fork's `main` branch).

If you need help with any of this, ask for advice in our Discord chat!
