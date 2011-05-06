

def add_checked_attribute(clazz, attribute, &validation) 
  clazz.class_eval do
    define_method "#{attribute}=" do |value|
       raise 'Invalid attribute' unless validation.call(value)
       instance_variable_set("@#{attribute}", value)
     end
     define_method attribute do 
       instance_variable_get "@#{attribute}"
     end 
  end
end
Object.const_set("Person", Class.new)
add_checked_attribute(Person, :age) {|v| v >= 18 }
@bob = Person.new
@bob.age = 20
p @bob.age