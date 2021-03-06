{
	"translatorID": "4c52eb69-e778-4a78-8ca2-4edf024a5074",
	"label": "Pandoc Citation",
	"creator": "Erik Hetzner & Emiliano heyns",
	"target": "bib",
	"minVersion": "2.1.9",
	"maxVersion": "",
	"priority": 100,
  "configOptions": {
    "getCollections": "true"
  },
  "displayOptions": {},
	"inRepository": true,
	"translatorType": 2,
	"browserSupport": "gcsv",
	"lastUpdated": "/*= timestamp =*/"
}

/*= include common.js =*/

function doExport() {
  var keys = [];
  while (item = Translator.nextItem()) {
    keys.push('@' + item.__citekey__);
  }
  Zotero.write('[' + keys.join('; ') + ']');
}

var exports = {
	"doExport": doExport
}
