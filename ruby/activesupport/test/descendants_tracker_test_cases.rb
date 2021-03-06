# frozen_string_literal: true

require "set"

module DescendantsTrackerTestCases
  class Parent
    extend ActiveSupport::DescendantsTracker
  end

  class Child1 < Parent
  end

  class Child2 < Parent
  end

  class Grandchild1 < Child1
  end

  class Grandchild2 < Child1
  end

  ALL = [Parent, Child1, Child2, Grandchild1, Grandchild2]

  def test_descendants
    assert_equal_sets [Child1, Grandchild1, Grandchild2, Child2], Parent.descendants
    assert_equal_sets [Grandchild1, Grandchild2], Child1.descendants
    assert_equal_sets [], Child2.descendants
  end

  def test_descendants_with_garbage_collected_classes
    # The Ruby GC (and most other GCs for that matter) are not fully precise.
    # When GC is run, the whole stack is scanned to mark any object reference
    # in registers. But some of these references might simply be leftovers from
    # previous method calls waiting to be overridden, and there's no definite
    # way to clear them. By executing this code in a distinct thread, we ensure
    # that such references are on a stack that will be entirely garbage
    # collected, effectively working around the problem.
    Thread.new do
      child_klass = Class.new(Parent)
      assert_equal_sets [Child1, Grandchild1, Grandchild2, Child2, child_klass], Parent.descendants
    end.join

    # Calling `GC.start` 4 times should trigger a full GC run
    4.times do
      GC.start
    end

    assert_equal_sets [Child1, Grandchild1, Grandchild2, Child2], Parent.descendants
  end

  def test_direct_descendants
    assert_equal_sets [Child1, Child2], Parent.direct_descendants
    assert_equal_sets [Grandchild1, Grandchild2], Child1.direct_descendants
    assert_equal_sets [], Child2.direct_descendants
  end

  def test_subclasses
    [Parent, Child1, Child2].each do |klass|
      assert_equal klass.direct_descendants, klass.subclasses
    end
  end

  def test_clear
    mark_as_autoloaded(*ALL) do
      ActiveSupport::DescendantsTracker.clear
      ALL.each do |k|
        assert_empty ActiveSupport::DescendantsTracker.descendants(k)
      end
    end
  end

  private
    def assert_equal_sets(expected, actual)
      assert_equal Set.new(expected), Set.new(actual)
    end

    def mark_as_autoloaded(*klasses)
      # If ActiveSupport::Dependencies is not loaded, forget about autoloading.
      # This allows using AS::DescendantsTracker without AS::Dependencies.
      if defined? ActiveSupport::Dependencies
        old_autoloaded = ActiveSupport::Dependencies.autoloaded_constants.dup
        ActiveSupport::Dependencies.autoloaded_constants = klasses.map(&:name)
      end

      old_descendants = ActiveSupport::DescendantsTracker.class_eval("@@direct_descendants").dup
      old_descendants.each { |k, v| old_descendants[k] = v.dup }

      yield
    ensure
      ActiveSupport::Dependencies.autoloaded_constants = old_autoloaded if defined? ActiveSupport::Dependencies
      ActiveSupport::DescendantsTracker.class_eval("@@direct_descendants").replace(old_descendants)
    end
end
