NEW ACTIONMAILER API IN RAILS 3.0
Tue Jan 26 12:13:00 -0800 2010
Action Mailer has long been the black sheep of the Rails family. Somehow, through many arguments, you get it doing exactly what you want. But it takes work! Well, we just fixed that.
Action Mailer now has a new API.
But why? Well, I had an itch to scratch, I am the maintainer for TMail, but found it very hard to use well, so I sat down and wrote a really Ruby Mail library, called, imaginatively enough, Mail
But Action Mailer was still using TMail, so then I replaced out TMail with Mail in Action Mailer
And now, with all the flexibility that Mail gives us, we all thought it would be a good idea to re-write the Action Mailer DSL. So with a lot of ideas thrown about between David, Yehuda and myself, we came up with a great DSL.
I then grabbed José Valim to pair program together (with him in Poland to me in Sydney!) on ripping out the guts of Action Mailer and replacing it with a lean, mean mailing machine.
This was merged today.
So what does this all mean? Well, code speaks louder than words, so:
Creating Email Messages:
Instead of this:
 class Notifier < ActionMailer::Base
   def signup_notification(recipient)
     recipients      recipient.email_address_with_name
     subject         "New account information"
     from            "system@example.com"
     content_type    "multipart/alternative"
     body            :account => recipient

     part :content_type => "text/html",
       :data => render_message("signup-as-html")

     part "text/plain" do |p|
       p.body = render_message("signup-as-plain")
       p.content_transfer_encoding = "base64"
     end
     
     attachment "application/pdf" do |a|
       a.body = generate_your_pdf_here()
     end

     attachment :content_type => "image/jpeg",
       :body => File.read("an-image.jpg")
     
   end
 end
You can do this:
class Notifier < ActionMailer::Base
  default :from => "system@example.com"
  
  def signup_notification(recipient)
    @account = recipient

    attachments['an-image.jp'] = File.read("an-image.jpg")
    attachments['terms.pdf'] = {:content => generate_your_pdf_here() }

    mail(:to => recipient.email_address_with_name,
         :subject => "New account information")
  end
end
Which I like a lot more :)
Any instance variables you define in the method become available in the email templates, just like it does with Action Controller, so all of the templates will have access to the @account instance var which has the recipient in it.
The mail method above also accepts a block so that you can do something like this:
def hello_email
  mail(:to => recipient.email_address_with_name) do |format|
    format.text { render :text => "This is text!" }
    format.html { render :text => "<h1>This is HTML</h1>" }
  end
end
In the same style that a respond_to block works in Action Controller.
Sending Email Messages:
Additionally, sending messages has been simplified as well. A Mail::Message object knows how to deliver itself, so all of the delivery code in Action Mailer was simply removed and responsibility given to the Mail::Message.
Instead of having magic methods called deliver_* and create_* we just call the method which returns a Mail::Message object, and you just call deliver on that:
So this:
Notifier.deliver_signup_notification(recipient)
Becomes this:
Notifier.signup_notification(recipient).deliver
And this:
message = Notifier.create_signup_notification(recipient)
Notifier.deliver(message)
Becomes this:
message = Notifier.signup_notification(recipient)
message.deliver
You still have access to all the usual types of delivery agents though, :smtp, :sendmail, :file and :test, these all work as they did with the prior version of ActionMailer.
Receiving Emails
This has not changed, except now you get a Mail::Message object instead of a TMail object.
Mail::Message will be getting a :reply method soon which will automatically map the Reply related fields properly. Once this is done, we will re-vamp receiving emails as well to simplify.



validates :rails_3, :awesome => true
Sun Jan 31 12:17:00 -0800 2010
The new validation methods in Rails 3.0 have been extracted out to Active Model, but in the process have been sprinkled with DRY goodness…
As you would know from Yehuda’s post on Active Model abstraction, in Rails 3.0, Active Record now mixes in many aspects of Active Model, including the validates modules.
Before we get started though, your old friends still exist:
validates_acceptance_of
validates_associated
validates_confirmation_of
validates_each
validates_exclusion_of
validates_format_of
validates_inclusion_of
validates_length_of
validates_numericality_of
validates_presence_of
validates_size_of
validates_uniqueness_of
Are still around and not going anywhere, but Rails version 3 offers you some cool, nay, awesome alternatives:
Introducing the validates method
The Validates method accepts an attribute, followed by a hash of validation options.
Which means you can type something like:
class Person < ActiveRecord::Base
  validates :email, :presence => true
