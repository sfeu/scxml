require File.dirname(__FILE__) + '/../spec_helper'

describe 'ATM' do
  before (:each) do

    @atm = Statemachine.build do
      startstate :ocioso
      superstate :operando do
        state :esperando_senha do
          event :senha, :senha_inserida
          on_entry Proc.new{puts "Digite a senha"}
        end
        state :senha_inserida do
          event :senha_errada, :esperando_senha, Proc.new {puts "Senha incorreta.";true}
          event :senha_correta, :esperando_opcao
          on_entry :verifica_senha
        end
        state :esperando_opcao do
          event :opcao, :opcao_escolhida
          on_entry Proc.new{puts "Digite a sua escolha"}
        end
        state :opcao_escolhida do
          event :saldo, :exibindo_saldo
          event :saque, :emitindo_quantia
          event :invalida, :esperando_opcao
          on_entry :verifica_escolha
        end
        state :exibindo_saldo do
          event :nova_opcao, :esperando_opcao
          on_entry :saldo

        end
        state :emitindo_quantia do
          event :nova_opcao, :esperando_opcao
          on_entry :emitindo
        end

        event :cancelar, :ocioso, Proc.new {puts "Saindo...";true}
      end

      state :ocioso do
        event :cartao, :esperando_senha
        event :cancelar, :ocioso
      end
      stub_context :verbose => true # this is an nternal  verbose stub context from statemachine that prints out action invocations.
    end

    # uncomment the next line to start testing your code
    # @atm = Statemachine.build_from_scxml "testmachines/atm_enhanced.xml"
  end

  it "should start with the correct state >ocioso<" do
   @atm.state.should equal(:ocioso)
  end

  it "should support transitions" do
    @atm.cartao
    @atm.state.should==:esperando_senha
    @atm.senha
    @atm.state.should==:senha_inserida
    @atm.senha_errada
    @atm.state.should==:esperando_senha
    @atm.senha
    @atm.senha_correta
    @atm.opcao
    @atm.state.should==:opcao_escolhida
  end
end

