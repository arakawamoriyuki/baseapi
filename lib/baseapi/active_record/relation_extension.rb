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
                function_chains = joins.clone
                function_chains.push key
                function_name = self.model.methods.include?("_#{prefix}_#{function_chains.join('_')}".to_sym) ? "_#{prefix}_#{function_chains.join('_')}" : "_#{prefix}"
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
  # count & page params example:
  #   count
  #     GET   /?count=10
  #   page
  #     GET   /?count=10&page=2
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
  # order & orderby params example:
  #   Model
  #     class Project < ActiveRecord::Base
  #       belongs_to  :status
  #       belongs_to  :manager, foreign_key: 'manager_id', class_name: 'User'
  #       belongs_to  :leader,  foreign_key: 'leader_id',  class_name: 'User'
  #       has_many    :tasks
  #     end
  #   single order
  #     GET   /?orderby=id&order=desc
  #   multiple order
  #     GET   /?orderby[]=name&order[]=asc&orderby[]=id&order[]=desc
  #   belongs_to association order
  #     GET   /?orderby=status.id&order=desc
  #   belongs_to association order (changed the foreign key)
  #     GET   /?orderby=manager.id&order=desc
  #   has_many association order
  #     GET   /?orderby=tasks.id&order=asc
  def sorting!(params)
    prefix = self.model.get_reserved_word_prefix
    if params["#{prefix}order".to_sym].present? and params["#{prefix}orderby".to_sym].present?
      orderby = params["#{prefix}orderby".to_sym]
      orderbys = orderby.instance_of?(Array) ? orderby : [orderby]
      order = params["#{prefix}order".to_sym]
      orders = order.instance_of?(Array) ? order : [order]
      orderbys.each_with_index do |orderby, index|
        next if orders[index].blank?
        next unless ['DESC', 'ASC'].include?(orders[index].upcase)
        order = orders[index].upcase
        joins_tables = orderby.split(".")
        column_name = joins_tables.pop
        table_name = joins_tables.count > 0 ? joins_tables.last.pluralize.underscore : self.model.to_s.pluralize.underscore
        parent_table_name = joins_tables.count > 1 ? joins_tables.last(2).first : self.model.to_s.pluralize.underscore
        association = parent_table_name.camelize.singularize.constantize.reflect_on_association(table_name.singularize)
        # belongs_to association order (changed the foreign key)
        if association and association.options[:class_name].present?
          association_table_name = association.options[:class_name].pluralize.underscore
          table_alias = table_name.pluralize.underscore
          next unless ActiveRecord::Base.connection.tables.include?(association_table_name)
          parent_model = parent_table_name.camelize.singularize.constantize
          association_model = association_table_name.camelize.singularize.constantize
          # joins
          arel_alias = association_model.arel_table.alias(table_alias)
          joins_arel = parent_model.arel_table.join(arel_alias).on(arel_alias[:id].eq parent_model.arel_table["#{table_alias.singularize}_id".to_sym])
          joins_arel.join_sources
          joins!(joins_arel.join_sources)
          # order
          order!(arel_alias[column_name.to_sym].send(order.downcase))
        # other order
        else
          # joins_tables exists check
          next unless joins_tables.select{|table| ActiveRecord::Base.connection.tables.include?(table.pluralize.underscore) }.count == joins_tables.count
          # table exists check
          next unless ActiveRecord::Base.connection.tables.include?(table_name)
          # column_name exists check
          next unless table_name.camelize.singularize.constantize.column_names.include?(column_name)
          # joins
          joins_array!(joins_tables)
          # order
          order!(table_name.camelize.singularize.constantize.arel_table[column_name.to_sym].send(order.downcase))
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
