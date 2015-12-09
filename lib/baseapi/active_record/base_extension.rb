module ActiveRecordBaseExtension extend ActiveSupport::Concern

  @reserved_word_prefix = ''

  # override if necessary
  def _destroy
    destroy
  end

  module ClassMethods

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
    def column_match(models, column, values, operator:'or')
      column_call(models, column, values, ->(column, value){
        "#{getPrefix(value)} #{models.name.pluralize.underscore}.#{column} #{getOperator(value)} #{getValue("#{models.name.pluralize.underscore}.#{column}", value, "'")}"
      }, operator:operator)
    end

    # column like search
    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    # @option   String                operator  'or' or 'and'
    def column_like(models, column, values, operator:'or')
      column_call(models, column, values, ->(column, value){
        "#{getPrefix(value)} #{models.name.pluralize.underscore}.#{column} #{getOperator(value, 'like')} #{getValue("#{models.name.pluralize.underscore}.#{column}", escape_like(value), "%", "'")}"
      }, operator:operator)
    end

    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array/String          values    search values
    # @param    Callable              callable
    # @option   String                operator  orかand
    def column_call(models, column, values, callable, operator:'or')
      column_values = values.instance_of?(Array) ? values : [values]
      models.where!(column_values.map{|value| callable.call(column, value)}.join(" #{operator} "))
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
    def relation_match(models, table, hash, operator:'or')
      relation_call(models, table, hash, ->(table, column, value){
        "#{getPrefix(value)} #{table}.#{column} #{getOperator(value)} #{getValue("#{table}.#{column}", value, "'")}"
      }, operator:operator)
    end

    # like search
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @option   String                operator  'or' or 'and'
    def relation_like(models, table, hash, operator:'or')
      relation_call(models, table, hash, ->(table, column, value){
        "#{getPrefix(value)} #{table}.#{column} #{getOperator(value, 'like')} #{getValue("#{table}.#{column}", escape_like(value), "%", "'")}"
      }, operator:operator)
    end

    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @param    Callable              callable
    # @option   String                operator  orかand
    def relation_call(models, table, hash, callable, operator:'or')
      hash.each do |column, value|
        if column.present? and value.present?
          relation_values = value.instance_of?(Array) ? value : [value]
          models.where!(relation_values.map{|value| callable.call(table.pluralize, column, value)}.join(" #{operator} "))
        end
      end
      models
    end

    # get sql prefix 'NOT'
    # @param  String  value
    # @return String  value
    def getPrefix(value)
      (value[0] == '!') ? 'NOT' : ''
    end

    # return = or IS
    # @param  String  value
    # @return String  operator
    def getOperator(value, default = '=')
      operator = default
      val = value.clone
      val.slice!(0) if val[0] == '!'
      if ['NULL', 'EMPTY'].include?(val.upcase)
        operator = 'IS'
      elsif val.length >= 2 and ['<=', '>='].include?(val[0..1])
        operator = val[0..1]
      elsif ['<', '>'].include?(val[0])
        operator = val[0]
      end
      operator
    end

    # slice '!' value
    # @param  String  column
    # @param  String  value
    # @param  String  wraps ' or %
    # @return String  val or sql
    def getValue(column, value, *wraps)
      original = value.clone
      val = value.clone
      val.slice!(0) if val[0] == '!'
      if val.upcase == 'NULL'
        val = 'NULL'
      elsif val.upcase == 'EMPTY'
        prefix = getPrefix(original)
        operator = prefix == 'NOT' ? 'AND' : 'OR'
        val = "NULL #{operator} #{prefix} #{column} = ''"
      elsif val.length >= 2 and ['<=', '>='].include?(val[0..1])
        val.sub!(val[0..1], '')
      elsif ['<', '>'].include?(value[0])
        val.sub!(val[0], '')
      else
        val = getNaturalValue(val)
        wraps.each do |wrap|
          val = "#{wrap}#{val}#{wrap}"
        end
      end
      return val
    end

    # removal of the enclosing
    # @param  String        value
    # @return String        val
    def getNaturalValue(value)
      val = value.clone
      if ((/^[\'].+?[\']$/ =~ val) != nil) or ((/^[\"].+?[\"]$/ =~ val) != nil)
        val = val[1..val.length-2]
      end
      val
    end

    # escape like
    # @param  String
    # @return String
    def escape_like(string)
      string.gsub(/[\\%_]/){|m| "\\#{m}"}
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


    # @param    Hash          params    getparams
    #             String/Array  {column}  search column value
    #             String        orderby   order column
    #             String        order     sort order ('asc' or 'desc')
    #             Integer       count     page count (all = '0' or '-1')
    #             Integer       page      paged
    def search(params)
      models = self._all

      # load
      self.get_associations().each do |association_key, relations|
        relations.each do |relation|
          models.includes!(relation.to_sym)
        end
      end

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
