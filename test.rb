# class Fruit
#   attr_accessor :kind
#   attr_reader :abc
#   attr_writer :bca
#    def initialize(a,b)
#      @kind = a
#      @abc = b
#      @bca = 24
#    end
#    
#    def get_abc=(k)
#      @abc = k
#    end
#    
#    def show_bca
#      @bca
#    end
#    
#    
#  end
#  
#  class Mango < Fruit
#    def show_bca(s)
#     @abc = 3678
#    end
#  end
#  
#  @f = Mango.new(10,40)
#  @f.kind = 10
#  @f.get_abc = 25
#  @f.bca = 34
#  puts "#{@f.kind}     #{@f.abc}        #{@f.show_bca}"


# class ClassAccess  
#   def m1
#     puts 10
#               # this method is public  
#   end  
#   protected  
#     def m2
#       puts 20        # this method is protected  
#     end  
#   private  
#     def m3
#      puts 40        # this method is private  
#     end  
# end
# 
# class SubClass < ClassAccess
#   def show_acesss
#     m1
#     m2
#     m3
#   end
# end  
# ca = SubClass.new  
# ca.show_acesss
# ca.m1
# ca.m2
# ca.m3
# 
# class Person  
#   def initialize(age)  
#     @age = age  
#   end  
#   def age  
#     @age  
#   end  
#   def compare_age(c)  
#     if c.age > age  
#       "The other object's age is bigger."  
#     else  
#       "The other object's age is the same or smaller."  
#     end  
#   end  
#   protected :age  
# end  
#   
# chris = Person.new(25)  
# marcos = Person.new(34)  
# puts chris.compare_age(marcos)  
# puts chris.age


# module Humor
#   def tickle
#     "hee, hee!"
#   end
# end
# 
# class Abc
#   include Humor
# end
# a = Abc.new
# # Abc.extend Humor
# a.extend Humor
# puts a.tickle


# Customer = Struct.new( "Customer", :name, :address, :zip )
# joe = Customer.new( "Joe Smith", "123 Maple, Anytown NC", 12345 )
# puts joe.inspect
# joe.each {|x| puts(x) }

# module MyModule
#   def my_method; 'hello'; end
# end
# 
# class MyClass
#   # class << self
#     # include MyModule
#   # end  
# end
# obj = MyClass.new
# obj1 = MyClass.new
# class << obj
#   include MyModule
# end
# p obj.my_method
# p obj1.my_method
# 
# 
# 

# module MyModule
#   def my_method; "hello #{self.abc}"; end
# end
# 
# class MyClass
#   # class << self
#     # include MyModule
#   # end 
#   def abc
#     "instance abc"
#   end
#   
#   def self.abc
#     "class abc"
#   end 
# end
# obj = MyClass.new
# obj1 = MyClass.new
# # class << obj
# #   include MyModule
# # end
# MyClass.extend MyModule
# obj.extend MyModule
# p obj.my_method
# p MyClass.my_method
# p obj1.my_method


# class String
#   
#   def length 
#     real_length > 5 ? 'long' : 'short'
#   end
#   alias :real_length :length 
# end
# p "War and Peace".length  # => "long" 
# p "War and Peace".real_length # => 13
# 
# 
# module M
#   
#     def self.b
#       "this is a class methode"
#     end
#   
#     def a
#       "this is a instance methode"
#     end
#   
# end
#  
# class MyClass
#    extend M
#    include M
# end
# obj = MyClass.new
#  p obj.a
# p MyClass.a
# 
#  p obj.b
# p MyClass.b
#   

module Mod
  def one
    "This is one"
  end
  module_function :one
end
class Cls
  include Mod
  def callOne
    one
  end
end
Mod.one     #=> "This is one"
c = Cls.new
puts c.callOne   #=> "This is one"
module Mod
  def one
    "This is the new one"
  end
end
puts Mod.one     #=> "This is one"
puts c.callOne   #=> "This is the new one"