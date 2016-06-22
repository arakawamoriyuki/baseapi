class BaseApiController < ActionController::Base
  protect_from_forgery with: :exception

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
      self.send("before_#{__method__}") if self.methods.include?("before_#{__method__}".to_sym)
      params.each do |key, value|
        if key.present? and @Model.column_names.include?(key)
          @model.send("#{key}=", value)
        end
      end
      @model.save
      self.send("after_#{__method__}") if self.methods.include?("after_#{__method__}".to_sym)
    })
  end

  # PATCH/PUT /{models}/{id}.json
  # @param
  # @return String  Json(Model)
  def update
    render 'model.json.jbuilder' if transaction(-> {
      self.send("before_#{__method__}") if self.methods.include?("before_#{__method__}".to_sym)
      params.each do |key, value|
        if key.present? and @Model.column_names.include?(key)
          @model.send("#{key}=", value)
        end
      end
      @model.save
      self.send("after_#{__method__}") if self.methods.include?("after_#{__method__}".to_sym)
    })
  end

  # DELETE /{models}/{id}.json
  # @param
  # @return String  Json(Model)
  def destroy
    render 'model.json.jbuilder' if transaction(-> {
      self.send("before_#{__method__}") if self.methods.include?("before_#{__method__}".to_sym)
      @model._destroy
      self.send("after_#{__method__}") if self.methods.include?("after_#{__method__}".to_sym)
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
