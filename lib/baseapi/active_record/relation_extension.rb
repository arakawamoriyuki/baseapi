module ActiveRecordRelationExtension

  # column search
  # @param  Hash    params
  def filtering!(params)
    models = self
    params.each do |key, value|
      if key.present? and value.present?
        # this model search
        if column_names.include?(key)
          # array change
          values = value.instance_of?(Array) ? value : [value]
          values.reject!(&:blank?)
          # call function
          function_name = self.model.methods.include?("_where_#{key}".to_sym) ? "_where_#{key}" : '_where'
          models = self.model.send(function_name, models, key, values)
        # belongs_to, has_many search
        else
          relationSearch = -> (models, currentModel, key, value, prefix = '', joins = []) {
            associations = currentModel.get_associations()
            associations.keys.each do |association|
              if currentModel.column_names.include?(key)
                # call function
                function_name = self.model.methods.include?("_#{prefix}_#{joins.join('_')}".to_sym) ? "_#{prefix}_#{joins.join('_')}" : "_#{prefix}"
                table_name = currentModel.name.underscore
                hash = {key => value}
                return self.model.send(function_name, models, table_name, hash)
              elsif associations[association].include?(key)
                # prefix = first association
                prefix = association if prefix == ''
                joins.push key
                models.joins_array!(joins)
                currentModel = key.camelize.singularize.constantize
                value.each do |k, v|
                  # this fnuction collback
                  relationSearch.call(models, currentModel, k, v, prefix, joins)
                end
              end
            end
            return models
          }
          models = relationSearch.call(models, self.model, key, value)
        end
      end
    end
    return models
  end

  # pager
  # @param  Hash    params
  def paging!(params)
    prefix = self.model.get_reserved_word_prefix
    count = params["#{prefix}count".to_sym].present? ? params["#{prefix}count".to_sym].to_i : -1;
    page = params["#{prefix}page".to_sym].present? ? params["#{prefix}page".to_sym].to_i : 1;
    if count > 0
      if count.present? and count
        limit!(count)
        if page
          offset!((page - 1) * count)
        end
      end
    end
  end

  # sort
  # @param  Hash    params
  def sorting!(params)
    prefix = self.model.get_reserved_word_prefix
    if params["#{prefix}order".to_sym].present? and params["#{prefix}orderby".to_sym].present?
      # array exchange
      orderby = params["#{prefix}orderby".to_sym]
      orderbys = orderby.instance_of?(Array) ? orderby : [orderby]
      order = params["#{prefix}order".to_sym]
      orders = order.instance_of?(Array) ? order : [order]
      # multiple order
      orderbys.each_with_index do |orderby, index|
        if orders[index].present? and ['DESC', 'ASC'].include?(orders[index].upcase)
          order = orders[index].upcase
          # dot notation  example: company.name
          joins_tables = orderby.split(".")
          column_name = joins_tables.pop
          table_name = joins_tables.count > 0 ? joins_tables.last.pluralize.underscore : self.model.to_s.pluralize.underscore
          # table_name parent table
          parent_table_name = joins_tables.count > 1 ? joins_tables.last(2).first : self.model.to_s.pluralize.underscore
          # parent_table get association
          association = parent_table_name.camelize.singularize.constantize.reflect_on_association(table_name.singularize)
          # If you have specified class_name in belongs_to method (for example, you have changed the foreign key)
          # example:
          # class Project < ActiveRecord::Base
          #   belongs_to :manager, foreign_key: 'manager_id', class_name: 'User'
          #   belongs_to :leader,  foreign_key: 'leader_id',  class_name: 'User'
          # end
          if association and association.options[:class_name].present?
            association_table_name = association.options[:class_name].pluralize.underscore
            table_alias = table_name.pluralize.underscore
            # check
            next if !ActiveRecord::Base.connection.tables.include?(association_table_name)
            # join
            joins!("INNER JOIN `#{association_table_name}` AS `#{table_alias}` ON `#{table_alias}`.`id` = `#{parent_table_name}`.`#{table_alias.singularize}_id`")
            # order
            order!("`#{table_alias}`.`#{column_name}` #{order}")
          # belongs_to along the rails convention
          # example:
          # class Project < ActiveRecord::Base
          #   belongs_to :manager
          # end
          else
            # joins_tables exists check
            is_next = false
            joins_tables.each do |table|
              is_next = true and break if !ActiveRecord::Base.connection.tables.include?(table.pluralize.underscore)
            end
            next if is_next
            # table exists check
            next if !ActiveRecord::Base.connection.tables.include?(table_name)
            # column_name exists check
            next if !table_name.camelize.singularize.constantize.column_names.include?(column_name)
            # joins
            joins_array!(joins_tables)
            # order
            order!("`#{table_name}`.`#{column_name}` #{order}")
          end
        end
      end
    end
  end


  # joins as array params
  # @param  array    param
  def joins_array!(joins)
    param = nil
    joins.reverse.each_with_index do |join, index|
      join = join.to_sym
      if index == 0
        param = join
      else
        param = {join => param}
      end
    end
    joins!(param)
  end
end
