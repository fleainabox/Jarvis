class TasksController < ApplicationController
  respond_to :html, :js

  before_filter :authorize

  def show
    @task = Task.find(params[:id])
    @completions = Completion.where(task_id: @task.id).order("completed DESC").limit(5)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @task }
    end
  end

  def new
    if params[:family_id]
      @task = Family.find_by_id(params[:family_id]).tasks.new()
    else
      @task = User.find_by_id(params[:user_id]).tasks.new()
    end
  end

  def edit
    @task = Task.find(params[:id])
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      flash[:notice] = t('controllers.task_created', task: @task.title)
    end
    respond_with @task
  end

  def update
    @task = Task.find(params[:id])

    flash[:notice] = t('controllers.task_updated', task: @task.title) if @task.update_attributes(task_params)
    respond_with @task
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to user_path(@task.user) }
      format.json { head :no_content }
    end
  end

  private

  def task_params
    params.require(:task).permit!
  end
end