end
The options you can pass in to validates are:
:acceptance => Boolean
:confirmation => Boolean
:exclusion => { :in => Ennumerable }
:inclusion => { :in => Ennumerable }
:format => { :with => Regexp }
:length => { :minimum => Fixnum, maximum => Fixnum, }
:numericality => Boolean
:presence => Boolean
:uniqueness => Boolean
Which gives you a huge range of easily usable, succinct options for your attributes and allows you to place your validations for each attribute in one place.
So for example, if you had to validate name and email, you might do something like this:
# app/models/person.rb
class User < ActiveRecord::Base
  validates :name,  :presence => true, 
                    :length => {:minimum => 1, :maximum => 254}
                   
  validates :email, :presence => true, 
                    :length => {:minimum => 3, :maximum => 254},
                    :uniqueness => true,
                    :format => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i}
  
end
This allows us to be able to look at a model and easily see the validations in one spot for each attribute, win for code readability!
Extracting Common Use Cases
However, the :format => {:with => EmailRegexp} is a bit of a drag to retype everywhere, and definitely fits the idea of a reusable validation that we might want to use in other models.
And what if you wanted to use a really impressive Regular Expression that takes more than a few characters to type to show that you know how to Google?
Well, validations can also except a custom validation.
To use this, we first make an email_validator.rb file in Rails.root’s lib directory:
# lib/email_validator.rb
class EmailValidator < ActiveModel::EachValidator

  EmailAddress = begin
    qtext = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
    dtext = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
    atom = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' +
      '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
    quoted_pair = '\\x5c[\\x00-\\x7f]'
    domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
    quoted_string = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
    domain_ref = atom
    sub_domain = "(?:#{domain_ref}|#{domain_literal})"
    word = "(?:#{atom}|#{quoted_string})"
    domain = "#{sub_domain}(?:\\x2e#{sub_domain})*"
    local_part = "#{word}(?:\\x2e#{word})*"
    addr_spec = "#{local_part}\\x40#{domain}"
    pattern = /\A#{addr_spec}\z/
  end

  def validate_each(record, attribute, value)
    unless value =~ EmailAddress
      record.errors[attribute] << (options[:message] || "is not valid") 
    end
  end
  
end
As each file in the lib directory gets loaded automatically by Rails, and as our class inherits from ActiveModel::EachValidator the class name is used to create a dynamic validator that you can then use in any object that makes use of the ActiveModel::Validations mix in, such as Active Record objects.
The name of the dynamic validation option is based on whatever is to the left of “Validator” down-cased and underscorized.
So now in our User class we can simply change it to:
# app/models/person.rb
class User < ActiveRecord::Base
  validates :name,  :presence => true, 
                    :length => {:minimum => 1, :maximum => 254}
                   
  validates :email, :presence => true, 
                    :length => {:minimum => 3, :maximum => 254},
                    :uniqueness => true,
                    :email => true
  
end
Notice the :email => true call? This is much cleaner and simple, and more importantly, reusable.
Now in our console, we will see something like:
 $ ./script/console 
Loading development environment (Rails 3.0.pre)
?> u = User.new(:name => 'Mikel', :email => 'bob')
=> #<User id: nil, name: "Mikel", email: "bob", created_at: nil, updated_at: nil>
>> u.valid?
=> false
>> u.errors
=> #<OrderedHash {:email=>["is not valid"]}>
With our custom error message “is not valid” showing up in the email.
Class Wide Validations
But what if you had, say, three different models, users, visitors and customers, all of which shared some common validations, but were different enough that you had to separate them out?
Well, you could use another custom validator, but pass it to your models as a validates_with call:
# app/models/person.rb
class User < ActiveRecord::Base
  validates_with HumanValidator
end

# app/models/person.rb
class Visitor < ActiveRecord::Base
  validates_with HumanValidator
end

# app/models/person.rb
class Customer < ActiveRecord::Base
  validates_with HumanValidator
end
You could then make a file in your lib directory like so:
class HumanValidator < ActiveModel::Validator

  def validate(record)
    record.errors[:base] << "This person is dead" unless check(human)
  end

  private

    def check(record)
      (record.age < 200) && (record.age > 0)
    end
  
