class VendorsController < ApplicationController
  # GET /vendors
  # GET /vendors.xml
  def index
      @address  = params[:address]
      @within   = params[:within]
      unless @within
        @vendors = Vendor.search(params[:search])
      else
          @vendors = Vendor.find :all, 
                          :origin => @address,
                          :within => @within,
                          :order => 'distance'
        
      end
    

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vendors }
    end
  end

  # GET /vendors/1
  # GET /vendors/1.xml
  def show
    @vendor = Vendor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vendor }
    end
  end

  # GET /vendors/new
  # GET /vendors/new.xml
  def new
    @vendor = Vendor.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vendor }
    end
  end

  # GET /vendors/1/edit
  def edit
    @vendor = Vendor.find(params[:id])
  end

  # POST /vendors
  # POST /vendors.xml
  def create
    @vendor = Vendor.new(params[:vendor])

    respond_to do |format|
      if @vendor.save
        flash[:notice] = 'Vendor was successfully created.'
        format.html { redirect_to(@vendor) }
        format.xml  { render :xml => @vendor, :status => :created, :location => @vendor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vendor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vendors/1
  # PUT /vendors/1.xml
  def update
    @vendor = Vendor.find(params[:id])

    respond_to do |format|
      if @vendor.update_attributes(params[:vendor])
        flash[:notice] = 'Vendor was successfully updated.'
        format.html { redirect_to(@vendor) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vendor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vendors/1
  # DELETE /vendors/1.xml
  def destroy
    @vendor = Vendor.find(params[:id])
    @vendor.destroy

    respond_to do |format|
      format.html { redirect_to(vendors_url) }
      format.xml  { head :ok }
    end
  end
  
  def search 
      @address = params[:address] 
      @within = params[:within] 
      @vendors = Vendor.find :all, 
      :origin => @address, 
      :within => @within, 
      :order => 'distance' 
      
      respond_to do |format| 
        format.html # search.html.erb 
        format.xml { render :xml => @vendors } 
    end 
  end 
  
end
