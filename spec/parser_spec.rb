require File.dirname(__FILE__) + '/spec_helper'

describe 'The StatemachineParser for' do
  describe 'states' do
  begin
    describe 'without a superstate' do
      before (:each) do
        @messenger = mock("messenger" )

        parser = StatemachineParser.new(nil,@messenger)

        scxml = <<EOS
<scxml name="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2"/>
     <transition event="event4" target="state2">
        <log expr="transition executing"/>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state3"/>
  </state>

  <state id="state3">
     <transition event="event3" target="state1"/>
  </state>
</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
      end

      it "should start with the correct initial state without initial attribute set" do
        @sm.state.should==:state1
      end

      it "should support transitions " do
        @sm.event1
        @sm.state.should==:state2
        @sm.event2
        @sm.state.should==:state3
        @sm.event3
        @sm.state.should==:state1
      end

      it "should support logging inside a transition" do
        @messenger.should_receive(:puts).with("transition executing" )
        @sm.event4
      end
    end

    describe "in the same superstate" do
      before (:each) do
        @messenger = mock("messenger" )

        parser = StatemachineParser.new(nil,@messenger)

        scxml = <<EOS
<?xml version="1.0"?>
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript">
  <state id="super" initial="child2">
    <state id="child1">
      <transition event="event1" target="child2">
        <log expr="'This is action1'"/>
      </transition>
    </state>
    <state id="child2">
      <transition event="event2" target="child3">
        <log expr="'This is action2'"/>
      </transition>
    </state>
    <state id="child3">
      <transition event="event3" target="child1">
        <log expr="'This is action3'"/>
      </transition>
    </state>
  </state>
</scxml>
EOS
        @sm = parser.build_from_scxml_string scxml
      end

      it "should start with the correct state" do
        @sm.state.should==:child2
      end

      it "should support transitions and logging inside transitions" do
        @messenger.should_receive(:puts).with("'This is action2'" )
        @sm.event2
        @sm.state.should==:child3

        @messenger.should_receive(:puts).with("'This is action3'" )
        @sm.event3
        @sm.state.should==:child1

        @messenger.should_receive(:puts).with("'This is action1'" )
        @sm.event1
        @sm.state.should==:child2
      end

      it 'should start with the correct state even if the initial state has not been explicitly set' do
        scxml = <<EOS
<?xml version="1.0"?>
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript">
  <state id="state">
    <state id="state1">
      <transition event="event1" target="state2">
        <log expr="'This is action1'"/>
      </transition>
    </state>
    <state id="state2">
      <transition event="event2" target="state3">
        <log expr="'This is action2'"/>
      </transition>
    </state>
  </state>
</scxml>
EOS
        parser = StatemachineParser.new
        @sm = parser.build_from_scxml_string scxml
        @sm.state.should==:state1

      end
    end
    describe "in double nested superstates" do
      before (:each) do

        parser = StatemachineParser.new
        scxml = <<EOS
<?xml version="1.0"?>
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript">
  <state id="state1" initial="state12">
    <transition event="to_state2" target="state2"/>
      <state id="state11" initial="state111">
        <state id="state111">
          <transition event="to_state12" target="state12"/>
        </state>
        <transition event="to_state111" target="state111"/>
        <transition event="to_state13" target="state13"/>
      </state>
      <state id="state12">
        <transition event="to_state13" target="state13"/>
      </state>
      <state id="state13">
        <transition event="to_state11" target="state11"/>
      </state>
    </state>
    <state id="state2"/>
</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
      end

      it "should support starting with the correct inital state that has been excplicitely set" do
        @sm.state.should==:state12
        @sm.to_state13
        @sm.to_state11
        @sm.state.should==:state111
      end

      it "should support transitions the are defined for a superstate to get into a nested state of the same superstate" do
        @sm.to_state13
        @sm.to_state11
        @sm.to_state111
        @sm.state.should==:state111
        @sm.to_state12
        @sm.state.should==:state12
      end
      it "should support transitions the are defined for a superstate to get into another state on the same level of the superstate" do
        @sm.to_state13
        @sm.to_state11
        @sm.to_state111
        @sm.state.should==:state111
        @sm.to_state13
        @sm.state.should==:state13
      end

      it "should support transitions the are defined from a super-superstate " do
        @sm.to_state13
        @sm.to_state11
        @sm.to_state111
        @sm.state.should==:state111
        @sm.to_state2
        @sm.state.should==:state2
      end
    end

    describe 'with onentry or onexit' do

      before (:each) do
        @messenger = mock("messenger" )

        @message_queue = mock("message_queue" )

        parser = StatemachineParser.new(nil, @messenger, @message_queue)

        scxml = <<EOS