end
Which is an obviously contrived example, but would produce this result in our console:
$ ./script/console 
Loading development environment (Rails 3.0.pre)
>> u = User.new
=> #<User id: nil, name: nil, email: nil, created_at: nil, updated_at: nil>
>> u.valid?
=> false
>> u.errors
=> #<OrderedHash {:base=>["This person is dead"]}>
Trigger times
As you would expect, any validates method can have the following sub options added to them:
:on
:if
:unless
:allow_blank
:allow_nil
Each of these can take a call to a method on the record itself. So we could have:
class Person < ActiveRecord::Base
  
  validates :post_code, :presence => true, :unless => :no_postcodes?

  def no_postcodes?
    ['TW'].include?(country_iso)
  end
  
end




ActiveModel: Make Any Ruby Object Feel Like ActiveRecord
January 10th, 2010

Rails 2.3 has a ton of really nice functionality locked up in monolithic components. I’ve posted quite a bit about how we’ve opened up a lot of that functionality in ActionPack, making it easier to reuse the router, dispatcher, and individual parts of ActionController. ActiveModel is another way we’ve exposed useful functionality to you in Rails 3.

Before I Begin, The ActiveModel API
Before I begin, there are two major elements to ActiveModel. The first is the ActiveModel API, the interface that models must adhere to in order to gain compatibility with ActionPack’s helpers. I’ll be talking more about that soon, but for now, the important thing about the ActiveModel API is that your models can become ActiveModel compliant without using a single line of Rails code.

In order to help you ensure that your models are compliant, ActiveModel comes with a module called ActiveModel::Lint that you can include into your test cases to test compliance with the API:

class LintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests
 
  class CompliantModel
    extend ActiveModel::Naming
 
    def to_model
      self
    end
 
    def valid?()      true end
    def new_record?() true end
    def destroyed?()  true end
 
    def errors
      obj = Object.new
      def obj.[](key)         [] end
      def obj.full_messages() [] end
      obj
    end
  end
 
  def setup
    @model = CompliantModel.new
  end
end
The ActiveModel::Lint::Tests provide a series of tests that are run against the @model, testing for compliance.

ActiveModel Modules
The second interesting part of ActiveModel is a series of modules provided by ActiveModel that you can use to implement common model functionality on your own Ruby objects. These modules were extracted from ActiveRecord, and are now included in ActiveRecord.

Because we’re dogfooding these modules, you can be assured that APIs you bring in to your models will remain consistent with ActiveRecord, and that they’ll continue to be maintained in future releases of Rails.

The ActiveModel comes with internationalization baked in, providing an avenue for much better community sharing around translating error messages and the like.

The Validations System
This was perhaps the most frustrating coupling in ActiveRecord, because it meant that people writing libraries for, say, CouchDB had to choose between painstakingly copying the API over, allowing inconsistencies to creep in, or just inventing a whole new API.

Validations have a few different elements.

First, declaring the validations themselves. You’ve seen the usage before in ActiveRecord:

class Person < ActiveRecord::Base
  validates_presence_of :first_name, :last_name
end
To do the same thing for a plain old Ruby object, simply do the following:

class Person
  include ActiveModel::Validations
 
  validates_presence_of :first_name, :last_name
 
  attr_accessor :first_name, :last_name
  def initialize(first_name, last_name)
    @first_name, @last_name = first_name, last_name
  end
end
The validations system calls read_attribute_for_validation to get the attribute, but by default, it aliases that method to send, which supports the standard Ruby attribute system of attr_accessor.

To use a more custom attribute lookup, you can do:

class Person
  include ActiveModel::Validations
 
  validates_presence_of :first_name, :last_name
 
  def initialize(attributes = {})
    @attributes = attributes
  end
 
  def read_attribute_for_validation(key)
    @attributes[key]
  end
end
Let’s look at what a validator actually is. First of all, the validates_presence_of method:

def validates_presence_of(*attr_names)
  validates_with PresenceValidator, _merge_attributes(attr_names)
end
You can see that validates_presence_of is using the more primitive validates_with, passing it the validator class, merging in {:attributes => attribute_names} into the options passed to the validator. Next, the validator itself:

class PresenceValidator < EachValidator
  def validate(record)
    record.errors.add_on_blank(attributes, options[:message])
  end
end
The EachValidator that it inherits from validates each attribute with the validate method. In this case, it adds the error message to the record, only if the attribute is blank.

The add_on_blank method does add(attribute, :blank, :default => custom_message) if value.blank? (among other things), which is adding the localized :blank message to the object. If you take a look at the built-in locale/en.yml looks like:

