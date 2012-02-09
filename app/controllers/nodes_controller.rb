class NodesController < ApplicationController
  # GET /nodes
  # GET /nodes.xml
  
  def index
    @racks = {}
    @layout =[]
    # @nodes = Location.all(:order => "rack ASC , rank ASC , hostname ASC")
    # @locations = Location.all
    d_racks = Location.all(:select => "DISTINCT rack")
    d_racks.each {|x| @layout[x.rack] = Location.find_all_by_rack(d_racks[x.rack].rack).size }

    @coordinates = Array.new(@layout.size){Array.new(@layout.max)}
    
    @layout.max.times do |rank| # fullest rack
      @layout.size.times do |rack| # number of racks, assumes sequential rack numbering; TODO: FIXME
        if t = Location.find_by_rack_and_rank(rack,rank)
          @coordinates[rack][rank] = t
        end
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nodes }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    @node = Node.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.xml
  def new
    @node = Node.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.xml
  def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        format.html { redirect_to(@node, :notice => 'Node was successfully created.') }
        format.xml  { render :xml => @node, :status => :created, :location => @node }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.xml
  def update
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html { redirect_to(@node, :notice => 'Node was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.xml
  def destroy
    @node = Node.find(params[:id])
    @node.destroy

    respond_to do |format|
      format.html { redirect_to(nodes_url) }
      format.xml  { head :ok }
    end
  end
  
  def thresh_defaults
    @node = Node.find(params[:id])
    @node.thresh_unc = @node.def_thresh_unc
    @node.thresh_ucr = @node.def_thresh_ucr
    @node.thresh_unr = @node.def_thresh_unr
    @node.save
    respond_to do |format|
      format.html { redirect_to(@node, :notice => "Thresholds were reset to default values") }
    end
  end
  
end
