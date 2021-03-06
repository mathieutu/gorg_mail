class EmailRedirectAccountsController < ApplicationController
  before_action :set_email_redirect_account, only: [:show, :edit, :update, :destroy]
  before_action :set_user


  # GET /users/:user_id/email_redirect_accounts.json
  def index
    @email_redirect_accounts = @user.email_redirect_accounts.all
    @email_redirect_accounts.each{|era| authorize!(:show, era)}
    respond_to do |format|
        format.js
        format.json
    end
  end


  # GET /users/:user_id/email_redirect_accounts/1.json
  def show
		authorize! :show, @email_redirect_account
    respond_to do |format|
      format.json
      format.js
    end
  end


  # POST /users/:user_id/email_redirect_accounts.json
  def create   
    @email_redirect_account = @user.email_redirect_accounts.new(email_redirect_account_params)
    authorize! :create, @email_redirect_account
    @email_redirect_account.type_redir = "smtp"
    @email_redirect_account.flag = "inactive"
    
    @email_redirect_account.generate_new_token
    
     respond_to do |format|
      if @email_redirect_account.save
        
        #attention, les deux lignes suivantes sont égaleement dans le controleur user / dashboard
        @emails_redirect = @user.email_redirect_accounts.order(:type_redir).select(&:persisted?)
        
        EmailValidationMailer.confirm_email(@user,@email_redirect_account,confirm_user_email_redirect_accounts_url(@user, @email_redirect_account.confirmation_token)).deliver_now

        format.json { render :show, status: :created, location: user_email_redirect_account_url(@user,@email_redirect_account) }
        #format.json {render :index}
        format.js
      else
        @emails_redirect = @user.email_redirect_accounts.order(:type_redir).select(&:persisted?)
        flash[:error] = "Impossible d'ajouter cette adresse car elle "+@email_redirect_account.errors[:redirect].to_a.first
        format.json { render json: @email_redirect_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/:user_id/email_redirect_accounts/1.json
  def update
		
		authorize! :update, @email_redirect_account
		
    respond_to do |format|
      if @email_redirect_account.update(email_redirect_account_params)
        format.json { render :show, status: :ok, location: user_email_redirect_account_url(@user,@email_redirect_account) }
      else
        format.json { render json: @email_redirect_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_redirect_accounts/1.json
  def destroy
		authorize! :destroy, @email_redirect_account

    @emails_redirect = email_redirect(@user)
    actives_eras_count = (@emails_redirect.select{|e| e.active?} - [@email_redirect_account]).count

    respond_to do |format|
      if actives_eras_count > 0 || @email_redirect_account.inactive?
        @email_redirect_account.destroy
        @emails_redirect = email_redirect(@user)
        format.json { head :no_content }
        format.js
      else
        flash[:error] = "Impossible de supprimer cette adresse, il n'y aurait plus de redirection."
        format.json { head :no_content }
        format.js
      end
    end
  end

  def confirm
    token=params[:token]
    
    if @email_redirect_account=EmailRedirectAccount.find_by_confirmation_token(token)
      if @email_redirect_account.set_confirmed
        @emails_redirect = email_redirect(@user)
        # on essaie d'activer l'adresse. Si ça ne marche pas ( trop d'adresse de redir, un revois un message différent)
        if @email_redirect_account.set_active
          respond_to do |format|
            flash[:notice] = "Adresse validée et activée avec succés!"
            format.json { render :show, status: :ok, location: user_email_redirect_account_url(@user,@email_redirect_account) }
            format.html {redirect_to dashboard_user_path(@user)}
            format.js
          end
        else
          respond_to do |format|
            flash[:notice] = "Adresse validée! Désactivez une autre adresse pour pouvoir l'activer"
            format.json { render :show, status: :ok, location: user_email_redirect_account_url(@user,@email_redirect_account) }
            format.html {redirect_to dashboard_user_path(@user)}
            format.js
        end
        end
      else
        respond_to do |format|
          flash[:error] = "Impossible de confirmer cette adresse."
          format.json { head :no_content }
          format.html {redirect_to root_path}
          format.js
        end        
      end
    else
        respond_to do |format|
          flash[:error] = "Impossible de confirmer cette adresse."
          format.json { head :no_content }
          format.html {redirect_to root_path}
          format.js
        end     
    end
  end
 
 #for changin flag
 def flag
      era = EmailRedirectAccount.find(params[:email_redirect_account_id])
      authorize! :update, era
      flag = params[:flag]
      case flag
      when "active"
        if era.set_active
          #attention, les deux lignes suivantes sont égaleement dans le controleur user / dashboard
          @emails_redirect = @user.email_redirect_accounts.order(:type_redir).select(&:persisted?)
        
          respond_to do |format|
            flash[:notice] = "Adresse activée avec succés!"
            format.json { head :no_content }
            format.js
          end
        else
            #attention, les deux lignes suivantes sont égaleement dans le controleur user / dashboard
            @emails_redirect = @user.email_redirect_accounts.order(:type_redir).select(&:persisted?)
          
            respond_to do |format|
            flash[:error] = "Tu ne peux pas activer plus de #{Configurable[:max_actives_era]} adresses en même temps"
            format.json { head :no_content }
            format.js
          end
        end
      when "inactive"
        if era.set_inactive
          #attention, les deux lignes suivantes sont égaleement dans le controleur user / dashboard
        @emails_redirect = @user.email_redirect_accounts.order(:type_redir).select(&:persisted?)
        
          respond_to do |format|
            flash[:notice] = "Adresse désactivée avec succés!"
            # format.json { head :no_content }
            format.js
          end
          else
            @emails_redirect = email_redirect(@user)

        
            respond_to do |format|
            flash[:error] = "Erreur lors de la désactivation"
            # format.json { head :no_content }
            format.js
          end
        end
      else
        
      end
 end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_redirect_account
      @email_redirect_account = EmailRedirectAccount.find(params[:id])
    end
  
    def set_user
      @user = User.find(params[:user_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def email_redirect_account_params
      params.require(:email_redirect_account).permit(:redirect, :flag, :type_redire, :user_id)
    end
end
