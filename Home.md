---
layout: default
title: Home
---
# Zotero: Better Bib(La)TeX [![Build Status](https://travis-ci.org/ZotPlus/zotero-better-bibtex.svg?branch=master)](https://travis-ci.org/ZotPlus/zotero-better-bibtex)

{% include version.html %}

This extension aims to make Zotero effective for us LaTeX holdouts. At its core, it behaves like any Zotero
import/export module; anywhere you can export or import bibliography items in Zotero, you'll find Better Bib(La)TeX
listed as one of the choices. If nothing else, you could keep your existing workflow as-is, and just enjoy the emproved
LaTeX &lt;-&gt; unicode translation on im-and export. Over and above this improvement, it adds the following features to
Zotero:

* Stable **[[Citation Keys]]**, without key clashes! Generates citation keys that take into account other existing keys in your library
  that are not part of the items you export. Prevent random breakage!
* **Converts from/to HTML/LaTeX**: Currently supports i/\emph/\textit, b/\textbf, sup/\_{...} and sub/^{...}; more can
  be added on request. Finally add italics and super/supscript to your titles! The plugin contains a comprehensive list
  of LaTeX constructs, so stuff like \"{o} or \"o will be converted to their unicode equivalents on import. If you need
  literal LaTeX in your export: surround it with &lt;pre&gt;....&lt;/pre&gt; tags.
* Integration with **[[Report Customizer|Citation Keys]]**
* Set your own, fixed **[[Citation Keys]]**, generate citation keys from JabRef patterns, drag and drop LaTeX citations, add other custom BibLaTeX fields
* **[[Customized Exports]]**
* **Jabref groups import/export**: During import, if JabRef explicit (not dynamic) groups are present, collections will
  be created to mirror these. During export, collections will be added to the export as explicit jabref groups.
* **Fixes date field exports**: export dates like 'forthcoming' as 'forthcoming' instead of empty.
* **[[Pull Export]]** from the embedded webserver
* Automatic **[[journal abbreviation|Citation Keys]]**

## Configuration

The Better BibTeX [[configuration pane|Customized Exports]] can be found under the regular Zotero preferences pane, tab 'Better Bib(La)TeX'.

# Installation (one-time)

After installation, the plugin will auto-update to newer releases. Install by downloading the [latest version](https://github.com/ZotPlus/zotero-better-bibtex/raw/master/zotero-better-bibtex-0.6.10.xpi) (**0.6.10**,
released on 2014-08-15 23:48). If you are not prompted with a Firefox installation dialog then double-click the
downloaded xpi; Firefox ought to start and present you with the installation dialog.

For standalone Zotero, do the following:

1. In the main menu go to Tools > Add-ons
2. Select 'Extensions'
3. Click on the gear in the top-right corner and choose 'Install Add-on From File...'
4. Choose .xpi that you've just downloaded, click 'Install'
5. Restart Zotero

# Got problems? We got fixes!

If you have any questions on the use of the plugin, please do not hesitate to file a GitHub issue to ask for help. If
you're reporting a bug in the plugin, please take a moment to glance through the [[Support Request Guidelines]]; it will
make sure I get your problem fixed as quick as possible. Clear bug reports commonly have time-to-fix of 10 minutes. The
guidelines are very detailed, perhaps to the point of being off-putting, but please do not fret; these guidelines
simply express my ideal bug submission. I of course prefer very clearly documented issue reports over fuzzy ones, but I
prefer fuzzy ones over missed ones.

# Plans

* add "citekey" columns to reference list view
* add "citeley" field to reference editor
* sync citekey cleanly without abusing the "extra" field
* faster journal abbreviator using the [LTWA](http://www.issn.org/services/online-services/access-to-the-ltwa/)
* Submission to Mozilla Extension registry is off the table -- MER moves *much* to slow for my sometimes daily releases.
