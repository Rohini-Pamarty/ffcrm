class ProjectsController < ApplicationController
before_filter :require_user
  before_filter :auto_complete, :only => :auto_complete
  before_filter :update_sidebar, :only => :index
  before_filter :set_current_tab, :only => [ :index, :show ]

  # GET /projects
  # GET /projects.xml
  #----------------------------------------------------------------------------
  def index
    @view = params[:view] || "pending"
puts @view

    @projects = Project.find_all_grouped(@current_user, @view)

    respond_to do |format|
      format.html # index.html.haml
      format.xml  { render :xml => @projects }
      format.xls  { send_data @projects.values.flatten.to_xls, :type => :xls }
      format.csv  { send_data @projects.values.flatten.to_csv, :type => :csv }
      format.rss  { render "common/index.rss.builder" }
      format.atom { render "common/index.atom.builder" }
    end
  end
def update_sidebar
    @view = params[:view]
    @view = "pending" unless %w(pending assigned completed).include?(@view)
    @project_total = Project.totals(@current_user, @view)

    # Update filters session if we added, deleted, or completed a project.
    if @project
      update_session do |filters|
        if @empty_bucket  # deleted, completed, rescheduled, or reassigned and need to hide a bucket
          filters.delete(@empty_bucket)
        elsif !@project.deleted_at && !@project.completed_at # created new project
          filters << @project.computed_bucket
        end
      end
    end

    # Create default filters if filters session is empty.
    name = "filter_by_project_#{@view}"
    unless session[name]
      filters = @project_total.keys.select { |key| key != :all && @project_total[key] != 0 }.join(",")
      session[name] = filters unless filters.blank?
    end
  end
 def new
    @project = Project.new
    @view = params[:view] || "pending"
    @users = User.except(@current_user).by_name
    @bucket = Setting.unroll(:project_bucket)[1..-1] 
#---------------------------------------------------------------try----------------------------------
    @category = Setting.unroll(:project_category)
    if params[:related]
      model, id = params[:related].split("_")
      instance_variable_set("@asset", model.classify.constantize.my.find(id))
    end

    respond_to do |format|
      format.js   # new.js.rjs
      format.xml  { render :xml => @project }
    end

  rescue ActiveRecord::RecordNotFound # Kicks in if related asset was not found.
    respond_to_related_not_found(model, :js) if model
  end

 def create
    @project = Project.new(params[:project]) # NOTE: we don't display validation messages for tasks.
    @view = params[:view] || "pending"

    respond_to do |format|
      if @project.save
        update_sidebar if called_from_index_page?
        format.js   # create.js.rjs
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.js   # create.js.rjs
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

end
