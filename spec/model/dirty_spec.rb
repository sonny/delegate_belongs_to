require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with dirty delegations' do

  before :all do
    @fields = Contact.column_names - ActiveRecord::Base.default_rejected_delegate_columns
    UserDefault.belongs_to :contact
    UserDefault.delegates_attributes_to :contact
  end

  before :each do
    @user = UserDefault.new
  end  

  it "should set reflection autosave option to true" do
    UserDefault.reflect_on_association(:contact).options[:autosave].should be_true
  end

  describe "reading from no contact" do
    it "should return nil as firstname" do
      @user.firstname.should be_nil
    end

    it "should return nil as change" do
      @user.firstname_change.should be_nil
    end
    
    it "should not be changed" do
      @user.firstname_changed?.should be_false
    end

    it "should return nil as firstname_was" do
      @user.firstname_was.should be_nil
    end
  
    it "should return nil as lastname" do
      @user.firstname_will_change!
      @user.firstname_change.should == [nil, nil]
    end
  end
    

  describe "reading from existing contact" do
    before :each do
      @user.build_contact
      @user.contact.firstname = "John"
      @user.contact.lastname = "Smith"
    end
  
    it "should be changed as user" do
      @user.should be_changed
    end

    it "should be changed as contact" do
      @user.contact.should be_changed
    end
  
    it "should read firstname" do
      @user.firstname.should == "John"
    end
  
    it "should read lastname" do
      @user.lastname.should == "Smith"
    end
    
    it "should return [nil, 'John'] as change" do
      @user.firstname_change.should == [nil, "John"]
    end
    
    it "should not be changed" do
      @user.firstname_changed?.should be_true
    end

    it "should return nil as firstname_was" do
      @user.firstname_was.should be_nil
    end
  
    it "should return nil as lastname" do
      @user.firstname_will_change!
      @user.firstname_change.should == ['John', 'John']
    end
  end

  describe "assigning value to delegators" do
    it "should initialize association" do
      @user.contact.should be_nil
      @user.firstname = "John"
      @user.contact.should_not be_nil
      @user.firstname.should == "John"
    end
    
    it "should NOT initialize association second time" do
      @user.firstname = "John"
      contact_object_id = @user.contact.object_id
      @user.lastname = "Smith"
      @user.contact.object_id.should == contact_object_id
      @user.firstname.should == "John"
    end
    
  end
  
  [false, true].each do |bool|
    describe "partial update #{bool}" do
      before :all do
        ActiveRecord::Base.partial_updates = bool
      end
  
      describe "#save" do
        it "should clear changed_attribute in dirty assosiations" do
          @user.firstname = "John"
          @user.send(:changed_attributes).size.should == 1
          @user.contact.send(:changed_attributes).size.should == 1
          @user.save
          @user.send(:changed_attributes).size.should == 0
          @user.contact.send(:changed_attributes).size.should == 0
        end
        
        it "should save delegated attributes" do
          @user.firstname = "Bob"
          @user.save
          
          @user = UserDefault.find(@user.id)

          @user.lastname = "Marley"
          @user.save
          
          @user = UserDefault.find(@user.id)
          @user.firstname.should == "Bob"
          @user.lastname.should  == "Marley"
        end
      end
  
      describe "#save(false)" do
        it "should clear changed_attribute in dirty assosiations" do
          @user.firstname = "John"
          @user.send(:changed_attributes).size.should == 1
          @user.contact.send(:changed_attributes).size.should == 1
          @user.save(false)
          @user.send(:changed_attributes).size.should == 0
          @user.contact.send(:changed_attributes).size.should == 0
        end
      end
  
      describe "#save!" do
        it "should clear changed_attribute in dirty assosiations" do
          @user.firstname = "John"
          @user.send(:changed_attributes).size.should == 1
          @user.contact.send(:changed_attributes).size.should == 1
          @user.save!
          @user.send(:changed_attributes).size.should == 0
          @user.contact.send(:changed_attributes).size.should == 0
        end
      end

      describe "#reload" do
        before :each do
          @user.firstname = "John"
          @user.save!
        end
    
        it "should clear changed_attribute in dirty assosiations" do
          @user.firstname = "Bob"
          @user.send(:changed_attributes).size.should == 1
          @user.contact.send(:changed_attributes).size.should == 1
          @user.reload
      
          @user.firstname.should == "John"
          @user.send(:changed_attributes).size.should == 0
          @user.contact.send(:changed_attributes).size.should == 0
        end
      end
    end
  end
end