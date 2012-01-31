require 'i18n/backend/active_record'

simple_backend = I18n::Backend::Simple.new
db_backend = I18n::Backend::ActiveRecord.new
I18n.backend = I18n::Backend::Chain.new(db_backend,simple_backend)
