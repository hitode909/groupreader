class Controller < Ramaze::Controller
  layout :default
  helper :xhtml
  engine :Etanni
end

class JsonController < Controller
  provide(:html, :type => 'application/json'){|a,s| s.to_json }
end

require 'controller/main'
require 'controller/api'

Innate::Route['group_entity'] = lambda{ |path, request|
   if path =~ %r|^/group/([^/.]+)\/([^/.]+)$|
     "/group/#{$2}/#{$1}"
   elsif path =~ %r|^/group/([^/.]+)\/([^/.]+)\.([^/.]+)$|
     "/group/#{$2}/#{$1}.#{$3}"
   end
}

