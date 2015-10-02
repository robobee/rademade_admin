# -*- encoding : utf-8 -*-
# todo extract more modules
module RademadeAdmin
  class ModelController < RademadeAdmin::AbstractController

    extend RademadeAdmin::ModelOptions

    include RademadeAdmin::InstanceOptions
    include RademadeAdmin::Templates
    include RademadeAdmin::Notifier
    
    helper RademadeAdmin::FieldHelper
    helper RademadeAdmin::FormHelper
    helper RademadeAdmin::UriHelper
    helper RademadeAdmin::PaginationHelper

    before_filter :load_options, :model, :pagination_variants
    before_filter :sortable_service, :only => [:index]

    def create
      authorize! :create, model_class
      saver = RademadeAdmin::Saver.new(model_info, params)
      saver.create_model
      saver.set_data
      before_create saver.item
      saver.save_item
      success_insert saver.item
    rescue Exception => e
      render_record_errors e
    end

    def update
      saver = RademadeAdmin::Saver.new(model_info, params)
      saver.find_model
      authorize! :update, saver.item
      saver.set_data
      before_update saver.item
      saver.save_item
      success_update saver.item
    rescue Exception => e
      render_record_errors e
    end

    def destroy
      @item = @model_info.query_adapter.find(params[:id])
      authorize! :destroy, @item
      before_destroy @item
      @model_info.persistence_adapter.destroy(@item) if @item
      success_delete @item
    end

    def autocomplete
      authorize! :read, model_class
      render :json => Autocomplete::BaseSerializer.new(autocomplete_items)
    end

    def index
      authorize! :read, model_class
      @items = index_items
      respond_to do |format|
        format.html { render_template }
        format.json { render :json => @items }
        format.csv { render_csv }
      end
    end

    def new
      authorize! :create, model_class
      @with_save_and_return_button = true
      @item = new_model
      @is_edit = false
      render_template
    end

    def edit
      @item = @model_info.query_adapter.find(params[:id])
      authorize! :update, @item
      @with_save_and_return_button = true
      @is_edit = true
      render_template
    end

    def show
      @item = @model_info.query_adapter.find(params[:id])
      authorize! :read, @item
      respond_to do |format|
        format.html { redirect_to :action => 'index' }
        format.json { render :json => @item }
      end
    end

    def form
      authorize! :read, model_class
      @item = params[:id].blank? ? new_model : @model_info.query_adapter.find(params[:id])
      render form_template_path(true), :layout => false
    end

    def sort
      sortable_service.sort_items
      success_action
    end

    protected
    # TODO move to search module

    def index_items
      conditions = Search::Conditions::List.new(params, model_info.data_items)
      if params[:rel_class] && params[:rel_id] && params[:rel_getter]
        related_info = RademadeAdmin::Model::Graph.instance.model_info(params[:rel_class])
        @related_model = related_info.query_adapter.find(params[:rel_id])
        conditions.base_items = @related_model.send(params[:rel_getter])
      end
      Search::Searcher.new(model_info).search(conditions)
    end

    def autocomplete_items
      conditions = Search::Conditions::Autocomplete.new(params, model_info.data_items)
      Search::Searcher.new(model_info).search(conditions)
    end

    def new_model
      @model_info.persistence_adapter.new_record
    end

    def before_create(item)

    end

    def before_update(item)

    end

    def before_destroy(item)

    end

    def model
      @model ||= model_info.model
    end

    def render_template(template = action_name)
      @with_layout = params[:layout] != 'false'
      render abstract_template(template), :layout => @with_layout
    end

    def sortable_service
      @sortable_service ||= RademadeAdmin::SortableService.new(model_info, params)
    end

    def render_record_errors(e)
      # todo place into adapters
      errors = case e
        when ActiveRecord::RecordInvalid, Mongoid::Errors::Validations
          e.record.errors
        when Sequel::ValidationFailed
          e.errors
        else
          e.message
      end
      render_errors errors
    end

    def render_csv
      send_data RademadeAdmin::CsvService.new(model_info, @items).to_csv
    end

    def pagination_variants
      @pagination_variants ||= [20, 40, 60]
    end

  end
end