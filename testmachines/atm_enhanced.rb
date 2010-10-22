# -*- coding: raw-text -*-
require 'rubygems'
require 'statemachine'

module Statemachine
  module SuperstateBuilding

    def state(id, &block)
      builder = StateBuilder.new(id, @subject, @statemachine)
      builder.instance_eval(&block) if block
      p "id>> #{id}"
    end
  end
  
end

class AtmContext
	
	attr_accessor :statemachine
	
	def initialize
		@conta = 100000
		@senha = "0000"
	end

	def verifica_senha(senha)
		if senha == @senha
			@statemachine.senha_correta
		else
			@statemachine.senha_errada
		end
	end
	
	def verifica_escolha(escolha)
		case escolha.downcase
		when "saldo": 	 @statemachine.saldo
		when "saque":	 puts "Entre com a quantia a ser sacada: "
						 @statemachine.saque(gets.chomp!)
		when "cancelar": @statemachine.cancelar
		else 			 @statemachine.invalida
		end
	end
	
	def emitindo(quantia)
		if (Integer(quantia) <= @conta)
			puts "Emitindo: R$#{quantia}"
			@conta -= Integer(quantia)
		else
			puts "Saldo insuficiente"
		end
		nova_operacao
	end
	
	def saldo
		puts "Seu saldo: R$#{@conta}"
		nova_operacao
	end
	
	def nova_operacao
		puts "Deseja realizar outra operacao? (S/N)"
		decisao = gets.chomp!
		if decisao.downcase == "s"
			@statemachine.nova_opcao
		else
			@statemachine.cancelar
		end
	end
end

if __FILE__ == $0 

	atm = Statemachine.build do
		startstate :ocioso
		superstate :operando do
			state :esperando_senha do
				event :senha, :senha_inserida
				on_entry Proc.new{puts "Digite a senha"}
			end
			state :senha_inserida do
				event :senha_errada, :esperando_senha, Proc.new {puts "Senha incorreta."} 
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
			
			event :cancelar, :ocioso, Proc.new {puts "Saindo..."}
		end
		
		state :ocioso do
			event :cartao, :esperando_senha
			event :cancelar, :ocioso
		end
		
		context AtmContext.new
	end

	atm.context.statemachine = atm
	atm.cartao
	# Continua perguntando a senha até acertar
	begin 
		atm.senha(gets.chomp!)
	end until atm.state != :esperando_senha
	
	# Continua perguntando até acertar
	begin 
		atm.opcao(gets.chomp!)
	end until atm.state != :esperando_opcao
	atm.cancelar
end

		