<scxml name="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
        <transition event="to_state2" target="state2"/>
  </state>
  <state id="state2">
     <onentry>
          <log expr="'inside state2 onentry'"/>
          <send type="'x-mint'" target="target" event="fax.SEND"/>
     </onentry>
     <onexit>
          <log expr="'inside state2 onexit'"/>
     </onexit>
      <transition event="to_state1" target="state1">
           <send type="'x-mint'" target="target-2" event="fax.SEND-2"/>
        </transition>
  </state>

</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
      end

      it "should consider onentry" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @message_queue.should_receive(:send).with("target","fax.SEND")
        @sm.to_state2
      end

      it "should consider onexit" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @message_queue.should_receive(:send).with("target","fax.SEND")
        @sm.to_state2
        @messenger.should_receive(:puts).with("'inside state2 onexit'" )
        @message_queue.should_receive(:send).with("target-2","fax.SEND-2")
        @sm.to_state1
      end

      it "should receive send inside onentry" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @message_queue.should_receive(:send).with("target","fax.SEND")
        @sm.to_state2
      end

      it "should receive send inside a transition" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @message_queue.should_receive(:send).with("target","fax.SEND")
        @sm.to_state2
        @messenger.should_receive(:puts).with("'inside state2 onexit'" )
        @message_queue.should_receive(:send).with("target-2","fax.SEND-2")
        @sm.to_state1
      end
    end
  end

  describe 'parallel' do
      before (:each) do
        parser = StatemachineParser.new

        scxml = <<EOS
<?xml version="1.0"?>
<scxml name="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state0">
    <transition event="to_p" target="parallel"/>
  </state>
  <state id="p_super">
    <transition event="to_0" target="state0"/>
    <parallel id="parallel">
        <state id="state1">
          <state id="state11">
            <transition event="to_12" cond="In(:state22)" target="state12"/>
          </state>
          <state id="state12">
            <transition event="to_11" cond="In(:state21)" target="state12"/>
          </state>
        </state>

        <state id="state2" initial="state22">
          <state id="state21">
           <transition event="to_22" target="state22"/>
          </state>
          <state id="state22">
            <transition event="to_21" target="state21"/>
          </state>
        </state>
    </parallel>
  </state>
</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
      end

      it "start with the initial state and transition to the parallel states" do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.states_id.should == [:state11,:state22]
      end

      it "support transitions for both parallel superstates" do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.process_event(:to_12)
        @sm.In(:state12).should == true
        @sm.process_event(:to_21)
        @sm.In(:state21).should == true
        @sm.states_id.should == [:state12,:state21]
      end

      it "support testing with 'in' condition for primitive states " do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.process_event(:to_12)
        @sm.In(:state12).should == true
      end

      it "support testing with 'in' condition for  superstates " do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.process_event(:to_12)
        @sm.In(:state1).should == true
      end

      it "support testing with 'in' condition for parallel superstates " do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.process_event(:to_12)
        @sm.In(:state2).should == true
        @sm.In(:state1).should == true
      end

      it "should only transition if In is satisfied" do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.process_event(:to_21)
        @sm.states_id.should == [:state11,:state21]
        @sm.process_event(:to_12)
        @sm.states_id.should == [:state11,:state21]
      end
  end

  describe "History States with default history state" do
    before(:each) do
      parser = StatemachineParser.new

        scxml = <<EOS
