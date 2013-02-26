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
          @sm.reset
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
          @sm.reset
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
          @sm.reset
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
          @sm.reset
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

      describe 'with spontaneous transitions' do
        before (:each) do
          @log = ""
          parser = StatemachineParser.new(nil,nil)
          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="off">
     <onentry>
       <script>Proc.new {puts "entering off"}</script>
     </onentry>
     <onexit>
       <script>Proc.new {puts "exiting off"}</script>
     </onexit>
     <transition event="toggle" target="on">
       <script>@log += "on"</script>
     </transition>
     <transition target="done" cond="@log == 'onoff'"/>
  </state>

  <state id="on">
     <transition event="toggle" target="off">
       <script>@log += "off"</script>
     </transition>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
          @sm.reset
          @sm.context = self
        end

        it "should be done" do
          @sm.toggle
          @sm.state.should == :on
          @sm.toggle
          @sm.state.should == :done
        end

        it "should execute inside parallel states as well" do
          parser = StatemachineParser.new(nil,nil)
          @sm = parser.build_from_scxml(File.dirname(__FILE__) + "/testmachines/button.scxml")
          @sm.reset
          @sm.position
          @sm.calculated
          @sm.process_event :display
          @sm.states_id.should == [:displayed,:released]
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
        @sm.reset
      end

      it "start with the initial state and transition to the parallel states" do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.states_id.should ==  [:state11, :state22]

      end

      it "start set active root statemachine state to parallel id after transition to the parallel states" do
        @sm.states_id.should == [:state0]
        @sm.process_event(:to_p)
        @sm.state.should ==  :parallel
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
        @sm.reset
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
        @sm.reset
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
        @sm.reset
      end

      it "should use history of sub superstates when transitioning itto it's own history" do
        @sm.go
        @sm.sister
        @sm.foo

        @sm.state.should eql(:daughter)
      end
    end

    describe "On_entry and on_exit actions in" do
      begin
        describe 'states' do

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
            @sm.reset
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

        describe 'superstates inside a parallel state' do
          before (:each) do
            def hello_world
              @log = "Hello world!"
            end

            def goodbye
              @log = "Goodbye cruel world!"
            end
            parser = StatemachineParser.new(nil,nil)

            scxml = <<EOS
<scxml initial="disconnected" name="Mouse" version="0.9" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=662.0 h=660.0  -->
 <state id="disconnected"><!--   node-size-and-position x=280.0 y=60.0 w=100.0 h=50.0  -->
  <transition event="connect" target="connected"></transition>
 </state>
 <parallel id="connected"><!--   node-size-and-position x=70.0 y=190.0 w=500.0 h=470.0  -->
  <transition event="disconnect" target="disconnected"><!--   edge-path [disconnected]  x=400.0 y=160.0  --></transition>
  <state id="leftbutton" initial="released"><!--   node-size-and-position x=40.0 y=50.0 w=210.0 h=210.0  -->
   <onentry>
    <script>hello_world</script>
   </onentry>
   <onexit>
    <script>goodbye </script>
   </onexit>
   <state id="released"><!--   node-size-and-position x=20.0 y=50.0 w=140.0 h=40.0  -->
    <transition event="press" target="pressed"><!--   edge-path [pressed]  x=60.0 y=110.0 pointx=0.0 pointy=-40.0 offsetx=0.0 offsety=-5.0  --></transition>
   </state>
   <state id="pressed"><!--   node-size-and-position x=30.0 y=140.0 w=120.0 h=40.0  -->
    <transition event="release" target="released"><!--   edge-path [released]  x=140.0 y=120.0  --></transition>
   </state>
  </state>
  <state id="pointer" initial="stopped"><!--   node-size-and-position x=270.0 y=50.0 w=210.0 h=210.0  -->
   <state id="stopped"><!--   node-size-and-position x=50.0 y=60.0 w=100.0 h=40.0  -->
    <transition event="move" target="moving"><!--   edge-path [moving]  x=140.0 y=120.0  --></transition>
   </state>
   <state id="moving"><!--   node-size-and-position x=30.0 y=150.0 w=100.0 h=40.0  -->
    <transition event="stop" target="stopped"><!--   edge-path [stopped]  x=50.0 y=130.0 pointx=0.0 pointy=2.0 offsetx=-15.0 offsety=-2.0  --></transition>
   </state>
  </state>
 </parallel>
