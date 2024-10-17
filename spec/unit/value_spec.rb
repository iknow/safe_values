# frozen_string_literal: true

# rubocop:disable Performance/HashEachMethods, Style/Semicolon, Lint/MissingCopEnableDirective

require 'safe_values'

require_relative '../spec_helper'

RSpec.describe Value do
  describe 'Value.new' do
    it 'requires arguments' do
      expect { Value.new }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1+)')
    end

    it 'requires members to be valid identifiers' do
      expect { Value.new(:Dog) }.to raise_error(ArgumentError, "param Dog is not a valid identifier")
    end
  end

  context "with a simple value" do
    let(:value) { Value.new(:a, :b) }

    it "can construct an instance with positional arguments" do
      v = value.new(1, 2)
      expect(v.a).to eq(1)
      expect(v.b).to eq(2)
    end

    it "can construct an instance with keyword arguments" do
      v = value.with(b: 2, a: 1)
      expect(v.a).to eq(1)
      expect(v.b).to eq(2)
    end

    it "raises an error if unknown keyword arguments are provided" do
      expect { value.with(a: 1, b: 2, c: 3) }.to raise_error(ArgumentError, /unknown keyword/)
    end

    it "is immutable" do
      v = value.new(1, 2)
      expect { v.a = 10 }.to raise_error(RuntimeError, /can't modify frozen/)
    end

    it "can be mutated after duplicating" do
      v = value.new(1, 2).dup
      v.a = 10
      expect(v.a).to eq(10)
    end

    it "can update values via .with" do
      v = value.new(1, 2).with(a: 10)
      expect(v.a).to eq(10)
      expect(v.b).to eq(2)
    end
  end

  context "with optional arguments" do
    let(:value) { Value.new(:a, :b, c: 3, d: 4) }

    it "can construct an instance with positional arguments" do
      v = value.new(1, 2, 30)
      expect(v.a).to eq(1)
      expect(v.b).to eq(2)
      expect(v.c).to eq(30)
      expect(v.d).to eq(4)
    end

    it "can construct an instance with keyword arguments" do
      v = value.with(b: 2, d: 40, a: 1)
      expect(v.a).to eq(1)
      expect(v.b).to eq(2)
      expect(v.c).to eq(3)
      expect(v.d).to eq(40)
    end

    it "can update values via .with" do
      v = value.new(10, 20, 30, 40).with(a: 11, c: 31)
      expect(v.a).to eq(11)
      expect(v.b).to eq(20)
      expect(v.c).to eq(31)
      expect(v.d).to eq(40)
    end

    it "raises an error unless all required positional arguments are provided" do
      expect { value.new(1) }.to raise_error(ArgumentError, /wrong number of arguments/)
    end

    it "raises an error unless all required keyword arguments are provided" do
      expect { value.with(a: 1, c: 3, d: 4) }.to raise_error(ArgumentError, /missing keyword/)
    end
  end

  context "with lazy defaults" do
    let(:next_value) do
      x = 0
      ->() { x += 1 }
    end

    let(:value) { Value.new(a: Value.lazy(&next_value)) }

    it "can construct an instance with positional lazy arguments" do
      v = value.new
      expect(v.a).to eq(1)
      v = value.new
      expect(v.a).to eq(2)
      v = value.new(-1)
      expect(v.a).to eq(-1)
    end

    it "can construct an instance with keyword lazy arguments" do
      v = value.with()
      expect(v.a).to eq(1)
      v = value.with()
      expect(v.a).to eq(2)
      v = value.with(a: -1)
      expect(v.a).to eq(-1)
    end
  end

  context "with a class body" do
    let(:value) do
      Value.new(:a) do
        @calls = (@calls || 0) + 1

        def self.calls
          @calls
        end

        def initialize(a)
          raise ArgumentError.new("not even") unless a.even?
          super
        end

        def b
          a + 1
        end
      end
    end

    it "can override the constructor and call super" do
      expect { value.new(3) }.to raise_error(ArgumentError, "not even")
    end

    it "can define methods" do
      v = value.new(2)
      expect(v.a).to eq(2)
      expect(v.b).to eq(3)
    end

    it "only invokes the class body once" do
      expect(value.calls).to eq(1)
    end
  end
end