<scxml id="SCXML" initial="state1" name="history" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=280.0 h=250.0  -->
 <state id="state1"><!--   node-size-and-position x=10.0 y=30.0 w=100.0 h=30.0  -->
  <transition event="to_3" target="state3"></transition>
 </state>
 <state id="state3" initial="state3_1"><!--   node-size-and-position x=140.0 y=30.0 w=130.0 h=200.0  -->
  <transition event="to_1" target="state1"></transition>
  <state id="state3_1"><!--   node-size-and-position x=20.0 y=40.0 w=100.0 h=30.0  -->
   <transition event="to_3_2" target="state3_2"></transition>
  </state>
  <state id="state3_2"><!--   node-size-and-position x=20.0 y=150.0 w=100.0 h=30.0  -->
   <transition event="to_3_1" target="state3_1"><!--   edge-path [state3_1]  x=110.0 y=110.0  --></transition>
  </state>
  <history id="H" type="deep"><!--   node-size-and-position x=10.0 y=110.0 w=40.0 h=30.0  -->
   <transition target="state3_2"></transition>
  </history>
 </state>
</scxml>
EOS

      @sm = parser.build_from_scxml_string scxml
    end


    it "default history" do
      @sm.process_event(:to_3)
      @sm.state.should eql(:state3_2)
    end

    it "reseting the statemachine resets history" do
      @sm.process_event(:to_3)
      @sm.process_event(:to_3_1)
      @sm.process_event(:to_1)
      @sm.get_state(:state3).history_id.should eql(:state3_1)

      @sm.reset
      @sm.get_state(:state3).history_id.should eql(:state3_2)
    end
  end

  describe "History States without default history state" do
    before(:each) do
      parser = StatemachineParser.new

        scxml = <<EOS
<scxml id="SCXML" initial="state1" name="history" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=280.0 h=250.0  -->
 <state id="state1"><!--   node-size-and-position x=10.0 y=30.0 w=100.0 h=30.0  -->
  <transition event="to_3" target="state3"></transition>
 </state>
 <state id="state3" initial="state3_1"><!--   node-size-and-position x=140.0 y=30.0 w=130.0 h=200.0  -->
  <transition event="to_1" target="state1"></transition>
  <state id="state3_1"><!--   node-size-and-position x=20.0 y=40.0 w=100.0 h=30.0  -->
   <transition event="to_3_2" target="state3_2"></transition>
  </state>
  <state id="state3_2"><!--   node-size-and-position x=20.0 y=150.0 w=100.0 h=30.0  -->
   <transition event="to_3_1" target="state3_1"><!--   edge-path [state3_1]  x=110.0 y=110.0  --></transition>
  </state>
  <history id="H" type="deep"><!--   node-size-and-position x=10.0 y=110.0 w=40.0 h=30.0  -->
  </history>
 </state>
</scxml>
EOS

      @sm = parser.build_from_scxml_string scxml
    end


    it "reseting the statemachine resets history" do
      @sm.process_event(:to_3)
      @sm.process_event(:to_1)
      @sm.get_state(:state3).history_id.should eql(:state3_1)

      @sm.reset
      @sm.get_state(:state3).history_id.should eql(nil)
    end
  end

  describe "Nested Superstates" do
    before(:each) do
      parser = StatemachineParser.new

        scxml = <<EOS
<scxml id="SCXML" initial="grandpa" name="history" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=250.0 h=270.0  -->
 <state id="grandpa" initial="start"><!--   node-size-and-position x=10.0 y=30.0 w=230.0 h=110.0  -->
  <transition event="sister" target="great_auntie"></transition>
  <state id="papa" initial="son"><!--   node-size-and-position x=10.0 y=30.0 w=150.0 h=70.0  -->
   <state id="daughter"><!--   node-size-and-position x=70.0 y=30.0 w=70.0 h=30.0  --></state>
   <state id="son"><!--   node-size-and-position x=10.0 y=30.0 w=50.0 h=30.0  --></state>
  </state>
  <state id="start"><!--   node-size-and-position x=170.0 y=30.0 w=50.0 h=30.0  -->
   <transition event="go" target="daughter"></transition>
  </state>
  <history id="H" type="deep"><!--   node-size-and-position x=180.0 y=70.0 w=30.0 h=30.0  --></history>
 </state>
 <state id="great_auntie"><!--   node-size-and-position x=100.0 y=230.0 w=100.0 h=30.0  -->
  <transition event="foo" target="grandpa"><!--   edge-path [grandpa]  x=200.0 y=200.0  --></transition>
 </state>
</scxml>
EOS

      @sm = parser.build_from_scxml_string scxml
 end

    it "should use history of sub superstates when transitioning itto it's own history" do
      @sm.go
      @sm.sister
      @sm.foo

      @sm.state.should eql(:daughter)
    end
  end
  end
end
