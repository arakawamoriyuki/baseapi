module ActiveRecordRelationExtension
  # ----- model relation object methods -----
  # def relation_object_method
  # end
  # Model.all.relation_object_method

  # カラムの検索
  # @param  Hash    params  検索パラメータ
  def filtering!(params)
    models = self
    associations = self.model.get_associations()
    params.each do |key, value|
      if key.present? and value.present?
        if column_names.include?(key)
          # 配列に対応する
          values = value.instance_of?(Array) ? value : [value]
          values.reject!(&:blank?)
          # カラム用関数が定義されていればそれを使用
          function_name = self.model.methods.include?("_where_#{key}".to_sym) ? "_where_#{key}" : '_where'
          models = self.model.send(function_name, models, key, values)
        end

        # belongs_to, has_manyの検索
        associations.keys.each do |association|
          if associations[association].include?(key) and value.instance_of?(ActionController::Parameters)#hash型はActionController::Parameters
            # カラム用関数が定義されていればそれを使用
            function_name = self.model.methods.include?("_#{association}_#{key}".to_sym) ? "_#{association}_#{key}" : "_#{association}"
            models = self.model.send(function_name, models, key, value)
          end
        end
      end
    end
    return models
  end

  # ページャー
  # @param  Hash    params  検索パラメータ
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

  # ソート
  # @param  Hash    params  検索パラメータ
  def sorting!(params)
    if params[:order].present? and params[:orderby].present?
      order!({params[:orderby] => params[:order]})
    end
  end
end
