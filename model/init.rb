require 'sequel'

Sequel::Model.plugin(:schema)
DB = Sequel.sqlite('feedg.db')

require 'model/model.rb'
