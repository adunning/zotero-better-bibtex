require 'headless'
require 'selenium-webdriver'
require 'json'
require 'pp'
require 'fileutils'
require 'ostruct'

Before do
  $headless ||= false
  unless $headless
    $headless = Headless.new
    $headless.start

    profile_dir = File.expand_path('features/profile')
    profile = Selenium::WebDriver::Firefox::Profile.new(profile_dir)

    extensions = {
      bbt: Dir['zotero-better-*.xpi'].first,
      dbb: Dir['tmp/zotero-debug-*.xpi'].first,
    }
    extensions.values.each{|xpi|
      profile.add_extension(xpi)
    }
    profile['extensions.zotero.httpServer.enabled'] = true;
    profile['extensions.zotero.debug.store'] = true;
    profile['extensions.zotero.debug.log'] = true;
    profile['extensions.zotero.translators.better-bibtex.debug'] = true;
    profile['extensions.zotero.translators.better-bibtex.attachmentRelativePath'] = true

    profile['browser.download.dir'] = "/tmp/webdriver-downloads"
    profile['browser.download.folderList'] = 2
    profile['browser.helperApps.neverAsk.saveToDisk'] = "application/pdf"
    profile['pdfjs.disabled'] = true

    BROWSER = Selenium::WebDriver.for :firefox, :profile => profile
    sleep 2
    DBB = JSONRPCClient.new('http://localhost:23119/debug-bridge')
    DBB.bootstrap('Zotero.BetterBibTeX')
    BBT = JSONRPCClient.new('http://localhost:23119/debug-bridge/better-bibtex')
    BBT.init
  end

  BBT.reset
  BBT.setPreference('translators.better-bibtex.testmode', true)
  sleep 1
  throw 'Library not empty!' unless BBT.librarySize == 0
end
at_exit do
  $headless.destroy if $headless
end

After do |s|
  open('_zotero.log', 'w'){|f| f.write(DBB.log) } if @logcapture
  @logcapture = false
end

#Given /^that ([^\s]+) is set to (.*)$/ do |pref, value|
#  if value =~ /^['"](.*)['"]$/
#    ZOTERO.setCharPref(pref, $1)
#  elsif ['false', 'true'].include?(value.downcase)
#    ZOTERO.setBoolPref(pref, value.downcase == 'true')
#  elsif value.downcase == 'null'
#    ZOTERO.setCharPref(pref, nil)
#  else
#    ZOTERO.setIntPref(pref, Integer(value))
#  end
#end

When /I need a log capture/ do
  @logcapture = true
end

When /^I import ([0-9]+) references? (with ([0-9]+) attachments? )?from '([^']+)'$/ do |references, dummy, attachments, filename|
  bib = File.expand_path(File.join(File.dirname(__FILE__), '..', filename))

  if File.extname(filename) == '.json'
    begin
      data = JSON.parse(open(bib).read)
    rescue
      data = {}
    end

    if data.is_a?(Hash) && data['config'].is_a?(Hash) && data['config']['label'] == 'Zotero TestCase'
      (data['config']['preferences'] || {}).each_pair{|key, value|
        BBT.setPreference('translators.better-bibtex.' + key, value)
      }
      (data['config']['options'] || {}).each_pair{|key, value|
        BBT.setExportOption(key, value)
      }
    end
  end

  entries = OpenStruct.new({start: BBT.librarySize})

  BBT.import(bib)

  start = Time.now

  expected = references.to_i + attachments.to_i

  while !entries.now || entries.now != entries.new
    sleep 2
    entries.now = entries.new || entries.start
    #STDOUT.puts entries.now
    entries.new = BBT.librarySize

    elapsed = Time.now - start
    if elapsed > 5
      processed = entries.new - entries.start
      remaining = expected - processed
      speed = processed / elapsed
      timeleft = (Time.mktime(0)+((expected - processed) / speed)).strftime("%H:%M:%S")
      STDOUT.puts "Slow import (#{elapsed}): #{processed} entries @ #{speed.round(1)} entries/sec, #{timeleft} remaining"
    end
  end

  expect(entries.now - entries.start).to eq(references.to_i + attachments.to_i)
end

Then /^write the library to '([^']+)'$/ do |filename|
  BBT.exportToFile('Zotero TestCase', filename)
end

Then /^the library should match '([^']+)'$/ do |filename|
  expected = File.expand_path(File.join(File.dirname(__FILE__), '..', filename))
  expected = JSON.parse(open(expected).read)

  found = BBT.library

  renum = lambda{|collection, idmap, items=true|
    collection.delete('id')
    collection['items'] = collection['items'].collect{|i| idmap[i] } if items
    collection['collections'].each{|coll|
      renum.call(coll, idmap)
    }
  }
  [expected, found].each_with_index{|library, i|
    library.delete('config')
    newID = {}
    library['items'].sort!{|a, b| a['itemID'] <=> b['itemID'] }
    library['items'].each_with_index{|item, i|
      newID[item['itemID']] = i
      item['itemID'] = i
      item.delete('itemID')
      item['attachments'].each{|a| a.delete('path')} if item['attachments']
    }
    renum.call(library, newID, false)
    library.normalize!
  }

  expect(found).to eq(expected)
end

Then(/^A library export using '([^']+)' should match '([^']+)'$/) do |translator, filename|
  found = BBT.export(translator).strip
  expected = File.expand_path(File.join(File.dirname(__FILE__), '..', filename))
  expected = open(expected).read.strip
  open("tmp/#{File.basename(filename)}", 'w'){|f| f.write(found)} if found != expected
  expect(found).to eq(expected)
end

Then(/^Export the library using '([^']+)' to '([^']+)'$/) do |translator, filename|
  BBT.exportToFile(translator, filename)
end

#Then(/^I should find the following citation keys:$/) do |table|
#  found = JSON.parse(BBT.export('BibTeX Citation Keys'))
#  found = found.keys.sort{|a, b| Integer(a) <=> Integer(b)}.collect{|k| found[k] }
#  expected = table.hashes.collect{|data| data['key']}
#  expect(found).to eq(expected)
#end

When(/^I set (preference|export option) ([^\s]+) to (.*)$/) do |setting, name, value|
  value.strip!
  value = case value
            when 'true', 'false' then (value == 'true')
            when /^'.*'$/ then value.gsub(/^'|'$/, '')
            else Integer(value)
          end

  case setting
    when 'preference'
      BBT.setPreference(name, value);

    else
      BBT.setExportOption(name, value)
  end
end


Then /^sleep ([0-9]+) seconds$/ do |secs|
  STDOUT.puts "sleeping #{secs} seconds"
  sleep Integer(secs)
  STDOUT.puts "proceeding"
end

Then /^show the (browser|Zotero) log$/ do |kind|
  STDOUT.puts DBB.log if kind == 'Zotero'
  STDOUT.puts browserLog if kind == 'browser'
end

Then /^(write|append) the (browser|Zotero) log to '([^']+)'$/ do |action, kind, filename|
  open(filename, action[0]){|f| 
    f.write(kind == 'Zotero' ? DBB.log : browserLog)
  }
end

Then /^show the citekeys$/ do
  pp BBT.getKeys
end