</scxml>
EOS

            @sm = parser.build_from_scxml_string scxml
            @sm.reset
            @sm.context = self
          end

          it "should support on entry for superstate inside a parallel state" do
            @sm.connect
            @log.should=="Hello world!"
          end

          it "should support on exit for superstate inside a parallel state" do
            @sm.connect
            @sm.disconnect
            @log.should=="Goodbye cruel world!"
          end

        end

        describe 'parallel states' do
          before (:each) do
            def hello_world
              @log = "Hello world!"
            end
            def goodbye
              @log = "Goodbye cruel world!"
            end
            parser = StatemachineParser.new(nil,nil)

            scxml = <<EOS
<scxml initial="disconnected" name="Mouse" version="0.9" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=662.0 h=660.0  -->
 <state id="disconnected"><!--   node-size-and-position x=280.0 y=60.0 w=100.0 h=50.0  -->
  <transition event="connect" target="connected"></transition>
 </state>
 <parallel id="connected"><!--   node-size-and-position x=70.0 y=190.0 w=500.0 h=470.0  -->
  <onentry>
   <script>hello_world</script>
  </onentry>
   <onexit>
    <script>goodbye </script>
   </onexit>
  <transition event="disconnect" target="disconnected"><!--   edge-path [disconnected]  x=400.0 y=160.0  --></transition>
  <state id="leftbutton" initial="released"><!--   node-size-and-position x=40.0 y=50.0 w=210.0 h=210.0  -->
   <state id="released"><!--   node-size-and-position x=20.0 y=50.0 w=140.0 h=40.0  -->
    <transition event="press" target="pressed"><!--   edge-path [pressed]  x=60.0 y=110.0 pointx=0.0 pointy=-40.0 offsetx=0.0 offsety=-5.0  --></transition>
   </state>
   <state id="pressed"><!--   node-size-and-position x=30.0 y=140.0 w=120.0 h=40.0  -->
    <transition event="release" target="released"><!--   edge-path [released]  x=140.0 y=120.0  --></transition>
   </state>
  </state>
  <state id="pointer" initial="stopped"><!--   node-size-and-position x=270.0 y=50.0 w=210.0 h=210.0  -->
   <state id="stopped"><!--   node-size-and-position x=50.0 y=60.0 w=100.0 h=40.0  -->
    <transition event="move" target="moving"><!--   edge-path [moving]  x=140.0 y=120.0  --></transition>
   </state>
   <state id="moving"><!--   node-size-and-position x=30.0 y=150.0 w=100.0 h=40.0  -->
    <transition event="stop" target="stopped"><!--   edge-path [stopped]  x=50.0 y=130.0 pointx=0.0 pointy=2.0 offsetx=-15.0 offsety=-2.0  --></transition>
   </state>
  </state>
 </parallel>
</scxml>
EOS

            @sm = parser.build_from_scxml_string scxml
            @sm.reset
            @sm.context = self
          end

          it "should support on entry for parallel states" do
            @sm.connect
            @log.should=="Hello world!"
          end

          it "should support on exit for parallel states" do
            @sm.connect
            @sm.disconnect
            @log.should=="Goodbye cruel world!"
          end


        end
      end
    end

    describe "with spontaneous transitions to parallel states" do
      it "should enter using spontaneous transitions " do

        class ActivationCallback
          attr_reader :called
          attr_reader :new_states
          attr_reader :abstract_states
          attr_reader :atomic_states

          def initialize
            @called = []
            @new_states = []
            @abstract_states = []
            @atomic_states =[]

          end
          def activate(new_states,abstract_states, atomic_states)
            @called << true
            @new_states<<  new_states
            @abstract_states << abstract_states
            @atomic_states <<  atomic_states
            puts "activate #{@new_states.last} #{@abstract_states.last} #{@atomic_states.last}"
          end
        end

        @callback = ActivationCallback.new


        def isInstant?
          true
        end

        def isContinuous?
          false
        end

        def isOnChange?
          false
        end

        def evaluate
          true
        end
        parser = StatemachineParser.new(nil,nil)

        scxml = <<EOS
