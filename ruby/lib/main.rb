require_relative '../lib/main_helper'

class Cat
  before_and_after_each_call(proc { puts 'before' }, proc { puts 'after' })
  before_and_after_each_call(proc { puts 'before2' }, proc { puts 'after2' })

  def hello_world
    puts "Hello"
  end

  def hello_world_con_nombre(name)
    puts "Hello #{name}"
  end

  def hello_world_con_nombre_y_bloque(name, &bloque)
    puts "Hello #{name}"
    bloque.call
    "Done"
  end
end

class Cat
  def maullar_con_delay()
    "Miau, a mi me agregaron despues"
  end
end

class Dog
  before_and_after_each_call(proc { puts 'Another before' }, proc { puts 'Another after' })
  def say_guau
    "Guau!"
  end
end

class Estudiante

  attr_accessor :anotadas, :aprobadas
  invariant { anotadas > 3 } #Para ser alumno regular
  invariant { aprobadas > 15 && aprobadas < 43 } #La cantidad de materias de Ing. en Sistemas

  def initialize
    @aprobadas = 42
    @anotadas = 4
  end

  def aprobar
    @aprobadas =@aprobadas+1
    puts "Aprobe una materia"
  end
end

class Guerrero
  attr_accessor :vida , :fuerza
  invariant { vida >= 0 }
  invariant { fuerza > 0 && fuerza < 100 }
  invariant do
    another=Guerrero.new
    another.vida=5
    mi_fuerza=atacar(another)
    mi_fuerza > 0 && mi_fuerza < 100
  end
  def atacar(otro)
    otro.vida -= fuerza
    puts "la vida del otro es #{otro.vida}"
    fuerza
  end
end

class Operaciones
  #precondición de dividir
  pre { divisor != 0 }
  #postcondición de dividir
  post { |result| result * divisor == dividendo }
  def dividir(dividendo, divisor)
    dividendo / divisor
  end
  # este método no se ve afectado por ninguna pre/post condición
  def restar(minuendo, sustraendo)
    minuendo - sustraendo
  end
end




