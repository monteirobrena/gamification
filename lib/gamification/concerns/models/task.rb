module Gamification::Concerns::Models::Task
  extend ActiveSupport::Concern

  included do
    belongs_to :rewarding, polymorphic: true
    has_one :medal
    has_many :rewards

    # TODO: These should be SQL. But that's hard.
    scope :completed_by,  ->(subject) { all.select { |task| task.completed_by? subject }}
    scope :incomplete_by, ->(subject) { all.reject { |task| task.completed_by? subject }}

    # Determine whether the given subject has completed the task.
    #
    # subject - An ActiveRecord model that can receive rewards.
    def completed_by? subject
      !!reward_for(subject)
    end

    # Complete the task for the given subject.
    #
    # subject - An ActiveRecord model that can receive rewards.
    def complete_for subject
      if completed_by? subject
        raise Completed, "Task is already completed for #{subject}"
      else
        ::Gamification::Reward.create! task: self, rewardable: subject
      end
    end

    private

    # Find the Scoring for the given subject.
    #
    # subject - An ActiveRecord model that can receive rewards.
    def reward_for subject
      rewards.find_by rewardable: subject
    end

    class Completed < StandardError; end
  end

  module ClassMethods
    # Complete all tasks for the given subject.
    #
    # subject - An ActiveRecord model that can receive rewards.
    def complete_for subject
      all.map { |task| task.complete_for subject unless task.completed_by? subject }.compact
    end
  end
end
