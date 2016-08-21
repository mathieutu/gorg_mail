class Ml::ListsController < ApplicationController
  before_action :set_ml_list, only: [:show, :edit, :update, :destroy]

  # GET /ml/lists
  # GET /ml/lists.json
  def index
    @ml_lists = Ml::List.all
  end

  # GET /ml/lists/1
  # GET /ml/lists/1.json
  def show
    @members = @ml_list.users
  end

  # GET /ml/lists/new
  def new
    @ml_list = Ml::List.new
  end

  # GET /ml/lists/1/edit
  def edit
  end

  # POST /ml/lists
  # POST /ml/lists.json
  def create
    @ml_list = Ml::List.new(ml_list_params)

    respond_to do |format|
      if @ml_list.save
        format.html { redirect_to @ml_list, notice: 'List was successfully created.' }
        format.json { render :show, status: :created, location: @ml_list }
      else
        format.html { render :new }
        format.json { render json: @ml_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ml/lists/1
  # PATCH/PUT /ml/lists/1.json
  def update
    respond_to do |format|
      if @ml_list.update(ml_list_params)
        format.html { redirect_to @ml_list, notice: 'List was successfully updated.' }
        format.json { render :show, status: :ok, location: @ml_list }
      else
        format.html { render :edit }
        format.json { render json: @ml_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ml/lists/1
  # DELETE /ml/lists/1.json
  def destroy
    @ml_list.destroy
    respond_to do |format|
      format.html { redirect_to ml_lists_url, notice: 'List was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def join
    #todo : add autorizatiosn
    @user = User.find(params[:user_id])
    @ml_list = Ml::List.find(params[:list_id])

    if @ml_list.add_user(@user)
      get_list(@user)
      respond_to do |format|
        flash[:notice] = "Tu as rejoint la liste de diffusion #{@ml_list.name}"
        format.json { head :no_content }
        format.js
      end
    else
      respond_to do |format|
        flash[:error] = "Impossible de rejoindre la liste de diffusion #{@ml_list.name}"
        format.json { head :no_content }
        format.js
      end
    end
  end

  def leave
    #todo : add autorizatiosn
    @user = User.find(params[:user_id])
    @ml_list = Ml::List.find(params[:list_id])

    if @ml_list.remove_user(@user)
      get_list(@user)
      respond_to do |format|
        flash[:notice] = "Tu as quitté la liste de diffusion #{@ml_list.name}"
        format.json { head :no_content }
        format.js {render :join}
      end
    else
      respond_to do |format|
        flash[:error] = "Impossible de quitter la liste de diffusion #{@ml_list.name}"
        format.json { head :no_content }
        format.js {render :join}
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ml_list
      @ml_list = Ml::List.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ml_list_params
      params.require(:ml_list).permit(:name, :email, :description, :aliases, :diffusion_policy, :inscription_policy_id, :is_public, :messsage_header, :message_footer, :is_archived, :custom_reply_to, :default_message_deny_notification_text, :msg_welcome, :msg_goodbye, :is_archived, :message_max_bytes_size)
    end
end