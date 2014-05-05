/*= bibtex_parser =*/

function detectImport() {
  var bib = '';
  var c;
  var maxChars = 1024 * 50;

  while (c = Zotero.read(1)) {
    bib += c;

    try {
      BibTeX.parse(bib);
      return true;
    } catch (e) {
    }

    if (bib.length > maxChars) { break; }
  }

  return false;
}

function doImport() {
  Config.initialize();
  var bib = '';
  var read;
  while(read = Zotero.read(1024)) { bib += read; }

  var bib = BibTeX.parse(bib);

  bib.references = bib.references.forEach(function(ref) {
    createZoteroReference(ref)
  });

  if (bib.comments.indexOf('jabref-meta: groupsversion:3;') >= 0) {
    var tree = bib.comments.filter(function(comment) { return (comment.indexOf('jabref-meta: groupstree:') == 0); });
    if (tree.length != 0) {
      tree = tree[0].replace(/[\r\n]/gm, '');
      tree = jabrefGroups(tree);
    }
  }
}

function jabrefSplit(str) {
  var result = [''];
  str = str.split('');
  while (str.length > 0) {
    if (str[0] == ';') {
      str.shift();
      result.push('');
    } else {
      if (str[0] == '\\') { str.shift(); }
      result[result.length - 1] += str.shift();
    }
  }
  return result;
}

function jabrefGroups(comment) {
  var collectionAt = {};
  var collections = [];

  comment = comment.replace(/^jabref-meta: groupstree:/, '');

  jabrefSplit(comment).forEach(function(record) {
    var fields = jabrefSplit(record);
    if (fields.length < 2) { return; }

    record = {id: fields.shift()};
    record.data = record.id.match(/^([0-9]) ([^:]*):(.*)/);
    if (record.data == null) {
      trLog("jabref: fatal: unexpected non-match for group " + record.id);
      return;
    }
    record.level = parseInt(record.data[1]);
    record.type = record.data[2];
    record.name = record.data[3];
    record.intersection = fields.shift(); // 0 = independent, 1 = intersection, 2 = union

    if (isNaN(record.level)) {
      trLog("jabref: fatal: unexpected record level in " + record.id);
      return;
    }

    if (record.level == 0) { return; }

    if (record.type != 'ExplicitGroup') {
      trLog("jabref: fatal: group type " + record.type + " is not supported");
      return;
    }

    var collection = new Zotero.Collection();
    collection.name = record.name;
    collection.type = 'collection';
    collection.children = fields;

    collections.push(collection);
    collectionAt[record.level] = collection;
    var parent = (record.level > 1 ? collectionAt[record.level - 1] : null);

    if (parent) {
      parent.children.push(collection);

      var parentkeys = parent.children.filter(function(child) { return (child.type == 'item'); }).map(function(child) { return child.id });

      switch (record.intersection) {
        case 0: // independent, do nothing
          break;
        case 1: // intersection with parent
          collection.children = collection.children.filter(function(key) { return (parentkeys.indexOf(key) >= 0); });
          break;
        case 2: // union with parent
          collection.children = collection.children.concat(parentkeys).filter(function(key, index, self) { return self.indexOf(key) === index; });
          break;
      }
    }

    collection.children = collection.children.map(function(key) { return {type: 'item', id: key}; });
  });

  collections.forEach(function(collection) {
    collection.complete();
  });
}
