module ActiveRecordRelationExtension

  # column search
  # @param  Hash    params
  def filtering!(params)
    models = self
    associations = self.model.get_associations()
    params.each do |key, value|
      if key.present? and value.present?
        if column_names.include?(key)
          # array change
          values = value.instance_of?(Array) ? value : [value]
          values.reject!(&:blank?)
          # call function
          function_name = self.model.methods.include?("_where_#{key}".to_sym) ? "_where_#{key}" : '_where'
          models = self.model.send(function_name, models, key, values)
        end

        # belongs_to, has_many search
        associations.keys.each do |association|
          if associations[association].include?(key) and value.instance_of?(ActionController::Parameters)#hash型はActionController::Parameters
            # call function
            function_name = self.model.methods.include?("_#{association}_#{key}".to_sym) ? "_#{association}_#{key}" : "_#{association}"
            models = self.model.send(function_name, models, key, value)
          end
        end
      end
    end
    return models
  end

  # pager
  # @param  Hash    params
  def paging!(params)
    count = params[:count].present? ? params[:count].to_i : -1;
    page = params[:page].present? ? params[:page].to_i : 1;
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
    if params[:order].present? and params[:orderby].present?
      order!({params[:orderby] => params[:order]})
    end
  end
end
