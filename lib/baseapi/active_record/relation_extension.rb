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
            joins.push key
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
                models.joins_array!(joins)
                currentModel = key.camelize.singularize.constantize
                value.each do |k, v|
                  # this fnuction collback
                  models = relationSearch.call(models, currentModel, k, v, prefix, joins)
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
          table_name = joins_tables.count > 0 ? joins_tables.last.pluralize.underscore : ''
          # joins_tables exists check
          joins_tables.each do |table|
            next if !ActiveRecord::Base.connection.tables.include?(table.pluralize.underscore)
          end
          if table_name.present?
            # table exists check
            next if table_name.present? and !ActiveRecord::Base.connection.tables.include?(table_name)
            # column_name exists check
            next if !table_name.camelize.singularize.constantize.column_names.include?(column_name)
          else
            # column_name exists check
            next if !self.model.column_names.include?(column_name)
          end
          # joins
          joins_array!(joins_tables)
          # order
          order!("#{table_name}#{table_name.present? ? '.' : ''}#{column_name} #{order}")
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
