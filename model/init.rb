require 'sequel'

Sequel::Model.plugin(:schema)
DB = Sequel.sqlite('groupreader.db')

require 'model/model.rb'
