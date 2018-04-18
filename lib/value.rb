# frozen_string_literal: true

# `Value` generates `Struct` classes with safer constructors. It is designed to
# provide a superset of the interface of the `Values` gem, with better
# performance, by subclassing actual native Structs.
#
# `Value` constructors require all mandatory arguments to be provided, and
# supply default values for all optional arguments. Additionally, the resulting
# instance is frozen. To obtain a mutable Value, `dup` the result.
#
# `Value` structure classes are created similarly to `Struct`s, with the
# addition that optional arguments are may be specified as keyword arguments:
# `ValueType = Value.new(:a, :b, c: default_value)`. The default values to
# optional arguments are saved at class creation time and supplied as default
# constructor arguments to instances. Default values are aliased, so providing
# mutable defaults is discouraged.
#
# Two instance constructors are provided, with positional and keyword arguments.
#
# Value types may be constructed with positional arguments using `new`.
# Arguments are provided in the same order as specified at class initialization
# time, with mandatory arguments before optional ones.
# For example: `ValueType.new(1, 2)`, `ValueType.new(1, 2, 3)`
#
# Value types may be constructed with keyword arguments using `with`.
# For example: `ValueType.with(a: 1, b: 2, c: 3)`
class Value < Struct
  class << self
    def new(*required_args, **optional_args, &block)
      arguments = {}
      required_args.each { |arg| arguments[arg] = true }
      optional_args.each_key { |arg| arguments[arg] = false }
      validate_names(*arguments.keys)

      clazz = super(*arguments.keys)

      # define class and instance methods in modules so that the class can
      # override them
      keyword_constructor = generate_keyword_constructor(arguments)
      class_method_module = Module.new do
        module_eval(keyword_constructor)
        define_method(:__constructor_default) do |name|
          optional_args.fetch(name)
        end
      end
      clazz.extend(class_method_module)

      constructor = generate_constructor(arguments)
      instance_method_module = Module.new do
        module_eval(constructor)
      end
      clazz.include(instance_method_module)

      # Evaluate the block in the context of the class
      clazz.class_eval(&block) if block_given?

      clazz
    end

    private

    def validate_names(*params)
      params.each do |param|
        unless param.is_a?(Symbol) && param =~ /\A[a-z_][a-zA-Z_0-9]*\z/
          raise ArgumentError.new("param #{param} is not a valid identifier")
        end
      end
    end

    # Generates an initialize method with required and optional parameters,
    # delegating to the Struct constructor. Parameter names must have already
    # been validated.
    #
    # For a Value.new(:a, b: x), will define the method:
    #
    # def initialize(a, b = self.class.__constructor_default(:b))
    #   super(a, b)
    #   freeze
    # end
    def generate_constructor(arguments)
      params = arguments.map do |arg_name, required|
        if required
          arg_name
        else
          "#{arg_name} = self.class.__constructor_default(:#{arg_name})"
        end
      end

      <<-SRC
        def initialize(#{params.join(", ")})
          super(#{arguments.keys.join(", ")})
          freeze
        end
      SRC
    end

    # Generates an alternative construction method accepting keyword arguments
    # for required and optional parameters, delegating to the generated
    # constructor. Parameter names must have already been validated.
    #
    # For a Value.new(:a, b: x), will define the (class) method:
    #
    # def with(a:, b: __constructor_default(:b))
    #   self.new(a, b)
    # end
    def generate_keyword_constructor(arguments)
      params = arguments.map do |arg_name, required|
        if required
          "#{arg_name}:"
        else
          "#{arg_name}: __constructor_default(:#{arg_name})"
        end
      end

      <<-SRC
        def with(#{params.join(", ")})
          self.new(#{arguments.keys.join(", ")})
        end
      SRC
    end
  end

  def with(hash = {})
    return self if hash.empty?
    self.class.with(to_h.merge(hash))
  end
end
