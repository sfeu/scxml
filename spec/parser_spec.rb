require 'scxml2.rb'

describe 'The StatemachineParser for' do
  describe 'states' do
    describe 'without a superstate' do
      before (:each) do
        @messenger = mock("messenger" )
        
        parser = StatemachineParser.new @messenger

        scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
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
        
        parser = StatemachineParser.new @messenger

        scxml = <<EOS
<?xml version="1.0"?>
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript" initial="off">
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
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript" initial="off">
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
        @messenger = mock("messenger" )
        
        parser = StatemachineParser.new @messenger

        scxml = <<EOS
<?xml version="1.0"?>
<scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" profile="ecmascript" initial="off">
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
    <state id="state2"/>
  </state>
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
        
        @messenger_queue = mock("message_queue" )
        
        parser = StatemachineParser.new(@messenger, @messenger_queue)

        scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
        <transition event="to_state2" target="state2"/>
  </state>
  <state id="state2">
     <onentry>
          <log expr="'inside state2 onentry'"/>
          <send type="'x-mint'" target="target" event="'fax.SEND'"/>
     </onentry>
     <onexit>
          <log expr="'inside state2 onexit'"/>
     </onexit>
      <transition event="to_state1" target="state1">
           <send ttype="'x-mint'" target="target-2" event="'fax.SEND-2'"/>
        </transition>
  </state>

</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
      end

      it "should consider onentry" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @sm.to_state2
      end

      it "should consider onexit" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @sm.to_state2
        @messenger.should_receive(:puts).with("'inside state2 onexit'" )
        @sm.to_state1
      end

      it "should receive send inside onentry" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @message_queue.should_receive(:send).with("target","fax.SEND")
        @sm.to_state2
      end

      it "should receive send inside a transition" do
        @messenger.should_receive(:puts).with("'inside state2 onentry'" )
        @sm.to_state2
        @messenger.should_receive(:puts).with("'inside state2 onexit'" )
        @message_queue.should_receive(:send).with("target-2","fax.SEND-2")
        @sm.to_state1
      end
    end
  end
end
