require 'set'

module MethodInterceptors

  def pre(&condicion)
    self.instance_variable_set(:@precondicion,condicion)
  end

  def post(&condicion)
    self.instance_variable_set(:@postcondicion,condicion)
  end

  def invariant(&condicion)
    eval_condicion_before = proc do |instancia|
      @@invariant=true
      raise "It does not satisfy invariants" unless instancia.instance_eval(&condicion)
    end
    eval_condicion_after = proc do |instancia|
      @@invariant=false
      raise "It does not satisfy invariants" unless instancia.instance_eval(&condicion)
    end
    before_and_after_each_call(eval_condicion_before, eval_condicion_after)
  end

  def before_and_after_each_call(before, after)
    define_list_if_not_defined(:@before_list)
    define_list_if_not_defined(:@after_list)
    define_intercepted_classes
    self.instance_variable_get(:@before_list) << before
    self.instance_variable_get(:@after_list) << after
    @@intercepted_classes << self
  end

  def llamar_before_procs(instancia)
    self.instance_variable_get(:@before_list).each { |bloque| instancia.instance_exec(instancia,&bloque) }
  end

  def llamar_after_procs(instancia)
    self.instance_variable_get(:@after_list).each { |bloque| instancia.instance_exec(instancia,&bloque) }
  end

  def diferent_of_initialize(method_name)
    method_name != :initialize
  end

  # Devuelve si una lista de parámetros tiene algún valor
  def has_any_parameter?(parametros)
    !parametros.nil? and !parametros.empty?
  end

  def last_parameter_is_a_block(parametros)
    "block".to_sym.eql? get_last_parameter(parametros)
  end

  def method_added(method_name)
    @@recursing = true
    @@invariant ||= false
    define_already_intercepted_methods
    define_intercepted_classes
    if diferent_of_method_added(method_name) &&
        not_intercepted(method_name) && has_requested_before_and_after
      @already_intercepted_methods << method_name
      unbound_method = self.instance_method(method_name)
      los_parametros = unbound_method.parameters
      define_method_with_parameters(method_name, unbound_method)
    else
      super(method_name)
    end
  end

  private

  def define_method_with_parameters(method_name, unbound_method)
    define_method method_name do |*parametros|
      if (@@recursing)
        if self.class.diferent_of_initialize(method_name) and !@@invariant
          begin
            self.class.llamar_before_procs(self)
          rescue RuntimeError => re
            @@recursing = true
            raise re
          end
          @@recursing = false
          @@invariant = false
        end
        #TODO habría que agarrar la precondicion y si existe, ejecutarla
        if self.class.has_any_parameter?(unbound_method.parameters) &&
            self.class.last_parameter_is_a_block(unbound_method.parameters)
          block = parametros.delete(parametros.last)
          retorno = unbound_method.bind(self).call(*parametros, &block)
        elsif
          retorno = unbound_method.bind(self).call(*parametros)
        end
        #TODO habría que agarrar la postcondicion y si existe, ejecutarla con el retorno
        @@recursing = true
        begin
          self.class.llamar_after_procs(self) unless @@invariant
        rescue RuntimeError => re
          @@invariant = false
          raise re
        end
        @@invariant = false
        retorno
      end
    end
  end

  def diferent_of_method_added(method_name)
    method_name != :method_added
  end

  def get_last_parameter(parametros)
    parametros.last.first
  end

  def not_intercepted(method_name)
    !@already_intercepted_methods.include?(method_name)
  end

  def define_already_intercepted_methods
    is_not_defined = (defined? @already_intercepted_methods).nil?

    if is_not_defined
      @already_intercepted_methods = Set[]
    end
  end

  def define_intercepted_classes
    is_not_defined = (defined? @@intercepted_classes).nil?

    if is_not_defined
      @@intercepted_classes = Set[]
    end
  end

  def define_list_if_not_defined(sym_list)
    is_not_defined = self.instance_variable_get(sym_list).nil?

    if is_not_defined
      self.instance_variable_set(sym_list,[])
    end
  end

  def has_requested_before_and_after
    @@intercepted_classes.include?(self)
  end
end

class Class
  include MethodInterceptors
end