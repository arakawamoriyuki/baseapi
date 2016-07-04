module ActiveRecordBaseExtension extend ActiveSupport::Concern

  @reserved_word_prefix = ''

  # override if necessary
  def _destroy
    destroy
  end

  module ClassMethods

    # @param    Hash          params    getparams
    #             String/Array  {column}  search column value
    #             String        orderby   order column
    #             String        order     sort order ('asc' or 'desc')
    #             Integer       count     page count (all = '0' or '-1')
    #             Integer       page      paged
    def search(params)
      models = self._all

      # recursive empty delete
      clean_hash!(params)

      # filter
      models.filtering!(params)

      # pager
      models.paging!(params)

      # sort
      models.sorting!(params)

      return models.uniq
    end

    # reserved word prefix(count,page,order,orderby...)
    # @return String
    def get_reserved_word_prefix
      @reserved_word_prefix
    end

    # override if necessary
    # @return ActiveRecordRelation
    def _all
      self.all
    end

    # override or create method '_where_{column}' if necessary
    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    def _where(models, column, values)
      column_match(models, column, values)
    end

    # column exact match search
    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    # @option   String                operator  'or' or 'and'
    def column_match(models, column, values, operator: 'or')
      callable = arel_match(self)
      column_call(models, column, values, callable, operator: operator)
    end

    # column like search
    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    # @option   String                operator  'or' or 'and'
    def column_like(models, column, values, operator:'or')
      callable = arel_like(self)
      column_call(models, column, values, callable, operator: operator)
    end

    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    # @param    Callable              callable  Arel
    def column_call(models, column, values, callable, operator:'or')
      base_arel = nil
      column_values = values.instance_of?(Array) ? values : [values]
      column_values.each do |value|
        if column.present? and value.present?
          arel = callable.call(column, value)
          base_arel = arel_merge(base_arel, arel, operator: operator)
        end
      end
      models.where!(base_arel)
      models
    end

    # override or create method '_belongs_to_{table}' if necessary
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    def _belongs_to(models, table, hash)
      relation_match(models, table, hash)
    end

    # override or create method '_has_many_{table}' if necessary
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    def _has_many(models, table, hash)
      relation_match(models, table, hash)
    end

    # Exact match search
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @option   String                operator  'or' or 'and'
    def relation_match(models, table, hash, operator: 'or')
      callable = arel_match(table.camelize.singularize.constantize)
      relation_call(models, hash, callable, operator: operator)
    end

    # like search
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @option   String                operator  'or' or 'and'
    def relation_like(models, table, hash, operator: 'or')
      callable = arel_like(table.camelize.singularize.constantize)
      relation_call(models, hash, callable, operator: operator)
    end

    # @param    ActiveRecordRelation  models
    # @param    Hash                  hash      column name => search values
    # @param    Callable              callable  Arel
    # @option   String                operator  'or' or 'and'
    def relation_call(models, hash, callable, operator:'or')
      base_arel = nil
      hash.each do |column, values|
        if column.present? and values.present?
          relation_values = values.instance_of?(Array) ? values : [values]
          relation_values.each do |value|
            if column.present? and value.present?
              arel = callable.call(column, value)
              base_arel = arel_merge(base_arel, arel, operator: operator)
            end
          end
        end
      end
      models.where!(base_arel)
      models
    end

    # get relation tables
    # @param  String  relate        'belongs_to','hasmany'..
    # @return Hash    associations  relation name => talbe name array
    def get_associations(relate = nil)
      associations = {
        'belongs_to' => [],
        'has_many'   => [],
      }
      self.reflect_on_all_associations.each do |association|
        associations.each do |key, value|
          if association.class.to_s == "ActiveRecord::Reflection::#{key.camelize}Reflection"
            associations[key].push(association.name.to_s)
          end
        end
      end
      relate.present? ? associations[relate] : associations
    end



    private

      # create arel like
      # @param  Model     model_class   ActiveRecord class
      # @return Callable                create arel function
      def arel_like(model_class)
        return ->(column, value){
          arel = model_class.arel_table[column.to_sym]
          arel = arel.matches("%#{escape_value(value)}%")
          arel = arel.not if value_is_not?(value)
          arel
        }
      end

      # create arel match
      # @param  Model model_class   ActiveRecord class
      # @return Callable            create arel function
      def arel_match(model_class)
        return ->(column, value){
          arel = model_class.arel_table[column.to_sym]
          if value_is_null?(value)
            arel = arel.eq(nil)
          elsif value_is_empty?(value)
            arel = arel.eq(nil).send('or', model_class.arel_table[column.to_sym].eq(''))
          elsif value_is_sign?(value)
            arel = arel.send(get_sign_method(get_sign(value)), escape_value(value))
          else
            arel = arel.eq(escape_value(value))
          end
          arel = arel.not if value_is_not?(value)
          arel
        }
      end

      # create arel match
      # @param  Arel  base_arel   base arel
      # @param  Arel  arel        merge target arel
      # @return Arel              merged arel object
      def arel_merge(base_arel, arel, operator: 'or')
        return arel if base_arel.nil?
        base_arel.send(operator, arel)
      end

      # escape `!`
      # @param  String  value
      # @return String
      def escape_not_value(value)
        value = value[1..value.length-1] if value[0] == '!'
        return value
      end

      # escape `>`,`<`,`=<`,`=>`
      # @param  String  value
      # @return String
      def escape_sign_value(value)
        if value.length >= 2 and ['<=', '>='].include?(value[0..1])
          value = value[2..value.length-1]
        elsif ['<', '>'].include?(value[0])
          value = value[1..value.length-1]
        end
        return value
      end

      # escape `'`,`"`
      # @param  String  value
      # @return String
      def escape_quotation_value(value)
        if ((/^[\'].+?[\']$/ =~ value) != nil) or ((/^[\"].+?[\"]$/ =~ value) != nil)
          value = value[1..value.length-2]
        end
        return value
      end

      # removal of the `!`,`>`,`<`,`=>`,`=<`,`'`,`"`
      # @param  String  value
      # @return String
      def escape_value(value)
        value = escape_not_value(value)
        value = escape_sign_value(value)
        value = escape_quotation_value(value)
        return value
      end

      # request not?
      # @param  String  value
      # @return Boolean
      def value_is_not?(value)
        value[0] == '!'
      end

      # request null?
      # @param  String  value
      # @return Boolean
      def value_is_null?(value)
        escape_not_value(value).upcase == 'NULL'
      end

      # request empty?
      # @param  String  value
      # @return Boolean
      def value_is_empty?(value)
        escape_not_value(value).upcase == 'EMPTY'
      end

      # request less or greater?
      # @param  String  value
      # @return Boolean
      def value_is_sign?(value)
        value = escape_not_value(value)
        value.length >= 2 and ['<=', '>='].include?(value[0..1]) || ['<', '>'].include?(value[0])
      end

      # get less or greater
      # @param  String  value
      # @return String  sign    > or < or => or <=
      def get_sign(value)
        value = escape_not_value(value)
        if value.length >= 2 and ['<=', '>='].include?(value[0..1])
          sign = value[0..1]
        elsif ['<', '>'].include?(value[0])
          sign = value[0]
        end
        sign
      end

      # less or greater to arel method
      # @param  String  sign    > or < or => or <=
      # @return String          Arel method
      def get_sign_method(sign)
        case sign
        when '<'
          return 'lt'
        when '<='
          return 'lteq'
        when '>'
          return 'gt'
        when '>='
          return 'gteq'
        end
      end

      # hash params empty delete
      # @param  hash    param
      def clean_hash!(param)
        recursive_delete_if = -> (param) {
          param.each do |key, value|
            if value.is_a?(Hash)
              recursive_delete_if.call(value)
            end
          end
          param.delete_if { |k, v| v.blank? }
        }
        recursive_delete_if.call(param) if param.is_a?(Hash)
      end
  end
end
