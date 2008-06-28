class Vendor < ActiveRecord::Base
    validates_presence_of :lat, :lng 
    
    def self.search(search)
        if search
            find(:all, :conditions => ['name LIKE ?', "%#{search}%"])
            
        else
            find(:all)        
        end
        
    end
    acts_as_mappable :auto_geocode => true 
    
    def self.near(address, within)
        if within
            find(:all)
##            :origin => [?, "#{address}" ],
##            :within => [?, "#{within}"],
##            :order => 'distance')
        else
            find(:all)
        end
##        Vendor.find(:all, :conditions => ["origin = ? AND within = ? AND order = 'distance'"]) 
    end
end