<scxml initial="inactive" name="StateObservation" version="0.9" xmlns="http://www.w3.org/2005/07/scxml"><!--   node-size-and-position x=0.0 y=0.0 w=868.0 h=725.0  -->
  <state id="inactive"><!--   node-size-and-position x=180.0 y=40.0 w=80.0 h=50.0  -->
    <transition event="start" target="active"><!--   edge-path [active]  x=170.0 y=120.0 pointx=0.0 pointy=-29.0 offsetx=-12.0 offsety=14.0  --></transition>
  </state>
  <state id="active" initial="init"><!--   node-size-and-position x=160.0 y=140.0 w=610.0 h=450.0  -->
    <transition event="stop" target="inactive"></transition>
    <state id="init"><!--   node-size-and-position x=20.0 y=30.0 w=60.0 h=40.0  -->
      <transition cond="isInstant? or isContinuous?" target="instant_evaluation">
        <script>evaluate</script>
      </transition>
      <transition cond="isOnChange?" target="subscribing"></transition>
    </state>
    <state id="instant_evaluation"><!--   node-size-and-position x=180.0 y=30.0 w=130.0 h=40.0  -->
      <transition cond="(not @result.nil?) and @result.length&gt;0" target="true">
        <invoke src="@varmap.merge! @result" type="x-mint"></invoke>
      </transition>
      <transition cond="@result.nil?" target="false"></transition>
    </state>
    <parallel id="running"><!--   node-size-and-position x=40.0 y=130.0 w=480.0 h=300.0  -->
      <state id="result" initial="false"><!--   node-size-and-position x=200.0 y=60.0 w=270.0 h=90.0  -->
        <state id="true"><!--   node-size-and-position x=170.0 y=40.0 w=50.0 h=30.0  -->
          <transition event="false" target="false"></transition>
        </state>
        <state id="false"><!--   node-size-and-position x=10.0 y=40.0 w=80.0 h=30.0  -->
          <transition event="true" target="true"><!--   edge-path [true]  x=130.0 y=40.0 pointx=0.0 pointy=14.0 offsetx=17.0 offsety=4.0  --></transition>
        </state>
      </state>
      <state id="subscription" initial="check"><!--   node-size-and-position x=30.0 y=40.0 w=150.0 h=250.0  -->
        <state id="subscribing"><!--   node-size-and-position x=40.0 y=110.0 w=80.0 h=40.0  -->
          <onentry>@subscribed=true</onentry>
          <transition event="subscribed" target="subscribed"></transition>
        </state>
        <state id="subscribed"><!--   node-size-and-position x=40.0 y=190.0 w=80.0 h=40.0  --></state>
        <state id="check"><!--   node-size-and-position x=40.0 y=30.0 w=80.0 h=40.0  -->
          <transition cond="isOnChange? or isContinuous?" target="subscribing"></transition>
        </state>
      </state>
    </parallel>
  </state>
</scxml>
EOS

        @sm = parser.build_from_scxml_string scxml
        @sm.reset
        @sm.activation=@callback.method(:activate)
        @sm.context = self
        @sm.start

        @callback.called.length.should == 3

        @callback.new_states[0].should == [:active,:init]
        @callback.new_states[1].should == [:instant_evaluation]
        @callback.new_states[2].should == [:running, :result, :subscription, :false, :check]
      end
    end
  end
end
