module ActiveRecordBaseExtension extend ActiveSupport::Concern

  # override if necessary
  def _destroy
    destroy
  end

  module ClassMethods

    # override if necessary
    # @return ActiveRecordRelation
    def _all
      self.all
    end

    # override or create method '_where_{column}' if necessary
    # @param    ActiveRecordRelation  models
    # @param    String                column    column name
    # @param    Array                 values    search values
    def _where(models, column, values)
      models.where!(column => values)
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
        "#{table}.#{column} = '#{value}'"
      }, operator:operator)
    end

    # like search
    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @option   String                operator  'or' or 'and'
    def relation_like(models, table, hash, operator:'or')
      relation_call(models, table, hash, ->(table, column, value){
        "#{table}.#{column} like '%#{value}%'"
      }, operator:operator)
    end

    # @param    ActiveRecordRelation  models
    # @param    String                table     table name
    # @param    Hash                  hash      column name => search values
    # @param    Callable              callable
    # @option   String                operator  orかand
    def relation_call(models, table, hash, callable, operator:'or')
      models.joins!(table.to_sym)
      hash.each do |column, value|
        if column.present? and value.present?
          relation_values = value.instance_of?(Array) ? value : [value]
          models.where!(relation_values.map{|value| callable.call(table.pluralize, column, value)}.join(" #{operator} "))
        end
      end
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

      # filter
      models.filtering!(params)

      # pager
      models.paging!(params)

      # sort
      models.sorting!(params)

      return models.uniq
    end
  end
end
