class ScriptsController < ApplicationController
  before_action :set_script, only: [:show, :edit, :update, :destroy]

  # GET /scripts
  # GET /scripts.json
  def index
    @scripts = Script.all

    unless params[:name].blank?
      @scripts = @scripts.where('name like ?', "%#{params[:name]}%")
    end
    
    unless params[:passed].blank?
      @scripts = @scripts.where(passed: params[:passed])
    end

    @scripts = @scripts.paginate(page: params[:page], per_page: 10)
  end

  # GET /scripts/1
  # GET /scripts/1.json
  def show
  end

  def play
    script = Script.friendly.find(params[:script_id])
    play_script(script, false)

    redirect_to scripts_url
  end 

  def action
    unless params[:ids].blank?
      scripts = Script.where(id: params[:ids].keys)

      if params[:action_name][0..20] == 'Play selected scripts'
        scripts.each do |script|
          headless_mode = (params[:action_name] == 'Play selected scripts in headless mode')
          play_script(script, headless_mode)
        end
        flash[:notice] = "#{scripts.count} script(s) played"  
      end
    end

    redirect_to scripts_url
  end

  # GET /scripts/new
  def new
    @script = Script.new
  end

  # GET /scripts/1/edit
  def edit
  end

  # POST /scripts
  # POST /scripts.json
  def create
    @script = Script.new(script_params)

    respond_to do |format|
      if @script.save
        
        play_script(@script, false)

        format.html { redirect_to @script, notice: 'Script was successfully created.' }
        format.json { render :show, status: :created, location: @script }
      else
        format.html { render :new }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scripts/1
  # PATCH/PUT /scripts/1.json
  def update
    respond_to do |format|
      if @script.update(script_params)

        play_script(@script, false)

        format.html { redirect_to @script }
        format.json { render :show, status: :ok, location: @script }
      else
        format.html { render :edit }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.json
  def destroy
    @script.destroy
    respond_to do |format|
      format.html { redirect_to scripts_url, notice: 'Script was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_script
      @script = Script.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def script_params
      params.require(:script).permit(:name, :description, :body)
    end

    # Execute le script de test avec les assertions du script #id
    def play_script(script, headless_mode)
      
      cmd = "script_id=#{script.id} headless_mode=#{ headless_mode ? '1': '0' } rails test test/system/automat_test.rb"
      wasGood = system(cmd)

      script.passed    = wasGood
      script.passed_at = DateTime.now
      script.save

      copy_screenshoot(script)

      if script.passed?
        flash[:notice] = "OK => Test passed successfully"
      else
        flash[:alert] = "KO! => Test failure"
      end
    end

    def copy_screenshoot(script)
      path = '/home/philnoug/RailsProjects/tests_monkey'
      dest = path + '/public' + script.screenshot

      if script.passed?
        system("cp #{ path }/tmp/screenshots/test_assertions_from_database.png #{ dest }")
      else  
        system("cp #{ path }/tmp/screenshots/failures_test_assertions_from_database.png #{ dest }")
      end  
    end

end