en:
  errors:
    # The default format use in full error messages.
    format: "{{attribute}} {{message}}"
 
    # The values :model, :attribute and :value are always available for interpolation
    # The value :count is available when applicable. Can be used for pluralization.
    messages:
      inclusion: "is not included in the list"
      exclusion: "is reserved"
      invalid: "is invalid"
      confirmation: "doesn't match confirmation"
      accepted: "must be accepted"
      empty: "can't be empty"
      blank: "can't be blank"
      too_long: "is too long (maximum is {{count}} characters)"
      too_short: "is too short (minimum is {{count}} characters)"
      wrong_length: "is the wrong length (should be {{count}} characters)"
      not_a_number: "is not a number"
      greater_than: "must be greater than {{count}}"
      greater_than_or_equal_to: "must be greater than or equal to {{count}}"
      equal_to: "must be equal to {{count}}"
      less_than: "must be less than {{count}}"
      less_than_or_equal_to: "must be less than or equal to {{count}}"
      odd: "must be odd"
      even: "must be even"
As a result, the error message will read first_name can't be blank.

The Error object is also a part of ActiveModel.

Serialization
ActiveRecord also comes with default serialization for JSON and XML, allowing you to do things like: @person.to_json(:except => :comment).

The main important part of the serialization support is adding general support for specifying the attributes to include across all serializers. That means that you can do @person.to_xml(:except => :comment) as well.

To add serialization support to your own model, you will need to include the serialization module and implement attributes. Check it out:

class Person
  include ActiveModel::Serialization
 
  attr_accessor :attributes
  def initialize(attributes)
    @attributes = attributes
  end
end
 
p = Person.new(:first_name => "Yukihiro", :last_name => "Matsumoto")
p.to_json #=> %|{"first_name": "Yukihiro", "last_name": "Matsumoto"}|
p.to_json(:only => :first_name) #=> %|{"first_name": "Yukihiro"}|
You can also pass in a :methods option to specify methods to call for certain attributes that are determined dynamically.

Here's the Person model with validations and serialization:

class Person
  include ActiveModel::Validations
  include ActiveModel::Serialization
 
  validates_presence_of :first_name, :last_name
 
  attr_accessor :attributes
  def initialize(attributes = {})
    @attributes = attributes
  end
 
  def read_attribute_for_validation(key)
    @attributes[key]
  end
end
Others
Those are just two of the modules available in ActiveModel. Some others include:

AttributeMethods: Makes it easy to add attributes that are set like table_name :foo
Callbacks: ActiveRecord-style lifecycle callbacks.
Dirty: Support for dirty tracking
Naming: Default implementations of model.model_name, which are used by ActionPack (for instance, when you do render :partial => model
Observing: ActiveRecord-style observers
StateMachine: A simple state-machine implementation for models
Translation: The core translation support
This mostly reflects the first step of ActiveRecord extractions done by Josh Peek for his Google Summer of Code project last summer. Over time, I expect to see more extractions from ActiveRecord and more abstractions built up around ActiveModel.

I also expect to see a community building up around things like adding new validators, translations, serializers and more, especially now that they can be reused not only in ActiveRecord, but in MongoMapper, Cassandra Object, and other ORMs that leverage ActiveModel's built-in modules.


Active Record Query Interface 3.0
Published about 1 year ago
I’ve been working on revamping the Active Record query interface for the last few weeks ( while taking some time off in India from consulting work, before joining 37signals ), building on top of Emilio’s GSOC project of integrating ARel and ActiveRecord. So here’s an overview of how things are going to work in Rails 3.

What’s going to be deprecated in Rails 3.1 ?

These deprecations will be effective in Rails’ 3.1 release ( NOT Rails 3 ) and will be fully removed in Rails 3.2, though there will be an official plugin to continue supporting them. Consider this an advance warning as it involves changing a lot of code.

In short, passing options hash containing :conditions, :include, :joins, :limit, :offset, :order, :select, :readonly, :group, :having, :from, :lock to any of the ActiveRecord provided class methods, is now deprecated.

Going into details, currently ActiveRecord provides the following finder methods :

find(id_or_array_of_ids, options)
find(:first, options)
find(:all, options)
first(options)
all(options)
update_all(updates, conditions, options)
And the following calculation methods :

count(column, options)
average(column, options)
minimum(column, options)
maximum(column, options)
sum(column, options)
calculate(operation, column, options)
Starting with Rails 3, supplying any option to the methods above will be deprecated. Support for supplying options will be removed from Rails 3.2. Moreover, find(:first) and find(:all) ( without any options ) are also being deprecated in favour of first and all. A tiny little exception here is that count() will still accept a :distinct option.

The following shows a few example of the deprecated usages :

User.find(:all, :limit => 1)
User.find(:all)
User.find(:first)
User.first(:conditions => {:name => 'lifo'})
User.all(:joins => :items)
But the following is NOT deprecated :

User.find(1)
User.find(1,2,3)
User.find_by_name('lifo')
Additionally, supplying options hash to named_scope is also deprecated :

named_scope :red, :conditions => { :colour => 'red' }
named_scope :red, lambda {|colour| {:conditions => { :colour => colour }} }
Supplying options hash to with_scope, with_exclusive_scope and default_scope has also been deprecated :

with_scope(:find => {:conditions => {:name => 'lifo'}) { ... }
with_exclusive_scope(:find => {:limit =>1}) { ... }
default_scope :order => "id DESC"
Dynamic scoped_by_ are also going to be deprecated :

red_items = Item.scoped_by_colour('red')
red_old_items = Item.scoped_by_colour_and_age('red', 2)
New API

ActiveRecord in Rails 3 will have the following new finder methods.

where (:conditions)
having (:conditions)
select
group
order
limit
offset
joins
includes (:include)
lock
readonly
from
1 Value in the bracket ( if different ) indicates the previous equivalent finder option.

Chainability

All of the above methods returns a Relation. Conceptually, a relation is very similar to an anonymous named scope. All these methods are defined on the Relation object as well, making it possible to chain them.

lifo = User.where(:name => 'lifo')
new_users = User.order('users.id DESC').limit(20).includes(:items)
You could also apply more finders to the existing relations :

cars = Car.where(:colour => 'black')
rich_ppls_cars = cars.order('cars.price DESC').limit(10)
Quacks like a Model

A relation quacks just like a model when it comes to the primary CRUD methods. You could call any of the following methods on a relation :

new(attributes)
create(attributes)
create!(attributes)
find(id_or_array)
destroy(id_or_array)
destroy_all
delete(id_or_array)
delete_all
update(ids, updates)
update_all(updates)
exists?
So the following code examples work as expected :

red_items = Item.where(:colour => 'red')
red_items.find(1)
item = red_items.new
item.colour #=> 'red'

red_items.exists? #=> true
red_items.update_all :colour => 'black'
red_items.exists? #=> false
Note that calling any of the update or delete/destroy methods would reset the relation, i.e delete the cached records used for optimizing methods like relation.size.

Lazy Loading

As it might be clear from the examples above, relations are loaded lazily – i.e you call an enumerable method on them. This is very similar to how associations and named_scopes already work.

cars = Car.where(:colour => 'black') # No Query
cars.each {|c| puts c.name } # Fires "select * from cars where ..."
This is very useful along side fragment caching. So in your controller action, you could just do :

def index
  @recent_items = Item.limit(10).order('created_at DESC')
end
And in your view :

<% cache('recent_items') do %>
  <% @recent_items.each do |item| %>
    ...
  <% end %>
<% end %>
In the above example, recent_items</tt> are loaded on <tt>recent_items.each call from the view. As the controller doesn’t actually fire any query, fragment caching becomes more effective without requiring any special work arounds.

Force loading – all, first & last

For the times you don’t need lazy loading, you could just call all on the relation :

cars = Car.where(:colour => 'black').all
It’s important to note that all returns an Array and not a Relation_. This is similar to how things work in Rails 2.3 with namedscopes and associations.

Similarly, first and last will always return an ActiveRecord object ( or nil ).

cars = Car.order('created_at ASC')
oldest_car = cars.first
newest_car = cars.last
named_scope → scopes

Using the method named_scope is deprecated in Rails 3.0. But the only change you’ll need to make is to remove the “named_” part. Supplying finder options hash will be deprecated in Rails 3.1.

named_scope have now been renamed to just scope.

So a definition like :

class Item
  named_scope :red, :conditions => { :colour => 'red' }
  named_scope :since, lambda {|time| {:conditions => ["created_at > ?", time] }}
end
Now becomes :

class Item
  scope :red, :conditions => { :colour => 'red' }
  scope :since, lambda {|time| {:conditions => ["created_at > ?", time] }}
end
However, as using options hash is going to be deprecated in 3.1, you should write it using the new finder methods :

class Item
  scope :red, where(:colour => 'red')
  scope :since, lambda {|time| where("created_at > ?", time) }
end
Internally, named scopes are built on top of Relation, making it very easy to mix and match them with the finder methods :
