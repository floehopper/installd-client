#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'sync'))

sync = Installd::Sync.new
sync.execute