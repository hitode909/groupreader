require 'sequel'

Sequel::Model.plugin(:schema)
DB = Sequel.sqlite('groupreader.db')


require 'model/model'
require 'model/entry'
require 'model/feed'
require 'model/group'
require 'model/blog'
require 'model/activity'
