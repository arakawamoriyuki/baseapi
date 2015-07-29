class BaseApiController < ActionController::Base

  before_action :set_Model
  before_action :set_models, only: [:index]
  before_action :set_model, only: [:show, :create, :update, :destroy]

  # GET /{models}.json
  # @param  Hash
  # @return String  Json(Models)
  def index
    render 'models.json.jbuilder'
  end

  # GET /{models}/{id}.json
  # @return String  Json(Model)
  def show
    render 'model.json.jbuilder'
  end

  # POST /{models}/{id}.json
  # @param
  # @return String  Json(Model)
  def create
    render 'model.json.jbuilder' if transaction(-> {
      params.each do |key, value|
        if key.present? and value.present? and @Model.column_names.include?(key)
          @model.send("#{key}=", value)
        end
      end
      @model.save
    })
  end

  # PATCH/PUT /{models}/{id}.json
  # @param
  # @return String  Json(Model)
  def update
    render 'model.json.jbuilder' if transaction(-> {
      params.each do |key, value|
        if key.present? and value.present? and @Model.column_names.include?(key)
          @model.send("#{key}=", value)
        end
      end
      @model.save
    })
  end

  # DELETE /{models}/{id}.json
  # @param
  # @return String  Json(Model)
  def destroy
    render 'model.json.jbuilder' if transaction(-> {
      @model._destroy
    })
  end


  private
    # set Model class
    def set_Model
      @Model = params[:controller].camelize.singularize.constantize
    end

    # set model
    def set_model
      @model = params[:id].present? ? @Model.find(params[:id]) : @Model.new
    end

    # set models
    def set_models
      @models = @Model.search(params)
    end

    # transaction
    # @param  callable  callable
    # @return bool
    def transaction (callable)
      begin
        @Model.transaction do
          callable.call()
        end
      rescue => e
        @message = e.message
        render 'error.json.jbuilder'
        return false
      end
      return true
    end
end
