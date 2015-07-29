require "baseapi/version"

# ActiveRecord::Relation Extension
require 'baseapi/active_record/relation_extension'
ActiveRecord::Relation.send(:include, ActiveRecordRelationExtension)

# ActiveRecord::Base Extension
require 'baseapi/active_record/base_extension'
ActiveRecord::Base.send(:include, ActiveRecordBaseExtension)
