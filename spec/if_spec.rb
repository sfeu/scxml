require File.dirname(__FILE__) + '/spec_helper'

describe 'The StatemachineParser for' do
  describe 'states' do
    begin
      describe 'with if/else' do
        before (:each) do
          @messenger = mock("messenger" )

          parser = StatemachineParser.new(nil,@messenger)

          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2">
        <if cond="1 > 2">
          <log expr="should have failed"/>
        <else/>
          <log expr="should have worked"/>
        </if>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state1"/>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
        end

        it "should support logging inside a transition" do
          @messenger.should_receive(:puts).with("should have worked" )
          @sm.event1
        end
      end

      describe 'with if/elseif/else' do
        before (:each) do
          @messenger = mock("messenger" )

          parser = StatemachineParser.new(nil,@messenger)

          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2">
        <if cond="1 > 2">
          <log expr="should have failed"/>
        <elseif cond="1 < 2"/>
          <log expr="should have worked"/>
        <else/>
          <log expr="should not have entered"/>
        </if>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state1"/>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
        end

        it "should support logging inside a transition" do
          @messenger.should_receive(:puts).with("should have worked" )
          @sm.event1
        end
      end

      describe 'with nested ifs' do
        before (:each) do
          @messenger = mock("messenger" )

          parser = StatemachineParser.new(nil,@messenger)

          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2">
        <if cond="1 <= 2">
          <if cond="1 == 2">
             <log expr="should have failed"/>
          <else/>
             <log expr="should have worked"/>
          </if>
        <elseif cond="1 > 2"/>
          <log expr="should not have entered"/>
        <else/>
          <log expr="should not have entered"/>
        </if>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state1"/>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
        end

        it "should support logging inside a transition" do
          @messenger.should_receive(:puts).with("should have worked" )
          @sm.event1
        end
      end

      describe 'with multiple nested ifs' do
        before (:each) do
          @messenger = mock("messenger" )

          parser = StatemachineParser.new(nil,@messenger)

          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2">
        <if cond="10 < 20">
          <if cond="10 == 20">
             <log expr="should have failed"/>
          <elseif cond="10 <= 15"/>
            <if cond="10 < 15">
              <log expr="should have worked"/>
            </if>
          <else/>
             <log expr="should not have entered"/>
          </if>
        <elseif cond="10 > 20"/>
          <log expr="should not have entered"/>
        <else/>
          <log expr="should not have entered"/>
        </if>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state1"/>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
        end

        it "should support logging inside a transition" do
          @messenger.should_receive(:puts).with("should have worked" )
          @sm.event1
        end
      end
      describe 'with multiple nested ifs' do
        before (:each) do
          @messenger = mock("messenger" )

          parser = StatemachineParser.new(nil,@messenger)

          scxml = <<EOS
<scxml id="SCXML" xmlns="http://www.w3.org/2005/07/scxml">
  <state id="state1">
     <transition event="event1" target="state2">
        <if cond="10 < 20">
          <if cond="10 == 20">
             <log expr="should have failed"/>
          <elseif cond="10 <= 15"/>
            <if cond="10 < 15">
              <if cond="10 < 10">
                <log expr="should have failed"/>
              <else/>
                <log expr="should have worked"/>
              </if>
            </if>
          <else/>
             <log expr="should not have entered"/>
          </if>
        <elseif cond="10 > 20"/>
          <log expr="should not have entered"/>
        <else/>
          <log expr="should not have entered"/>
        </if>
     </transition>
  </state>

  <state id="state2">
     <transition event="event2" target="state1"/>
  </state>
</scxml>
EOS

          @sm = parser.build_from_scxml_string scxml
        end

        it "should support logging inside a transition" do
          @messenger.should_receive(:puts).with("should have worked" )
          @sm.event1
        end
      end
    end
  end
end

